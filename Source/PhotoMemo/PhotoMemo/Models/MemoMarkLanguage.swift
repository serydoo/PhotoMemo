import Foundation

enum MemoMarkLanguage: String, Codable, CaseIterable, Hashable {

    case simplifiedChinese = "zh-Hans"
    case english = "en"

    static let storageKey = "photomemo.language"
    static let preferenceStorageKey = "photomemo.language.preference"
    static let interfacePreferenceStorageKey =
        "photomemo.interface.language.preference"

    static var preference: MemoMarkLanguagePreference {
        if let rawValue = PhotoMemoSharedContainer
            .sharedUserDefaults
            .string(forKey: preferenceStorageKey),
           let preference = MemoMarkLanguagePreference(rawValue: rawValue) {
            return preference
        }

        // The first localization slice stored the language directly. Treat
        // that value as an explicit override during the migration window.
        if let rawValue = PhotoMemoSharedContainer
            .sharedUserDefaults
            .string(forKey: storageKey),
           let language = Self(rawValue: rawValue) {
            return language == .simplifiedChinese
                ? .simplifiedChinese
                : .english
        }

        return .system
    }

    static var stored: Self {
        preference.resolvedLanguage
    }

    static var interfacePreference:
        MemoMarkInterfaceLanguagePreference {
        if let rawValue = PhotoMemoSharedContainer
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
        PhotoMemoSharedContainer
            .sharedUserDefaults
            .set(language.rawValue, forKey: storageKey)
        PhotoMemoSharedContainer
            .sharedUserDefaults
            .set(language.rawValue, forKey: preferenceStorageKey)
    }

    static func persistSystemDefault() {
        let defaults = PhotoMemoSharedContainer.sharedUserDefaults
        defaults.removeObject(forKey: storageKey)
        defaults.set(
            MemoMarkLanguagePreference.system.rawValue,
            forKey: preferenceStorageKey
        )
    }

    static func persistInterfacePreference(
        _ preference: MemoMarkInterfaceLanguagePreference
    ) {
        PhotoMemoSharedContainer
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
        }
    }

    var locale: Locale {
        switch self {
        case .simplifiedChinese:
            return Locale(identifier: "zh_CN")
        case .english:
            return Locale(identifier: "en_US")
        }
    }

    func localized(
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
        let language = locale.language
        return language.languageCode?.identifier.lowercased() == "zh"
            && language.script?.identifier.lowercased() == "hans"
            ? Self.simplifiedChinese
            : Self.english
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
        return code == "zh" || code == "en"
    }
}

enum MemoMarkLanguagePreference: String, Codable, CaseIterable, Hashable {

    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

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
        }
    }
}

enum MemoMarkInterfaceLanguagePreference:
    String, Codable, CaseIterable, Hashable {

    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

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
