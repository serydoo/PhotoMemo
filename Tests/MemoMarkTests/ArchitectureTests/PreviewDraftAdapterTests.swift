#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Preview draft adapter")
struct PreviewDraftAdapterTests {

    @Test("all insertable modules share one canonical preview projection")
    @MainActor
    func allModulesShareCanonicalProjection() {
        let engine = MemoryCardPreviewCompositionEngine()
        let context = MemoryCardPreviewCompositionContext(
            subject: nil,
            birthdayDate: Date(timeIntervalSince1970: 0),
            captureDate: Date(timeIntervalSince1970: 1_800_000_000),
            language: .simplifiedChinese
        )

        for module in IOSInsertableModule.allCases {
            let expected = engine.makeModuleItem(
                module,
                context: context
            )
            let actual = PreviewDraftAdapter.moduleItem(
                module,
                context: context,
                engine: engine
            )

            #expect(actual.kind == .token)
            #expect(actual.title == expected.title)
            #expect(actual.value == expected.value)
            #expect(actual.savedValue == expected.savedValue)
            #expect(actual.systemImage == expected.systemImage)
            #expect(
                PreviewDraftAdapter.moduleDisplayText(
                    module,
                    context: context,
                    engine: engine
                )
                == engine.displayText(
                    for: module,
                    context: context
                )
            )
        }
    }
}
#endif
