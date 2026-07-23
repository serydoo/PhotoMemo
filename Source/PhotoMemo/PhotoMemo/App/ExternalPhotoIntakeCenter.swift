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

    @Published private(set) var intakePersistenceError:
        PhotoMemoSharedDefaultsReadFailure?

    @Published private(set) var defaultConfigurationSnapshot:
        BatchConfigurationSnapshot

    private var pendingRequests:
        [ExternalPhotoIntakeRequest] = []

    private let intakeStore:
        ExternalPhotoIntakeStore

    init() {

        self.intakeStore =
            .shared

        self.defaultConfigurationSnapshot =
            SettingsService()
            .buildBatchConfigurationSnapshot()
        self.intakePersistenceError = nil
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
        self.intakePersistenceError = nil
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

    func submit(
        items: [ExternalPhotoIntakeItem],
        importSummary:
            ExternalPhotoImportSummary? = nil,
        source: BatchJobLaunchSource
    ) {

        let acceptedItems =
            items
            .map(normalizedIntakeItem)
            .filter(isSupportedIntakeItem)
            .reduce(into: [ExternalPhotoIntakeItem]()) {
                partialResult,
                item in

                if !partialResult.contains(
                    where: {
                        $0.managedURL
                            .standardizedFileURL
                            .path
                        == item.managedURL
                            .standardizedFileURL
                            .path
                    }
                ) {
                    partialResult.append(item)
                }
            }

        guard !acceptedItems.isEmpty else {
            return
        }

        if let persistedRequest =
            intakeStore.persistRequest(
                items: acceptedItems,
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
                    urls:
                        acceptedItems.map(
                            \.managedURL
                        ),
                    items:
                        acceptedItems,
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

        let persistedRequests: [ExternalPhotoIntakeRequest]
        switch intakeStore.loadRequestsForProcessingResult() {
        case .success(let requests):
            intakePersistenceError = nil
            persistedRequests = requests
        case .noValue:
            intakePersistenceError = nil
            persistedRequests = []
        case .decodingFailed(let failure):
            intakePersistenceError = failure
            persistedRequests = []
        }

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

        return requests
    }

    func acknowledgeProcessedRequests(
        _ requests: [ExternalPhotoIntakeRequest]
    ) -> PhotoMemoSharedDefaultsWriteResult {

        let requestIDs = Set(requests.map(\.id))
        let result = intakeStore.acknowledgeRequests(requestIDs)

        guard case .success = result else {
            return result
        }

        pendingRequests.removeAll {
            requestIDs.contains($0.id)
        }
        revision = UUID()
        return result
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

        return PhotoProcessingInputPolicy.standard
            .isSupportedContentType(type)
    }

    func normalizedIntakeItem(
        _ item: ExternalPhotoIntakeItem
    ) -> ExternalPhotoIntakeItem {

        ExternalPhotoIntakeItem(
            managedURL:
                normalizedFileURL(
                    for:
                        item.managedURL
                ),
            originalFileName:
                item.originalFileName,
            sourceIdentifier:
                item.sourceIdentifier,
            contentTypeIdentifier:
                item.contentTypeIdentifier,
            livePhotoRecoveryHint:
                item.livePhotoRecoveryHint
        )
    }

    func isSupportedIntakeItem(
        _ item: ExternalPhotoIntakeItem
    ) -> Bool {

        guard item.managedURL.isFileURL else {
            return false
        }

        let declaredType =
            item.contentTypeIdentifier
            .flatMap(UTType.init)
        let extensionType =
            UTType(
                filenameExtension:
                    item.managedURL
                    .pathExtension
                    .lowercased()
            )
        let contentType =
            declaredType
            ?? extensionType

        return PhotoProcessingInputPolicy(
            allowsLivePhoto: true
        )
        .isSupportedContentType(contentType)
    }
}
