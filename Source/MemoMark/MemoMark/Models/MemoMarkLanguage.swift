import Foundation

enum MemoMarkLanguage: String, Codable, CaseIterable, Hashable {

    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"

    static let storageKey = "photomemo.language"
    static let preferenceStorageKey = "photomemo.language.preference"
    static let interfacePreferenceStorageKey =
        "photomemo.interface.language.preference"

    static var preference: MemoMarkLanguagePreference {
        if let rawValue = MemoMarkSharedContainer
            .sharedUserDefaults
            .string(forKey: preferenceStorageKey),
           let preference = MemoMarkLanguagePreference(rawValue: rawValue) {
            return preference
        }

        // The first localization slice stored the language directly. Treat
        // that value as an explicit override during the migration window.
        if let rawValue = MemoMarkSharedContainer
            .sharedUserDefaults
            .string(forKey: storageKey),
           let language = Self(rawValue: rawValue) {
            return MemoMarkLanguagePreference(
                rawValue: language.rawValue
            ) ?? .english
        }

        return .system
    }

    static var stored: Self {
        preference.resolvedLanguage
    }

    static var defaultOutputLanguage: Self {
        stored
    }

    static var interfacePreference:
        MemoMarkInterfaceLanguagePreference {
        if let rawValue = MemoMarkSharedContainer
            .sharedUserDefaults
            .string(forKey: interfacePreferenceStorageKey),
           let preference = MemoMarkInterfaceLanguagePreference(
               rawValue: rawValue
           ) {
            return preference
        }

        return .system
    }

    static var interfaceStored: Self {
        interfacePreference.resolvedLanguage
    }

    static func persist(_ language: Self) {
        MemoMarkSharedContainer
            .sharedUserDefaults
            .set(language.rawValue, forKey: storageKey)
        MemoMarkSharedContainer
            .sharedUserDefaults
            .set(language.rawValue, forKey: preferenceStorageKey)
    }

    static func persistSystemDefault() {
        let defaults = MemoMarkSharedContainer.sharedUserDefaults
        defaults.removeObject(forKey: storageKey)
        defaults.set(
            MemoMarkLanguagePreference.system.rawValue,
            forKey: preferenceStorageKey
        )
    }

    static func persistInterfacePreference(
        _ preference: MemoMarkInterfaceLanguagePreference
    ) {
        MemoMarkSharedContainer
            .sharedUserDefaults
            .set(
                preference.rawValue,
                forKey: interfacePreferenceStorageKey
            )
    }

    var displayTitle: String {
        switch self {
        case .simplifiedChinese:
            return "简体中文"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        }
    }

    var locale: Locale {
        switch self {
        case .simplifiedChinese:
            return Locale(identifier: "zh_CN")
        case .english:
            return Locale(identifier: "en_US")
        case .japanese:
            return Locale(identifier: "ja_JP")
        case .korean:
            return Locale(identifier: "ko_KR")
        }
    }

    nonisolated func localized(
        key: String,
        fallback: String
    ) -> String {
        guard let path = Bundle.main.path(
            forResource: rawValue,
            ofType: "lproj"
        ),
        let bundle = Bundle(path: path)
        else {
            return fallback
        }

        return bundle.localizedString(
            forKey: key,
            value: fallback,
            table: nil
        )
    }

    static func resolved(
        from locale: Locale
    ) -> Self {
        let code = locale.language.languageCode?.identifier
            .lowercased()
        let script = locale.language.script?.identifier
            .lowercased()

        switch code {
        case "zh":
            return script == "hant"
                ? .english
                : .simplifiedChinese
        case "en":
            return .english
        case "ja":
            return .japanese
        case "ko":
            return .korean
        default:
            return .english
        }
    }

    static func isSupported(
        locale: Locale,
        layoutDirectionSupport: Bool = false
    ) -> Bool {
        let code = locale.language.languageCode?.identifier
            .lowercased()
        if code == "ar" || code == "he" {
            return layoutDirectionSupport
        }
        return code == "zh"
            || code == "en"
            || code == "ja"
            || code == "ko"
    }
}

enum MemoMarkLanguagePreference: String, Codable, CaseIterable, Hashable {

    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"

    var resolvedLanguage: MemoMarkLanguage {
        switch self {
        case .system:
            let identifier = Locale.preferredLanguages.first
                ?? Locale.current.identifier
            return MemoMarkLanguage.resolved(
                from: Locale(identifier: identifier)
            )
        case .simplifiedChinese:
            return .simplifiedChinese
        case .english:
            return .english
        case .japanese:
            return .japanese
        case .korean:
            return .korean
        }
    }

    var displayTitle: String {
        switch self {
        case .system:
            return "跟随系统 / System"
        case .simplifiedChinese:
            return MemoMarkLanguage.simplifiedChinese.displayTitle
        case .english:
            return MemoMarkLanguage.english.displayTitle
        case .japanese:
            return MemoMarkLanguage.japanese.displayTitle
        case .korean:
            return MemoMarkLanguage.korean.displayTitle
        }
    }
}

enum MemoMarkInterfaceLanguagePreference:
    String, Codable, CaseIterable, Hashable {

    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"

    var resolvedLanguage: MemoMarkLanguage {
        switch self {
        case .system:
            let identifier = Locale.preferredLanguages.first
                ?? Locale.current.identifier
            return MemoMarkLanguage.resolved(
                from: Locale(identifier: identifier)
            )
        case .simplifiedChinese:
            return .simplifiedChinese
        case .english:
            return .english
        case .japanese:
            return .japanese
        case .korean:
            return .korean
        }
    }

    var displayTitle: String {
        switch self {
        case .system:
            return "跟随系统 / System"
        case .simplifiedChinese:
            return MemoMarkLanguage.simplifiedChinese.displayTitle
        case .english:
            return MemoMarkLanguage.english.displayTitle
        case .japanese:
            return MemoMarkLanguage.japanese.displayTitle
        case .korean:
            return MemoMarkLanguage.korean.displayTitle
        }
    }
}

enum MemoMarkAppearancePreference:
    String, Codable, CaseIterable, Hashable {

    static let storageKey =
        "photomemo.interface.appearance.preference"

    case system
    case light
    case dark
}
