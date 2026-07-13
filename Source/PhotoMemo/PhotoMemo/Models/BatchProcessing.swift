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

extension BatchJobState {

    var displayTitle: String {

        switch self {

        case .draft:
            return "等待开始"

        case .queued:
            return "排队中"

        case .preparing:
            return "准备处理"

        case .ready:
            return "处理中"

        case .running:
            return "正在写入"

        case .completed:
            return "已完成"

        case .failed:
            return "有失败项"

        case .cancelled:
            return "已取消"
        }
    }
}

enum BatchJobLaunchSource: String, Codable, Hashable {

    case inAppPreview

    case shareExtension

    case fileOpen

    case quickAction

    case automation
}

extension BatchJobLaunchSource {

    var displayTitle: String {

        switch self {

        case .shareExtension:
            return "分享进入"

        case .fileOpen:
            return "文件打开"

        case .quickAction:
            return "快捷动作"

        case .automation:
            return "自动流程"

        case .inAppPreview:
            return "主界面"
        }
    }
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

    var displayTitle: String {

        switch self {

        case .queued:
            return "排队中"

        case .importing:
            return "读取原图"

        case .metadataReady:
            return "读取 EXIF"

        case .previewReady:
            return "生成模板内容"

        case .waitingForExport:
            return "等待导出"

        case .exporting:
            return "生成图片"

        case .savingToPhotoLibrary:
            return "写入系统图库"

        case .completed:
            return "处理完成"

        case .failed:
            return "处理失败"

        case .cancelled:
            return "已取消"
        }
    }

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

    // Transport/compatibility DTO only. New production semantics belong in
    // ConfigurationSnapshot.

    let id: UUID

    let createdAt: Date

    var configurationID: UUID?

    var configurationRevision: Int?

    var productionContractVersion: Int?

    var template: Template

    var badge: Badge?

    var anchor: Anchor?

    var memorySubjectText: String?

    var locationDisplayConfiguration:
        ExpressionModuleConfiguration?

    var usesCustomMemoryWriteText: Bool

    var customMemoryWriteText: String

    var presentationRouteRawValue: String?

    var logoModeRawValue: String?

#if !PHOTOMEMO_SHARE_EXTENSION
    private(set) var frozenMemorySubject:
        MemorySubject?

    private(set) var frozenConfigurationSnapshot:
        ConfigurationSnapshot?
#endif

    var shouldWritePhotoDescription: Bool

    var photoDescriptionOverride: String

    var selectedAlbumIdentifier: String

    var mediaOutputModeRawValue: String?

    var livePhotoPolicyRawValue: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        configurationID: UUID? = nil,
        configurationRevision: Int? = nil,
        productionContractVersion: Int? = nil,
        template: Template,
        badge: Badge?,
        anchor: Anchor?,
        memorySubjectText: String? = nil,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration? = nil,
        usesCustomMemoryWriteText: Bool = false,
        customMemoryWriteText: String = "",
        presentationRouteRawValue: String? = nil,
        logoModeRawValue: String? = nil,
        shouldWritePhotoDescription: Bool,
        photoDescriptionOverride: String,
        selectedAlbumIdentifier: String,
        mediaOutputModeRawValue: String? = nil,
        livePhotoPolicyRawValue: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.configurationID = configurationID
        self.configurationRevision =
            configurationRevision
        self.productionContractVersion =
            productionContractVersion
        self.template = template
        self.badge = badge
        self.anchor = anchor
        self.memorySubjectText =
            memorySubjectText
        self.locationDisplayConfiguration =
            locationDisplayConfiguration
        self.usesCustomMemoryWriteText =
            usesCustomMemoryWriteText
        self.customMemoryWriteText =
            customMemoryWriteText
        self.presentationRouteRawValue =
            presentationRouteRawValue
        self.logoModeRawValue =
            logoModeRawValue
        self.shouldWritePhotoDescription =
            shouldWritePhotoDescription
        self.photoDescriptionOverride =
            photoDescriptionOverride
        self.selectedAlbumIdentifier =
            selectedAlbumIdentifier
        self.mediaOutputModeRawValue =
            mediaOutputModeRawValue
        self.livePhotoPolicyRawValue =
            livePhotoPolicyRawValue
    }
}

