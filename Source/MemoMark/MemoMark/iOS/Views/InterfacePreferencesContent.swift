#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Presents interface-preference controls from bindings owned by Settings.
/// It never reads or writes preference storage directly.
struct InterfacePreferencesContent: View {
    let language: MemoMarkLanguage
    let usesAccessibilityPickerStyle: Bool
    let appearance: Binding<MemoMarkAppearancePreference>
    let interfaceLanguage: Binding<MemoMarkInterfaceLanguagePreference>

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            preferenceControl(
                title: localized("settings.appearance.title", fallback: "外观"),
                description: localized("settings.appearance.description", fallback: "跟随 iPhone 的外观，或始终使用浅色或深色。")
            ) { appearancePicker }
            HorizontalDivider()
            preferenceControl(
                title: localized("settings.interface.title", fallback: "界面语言"),
                description: localized("settings.interface.description", fallback: "控制时光记中支持切换的菜单、设置与处理状态文字；不改变你填写的内容，也不替代配置中的输出语言。")
            ) { interfaceLanguagePicker }
        }
        .padding(.horizontal, ConfigurationUI.innerPanelPadding)
    }

    static func summary(
        language: MemoMarkLanguage,
        appearance: MemoMarkAppearancePreference,
        interfaceLanguage: MemoMarkInterfaceLanguagePreference
    ) -> String {
        "\(appearanceTitle(appearance, language: language)) · \(interfaceLanguageTitle(interfaceLanguage, language: language))"
    }

    @ViewBuilder private var appearancePicker: some View {
        if usesAccessibilityPickerStyle {
            appearancePickerBase
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else {
            appearancePickerBase.pickerStyle(.segmented)
        }
    }

    private var appearancePickerBase: some View {
        Picker(localized("settings.appearance.title", fallback: "外观"), selection: appearance) {
            ForEach(MemoMarkAppearancePreference.allCases, id: \.self) { preference in
                Text(Self.appearanceTitle(preference, language: language)).tag(preference)
            }
        }
    }

    @ViewBuilder private var interfaceLanguagePicker: some View {
        if usesAccessibilityPickerStyle {
            interfaceLanguagePickerBase
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else {
            interfaceLanguagePickerBase.pickerStyle(.segmented)
        }
    }

    private var interfaceLanguagePickerBase: some View {
        Picker(localized("settings.interface.title", fallback: "界面语言"), selection: interfaceLanguage) {
            ForEach(MemoMarkInterfaceLanguagePreference.allCases, id: \.self) { preference in
                Text(Self.interfaceLanguageTitle(preference, language: language)).tag(preference)
            }
        }
    }

    private func preferenceControl<Control: View>(title: String, description: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 8) { Text(title).font(.subheadline.weight(.semibold)); control(); Text(description).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func appearanceTitle(_ preference: MemoMarkAppearancePreference, language: MemoMarkLanguage) -> String {
        switch preference { case .system: language.localized(key: "settings.appearance.system", fallback: "跟随系统"); case .light: language.localized(key: "settings.appearance.light", fallback: "浅色"); case .dark: language.localized(key: "settings.appearance.dark", fallback: "深色") }
    }
    private static func interfaceLanguageTitle(_ preference: MemoMarkInterfaceLanguagePreference, language: MemoMarkLanguage) -> String {
        switch preference { case .system: language.localized(key: "settings.appearance.system", fallback: "跟随系统"); case .simplifiedChinese: MemoMarkLanguage.simplifiedChinese.displayTitle; case .english: MemoMarkLanguage.english.displayTitle; case .japanese: MemoMarkLanguage.japanese.displayTitle; case .korean: MemoMarkLanguage.korean.displayTitle }
    }
    private func localized(_ key: String, fallback: String) -> String { language.localized(key: key, fallback: fallback) }
}
#endif
