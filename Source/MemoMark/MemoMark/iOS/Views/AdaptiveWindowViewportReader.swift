#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

/// The hosting window's safe viewport is independent of software-keyboard
/// occlusion. Content still uses SwiftUI's live keyboard-avoiding geometry.
struct AdaptiveWindowViewportReader: UIViewRepresentable {
    let onChange: (CGSize) -> Void

    func makeUIView(context: Context) -> AdaptiveWindowViewportProbe {
        let view = AdaptiveWindowViewportProbe()
        view.isUserInteractionEnabled = false
        view.onChange = onChange
        return view
    }

    func updateUIView(_ view: AdaptiveWindowViewportProbe, context: Context) {
        view.onChange = onChange
        view.reportGeometry()
    }
}

final class AdaptiveWindowViewportProbe: UIView {
    var onChange: ((CGSize) -> Void)?
    private var lastSize: CGSize?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reportGeometry()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reportGeometry()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        reportGeometry()
    }

    func reportGeometry() {
        Task { @MainActor [weak self] in
            guard let self, let window, window.windowScene != nil else { return }
            let size = window.bounds.inset(by: window.safeAreaInsets).size
            guard size.width.isFinite, size.height.isFinite, size.width > 0,
                  size.height > 0, size != lastSize else { return }
            lastSize = size
            onChange?(size)
        }
    }
}
#endif
