#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1EditorPresentationModifier<EditorContent: View>: ViewModifier {

    @Binding
    var showsRegionContentSheet: Bool

    let editorContent: EditorContent
    let onDismissKeyboard: () -> Void
    let onToggleModuleLibrary: () -> Void
    let canToggleModuleLibrary: Bool
    let isModuleLibraryPresented: Bool
    let onDismissEditor: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

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
                        onToggleModuleLibrary: onToggleModuleLibrary,
                        canToggleModuleLibrary: canToggleModuleLibrary,
                        isModuleLibraryPresented: isModuleLibraryPresented
                    )
                    .transition(
                        accessibilityReduceMotion
                        ? .opacity
                        : .move(edge: .bottom).combined(with: .opacity)
                    )
                }
            }
            .animation(
                accessibilityReduceMotion
                ? nil
                : .easeOut(duration: 0.22),
                value: showsRegionContentSheet
            )
    }
}

private struct V1CardEditorOverlay<EditorContent: View>: View {

    @State private var keyboardBottomInset: CGFloat = 0
    @State private var editorViewportBottom: CGFloat = 0
    @State private var pullDownOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

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
            let currentViewportBottom = proxy.frame(in: .global).maxY
            let editorHeight = max(
                0,
                proxy.size.height - bottomInset - topBoundary
            )

            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(0.12)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.42))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .accessibilityHidden(true)

                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localized("configuration.card_editor.title", fallback: "卡片内容"))
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(localized(
                                "configuration.card_editor.subtitle",
                                fallback: "组合文字、照片信息与记忆表达。"
                            ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 12)

                        Button {
                            onToggleModuleLibrary()
                        } label: {
                            Label(
                                localized("configuration.card_editor.add_module", fallback: "模块"),
                                systemImage:
                                isModuleLibraryPresented ? "minus" : "plus"
                            )
                        }
                        .buttonStyle(.borderless)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(
                            minWidth: ConfigurationUI.minimumInteractiveHeight,
                            minHeight: ConfigurationUI.minimumInteractiveHeight
                        )
                        .disabled(!canToggleModuleLibrary)
                        .accessibilityIdentifier("card-editor-add-module")

                        Button(
                            localized("configuration.card_editor.done", fallback: "完成"),
                            action: onDismiss
                        )
                            .buttonStyle(.borderless)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(
                                minWidth: ConfigurationUI.minimumInteractiveHeight,
                                minHeight: ConfigurationUI.minimumInteractiveHeight
                            )
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
                                    Image(systemName: "keyboard.chevron.compact.down")
                                }
                                .accessibilityLabel(
                                    localized(
                                        "configuration.card_editor.dismiss_keyboard",
                                        fallback: "收起键盘"
                                    )
                                )
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(height: editorHeight)
                .padding(.bottom, bottomInset)
                .background(ConfigurationUI.appBackground)
                .clipShape(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if keyboardBottomInset > 0 {
                    Button(action: onDismissKeyboard) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.body.weight(.semibold))
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .background(Color(uiColor: .systemBackground), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
                    }
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
                    .padding(.trailing, 18)
                    .padding(.bottom, max(0, keyboardBottomInset - 19))
                    .accessibilityIdentifier("card-editor-dismiss-keyboard")
                    .accessibilityLabel("收起键盘")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .offset(y: pullDownOffset)
            .simultaneousGesture(pullToDismissGesture)
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
            let frame = notification.userInfo?[
                UIResponder.keyboardFrameEndUserInfoKey
            ] as? CGRect
            guard let frame else {
                keyboardBottomInset = 0
                return
            }

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
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel(
            MemoMarkLanguage.interfaceStored.localized(
                key: "configuration.card_editor.accessibility_label",
                fallback: "卡片内容编辑"
            )
        )
    }

    private var pullToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard keyboardBottomInset == 0 else {
                    pullDownOffset = 0
                    return
                }

                let translation = value.translation
                guard translation.height > abs(translation.width) else {
                    pullDownOffset = 0
                    return
                }

                pullDownOffset = min(translation.height * 0.72, 180)
            }
            .onEnded { value in
                guard keyboardBottomInset == 0 else {
                    pullDownOffset = 0
                    return
                }

                let translation = value.translation
                let predictedHeight = value.predictedEndTranslation.height
                let shouldDismiss =
                    translation.height >= ConfigurationUI.cardEditorDismissThreshold
                    || predictedHeight >= ConfigurationUI.cardEditorDismissThreshold * 1.35

                guard translation.height > abs(translation.width), shouldDismiss else {
                    withAnimation(
                        accessibilityReduceMotion
                        ? nil
                        : .spring(response: 0.3, dampingFraction: 0.86)
                    ) {
                        pullDownOffset = 0
                    }
                    return
                }

                onDismiss()
            }
    }

    private func localized(_ key: String, fallback: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(key: key, fallback: fallback)
    }
}
#endif
