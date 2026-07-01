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
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 18) {
                        previewContent
                            .opacity(
                                max(
                                    1 - previewPinProgress,
                                    0
                                )
                            )

                        editorContent
                            .opacity(
                                max(
                                    editorRevealProgress,
                                    0.26
                                )
                            )
                            .offset(
                                y:
                                    (1 - editorRevealProgress)
                                    * 12
                            )

                        accessoryContent
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 34)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            onDismissKeyboard()
                        }
                )

                if previewPinProgress > 0.01 {
                    previewContent
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .opacity(previewPinProgress)
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
