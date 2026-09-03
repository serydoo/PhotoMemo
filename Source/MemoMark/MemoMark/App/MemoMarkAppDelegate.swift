import Foundation
#if os(macOS)
import AppKit
#endif

#if os(macOS)
@MainActor
final class MemoMarkAppDelegate:
    NSObject,
    NSApplicationDelegate {

    var openURLsHandler:
        (@MainActor ([URL]) -> Void)?

    private var pendingURLBatches = [[URL]]()

    override init() {
        super.init()
    }

    func application(
        _ application: NSApplication,
        open urls: [URL]
    ) {

        routeOpenURLs(urls)
    }

    func application(
        _ sender: NSApplication,
        openFile filename: String
    ) -> Bool {

        routeOpenURLs([
            URL(
                fileURLWithPath:
                    filename
            )
        ])

        return true
    }

    func application(
        _ sender: NSApplication,
        openFiles filenames: [String]
    ) {

        routeOpenURLs(
            filenames.map {
                URL(
                    fileURLWithPath: $0
                )
            }
        )

        sender.reply(
            toOpenOrPrint: .success
        )
    }

    private func routeOpenURLs(_ urls: [URL]) {
        guard !urls.isEmpty else {
            return
        }

        if let openURLsHandler {
            openURLsHandler(urls)
        } else {
            // AppKit can deliver file-open events before SwiftUI has mounted
            // the root scene. Retain them until the composed runtime handler
            // is installed instead of falling back to a global intake center.
            pendingURLBatches.append(urls)
        }
    }

    func install(openURLsHandler: @escaping @MainActor ([URL]) -> Void) {
        self.openURLsHandler = openURLsHandler
        let pendingURLBatches = self.pendingURLBatches
        self.pendingURLBatches.removeAll(keepingCapacity: false)
        pendingURLBatches.forEach(openURLsHandler)
    }
}
#endif