extension BatchConfigurationSnapshot {

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case configurationID
        case configurationRevision
        case productionContractVersion
        case template
        case badge
        case anchor
        case memorySubjectText
        case locationDisplayConfiguration
        case usesCustomMemoryWriteText
        case customMemoryWriteText
        case presentationRouteRawValue
        case logoModeRawValue
#if !PHOTOMEMO_SHARE_EXTENSION
        case frozenMemorySubject
        case frozenConfigurationSnapshot
#endif
        case shouldWritePhotoDescription
        case photoDescriptionOverride
        case selectedAlbumIdentifier
        case mediaOutputModeRawValue
        case livePhotoPolicyRawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(
            Date.self,
            forKey: .createdAt
        )
        configurationID = try container.decodeIfPresent(
            UUID.self,
            forKey: .configurationID
        )
        configurationRevision = try container.decodeIfPresent(
            Int.self,
            forKey: .configurationRevision
        )
        productionContractVersion = try container.decodeIfPresent(
            Int.self,
            forKey: .productionContractVersion
        )
        template = try container.decode(
            Template.self,
            forKey: .template
        )
        badge = try container.decodeIfPresent(
            Badge.self,
            forKey: .badge
        )
        anchor = try container.decodeIfPresent(
            Anchor.self,
            forKey: .anchor
        )
        memorySubjectText = try container.decodeIfPresent(
            String.self,
            forKey: .memorySubjectText
        )
        locationDisplayConfiguration = try container.decodeIfPresent(
            ExpressionModuleConfiguration.self,
            forKey: .locationDisplayConfiguration
        )
        usesCustomMemoryWriteText = try container.decodeIfPresent(
            Bool.self,
            forKey: .usesCustomMemoryWriteText
        ) ?? false
        customMemoryWriteText = try container.decodeIfPresent(
            String.self,
            forKey: .customMemoryWriteText
        ) ?? ""
        presentationRouteRawValue = try container.decodeIfPresent(
            String.self,
            forKey: .presentationRouteRawValue
        )
        logoModeRawValue = try container.decodeIfPresent(
            String.self,
            forKey: .logoModeRawValue
        )
#if !PHOTOMEMO_SHARE_EXTENSION
        frozenMemorySubject = try container.decodeIfPresent(
            MemorySubject.self,
            forKey: .frozenMemorySubject
        )
        frozenConfigurationSnapshot = try container.decodeIfPresent(
            ConfigurationSnapshot.self,
            forKey: .frozenConfigurationSnapshot
        )
#endif
        shouldWritePhotoDescription = try container.decode(
            Bool.self,
            forKey: .shouldWritePhotoDescription
        )
        photoDescriptionOverride = try container.decode(
            String.self,
            forKey: .photoDescriptionOverride
        )
        selectedAlbumIdentifier = try container.decode(
            String.self,
            forKey: .selectedAlbumIdentifier
        )
        mediaOutputModeRawValue = try container.decodeIfPresent(
            String.self,
            forKey: .mediaOutputModeRawValue
        )
        livePhotoPolicyRawValue = try container.decodeIfPresent(
            String.self,
            forKey: .livePhotoPolicyRawValue
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(
            configurationID,
            forKey: .configurationID
        )
        try container.encodeIfPresent(
            configurationRevision,
            forKey: .configurationRevision
        )
        try container.encodeIfPresent(
            productionContractVersion,
            forKey: .productionContractVersion
        )
        try container.encode(template, forKey: .template)
        try container.encodeIfPresent(badge, forKey: .badge)
        try container.encodeIfPresent(anchor, forKey: .anchor)
        try container.encodeIfPresent(
            memorySubjectText,
            forKey: .memorySubjectText
        )
        try container.encodeIfPresent(
            locationDisplayConfiguration,
            forKey: .locationDisplayConfiguration
        )
        try container.encode(
            usesCustomMemoryWriteText,
            forKey: .usesCustomMemoryWriteText
        )
        try container.encode(
            customMemoryWriteText,
            forKey: .customMemoryWriteText
        )
        try container.encodeIfPresent(
            presentationRouteRawValue,
            forKey: .presentationRouteRawValue
        )
        try container.encodeIfPresent(
            logoModeRawValue,
            forKey: .logoModeRawValue
        )
#if !PHOTOMEMO_SHARE_EXTENSION
        try container.encodeIfPresent(
            frozenMemorySubject,
            forKey: .frozenMemorySubject
        )
        try container.encodeIfPresent(
            frozenConfigurationSnapshot,
            forKey: .frozenConfigurationSnapshot
        )
#endif
        try container.encode(
            shouldWritePhotoDescription,
            forKey: .shouldWritePhotoDescription
        )
        try container.encode(
            photoDescriptionOverride,
            forKey: .photoDescriptionOverride
        )
        try container.encode(
            selectedAlbumIdentifier,
            forKey: .selectedAlbumIdentifier
        )
        try container.encodeIfPresent(
            mediaOutputModeRawValue,
            forKey: .mediaOutputModeRawValue
        )
        try container.encodeIfPresent(
            livePhotoPolicyRawValue,
            forKey: .livePhotoPolicyRawValue
        )
    }
}

