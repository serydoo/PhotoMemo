import SwiftUI
#if os(macOS)
import AppKit
#endif
import Combine

@main
struct PhotoMemoApp: App {

    @StateObject
    private var batchQueueStore =
        BatchQueueStore()

    @StateObject
    private var externalIntakeCenter =
        ExternalPhotoIntakeCenter.shared

#if os(macOS)
    @NSApplicationDelegateAdaptor(
        PhotoMemoAppDelegate.self
    )
    private var appDelegate
#endif

    init() {

#if os(macOS)
        NSApplication.shared.appearance =
        NSAppearance(
                named: .aqua
            )
#endif
    }

    var body: some Scene {

        WindowGroup {

            MainView()
                .environmentObject(
                    batchQueueStore
                )
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    handleExternalURLs(
                        [url],
                        source: .fileOpen
                    )
                }
                .onReceive(
                    externalIntakeCenter.$revision
                ) { _ in
                    flushExternalRequests()
                }
                .task {
                    flushExternalRequests()
                }
        }
    }
}

private extension PhotoMemoApp {

    func handleExternalURLs(
        _ urls: [URL],
        source: BatchJobLaunchSource
    ) {

        ExternalPhotoIntakeCenter
            .shared
            .submit(
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
            _ = batchQueueStore.enqueue(
                urls: request.urls,
                launchSource:
                    request.launchSource,
                title:
                    resolvedRequestTitle(
                        for: request
                    )
            )
        }
    }

    func resolvedRequestTitle(
        for request: ExternalPhotoIntakeRequest
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "zh_CN")
        formatter.dateFormat =
            "yyyy.MM.dd HH:mm"

        return "外部图片处理 \(formatter.string(from: request.receivedAt)) · \(request.urls.count)张"
    }
}
