import Testing
@testable import PhotoMemo

@Suite("Inline content text composer")
struct InlineContentTextComposerTests {

    @Test("Keeps Chinese custom text attached to inserted modules")
    func keepsChineseCustomTextAttachedToInsertedModules() {
        let text =
            InlineContentTextComposer.compose([
                .init(kind: .text, value: "他爹手持"),
                .init(kind: .token, value: "iPhone 17 Pro Max")
            ])

        #expect(text == "他爹手持iPhone 17 Pro Max")
    }

    @Test("Keeps suffix text attached to age modules")
    func keepsSuffixTextAttachedToAgeModules() {
        let text =
            InlineContentTextComposer.compose([
                .init(kind: .token, value: "途途"),
                .init(kind: .text, value: "今天"),
                .init(kind: .token, value: "1岁1个月2天"),
                .init(kind: .text, value: "啦！")
            ])

        #expect(text == "途途今天1岁1个月2天啦！")
    }

    @Test("Keeps adjacent token values readable")
    func keepsAdjacentTokenValuesReadable() {
        let text =
            InlineContentTextComposer.compose([
                .init(kind: .token, value: "2026.06.27"),
                .init(kind: .token, value: "11:24:25")
            ])

        #expect(text == "2026.06.27 11:24:25")
    }

    @Test("Respects explicit separators without adding extra spaces")
    func respectsExplicitSeparatorsWithoutAddingExtraSpaces() {
        let text =
            InlineContentTextComposer.compose([
                .init(kind: .token, value: "2026.06.27"),
                .init(kind: .separator, value: "·"),
                .init(kind: .token, value: "11:24:25")
            ])

        #expect(text == "2026.06.27·11:24:25")
    }

    @Test("Composes formal configuration text modules and continuation naturally")
    func composesFormalConfigurationPartsNaturally() {
        let text =
            InlineContentTextComposer.compose([
                .init(kind: .text, value: "途途今天"),
                .init(kind: .token, value: "1岁1个月2天"),
                .init(kind: .text, value: "啦！")
            ])

        #expect(text == "途途今天1岁1个月2天啦！")
    }
}
