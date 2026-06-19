import Foundation

struct ExternalPhotoIntakeRequest:
    Identifiable,
    Hashable,
    Codable {

    let id: UUID

    let launchSource: BatchJobLaunchSource

    let urls: [URL]

    let configurationSnapshot:
        BatchConfigurationSnapshot

    let receivedAt: Date

    init(
        id: UUID = UUID(),
        launchSource: BatchJobLaunchSource,
        urls: [URL],
        configurationSnapshot: BatchConfigurationSnapshot,
        receivedAt: Date = Date()
    ) {
        self.id = id
        self.launchSource = launchSource
        self.urls = urls
        self.configurationSnapshot =
            configurationSnapshot
        self.receivedAt = receivedAt
    }
}
