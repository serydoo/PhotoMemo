import Foundation
#if os(macOS)
import AppKit
#endif

#if os(macOS)
final class PhotoMemoAppDelegate:
    NSObject,
    NSApplicationDelegate {

    func application(
        _ application: NSApplication,
        open urls: [URL]
    ) {

        Task { @MainActor in
            ExternalPhotoIntakeCenter
                .shared
                .submit(
                    urls: urls,
                    source: .fileOpen
                )
        }
    }

    func application(
        _ sender: NSApplication,
        openFile filename: String
    ) -> Bool {

        Task { @MainActor in
            ExternalPhotoIntakeCenter
                .shared
                .submit(
                    urls: [
                        URL(
                            fileURLWithPath:
                                filename
                        )
                    ],
                    source: .fileOpen
                )
        }

        return true
    }

    func application(
        _ sender: NSApplication,
        openFiles filenames: [String]
    ) {

        Task { @MainActor in
            ExternalPhotoIntakeCenter
                .shared
                .submit(
                    urls: filenames.map {
                        URL(
                            fileURLWithPath: $0
                        )
                    },
                    source: .fileOpen
                )
        }

        sender.reply(
            toOpenOrPrint: .success
        )
    }
}
#endif
