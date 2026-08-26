import Foundation
import Testing

@Suite("Active localization usage audit")
struct ActiveLocalizationUsageAuditTests {

    private let languageCodes = ["en", "zh-Hans", "ja", "ko"]

    // This is the current iOS Main App surface allowlist. It intentionally
    // excludes Share Extension, Widget, macOS-only views, and coordinators
    // whose strings are developer diagnostics rather than UI copy.
    private let activeSurfaceFiles = [
        "Source/MemoMark/MemoMark/iOS/Views/MemoMarkiOSV1View.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenteriOSView.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterActiveRegionEditorSection.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterDetailPanelSection.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterDetailSupportPanels.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterIOSSupportViews.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterInsertableModuleLibrarySection.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterPresetMenu.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterRegionComposerSection.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterSidebarView.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterSummarySection.swift",
        "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterTopPreviewSection.swift",
        "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusBadge.swift",
        "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusPurchaseView.swift",
        "Source/MemoMark/MemoMark/iOS/Views/MemoryWriteOptionPresenter.swift",
        "Source/MemoMark/MemoMark/iOS/Views/MemoMarkiOSBackgroundStatusSheet.swift",
        "Source/MemoMark/MemoMark/iOS/Views/MemoMarkiOSBackgroundStatusSheetSupportViews.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1ConfigurationPageSurface.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1HomeFeedbackSection.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1HomePageSurface.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1ReleaseNotesSheet.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1SettingsExpressionGuide.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1SettingsPageSurface.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1TaskPageSurface.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1WelcomeAndSettingsPresentationModifier.swift",
        "Source/MemoMark/MemoMark/iOS/Views/V1WelcomePresentation.swift",
        "Source/MemoMark/MemoMark/Services/MemoMarkCommerceStore.swift"
    ]

    private let keyPattern = try! NSRegularExpression(
        pattern: #""((?:common|settings|configuration|welcome|processing|task|commerce|output|home)\.[A-Za-z0-9_.]+)""#
    )

    private let intentionalEnglishKeys: Set<String> = [
        "common.ok",
        "commerce.title",
        "settings.feedback.github.title",
        "settings.version.compact_format",
        "settings.version.copyright",
        "home.apple_photos.brand",
        "welcome.title",
        "welcome.hero.version",
        "welcome.workflow.pipeline"
    ]

    // Expression formulas are examples rendered by the guide. They are
    // classified as Preview/Mock content in the active-literal audit and are
    // not counted as production UI fallback. The guide's surrounding labels
    // and anchor descriptions remain active localized UI and are audited.
    private let previewOnlyPrefixes = [
        "settings.expression.formula."
    ]

    @Test("Active Main App keys have four-language values without accidental fallback")
    func activeKeysHaveNoAccidentalFallback() throws {
        let resources = try loadResources()
        let english = try #require(resources["en"])
        var activeKeys = Set<String>()

        for relativePath in activeSurfaceFiles {
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(relativePath),
                encoding: .utf8
            )
            activeKeys.formUnion(keys(in: source))
        }

        // Dynamic guide keys cannot be recovered from a literal-only scan.
        // Add them from the resource contract so the audit remains honest.
        activeKeys.formUnion(
            english.keys.filter {
                $0.hasPrefix("settings.expression.anchor.")
            }
        )

        let missing = languageCodes.reduce(into: [String: [String]]()) { result, code in
            let entries = resources[code, default: [:]]
            let missingKeys = activeKeys.filter { entries[$0] == nil }.sorted()
            if !missingKeys.isEmpty {
                result[code] = missingKeys
            }
        }

        let auditedKeys = activeKeys.filter { key in
            !previewOnlyPrefixes.contains(where: key.hasPrefix)
        }
        let japaneseFallbacks = auditedKeys.filter { key in
            guard !intentionalEnglishKeys.contains(key),
                  let englishValue = english[key],
                  let localizedValue = resources["ja"]?[key]
            else {
                return false
            }
            return localizedValue == englishValue
        }.sorted()
        let koreanFallbacks = auditedKeys.filter { key in
            guard !intentionalEnglishKeys.contains(key),
                  let englishValue = english[key],
                  let localizedValue = resources["ko"]?[key]
            else {
                return false
            }
            return localizedValue == englishValue
        }.sorted()

        let orphanKeys = english.keys.filter { !activeKeys.contains($0) }.sorted()

        print("Active localization audit: active=\(activeKeys.count), audited=\(auditedKeys.count), jaFallback=\(japaneseFallbacks.count), koFallback=\(koreanFallbacks.count), missing=\(missing.values.reduce(0) { $0 + $1.count }), orphan=\(orphanKeys.count)")
        if !japaneseFallbacks.isEmpty {
            print("Japanese active fallback keys: \(japaneseFallbacks)")
        }
        if !koreanFallbacks.isEmpty {
            print("Korean active fallback keys: \(koreanFallbacks)")
        }

        #expect(missing.isEmpty)
        #expect(japaneseFallbacks.isEmpty)
        #expect(koreanFallbacks.isEmpty)
    }

    private func keys(in source: String) -> Set<String> {
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        return Set(
            keyPattern.matches(in: source, range: range).compactMap { match in
                guard let keyRange = Range(match.range(at: 1), in: source) else {
                    return nil
                }
                return String(source[keyRange])
            }
        )
    }

    private func loadResources() throws -> [String: [String: String]] {
        try Dictionary(uniqueKeysWithValues: languageCodes.map { code in
            let source = try String(
                contentsOf: repositoryRoot.appendingPathComponent(
                    "Source/MemoMark/MemoMark/\(code).lproj/Localizable.strings"
                ),
                encoding: .utf8
            )
            return (code, parse(source))
        })
    }

    private func parse(_ source: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(line)
            guard line.first == "\"",
                  let separator = line.range(of: "\" = \"") else {
                continue
            }
            let key = String(line[line.index(after: line.startIndex)..<separator.lowerBound])
            let valueStart = separator.upperBound
            let valueEnd = line.lastIndex(of: "\"") ?? line.endIndex
            guard valueStart <= valueEnd else {
                continue
            }
            result[key] = String(line[valueStart..<valueEnd])
        }
        return result
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
