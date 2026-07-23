#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1EditorPageSurface<
    PreviewContent: View,
    EditorContent: View,
    AccessoryContent: View
>: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    let previewPinProgress: CGFloat
    let editorRevealProgress: CGFloat
    let pageTitle: String
    let pageSubtitle: String
    let onDismissKeyboard: () -> Void
    @ViewBuilder var previewContent: PreviewContent
    @ViewBuilder var editorContent: EditorContent
    @ViewBuilder var accessoryContent: AccessoryContent

    init(
        previewPinProgress: CGFloat,
        editorRevealProgress: CGFloat,
        pageTitle: String,
        pageSubtitle: String,
        onDismissKeyboard: @escaping () -> Void,
        @ViewBuilder previewContent: () -> PreviewContent,
        @ViewBuilder editorContent: () -> EditorContent,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.previewPinProgress = previewPinProgress
        self.editorRevealProgress = editorRevealProgress
        self.pageTitle = pageTitle
        self.pageSubtitle = pageSubtitle
        self.onDismissKeyboard = onDismissKeyboard
        self.previewContent = previewContent()
        self.editorContent = editorContent()
        self.accessoryContent = accessoryContent()
    }

    var body: some View {
        GeometryReader { proxy in
            Group {
                switch V1AdaptivePageLayout
                    .editorComposition(
                        for: proxy.size.width
                    ) {
                case .stacked:
                    stackedContent

                case .sideBySide:
                    sideBySideContent(
                        availableWidth:
                            proxy.size.width
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .coordinateSpace(name: "v1-scroll")
        }
    }

    private var stackedContent: some View {
        VStack(spacing: 0) {
            previewPane
                .zIndex(1)

            editorScrollView
        }
    }

    private func sideBySideContent(
        availableWidth: CGFloat
    ) -> some View {
        let previewWidth =
            min(
                max(
                    availableWidth * 0.46,
                    350
                ),
                520
            )

        return HStack(spacing: 0) {
            previewPane
                .frame(width: previewWidth)
                .frame(
                    maxHeight: .infinity,
                    alignment: .top
                )

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(width: 0.5)

            editorScrollView
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            V1PageHeader(
                pageTitle,
                subtitle: pageSubtitle
            )

            previewContent
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .v1AdaptivePageContent(
            horizontalPadding: ConfigurationUI.contentColumnPadding
        )
        .background(
            ConfigurationUI.appBackground
        )
    }

    private var editorScrollView: some View {
        ScrollView {
            VStack(spacing: 14) {
                editorContent

                accessoryContent
            }
            .padding(.top, 8)
            .padding(
                .bottom,
                V1AdaptivePageLayout
                    .scrollBottomPadding(
                        isPad:
                            UIDevice.current
                            .userInterfaceIdiom == .pad,
                        hasRegularHorizontalSizeClass:
                            horizontalSizeClass == .regular
                    )
            )
            .v1AdaptiveScrollContent(
                horizontalPadding: ConfigurationUI.contentColumnPadding
            )
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
#endif
