import Foundation
import Testing

@Suite("Localization resource parity")
struct LocalizationResourceParityTests {

    private let languageCodes = [
        "en",
        "zh-Hans",
        "ja",
        "ko"
    ]

    @Test("All four resource files expose the same non-empty keys")
    func allResourceKeysStayInParity() throws {
        let resources = try languageCodes.map { code in
            (
                code: code,
                source: try sourceText(
                    "Source/MemoMark/MemoMark/\(code).lproj/Localizable.strings"
                )
            )
        }
        let parsed = resources.map { resource in
            (
                code: resource.code,
                resource: parseResource(resource.source)
            )
        }
        let referenceKeys = try #require(
            parsed.first.map { Set($0.resource.entries.keys) }
        )

        for resource in parsed {
            #expect(resource.resource.entries.count == referenceKeys.count)
            #expect(Set(resource.resource.entries.keys) == referenceKeys)
            #expect(resource.resource.duplicateKeys.isEmpty)
            #expect(resource.resource.emptyKeys.isEmpty)
        }
    }

    @Test("Each language bundle can resolve a Localizable.strings value")
    func eachLanguageBundleResolvesAString() throws {
        let key = "输出语言"
        let expectedValues = [
            "en": "Output language",
            "zh-Hans": "输出语言",
            "ja": "出力言語",
            "ko": "출력 언어"
        ]

        for code in languageCodes {
            let bundle = Bundle(
                path: repositoryRoot
                    .appendingPathComponent(
                        "Source/MemoMark/MemoMark/\(code).lproj"
                    )
                    .path
            )
            let value = bundle?.localizedString(
                forKey: key,
                value: nil,
                table: "Localizable"
            )

            #expect(value != nil)
            #expect(value == expectedValues[code])
        }
    }

    @Test("Settings core surface has explicit Japanese and Korean values")
    func settingsCoreSurfaceHasLocalizedValues() throws {
        let keys = [
            "settings.navigation.title",
            "settings.interface_preferences.title",
            "settings.appearance.title",
            "settings.appearance.description",
            "settings.appearance.system",
            "settings.appearance.light",
            "settings.appearance.dark",
            "settings.interface.title",
            "settings.interface.description",
            "settings.getting_started.title",
            "settings.getting_started.detail",
            "settings.expression_guide.title",
            "settings.photo_processing.title",
            "settings.support.title",
            "settings.data_safety.title",
            "settings.privacy.title",
            "settings.feedback.section_title",
            "settings.community.section_title",
            "settings.feedback.diagnostics.title",
            "settings.feedback.diagnostics.detail",
            "settings.about.title",
            "settings.version.release_notes",
            "settings.version.release_notes_detail",
            "settings.footer.closing"
        ]

        let resources = try ["en", "ja", "ko"].map { code in
            (
                code: code,
                entries: parseResource(
                    try sourceText(
                        "Source/MemoMark/MemoMark/\(code).lproj/Localizable.strings"
                    )
                ).entries
            )
        }
        let english = try #require(
            resources.first(where: { $0.code == "en" })?.entries
        )

        for key in keys {
            let englishValue = try #require(english[key])
            for resource in resources where resource.code != "en" {
                let localizedValue = try #require(resource.entries[key])
                #expect(localizedValue != englishValue, "\(resource.code) unexpectedly uses the English baseline for \(key)")
            }
        }
    }

    @Test("Configuration Center core surface has explicit Japanese and Korean values")
    func configurationCenterCoreSurfaceHasLocalizedValues() throws {
        let resources = try ["en", "ja", "ko"].map { code in
            (
                code: code,
                entries: parseResource(
                    try sourceText(
                        "Source/MemoMark/MemoMark/\(code).lproj/Localizable.strings"
                    )
                ).entries
            )
        }
        let english = try #require(
            resources.first(where: { $0.code == "en" })?.entries
        )
        let prefixes = [
            "configuration.summary.",
            "configuration.sidebar.",
            "configuration.modules.",
            "configuration.editor.",
            "configuration.output.",
            "configuration.navigation.",
            "configuration.preview.",
            "configuration.memory_start.",
            "configuration.expression.",
            "configuration.card_style.",
            "configuration.layout.",
            "configuration.photo_description.",
            "configuration.save_location.",
            "configuration.time_place.",
            "configuration.disclosure.",
            "configuration.state.",
            "welcome.first_run.",
            "welcome.configuration_required."
        ]
        let genericDisclosureKeys = [
            "收起",
            "调整",
            "已折叠",
            "已展开"
        ]
        let keys = english.keys.filter { key in
            prefixes.contains(where: key.hasPrefix)
        } + genericDisclosureKeys

        for key in keys {
            let englishValue = try #require(english[key])
            for resource in resources where resource.code != "en" {
                let localizedValue = try #require(resource.entries[key])
                #expect(localizedValue != englishValue, "\(resource.code) unexpectedly uses the English baseline for \(key)")
            }
        }
    }

    @Test("Welcome core surface has explicit Japanese and Korean values")
    func welcomeCoreSurfaceHasLocalizedValues() throws {
        let resources = try ["en", "ja", "ko"].map { code in
            (
                code: code,
                entries: parseResource(
                    try sourceText(
                        "Source/MemoMark/MemoMark/\(code).lproj/Localizable.strings"
                    )
                ).entries
            )
        }
        let english = try #require(
            resources.first(where: { $0.code == "en" })?.entries
        )
        let keys = english.keys.filter { key in
            let fixedIdentityKeys = [
                "welcome.title",
                "welcome.hero.version",
                "welcome.workflow.pipeline"
            ]
            return (
                key.hasPrefix("welcome.")
                && !fixedIdentityKeys.contains(key)
            ) || key == "common.done"
        }

        for key in keys {
            let englishValue = try #require(english[key])
            for resource in resources where resource.code != "en" {
                let localizedValue = try #require(resource.entries[key])
                #expect(localizedValue != englishValue, "\(resource.code) unexpectedly uses the English baseline for \(key)")
            }
        }
    }

    @Test("Commerce purchase transient states resolve in all four languages")
    func commerceTransientStatesHaveFourLanguageValues() throws {
        let keys = [
            "commerce.purchase.restoring",
            "commerce.purchase.redeeming"
        ]
        for code in languageCodes {
            let resource = parseResource(
                try sourceText(
                    "Source/MemoMark/MemoMark/\(code).lproj/Localizable.strings"
                )
            )
            for key in keys {
                #expect(resource.entries[key] != nil)
                #expect(resource.entries[key]?.isEmpty == false)
            }
        }
    }

    @Test("Processing status surface has explicit Japanese and Korean values")
    func processingSurfaceHasLocalizedValues() throws {
        let resources = try ["en", "ja", "ko"].map { code in
            (
                code: code,
                entries: parseResource(
                    try sourceText(
                        "Source/MemoMark/MemoMark/\(code).lproj/Localizable.strings"
                    )
                ).entries
            )
        }
        let english = try #require(
            resources.first(where: { $0.code == "en" })?.entries
        )
        for key in english.keys where key.hasPrefix("processing.") {
            let englishValue = try #require(english[key])
            for resource in resources where resource.code != "en" {
                let localizedValue = try #require(resource.entries[key])
                #expect(localizedValue != englishValue, "\(resource.code) unexpectedly uses the English baseline for \(key)")
            }
        }
    }

    @Test("Core product terminology has an explicit Japanese and Korean value")
    func coreTerminologyIsNotAnEnglishFallback() throws {
        let japanese = parseResource(
            try sourceText(
                "Source/MemoMark/MemoMark/ja.lproj/Localizable.strings"
            )
        )
        let korean = parseResource(
            try sourceText(
                "Source/MemoMark/MemoMark/ko.lproj/Localizable.strings"
            )
        )

        let expectedJapanese = [
            "出力言語",
            "プリセット",
            "タイムアンカー",
            "メモリーカード"
        ]
        let expectedKorean = [
            "출력 언어",
            "프리셋",
            "시간 앵커",
            "메모리 카드"
        ]

        for value in expectedJapanese {
            #expect(japanese.entries.values.contains(where: { $0.contains(value) }))
        }
        for value in expectedKorean {
            #expect(korean.entries.values.contains(where: { $0.contains(value) }))
        }
    }

    @Test("The Xcode Localizable.strings variant group contains ja and ko")
    func xcodeVariantGroupContainsNewLanguages() throws {
        let project = try sourceText(
            "Source/MemoMark/MemoMark.xcodeproj/project.pbxproj"
        )

        #expect(
            project.contains(
                "MemoMark/ja.lproj/Localizable.strings"
            )
        )
        #expect(
            project.contains(
                "MemoMark/ko.lproj/Localizable.strings"
            )
        )
        #expect(
            project.contains("ja Localizable.strings")
        )
        #expect(
            project.contains("ko Localizable.strings")
        )
    }

    private struct ParsedResource {
        let entries: [String: String]
        let duplicateKeys: Set<String>
        let emptyKeys: Set<String>
    }

    private func parseResource(
        _ source: String
    ) -> ParsedResource {
        var entries: [String: String] = [:]
        var duplicateKeys: Set<String> = []
        var emptyKeys: Set<String> = []

        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(line)
            guard line.first == "\"" else {
                continue
            }

            let separator = "\" = \""
            guard let range = line.range(of: separator) else {
                continue
            }

            let key = String(line[line.index(after: line.startIndex)..<range.lowerBound])
            let valueStart = range.upperBound
            let valueEnd = line.lastIndex(of: "\"") ?? line.endIndex
            guard valueStart <= valueEnd else {
                continue
            }

            let value = String(line[valueStart..<valueEnd])
            if entries[key] != nil {
                duplicateKeys.insert(key)
            }
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                emptyKeys.insert(key)
            }
            entries[key] = value
        }

        return ParsedResource(
            entries: entries,
            duplicateKeys: duplicateKeys,
            emptyKeys: emptyKeys
        )
    }

    private func sourceText(
        _ relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
