#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 iOS time anchor presentation")
struct V1IOSTimeAnchorPresentationTests {

    @Test("title follows the current primary anchor instead of the subject name")
    func titleFollowsCurrentPrimaryAnchor() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "小宝成长记录",
                    shortName: "小宝"
                ),
                relationship: .init(
                    role: "family",
                    label: "成长记录"
                ),
                definition: "",
                referenceDate: Date(timeIntervalSince1970: 0),
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: Date(timeIntervalSince1970: 0),
                        note: "出生日期"
                    ),
                    .init(
                        title: "入园",
                        date: Date(timeIntervalSince1970: 86_400),
                        note: "第一次去幼儿园"
                    )
                ],
                activeTimeAnchorID: nil,
                behavior: .init(
                    primaryAnchor: "入园",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )

        #expect(
            V1IOSTimeAnchorPresentation
                .title(subject: subject)
            == "入园"
        )
    }

    @Test("title falls back when the subject has no usable anchor title")
    func titleFallsBackWithoutUsableAnchor() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "成长记录",
                    shortName: ""
                ),
                relationship: .init(
                    role: "family",
                    label: "成长记录"
                ),
                definition: "",
                referenceDate: Date(timeIntervalSince1970: 0),
                timeAnchors: [],
                activeTimeAnchorID: nil,
                behavior: .init(
                    primaryAnchor: "",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )

        #expect(
            V1IOSTimeAnchorPresentation
                .title(
                    subject: subject,
                    fallback: "时间锚点"
                )
            == "时间锚点"
        )
    }

    @Test("loading anchor drafts keeps selection without auto-opening the edit sheet")
    func loadingAnchorDraftsDoesNotAutoOpenEditSheet() throws {
        let source =
            try String(
                contentsOfFile:
                    "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift",
                encoding: .utf8
            )

        #expect(
            source.contains("editingTimeAnchorID = nil"),
            "Draft loading should clear editingTimeAnchorID so anchor maintenance does not auto-open edit."
        )
    }
}
#endif
