#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 subject home summary presenter")
struct V1SubjectHomeSummaryPresenterTests {

    @Test("presentation prefers short subject name and preserves home summary facts")
    func presentationPrefersShortSubjectNameAndPreservesFacts() {
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "团团小朋友",
                        shortName: "团团"
                    ),
                relationship:
                    .init(
                        role: "family",
                        label: "女儿"
                    ),
                definition: "用于生成照片底部信息卡。",
                referenceDate: Date(timeIntervalSince1970: 1_704_067_200),
                behavior:
                    .init(
                        primaryAnchor: "出生",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            .init(
                                title: "记忆",
                                blocks: [.text("记录于")]
                            )
                    ),
                decorations: []
            )

        let presentation =
            V1SubjectHomeSummaryPresenter
            .presentation(
                subject: subject,
                currentConfigurationLabel: "团团小朋友 · 出生",
                activeConfigurationStatus: .saved,
                currentTimeAnchorTitle: "出生",
                currentTimeAnchorDescription: "团团出生"
            )

        #expect(
            presentation.configurationTitle
            == "团团小朋友 · 出生"
        )
        #expect(
            presentation.subjectTitle
            == "团团"
        )
        #expect(
            presentation.relationshipSummary
            == "女儿"
        )
        #expect(
            presentation.anchorSummary
            == "出生"
        )
        #expect(
            presentation.description
            == "团团出生"
        )
        #expect(
            presentation.statusText
            == "已保存为分享配置"
        )
        #expect(
            presentation.statusTone
            == .accent
        )
    }

    @Test("presentation falls back to stable subject home copy when subject fields are empty")
    func presentationFallsBackToStableSubjectHomeCopyWhenSubjectFieldsAreEmpty() {
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "   ",
                        shortName: ""
                    ),
                relationship:
                    .init(
                        role: "family",
                        label: "  "
                    ),
                definition: "   ",
                referenceDate: Date(timeIntervalSince1970: 1_704_067_200),
                behavior:
                    .init(
                        primaryAnchor: "出生",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            .init(
                                title: "记忆",
                                blocks: [.text("记录于")]
                            )
                    ),
                decorations: []
            )

        let presentation =
            V1SubjectHomeSummaryPresenter
            .presentation(
                subject: subject,
                currentConfigurationLabel: "   ",
                activeConfigurationStatus: .idle,
                currentTimeAnchorTitle: "  ",
                currentTimeAnchorDescription: "  "
            )

        #expect(
            presentation.configurationTitle
            == "记忆对象"
        )
        #expect(
            presentation.subjectTitle
            == "记忆对象"
        )
        #expect(
            presentation.relationshipSummary
            == "补充主角信息"
        )
        #expect(
            presentation.anchorSummary
            == "未设置"
        )
        #expect(
            presentation.description
            == "用于生成照片底部信息卡。"
        )
        #expect(
            presentation.statusText
            == "尚未保存为分享配置"
        )
        #expect(
            presentation.statusTone
            == .neutral
        )
    }

    @Test("subject library synced status uses accent tone")
    func subjectLibrarySyncedStatusUsesAccentTone() {
        let presentation =
            V1SubjectHomeSummaryPresenter
            .presentation(
                subject: nil,
                currentConfigurationLabel: "",
                activeConfigurationStatus: .subjectSynced,
                currentTimeAnchorTitle: "",
                currentTimeAnchorDescription: ""
            )

        #expect(
            presentation.statusText
            == "记忆对象已同步"
        )
        #expect(
            presentation.statusTone
            == .accent
        )
    }
}
#endif
