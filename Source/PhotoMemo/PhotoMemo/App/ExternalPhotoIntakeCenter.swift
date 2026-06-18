import Foundation
import UniformTypeIdentifiers
import Combine

struct ExternalPhotoIntakeRequest:
    Identifiable,
    Hashable {

    let id: UUID

    let launchSource: BatchJobLaunchSource

    let urls: [URL]

    let receivedAt: Date

    init(
        id: UUID = UUID(),
        launchSource: BatchJobLaunchSource,
        urls: [URL],
        receivedAt: Date = Date()
    ) {
        self.id = id
        self.launchSource = launchSource
        self.urls = urls
        self.receivedAt = receivedAt
    }
}

@MainActor
final class ExternalPhotoIntakeCenter:
    ObservableObject {

    static let shared =
        ExternalPhotoIntakeCenter()

    @Published private(set) var revision =
        UUID()

    private var pendingRequests:
        [ExternalPhotoIntakeRequest] = []

    private let supportedTypes:
        [UTType] = [
            .jpeg,
            .png,
            .heic,
            .heif,
            .tiff
        ]

    private init() {
    }

    func submit(
        urls: [URL],
        source: BatchJobLaunchSource
    ) {

        let acceptedURLs =
            urls
            .map(normalizedFileURL(for:))
            .filter(isSupportedImageURL)

        guard !acceptedURLs.isEmpty else {
            return
        }

        pendingRequests.append(
            ExternalPhotoIntakeRequest(
                launchSource: source,
                urls: acceptedURLs
            )
        )

        revision = UUID()
    }

    func drainPendingRequests() -> [ExternalPhotoIntakeRequest] {

        let requests = pendingRequests
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
