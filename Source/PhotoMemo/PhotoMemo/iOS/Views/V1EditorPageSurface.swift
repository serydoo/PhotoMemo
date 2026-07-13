#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1EditorPageSurface<
    PreviewContent: View,
    EditorContent: View,
    AccessoryContent: View
>: View {

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
        GeometryReader { _ in
            VStack(spacing: 0) {
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
                        horizontalPadding: 16
                    )
                    .background(
                        ConfigurationUI.appBackground
                    )
                    .zIndex(1)

                ScrollView {
                    VStack(spacing: 14) {
                        editorContent

                        accessoryContent
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 26)
                    .v1AdaptiveScrollContent(
                        horizontalPadding: 16
                    )
                }
                .scrollDismissesKeyboard(.interactively)
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
}
#endif
