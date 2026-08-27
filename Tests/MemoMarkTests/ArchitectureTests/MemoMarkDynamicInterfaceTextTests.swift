#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("Dynamic interface text")
struct MemoMarkDynamicInterfaceTextTests {

    @Test("Subject switch accessibility label is localized in all interface languages")
    func subjectSwitchAccessibilityLabelIsLocalized() {
        #expect(
            MemoMarkDynamicInterfaceText.subjectSwitchLabel(
                subjectName: "小满",
                language: .simplifiedChinese
            ) == "切换到小满"
        )
        #expect(
            MemoMarkDynamicInterfaceText.subjectSwitchLabel(
                subjectName: "Luna",
                language: .english
            ) == "Switch to Luna"
        )
        #expect(
            MemoMarkDynamicInterfaceText.subjectSwitchLabel(
                subjectName: "ルナ",
                language: .japanese
            ) == "ルナに切り替える"
        )
        #expect(
            MemoMarkDynamicInterfaceText.subjectSwitchLabel(
                subjectName: "루나",
                language: .korean
            ) == "루나 선택"
        )
    }

    @Test("Region module candidate accessibility label is localized in all interface languages")
    func regionModuleCandidateAccessibilityLabelIsLocalized() {
        #expect(
            MemoMarkDynamicInterfaceText.moduleCandidatesLabel(
                regionTitle: "标题",
                language: .simplifiedChinese
            ) == "标题的模块候选"
        )
        #expect(
            MemoMarkDynamicInterfaceText.moduleCandidatesLabel(
                regionTitle: "Title",
                language: .english
            ) == "Module options for Title"
        )
        #expect(
            MemoMarkDynamicInterfaceText.moduleCandidatesLabel(
                regionTitle: "タイトル",
                language: .japanese
            ) == "タイトルのモジュール候補"
        )
        #expect(
            MemoMarkDynamicInterfaceText.moduleCandidatesLabel(
                regionTitle: "제목",
                language: .korean
            ) == "제목 모듈 후보"
        )
    }

    @Test("Subject configuration title is localized in all interface languages")
    func subjectConfigurationTitleIsLocalized() {
        #expect(
            MemoMarkDynamicInterfaceText.subjectConfigurationTitle(
                subjectName: "小满",
                language: .simplifiedChinese
            ) == "小满的配置"
        )
        #expect(
            MemoMarkDynamicInterfaceText.subjectConfigurationTitle(
                subjectName: "Luna",
                language: .english
            ) == "Luna configurations"
        )
        #expect(
            MemoMarkDynamicInterfaceText.subjectConfigurationTitle(
                subjectName: "ルナ",
                language: .japanese
            ) == "ルナの構成"
        )
        #expect(
            MemoMarkDynamicInterfaceText.subjectConfigurationTitle(
                subjectName: "루나",
                language: .korean
            ) == "루나 구성"
        )
    }
}
#endif
