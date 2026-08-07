#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1EditorPresentationModifier<EditorContent: View>: ViewModifier {
    @Binding var showsRegionContentSheet: Bool

    let editorContent: EditorContent
    let onDismissKeyboard: () -> Void
    let onToggleModuleLibrary: () -> Void
    let canToggleModuleLibrary: Bool
    let isModuleLibraryPresented: Bool
    let onDismissEditor: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if showsRegionContentSheet {
                    V1CardEditorOverlay(
                        editorContent: editorContent,
                        onDismiss: {
                            onDismissKeyboard()
                            onDismissEditor()
                            showsRegionContentSheet = false
                        },
                        onDismissKeyboard: onDismissKeyboard,
                        onToggleModuleLibrary:
                            onToggleModuleLibrary,
                        canToggleModuleLibrary:
                            canToggleModuleLibrary,
                        isModuleLibraryPresented:
                            isModuleLibraryPresented
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(
                .easeOut(duration: 0.22),
                value: showsRegionContentSheet
            )
    }
}

private struct V1CardEditorOverlay<EditorContent: View>: View {
    @State private var keyboardBottomInset: CGFloat = 0
    @State private var editorViewportBottom: CGFloat = 0

    let editorContent: EditorContent
    let onDismiss: () -> Void
    let onDismissKeyboard: () -> Void
    let onToggleModuleLibrary: () -> Void
    let canToggleModuleLibrary: Bool
    let isModuleLibraryPresented: Bool

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = max(
                proxy.safeAreaInsets.bottom,
                keyboardBottomInset
            )
            let topBoundary = max(
                proxy.size.height
                    * ConfigurationUI.contentEditorTopBoundaryFraction,
                ConfigurationUI.contentEditorMinimumTopBoundary
            )
            let currentViewportBottom =
                proxy.frame(in: .global).maxY
            let maximumEditorHeight = max(
                0,
                proxy.size.height - bottomInset - topBoundary
            )
            let editorHeight = maximumEditorHeight

            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(0.16)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.42))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .accessibilityHidden(true)

                    HStack {
                        Text("卡片内容")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 12)

                        Button {
                            onToggleModuleLibrary()
                        } label: {
                            Label(
                                "模块",
                                systemImage:
                                    isModuleLibraryPresented
                                    ? "minus"
                                    : "plus"
                            )
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .disabled(!canToggleModuleLibrary)
                        .accessibilityIdentifier("card-editor-add-module")

                        Button("完成", action: onDismiss)
                            .buttonStyle(.bordered)
                            .tint(.primary)
                            .accessibilityIdentifier("card-editor-done")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                    editorContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .safeAreaPadding(.bottom, 12)
                        .clipped()
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button(action: onDismissKeyboard) {
                                    Image(
                                        systemName:
                                            "keyboard.chevron.compact.down"
                                    )
                                }
                                .accessibilityLabel("收起键盘")
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(height: editorHeight)
                .padding(.bottom, bottomInset)
                .background(ConfigurationUI.appBackground)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 28,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 28,
                        style: .continuous
                    )
                    .stroke(
                        Color.primary.opacity(0.12),
                        lineWidth: 0.8
                    )
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if keyboardBottomInset > 0 {
                    Button(action: onDismissKeyboard) {
                        Image(
                            systemName:
                                "keyboard.chevron.compact.down"
                        )
                        .font(.body.weight(.semibold))
                        .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .background(
                        Color(uiColor: .systemBackground),
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
                    }
                    .shadow(
                        color: .black.opacity(0.16),
                        radius: 8,
                        y: 3
                    )
                    .padding(.trailing, 18)
                    // Let the compact control straddle the keyboard's top
                    // edge instead of creating a separate editor-height band.
                    .padding(
                        .bottom,
                        max(0, keyboardBottomInset - 19)
                    )
                    .accessibilityIdentifier(
                        "card-editor-dismiss-keyboard"
                    )
                    .accessibilityLabel("收起键盘")
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottom
            )
            .onAppear {
                editorViewportBottom = currentViewportBottom
            }
            .onChange(of: currentViewportBottom) { _, newValue in
                editorViewportBottom = newValue
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillChangeFrameNotification
            )
        ) { notification in
            let frame =
                notification.userInfo?[
                    UIResponder.keyboardFrameEndUserInfoKey
                ] as? CGRect
            guard let frame else {
                keyboardBottomInset = 0
                return
            }

            // `frame.height` is the keyboard's own height, not the distance
            // from the window bottom to its top. Using the latter keeps the
            // editor surface and the dismiss control attached to the actual
            // keyboard boundary on iPhone layouts.
            keyboardBottomInset = max(
                0,
                editorViewportBottom - frame.minY
            )
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillHideNotification
            )
        ) { _ in
            keyboardBottomInset = 0
        }
        .ignoresSafeArea(.keyboard)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("卡片内容编辑")
    }
}
#endif