extension BatchConfigurationSnapshot {

    var productionConfigurationReference:
        ProductionConfigurationReference? {
        guard let configurationID,
            let configurationRevision,
            let productionContractVersion
        else {
            return nil
        }
        return ProductionConfigurationReference(
            configurationID: configurationID,
            revision: configurationRevision,
            contractVersion: productionContractVersion
        )
    }

    func withProductionConfigurationReference(
        _ reference: ProductionConfigurationReference
    ) -> BatchConfigurationSnapshot {
        var copy = self
        copy.configurationID = reference.configurationID
        copy.configurationRevision = reference.revision
        copy.productionContractVersion = reference.contractVersion
#if !PHOTOMEMO_SHARE_EXTENSION
        if var snapshot = copy.frozenConfigurationSnapshot {
            snapshot.configurationID = reference.configurationID
            snapshot.configurationRevision = reference.revision
            copy.frozenConfigurationSnapshot = snapshot
        }
#endif
        return copy
    }
}

#if !PHOTOMEMO_SHARE_EXTENSION
extension BatchConfigurationSnapshot {

    var v1MediaOutputMode: V1MediaOutputMode {
        if let livePhotoPolicyRawValue,
            let policy =
                MemoryConfigurationRecord.Output.LivePhotoPolicy(
                    rawValue: livePhotoPolicyRawValue
                ) {
            switch policy {
            case .preserveMotion:
                return .originalFormat
            case .staticImageOnly:
                return .staticImage
            }
        }

        guard
            let mediaOutputModeRawValue,
            let mode =
                V1MediaOutputMode(
                    rawValue:
                        mediaOutputModeRawValue
                )
        else {
            return .originalFormat
        }

        return mode
    }
}
#endif

#if !PHOTOMEMO_SHARE_EXTENSION
extension BatchConfigurationSnapshot {

    var resolvedProductionAnchorTitle: String? {
#if !PHOTOMEMO_SHARE_EXTENSION
        if let canonicalProductionSnapshot {
            return normalizedAnchorTitle(
                canonicalProductionSnapshot
                    .primaryAnchor?
                    .title
            )
        }
#endif

        return normalizedAnchorTitle(
            legacyAnchor?.title
        )
    }

