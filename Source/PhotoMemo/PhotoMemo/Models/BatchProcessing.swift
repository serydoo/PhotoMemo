import Foundation

enum BatchJobState: String, Codable, Hashable {

    case draft

    case queued

    case preparing

    case ready

    case running

    case completed

    case failed

    case cancelled
}

enum BatchJobLaunchSource: String, Codable, Hashable {

    case inAppPreview

    case shareExtension

    case fileOpen

    case quickAction

    case automation
}

enum BatchTaskPhase: String, Codable, Hashable {

    case queued

    case importing

    case metadataReady

    case previewReady

    case waitingForExport

    case exporting

    case savingToPhotoLibrary

    case completed

    case failed

    case cancelled
}

extension BatchTaskPhase {

    var isTerminal: Bool {

        switch self {

        case .completed,
             .failed,
             .cancelled:

            return true

        case .queued,
             .importing,
             .metadataReady,
             .previewReady,
             .waitingForExport,
             .exporting,
             .savingToPhotoLibrary:

            return false
        }
    }
}

struct BatchPipelinePolicy: Codable, Hashable {

    var importConcurrency: Int

    var previewConcurrency: Int

    var exportConcurrency: Int

    var photoLibraryWriteConcurrency: Int

    init(
        importConcurrency: Int = 2,
        previewConcurrency: Int = 2,
        exportConcurrency: Int = 1,
        photoLibraryWriteConcurrency: Int = 1
    ) {
        self.importConcurrency = max(importConcurrency, 1)
        self.previewConcurrency = max(previewConcurrency, 1)
        self.exportConcurrency = max(exportConcurrency, 1)
        self.photoLibraryWriteConcurrency =
            max(photoLibraryWriteConcurrency, 1)
    }
}

struct BatchConfigurationSnapshot:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID

    let createdAt: Date

    var template: Template

    var badge: Badge?

    var anchor: Anchor?

    var shouldWritePhotoDescription: Bool

    var photoDescriptionOverride: String

    var selectedAlbumIdentifier: String

    var titleText: String

    var storyText: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        template: Template,
        badge: Badge?,
        anchor: Anchor?,
        shouldWritePhotoDescription: Bool,
        photoDescriptionOverride: String,
        selectedAlbumIdentifier: String,
        titleText: String,
        storyText: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.template = template
        self.badge = badge
        self.anchor = anchor
        self.shouldWritePhotoDescription =
            shouldWritePhotoDescription
        self.photoDescriptionOverride =
            photoDescriptionOverride
        self.selectedAlbumIdentifier =
            selectedAlbumIdentifier
        self.titleText = titleText
        self.storyText = storyText
    }
}

struct BatchTaskIntakePayload:
    Codable,
    Hashable {

    var sourceURL: URL

    var sourceIdentifier: String?

    var requestedAt: Date

    init(
        sourceURL: URL,
        sourceIdentifier: String? = nil,
        requestedAt: Date = Date()
    ) {
        self.sourceURL = sourceURL
        self.sourceIdentifier = sourceIdentifier
        self.requestedAt = requestedAt
    }
}

struct BatchTaskFailure:
    Codable,
    Hashable {

    var phase: BatchTaskPhase

    var message: String

    var timestamp: Date

    init(
        phase: BatchTaskPhase,
        message: String,
        timestamp: Date = Date()
    ) {
        self.phase = phase
        self.message = message
        self.timestamp = timestamp
    }
}

struct BatchTaskProgress:
    Codable,
    Hashable {

    var currentUnit: Int

    var totalUnits: Int

    var statusMessage: String

    init(
        currentUnit: Int = 0,
        totalUnits: Int = 1,
        statusMessage: String = ""
    ) {
        self.currentUnit = max(currentUnit, 0)
        self.totalUnits = max(totalUnits, 1)
        self.statusMessage = statusMessage
    }

    var fractionCompleted: Double {

        guard totalUnits > 0 else {
            return 0
        }

        return min(
            max(
                Double(currentUnit) / Double(totalUnits),
                0
            ),
            1
        )
    }
}

struct BatchTask:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID

    let sourceURL: URL

    let fileName: String

    let createdAt: Date

    var phase: BatchTaskPhase

    var captureDate: Date?

    var savedAlbumName: String?

    var savedAssetIdentifier: String?

    var renderedFileURL: URL?

    var retryCount: Int

    var failure: BatchTaskFailure?

    var progress: BatchTaskProgress

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        fileName: String? = nil,
        createdAt: Date = Date(),
        phase: BatchTaskPhase = .queued,
        captureDate: Date? = nil,
        savedAlbumName: String? = nil,
        savedAssetIdentifier: String? = nil,
        renderedFileURL: URL? = nil,
        retryCount: Int = 0,
        failure: BatchTaskFailure? = nil,
        progress: BatchTaskProgress = .init()
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.fileName =
            fileName ?? sourceURL.lastPathComponent
        self.createdAt = createdAt
        self.phase = phase
        self.captureDate = captureDate
        self.savedAlbumName = savedAlbumName
        self.savedAssetIdentifier = savedAssetIdentifier
        self.renderedFileURL = renderedFileURL
        self.retryCount = max(retryCount, 0)
        self.failure = failure
        self.progress = progress
    }
}

struct BatchJob:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID

    var title: String

    var createdAt: Date

    var updatedAt: Date

    var state: BatchJobState

    var launchSource: BatchJobLaunchSource

    var configuration: BatchConfigurationSnapshot

    var tasks: [BatchTask]

    var policy: BatchPipelinePolicy

    var startNotificationSentAt: Date?

    var finalNotificationSentAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        state: BatchJobState = .draft,
        launchSource: BatchJobLaunchSource = .inAppPreview,
        configuration: BatchConfigurationSnapshot,
        tasks: [BatchTask],
        policy: BatchPipelinePolicy = .init(),
        startNotificationSentAt: Date? = nil,
        finalNotificationSentAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.state = state
        self.launchSource = launchSource
        self.configuration = configuration
        self.tasks = tasks
        self.policy = policy
        self.startNotificationSentAt =
            startNotificationSentAt
        self.finalNotificationSentAt =
            finalNotificationSentAt
    }
}

extension BatchJob {

    var completedTaskCount: Int {

        tasks.filter {
            $0.phase == .completed
        }.count
    }

    var failedTaskCount: Int {

        tasks.filter {
            $0.phase == .failed
        }.count
    }

    var runningTaskCount: Int {

        tasks.filter {
            !$0.phase.isTerminal
        }.count
    }

    var totalTaskCount: Int {

        tasks.count
    }
}

struct BatchUsageLeaderboardEntry: Hashable {

    let title: String

    let count: Int
}

struct BatchUsageSnapshot: Hashable {

    let completedPhotoCount: Int

    let completedBatchCount: Int

    let failedPhotoCount: Int

    let activePhotoCount: Int

    let templateChampion: BatchUsageLeaderboardEntry?

    let anchorChampion: BatchUsageLeaderboardEntry?

    let lastCompletedAt: Date?
}
