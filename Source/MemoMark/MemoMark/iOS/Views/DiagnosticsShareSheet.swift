#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

/// System share-sheet wrapper for a diagnostics file. It owns no diagnostic
/// generation, data classification, or durable state.
struct DiagnosticsShareSheet:
    UIViewControllerRepresentable {

    let fileURL: URL

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
#endif