    var canonicalProductionSnapshot:
        ConfigurationSnapshot? {
        guard var snapshot =
            frozenConfigurationSnapshot
        else {
            return nil
        }

        if snapshot.memorySubject == nil,
           let frozenMemorySubject {
            snapshot.memorySubject =
                frozenMemorySubject
        }

        guard snapshot.memorySubject != nil else {
            return nil
        }

        return snapshot
    }

    var completedFrozenConfigurationSnapshot:
        ConfigurationSnapshot? {
        canonicalProductionSnapshot
    }

    var legacyFrozenMemorySubject:
        MemorySubject? {
        frozenMemorySubject
    }

    func withLegacyPairedFrozenMemoryConfiguration(
        subject: MemorySubject,
        snapshot: ConfigurationSnapshot
    ) -> BatchConfigurationSnapshot {
        var copy = self
        var frozenSnapshot = snapshot
        if frozenSnapshot.memorySubject == nil {
            frozenSnapshot.memorySubject = subject
        }
        copy.frozenMemorySubject = subject
        copy.frozenConfigurationSnapshot = frozenSnapshot
        return copy
    }

    func withLegacyFrozenMemorySubject(
        _ subject: MemorySubject
    ) -> BatchConfigurationSnapshot {
        var copy = self
        copy.frozenMemorySubject = subject
        return copy
    }

    func withCanonicalProductionSnapshot(
        _ snapshot: ConfigurationSnapshot
    ) -> BatchConfigurationSnapshot {
        var copy = self
        copy.frozenConfigurationSnapshot = snapshot
        return copy
    }

    func withConfigurationIdentity(
        id: UUID,
        revision: Int
    ) -> BatchConfigurationSnapshot {
        var copy = self
        copy.configurationID = id
        copy.configurationRevision = revision
        if var snapshot = copy.frozenConfigurationSnapshot {
            snapshot.configurationID = id
            snapshot.configurationRevision = revision
            copy.frozenConfigurationSnapshot = snapshot
        }
        return copy
    }

