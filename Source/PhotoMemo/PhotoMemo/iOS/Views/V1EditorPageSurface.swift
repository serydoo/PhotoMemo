#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1EditorPageSurface<
    PreviewContent: View,
    EditorContent: View,
    AccessoryContent: View
>: View {

    let previewPinProgress: CGFloat
    let editorRevealProgress: CGFloat
    let onDismissKeyboard: () -> Void
    @ViewBuilder var previewContent: PreviewContent
    @ViewBuilder var editorContent: EditorContent
    @ViewBuilder var accessoryContent: AccessoryContent

    init(
        previewPinProgress: CGFloat,
        editorRevealProgress: CGFloat,
        onDismissKeyboard: @escaping () -> Void,
        @ViewBuilder previewContent: () -> PreviewContent,
        @ViewBuilder editorContent: () -> EditorContent,
        @ViewBuilder accessoryContent: () -> AccessoryContent
    ) {
        self.previewPinProgress = previewPinProgress
        self.editorRevealProgress = editorRevealProgress
        self.onDismissKeyboard = onDismissKeyboard
        self.previewContent = previewContent()
        self.editorContent = editorContent()
        self.accessoryContent = accessoryContent()
    }

    var body: some View {
        GeometryReader { _ in
            let isPreviewPinned =
                previewPinProgress > 0.01

            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 18) {
                        previewContent
                            .opacity(
                                isPreviewPinned
                                ? 0
                                : 1
                            )

                        editorContent

                        accessoryContent
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 34)
                }
                .scrollDismissesKeyboard(.interactively)

                if isPreviewPinned {
                    previewContent
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
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
}
#endif
