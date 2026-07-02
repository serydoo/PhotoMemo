import Foundation
import UniformTypeIdentifiers
import Combine

@MainActor
final class ExternalPhotoIntakeCenter:
    ObservableObject {

    static let shared =
        ExternalPhotoIntakeCenter()

    @Published private(set) var revision =
        UUID()

    @Published private(set) var defaultConfigurationSnapshot:
        BatchConfigurationSnapshot

    private var pendingRequests:
        [ExternalPhotoIntakeRequest] = []

    private let intakeStore:
        ExternalPhotoIntakeStore

    private let supportedTypes:
        [UTType] = [
            .jpeg,
            .png,
            .heic,
            .heif,
            .tiff
        ]

    init() {

        self.intakeStore =
            .shared

        self.defaultConfigurationSnapshot =
            SettingsService()
            .buildBatchConfigurationSnapshot()
    }

    init(
        intakeStore:
            ExternalPhotoIntakeStore,
        settingsService:
            SettingsService
    ) {

        self.intakeStore =
            intakeStore

        self.defaultConfigurationSnapshot =
            settingsService
            .buildBatchConfigurationSnapshot()
    }

    func updateDefaultConfiguration(
        _ snapshot: BatchConfigurationSnapshot
    ) {

        defaultConfigurationSnapshot = snapshot
    }

    func submit(
        urls: [URL],
        importSummary:
            ExternalPhotoImportSummary? = nil,
        source: BatchJobLaunchSource
    ) {

        let acceptedURLs =
            urls
            .map(normalizedFileURL(for:))
            .filter(isSupportedImageURL)
            .reduce(into: [URL]()) {
                partialResult,
                url in

                if !partialResult.contains(
                    url.standardizedFileURL
                ) {
                    partialResult.append(url)
                }
            }

        guard !acceptedURLs.isEmpty else {
            return
        }

        if let persistedRequest =
            intakeStore.persistRequest(
                urls: acceptedURLs,
                source: source,
                importSummary:
                    importSummary,
                configurationSnapshot:
                    defaultConfigurationSnapshot
            ) {
            pendingRequests.append(
                persistedRequest
            )
        } else {
            pendingRequests.append(
                ExternalPhotoIntakeRequest(
                    launchSource: source,
                    urls: acceptedURLs,
                    items:
                        acceptedURLs.map {
                            ExternalPhotoIntakeItem(
                                managedURL: $0
                            )
                        },
                    configurationSnapshot:
                        defaultConfigurationSnapshot,
                    importSummary:
                        importSummary
                )
            )
        }

        revision = UUID()
    }

    func drainPendingRequests() -> [ExternalPhotoIntakeRequest] {

        let persistedRequests =
            intakeStore.drainRequests()

        var requests = pendingRequests

        if !persistedRequests.isEmpty {
            let pendingIDs =
                Set(
                    requests.map(\.id)
                )

            requests.append(
                contentsOf:
                    persistedRequests.filter {
                        !pendingIDs.contains(
                            $0.id
                        )
                    }
            )
        }

        pendingRequests.removeAll()
        return requests
    }
}

private extension ExternalPhotoIntakeCenter {

    func normalizedFileURL(
        for url: URL
    ) -> URL {

        if url.isFileURL {
            return url.standardizedFileURL
        }

        return url
    }

    func isSupportedImageURL(
        _ url: URL
    ) -> Bool {

        guard url.isFileURL else {
            return false
        }

        guard
            let type = UTType(
                filenameExtension:
                    url.pathExtension
                    .lowercased()
            )
        else {
            return false
        }

        return supportedTypes.contains(type)
    }
}