    private func normalizedAnchorTitle(
        _ title: String?
    ) -> String? {
        let trimmed =
            title?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
#endif

extension BatchConfigurationSnapshot {

    var legacyAnchor: Anchor? {
        anchor
    }

    var legacyMemorySubjectText: String? {
        memorySubjectText
    }
}

struct BatchTaskIntakePayload:
    Codable,
    Hashable {

    var sourceURL: URL

    var sourceIdentifier: String?

    var fileName: String?

    var contentTypeIdentifier: String?

    var requestedAt: Date

    init(
        sourceURL: URL,
        sourceIdentifier: String? = nil,
        fileName: String? = nil,
        contentTypeIdentifier: String? = nil,
        requestedAt: Date = Date()
    ) {
        self.sourceURL = sourceURL
        self.sourceIdentifier = sourceIdentifier
        self.fileName = fileName
        self.contentTypeIdentifier =
            contentTypeIdentifier
        self.requestedAt = requestedAt
    }
}

struct BatchTaskFailure:
    Codable,
    Hashable {

    enum Classification:
        String,
        Codable,
        Hashable {

        case unsupportedInput

        case interrupted

        case processingFailure
    }

    var phase: BatchTaskPhase

    var message: String

    var classification:
        Classification?

    var canRetry: Bool

    var timestamp: Date

    init(
        phase: BatchTaskPhase,
        message: String,
        classification:
            Classification? = nil,
        canRetry: Bool = true,
        timestamp: Date = Date()
    ) {
        self.phase = phase
        self.message = message
        self.classification =
            classification
        self.canRetry = canRetry
        self.timestamp = timestamp
    }
}

extension BatchTaskFailure {

    var phaseTitle: String {
        phase.displayTitle
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

    let sourceIdentifier: String?

    let contentTypeIdentifier: String?

    let createdAt: Date

    var phase: BatchTaskPhase

    var captureDate: Date?

    var savedAlbumName: String?

    var savedAssetIdentifier: String?

    var renderedFileURL: URL?

    var notificationAttachmentURL: URL?

    var retryCount: Int

    var failure: BatchTaskFailure?

    var progress: BatchTaskProgress

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        fileName: String? = nil,
        sourceIdentifier: String? = nil,
        contentTypeIdentifier: String? = nil,
        createdAt: Date = Date(),
        phase: BatchTaskPhase = .queued,
        captureDate: Date? = nil,
        savedAlbumName: String? = nil,
        savedAssetIdentifier: String? = nil,
        renderedFileURL: URL? = nil,
        notificationAttachmentURL: URL? = nil,
        retryCount: Int = 0,
        failure: BatchTaskFailure? = nil,
        progress: BatchTaskProgress = .init()
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.fileName =
            fileName ?? sourceURL.lastPathComponent
        self.sourceIdentifier =
            sourceIdentifier
        self.contentTypeIdentifier =
            contentTypeIdentifier
        self.createdAt = createdAt
        self.phase = phase
        self.captureDate = captureDate
        self.savedAlbumName = savedAlbumName
        self.savedAssetIdentifier = savedAssetIdentifier
        self.renderedFileURL = renderedFileURL
        self.notificationAttachmentURL =
            notificationAttachmentURL
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

    var intakeSummary:
        ExternalPhotoImportSummary?

    var policy: BatchPipelinePolicy

    var startNotificationSentAt: Date?

    var lastProgressNotificationStage: String?

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
        intakeSummary:
            ExternalPhotoImportSummary? = nil,
        policy: BatchPipelinePolicy = .init(),
        startNotificationSentAt: Date? = nil,
        lastProgressNotificationStage: String? = nil,
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
        self.intakeSummary =
            intakeSummary
        self.policy = policy
        self.startNotificationSentAt =
            startNotificationSentAt
        self.lastProgressNotificationStage =
            lastProgressNotificationStage
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

    var latestFailure: BatchTaskFailure? {

        tasks.compactMap(\.failure)
            .max {
                $0.timestamp < $1.timestamp
            }
    }

    var hasRetryableFailures: Bool {

        tasks.contains {
            $0.phase == .failed
            && ($0.failure?.canRetry ?? true)
        }
    }

    var hasOnlyUnsupportedFailures: Bool {

        let failedTasks =
            tasks.filter {
                $0.phase == .failed
            }

        guard !failedTasks.isEmpty else {
            return false
        }

        return failedTasks.allSatisfy {
            $0.failure?.classification
            == .unsupportedInput
        }
    }

    var exceptionTaskCount: Int {

        failedTaskCount
    }

    var completionRatio: Double {

        guard totalTaskCount > 0 else {
            return 0
        }

        return Double(completedTaskCount)
            / Double(totalTaskCount)
    }

    var isMostlyCompletedWithExceptions: Bool {

        completedTaskCount > 0
        && failedTaskCount > 0
        && completionRatio >= 0.8
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

struct BatchFailureSummary: Hashable {

    let jobID: UUID

    let jobTitle: String

    let failedTaskCount: Int

    let completedTaskCount: Int

    let totalTaskCount: Int

    let hasRetryableFailures: Bool

    let latestFailure: BatchTaskFailure

    let updatedAt: Date
}

struct BatchFailureRecord:
    Identifiable,
    Hashable {

    let id: String

    let jobID: UUID

    let jobTitle: String

    let taskID: UUID

    let fileName: String

    let retryCount: Int

    let failure: BatchTaskFailure
}

struct ExternalIntakeSummary: Hashable {

    let jobID: UUID

    let title: String

    let launchSource: BatchJobLaunchSource

    let taskCount: Int

    let state: BatchJobState

    let templateName: String

    let anchorTitle: String?

    let importSummary:
        ExternalPhotoImportSummary?

    let updatedAt: Date
}
