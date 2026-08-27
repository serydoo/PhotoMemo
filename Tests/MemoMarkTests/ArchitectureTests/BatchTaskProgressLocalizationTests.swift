#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Batch task progress localization")
struct BatchTaskProgressLocalizationTests {

    @Test("Legacy status-only JSON migrates known messages to a semantic stage")
    func legacyStatusOnlyJSONMigratesKnownMessage() throws {
        let data = try #require(
            """
            {
              "currentUnit": 4,
              "totalUnits": 6,
              "statusMessage": "正在生成图片"
            }
            """.data(using: .utf8)
        )

        let progress = try JSONDecoder().decode(
            BatchTaskProgress.self,
            from: data
        )

        #expect(progress.stage == .renderingImage)
        #expect(
            progress.localizedStatusMessage(
                for: .english
            )
            == "Creating image"
        )
    }

    @Test("Unknown legacy messages remain readable")
    func unknownLegacyMessageRemainsReadable() throws {
        let data = try #require(
            """
            {
              "currentUnit": 1,
              "totalUnits": 2,
              "statusMessage": "旧版自定义说明"
            }
            """.data(using: .utf8)
        )

        let progress = try JSONDecoder().decode(
            BatchTaskProgress.self,
            from: data
        )

        #expect(progress.stage == nil)
        #expect(
            progress.localizedStatusMessage(
                for: .english
            )
            == "旧版自定义说明"
        )
    }

    @Test("Semantic stages resolve in every supported interface language")
    func semanticStagesResolveInEverySupportedLanguage() {
        let progress = BatchTaskProgress(
            currentUnit: 4,
            totalUnits: 6,
            stage: .renderingImage
        )

        #expect(
            progress.localizedStatusMessage(
                for: .simplifiedChinese
            )
            == "正在生成图片"
        )
        #expect(
            progress.localizedStatusMessage(
                for: .english
            )
            == "Creating image"
        )
        #expect(
            progress.localizedStatusMessage(
                for: .japanese
            )
            == "画像を作成中"
        )
        #expect(
            progress.localizedStatusMessage(
                for: .korean
            )
            == "이미지 생성 중"
        )
    }

    @Test("Current progress JSON stores a semantic stage without a Chinese display message")
    func currentProgressJSONStoresSemanticStage() throws {
        let progress = BatchTaskProgress(
            currentUnit: 4,
            totalUnits: 6,
            stage: .renderingImage
        )
        let object = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(progress)
            ) as? [String: Any]
        )

        #expect(object["stage"] as? String == "renderingImage")
        #expect(object["statusMessage"] as? String == "")
    }
}
#endif
