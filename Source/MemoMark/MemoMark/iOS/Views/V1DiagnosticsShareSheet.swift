#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1DiagnosticsShareSheet:
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
