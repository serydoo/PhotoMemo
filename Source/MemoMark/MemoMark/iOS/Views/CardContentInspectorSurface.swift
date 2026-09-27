#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Presents the existing TextKit editor in the Configuration Center's inspector
/// column while the same Memory Card preview remains on screen.
struct CardContentInspectorSurface<EditorContent: View>: View {
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let onDismissKeyboard: () -> Void
    let onToggleModuleLibrary: () -> Void
    let canToggleModuleLibrary: Bool
    let isModuleLibraryPresented: Bool
    let onDone: () -> Void
    @ViewBuilder let editorContent: EditorContent

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        headerText
                        HStack(spacing: 10) {
                            Spacer(minLength: 0)
                            headerActions
                        }
                    }
                } else {
                    HStack(alignment: .center, spacing: 10) {
                        headerText
                        Spacer(minLength: 0)
                        headerActions
                    }
                }
            }
            .padding(.horizontal, ConfigurationUI.contentColumnPadding)
            .padding(.vertical, 8)

            editorContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ConfigurationUI.appBackground)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: onDismissKeyboard) {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                .accessibilityLabel(localized(
                    "configuration.card_editor.dismiss_keyboard",
                    fallback: "收起键盘"
                ))
                .accessibilityIdentifier("card-editor-dismiss-keyboard")
            }
        }
        .accessibilityIdentifier("card-content-inspector")
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(localized("configuration.card_editor.title", fallback: "卡片内容"))
                .font(.headline.weight(.semibold))
            Text(localized(
                "configuration.card_editor.subtitle",
                fallback: "组合文字、照片信息与记忆表达。"
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var headerActions: some View {
        Group {
            Button(action: onToggleModuleLibrary) {
                Label(
                    localized("configuration.card_editor.add_module", fallback: "模块"),
                    systemImage: isModuleLibraryPresented ? "minus" : "plus"
                )
                .labelStyle(.titleAndIcon)
            }
            .disabled(!canToggleModuleLibrary)
            .accessibilityIdentifier("card-editor-add-module")

            Button(localized("configuration.card_editor.done", fallback: "完成"), action: onDone)
                .accessibilityIdentifier("card-editor-done")
        }
        .buttonStyle(.borderless)
        .font(.body.weight(.semibold))
        .foregroundStyle(Color.accentColor)
        .controlSize(.regular)
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
    }

    private func localized(_ key: String, fallback: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(key: key, fallback: fallback)
    }
}
#endif
