import Foundation
import Combine

@MainActor
final class PhotoMemoAppRuntime:
    ObservableObject {

    let batchQueueStore: BatchQueueStore

    let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    init(
        batchQueueStore: BatchQueueStore? = nil,
        externalIntakeCenter:
            ExternalPhotoIntakeCenter? = nil
    ) {
        self.batchQueueStore =
            batchQueueStore
            ?? BatchQueueStore()
        self.externalIntakeCenter =
            externalIntakeCenter
            ?? .shared
        self.externalIntakeStore =
            .shared
    }

    func handleExternalURLs(
        _ urls: [URL],
        source: BatchJobLaunchSource
    ) {

        externalIntakeCenter.submit(
            urls: urls,
            source: source
        )
    }

    func flushExternalRequests() {

        let requests =
            externalIntakeCenter
            .drainPendingRequests()

        guard !requests.isEmpty else {
            return
        }

        for request in requests {
            let validURLs =
                request.urls.filter {
                    isValidRequestSourceURL($0)
                }

            guard !validURLs.isEmpty else {
                request.urls.forEach {
                    externalIntakeStore
                        .cleanupManagedSourceIfNeeded(
                            at: $0
                        )
                }
                continue
            }

            _ = batchQueueStore.enqueue(
                payloads: validURLs.map {
                    BatchTaskIntakePayload(
                        sourceURL: $0
                    )
                },
                configuration:
                    request.configurationSnapshot,
                launchSource:
                    request.launchSource,
                title:
                    resolvedRequestTitle(
                        receivedAt:
                            request.receivedAt,
                        taskCount:
                            validURLs.count
                    )
                    )
        }

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
    }

    func refreshExternalIntakeState() {

        externalIntakeStore
            .cleanupOrphanedManagedContent(
                keepingReferencedURLs:
                    batchQueueStore
                    .referencedManagedSourceURLs
            )

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
        flushExternalRequests()
    }
}

private extension PhotoMemoAppRuntime {

    func resolvedRequestTitle(
        receivedAt: Date,
        taskCount: Int
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "zh_CN")
        formatter.dateFormat =
            "yyyy.MM.dd HH:mm"

        return "外部图片处理 \(formatter.string(from: receivedAt)) · \(taskCount)张"
    }

    func isValidRequestSourceURL(
        _ url: URL
    ) -> Bool {

        guard url.isFileURL else {
            return false
        }

        return FileManager.default
            .fileExists(
                atPath:
                    url.standardizedFileURL
                    .path
            )
    }
}
