#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@MainActor
@Suite("Release UI localization and selection")
struct ReleaseUIPolishTests {
    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }

    private func source(_ name: String) throws -> String {
        try String(contentsOf: root.appendingPathComponent(
            "Source/MemoMark/MemoMark/iOS/Views/\(name).swift"
        ), encoding: .utf8)
    }

    @Test("Anchor and backup controls never bypass interface localization")
    func localizedReleaseSurfaces() throws {
        let directLiteral = try NSRegularExpression(pattern:
            #"\b(?:Text|Button|Label|navigationTitle|accessibilityLabel|accessibilityAction|DatePicker)\s*\(\s*(?:named:\s*)?"[^"\n]*\p{Han}"#)
        let localizedKey = try NSRegularExpression(pattern: #"uiText\("([^"]+)"\)"#)
        for name in ["SubjectAnchorDetailSection", "LocalConfigurationLibrarySheet"] {
            let text = try source(name)
            let range = NSRange(text.startIndex..., in: text)
            #expect(directLiteral.numberOfMatches(in: text, range: range) == 0)
            let keys = localizedKey.matches(in: text, range: range).compactMap {
                Range($0.range(at: 1), in: text).map { String(text[$0]) }
            }
            #expect(!keys.isEmpty)
            for key in Set(keys) {
                for language in MemoMarkLanguage.allCases {
                    let value = language.localized(key: key, fallback: "MISSING")
                    #expect(value != "MISSING", "\(language): \(key)")
                    #expect(!value.isEmpty)
                    if language != .simplifiedChinese {
                        #expect(value.range(of: #"\p{Han}"#, options: .regularExpression) == nil || language == .japanese)
                    }
                }
            }
        }
    }

    @Test("Destructive confirmations preserve names and backup revision/date placeholders")
    func localizedFormats() {
        for language in MemoMarkLanguage.allCases {
            for key in ["time_anchor.delete.named", "local_backup.delete.named"] {
                let format = language.localized(key: key, fallback: "MISSING")
                #expect(format.components(separatedBy: "%@").count == 2)
                #expect(String(format: format, "Family 🌿").contains("Family 🌿"))
            }
            let format = language.localized(key: "local_backup.revision_date", fallback: "MISSING")
            #expect(format.components(separatedBy: "%@").count == 3)
            let value = String(format: format, "42", "2026-10-03")
            #expect(value.contains("42") && value.contains("2026-10-03"))
        }
    }

    @Test("Language always uses a menu and expression fit reserves uncompressed equal segments")
    func stableSelectionSurfaces() throws {
        let settings = try source("InterfacePreferencesContent")
        let start = try #require(settings.range(of: "private var interfaceLanguagePicker:"))
        let end = try #require(settings.range(of: "private var interfaceLanguagePickerBase:"))
        let languagePicker = settings[start.lowerBound..<end.lowerBound]
        #expect(languagePicker.contains(".pickerStyle(.menu)"))
        #expect(!languagePicker.contains(".segmented"))
        let options = try source("ConfigurationOptionList")
        let choicesStart = try #require(options.range(of: "private var memoryDisplayStyleChoices:"))
        let choicesEnd = try #require(options.range(of: "private var memoryDisplayPicker:"))
        let choices = options[choicesStart.lowerBound..<choicesEnd.lowerBound]
        #expect(choices.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(choices.contains("ViewThatFits(in: .horizontal)"))
        #expect(choices.contains(".fixedSize(horizontal: true, vertical: false)"))
        #expect(choices.contains("ZStack"))
        #expect(choices.contains("memoryDisplayPicker.pickerStyle(.menu)"))
    }
}
#endif
