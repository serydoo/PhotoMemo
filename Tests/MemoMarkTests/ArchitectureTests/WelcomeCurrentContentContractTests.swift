import Foundation
import Testing

@Suite("V1 welcome current content")
struct WelcomeCurrentContentContractTests {

    @Test("welcome fallbacks describe the current V4 workflow")
    func welcomeFallbacksStayCurrent() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/WelcomePresentation.swift"
        )

        #expect(source.contains("fallback: \"V4\""))
        #expect(source.contains("fallback: \"记忆卡预设\""))
        #expect(source.contains("fallback: \"生日回顾\""))
        #expect(source.contains("fallback: \"完成后保存到 Apple Photos\""))
        #expect(source.contains("fallback: \"Apple Photos -> 分享 -> 时光记 -> 本地处理 -> Apple Photos\""))
        #expect(!source.contains("fallback: \"V1.0\""))
        #expect(!source.contains("fallback: \"表达语气\""))
        #expect(!source.contains("fallback: \"自动保存到 Apple Photos\""))
    }

    @Test("localized welcome copy stays aligned across supported languages")
    func localizedWelcomeCopyStaysAligned() throws {
        let expected: [String: [String: String]] = [
            "zh-Hans": [
                "welcome.hero.version": "V4",
                "welcome.first_run.expression_style": "记忆卡预设",
                "welcome.first_run.natural_style": "生日回顾",
                "welcome.first_run.next_save": "完成后保存到 Apple Photos"
            ],
            "en": [
                "welcome.hero.version": "V4",
                "welcome.first_run.expression_style": "Memory Card Preset",
                "welcome.first_run.natural_style": "Birthday Review",
                "welcome.first_run.next_save": "Save to Apple Photos when finished"
            ],
            "ja": [
                "welcome.hero.version": "V4",
                "welcome.first_run.expression_style": "メモリーカードのプリセット",
                "welcome.first_run.natural_style": "誕生日の記録",
                "welcome.first_run.next_save": "完了後にApple Photosへ保存します"
            ],
            "ko": [
                "welcome.hero.version": "V4",
                "welcome.first_run.expression_style": "메모리 카드 프리셋",
                "welcome.first_run.natural_style": "생일 기록",
                "welcome.first_run.next_save": "완료 후 Apple Photos에 저장합니다"
            ]
        ]

        for (language, values) in expected {
            let source = try sourceText(
                "Source/MemoMark/MemoMark/\(language).lproj/Localizable.strings"
            )
            for (key, value) in values {
                #expect(source.contains("\"\(key)\" = \"\(value)\";"))
            }
        }
    }

    private func sourceText(_ relativePath: String) throws -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
