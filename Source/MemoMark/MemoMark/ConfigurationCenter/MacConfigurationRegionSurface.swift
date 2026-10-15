#if os(macOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Stateless arrangement: the page retains session, draft, inspector and undo owners.
struct MacConfigurationRegionSurface<Header: View, Preview: View, Editor: View, Progress: View>: View {
    @ScaledMetric(relativeTo: .body)
    private var minimumPreviewWidth = DesktopConfigurationRegionPolicy.minimumPreviewWidth
    @ScaledMetric(relativeTo: .body)
    private var minimumEditorWidth = DesktopConfigurationRegionPolicy.minimumEditorWidth

    @ViewBuilder var header: Header
    @ViewBuilder var preview: (CGFloat) -> Preview
    @ViewBuilder var editor: (CGFloat) -> Editor
    @ViewBuilder var progress: Progress

    var body: some View {
        VStack(spacing: 16) {
            header
            GeometryReader { viewport in
                let width = min(1500, max(0, viewport.size.width))
                let split = DesktopConfigurationRegionPolicy.arrangement(
                    viewport: CGSize(width: width, height: viewport.size.height),
                    minimumPreviewWidth: minimumPreviewWidth,
                    minimumEditorWidth: minimumEditorWidth) == .sideBySide
                let previewWidth = split ? DesktopConfigurationRegionPolicy.previewWidth(
                    viewportWidth: width, minimumPreviewWidth: minimumPreviewWidth,
                    minimumEditorWidth: minimumEditorWidth) : width
                let editorWidth = split ? max(0, width - previewWidth - DesktopConfigurationRegionPolicy.spacing) : width
                let layout = split
                    ? AnyLayout(HStackLayout(alignment: .top, spacing: DesktopConfigurationRegionPolicy.spacing))
                    : AnyLayout(VStackLayout(spacing: DesktopConfigurationRegionPolicy.spacing))
                layout {
                    ScrollView {
                        preview(previewWidth)
                    }
                    .frame(width: previewWidth)
                    .frame(height: split ? nil : min(viewport.size.height / 2,
                        max(0, viewport.size.height - WideConfigurationRegionPolicy.minimumEditorHeight)))
                    .accessibilityIdentifier("mac.configuration.preview-region")

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            editor(editorWidth)
                            progress
                        }
                    }
                    .frame(width: editorWidth)
                    .frame(maxHeight: .infinity)
                    .accessibilityIdentifier("mac.configuration.editor-region")
                }
                .frame(width: width, height: viewport.size.height, alignment: .top)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
#endif
