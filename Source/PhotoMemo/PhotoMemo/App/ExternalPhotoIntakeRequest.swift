import Foundation

struct ExternalPhotoImportSummary:
    Hashable,
    Codable {

    let importedCount: Int

    let skippedCount: Int

    let failedCount: Int

    var selectedCount: Int {
        importedCount + skippedCount + failedCount
    }

    var hasWarnings: Bool {
        skippedCount > 0 || failedCount > 0
    }
}

struct ExternalPhotoIntakeRequest:
    Identifiable,
    Hashable,
    Codable {

    let id: UUID

    let launchSource: BatchJobLaunchSource

    let urls: [URL]

    let configurationSnapshot:
        BatchConfigurationSnapshot

    let importSummary:
        ExternalPhotoImportSummary?

    let receivedAt: Date

    init(
        id: UUID = UUID(),
        launchSource: BatchJobLaunchSource,
        urls: [URL],
        configurationSnapshot: BatchConfigurationSnapshot,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        receivedAt: Date = Date()
    ) {
        self.id = id
        self.launchSource = launchSource
        self.urls = urls
        self.configurationSnapshot =
            configurationSnapshot
        self.importSummary =
            importSummary
        self.receivedAt = receivedAt
    }
}
