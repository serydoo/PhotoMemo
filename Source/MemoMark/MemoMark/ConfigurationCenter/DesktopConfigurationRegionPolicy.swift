#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics

/// Desktop form capacity uses the same region vocabulary, with its own chrome.
enum DesktopConfigurationRegionPolicy {
    static let spacing: CGFloat = 16
    static let minimumPreviewWidth: CGFloat = 350
    static let minimumEditorWidth: CGFloat = 500

    static func arrangement(viewport: CGSize,
        minimumPreviewWidth: CGFloat = minimumPreviewWidth,
        minimumEditorWidth: CGFloat = minimumEditorWidth) -> ConfigurationContentArrangement {
        guard viewport.width.isFinite, viewport.height.isFinite,
              minimumPreviewWidth.isFinite, minimumEditorWidth.isFinite,
              minimumPreviewWidth > 0, minimumEditorWidth > 0,
              viewport.width >= minimumPreviewWidth + minimumEditorWidth + spacing,
              viewport.height >= 360 else { return .stacked }
        return .sideBySide
    }

    static func previewWidth(viewportWidth: CGFloat,
        minimumPreviewWidth: CGFloat = minimumPreviewWidth,
        minimumEditorWidth: CGFloat = minimumEditorWidth) -> CGFloat {
        guard viewportWidth.isFinite, viewportWidth > 0,
              minimumPreviewWidth.isFinite, minimumEditorWidth.isFinite,
              minimumPreviewWidth > 0, minimumEditorWidth > 0 else { return 0 }
        let preferred = min(640, max(minimumPreviewWidth, (viewportWidth - spacing) * 0.42))
        return max(0, min(preferred, viewportWidth - spacing - minimumEditorWidth))
    }
}
#endif
