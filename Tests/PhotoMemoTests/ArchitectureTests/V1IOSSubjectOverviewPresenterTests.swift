#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 iOS subject overview presenter")
struct V1IOSSubjectOverviewPresenterTests {

    @Test("presentation reflects selected anchor and subject facts")
    func presentationReflectsSelectedAnchorAndSubjectFacts() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "途途成长记录",
                    shortName: "途途"
                ),
                relationship: .init(
                    role: "family",
                    label: "成长记录"
                ),
                definition: "围绕成长阶段持续记录。",
                referenceDate: Date(
                    timeIntervalSince1970: 0
                ),
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: Date(
                            timeIntervalSince1970: 0
                        ),
                        note: "途途出生日期"
                    ),
                    .init(
                        title: "入园",
                        date: Date(
                            timeIntervalSince1970: 86_400
                        ),
                        note: "第一次去幼儿园"
                    )
                ],
                behavior: .init(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )

        let presentation =
            V1IOSSubjectOverviewPresenter
            .presentation(
                subject: subject,
                currentTimeAnchorTitle: "生日",
                currentTimeAnchorDescription: "途途出生日期"
            )
        let expectedAnchorDateLabel =
            Date(timeIntervalSince1970: 0)
            .formatted(
                .dateTime
                    .year()
                    .month()
                    .day()
            )

        #expect(presentation.title == "途途")
        #expect(presentation.subtitle == "成长记录")
        #expect(presentation.expressionSubjectTitle == "显示名称")
        #expect(presentation.expressionSubjectValue == "途途成长记录")
        #expect(presentation.anchorTitle == "生日")
        #expect(
            presentation.anchorDateLabel
            == expectedAnchorDateLabel
        )
        #expect(presentation.anchorCountLabel == "2 个时间锚点")
        #expect(presentation.anchorDescription == "途途出生日期")
    }

    @Test("presentation falls back when subject is unavailable")
    func presentationFallsBackWhenSubjectIsUnavailable() {
        let presentation =
            V1IOSSubjectOverviewPresenter
            .presentation(
                subject: nil,
                currentTimeAnchorTitle: "",
                currentTimeAnchorDescription: ""
            )

        #expect(presentation.title == "记忆对象")
        #expect(presentation.subtitle == "补充主角信息")
        #expect(presentation.expressionSubjectTitle == "显示名称")
        #expect(presentation.expressionSubjectValue == "记忆对象")
        #expect(presentation.anchorTitle == "未设置")
        #expect(presentation.anchorDateLabel == "未设置")
        #expect(presentation.anchorCountLabel == "0 个时间锚点")
    }

    @Test("configuration flow keeps a draft copy until save")
    func configurationFlowKeepsDraftCopyUntilSave() throws {
        let originalAnchor =
            MemorySubject.TimeAnchor(
                title: "生日",
                date: Date(timeIntervalSince1970: 0),
                note: "原始说明"
            )
        let originalSubject =
            MemorySubject(
                identity: .init(
                    displayName: "途途成长记录",
                    shortName: "途途"
                ),
                relationship: .init(
                    role: "family",
                    label: "成长记录"
                ),
                definition: "围绕成长阶段持续记录。",
                referenceDate: originalAnchor.date,
                timeAnchors: [originalAnchor],
                behavior: .init(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )
        let liveSession =
            ConfigurationSession(
                state: ConfigurationCenterState(
                    subjects: [originalSubject],
                    selectedSubjectID: originalSubject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil,
                    cardSelection: .init(selectedRegion: .subject),
                    selectedBlockID: nil,
                    tokenLibrary: .init(),
                    availableDecorations: [],
                    regionPreviewTexts: [:]
                )
            )

        let flow =
            V1IOSSubjectConfigurationFlowPresenter
            .makeFlowState(from: liveSession)

        #expect(flow?.sourceSubjectID == originalSubject.id)
        #expect(
            flow?.draftSession.state.selectedSubject?.identity.displayName
            == "途途成长记录"
        )

        var updatedDraft =
            try #require(
                flow?.draftSession.state.selectedSubject
            )
        updatedDraft.identity.displayName = "新的名字"
        flow?.draftSession.updateSelectedSubject(updatedDraft)

        #expect(
            liveSession.state.selectedSubject?.identity.displayName
            == "途途成长记录"
        )

        flow?.saveChanges()

        #expect(
            liveSession.state.selectedSubject?.identity.displayName
            == "新的名字"
        )
    }

    @Test("configuration flow save can persist updated subject through an external save hook")
    func configurationFlowSaveCanPersistUpdatedSubjectThroughExternalSaveHook() throws {
        let originalSubject =
            MemorySubject(
                identity: .init(
                    displayName: "途途成长记录",
                    shortName: "途途"
                ),
                relationship: .init(
                    role: "family",
                    label: "成长记录"
                ),
                definition: "围绕成长阶段持续记录。",
                referenceDate: Date(timeIntervalSince1970: 0),
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: Date(timeIntervalSince1970: 0),
                        note: "原始说明",
                        anchorType: .birthday
                    )
                ],
                expressionSubjectSource: .displayName,
                behavior: .init(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )
        let liveSession =
            ConfigurationSession(
                state: ConfigurationCenterState(
                    subjects: [originalSubject],
                    selectedSubjectID: originalSubject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil,
                    cardSelection: .init(selectedRegion: .subject),
                    selectedBlockID: nil,
                    tokenLibrary: .init(),
                    availableDecorations: [],
                    regionPreviewTexts: [:]
                )
            )

        var persistedSubject: MemorySubject?
        let flow =
            V1IOSSubjectConfigurationFlowState(
                liveSession: liveSession,
                persistSubject: { subject in
                    persistedSubject = subject
                }
            )

        var updatedDraft =
            try #require(
                flow?.draftSession.state.selectedSubject
            )
        updatedDraft.expressionSubjectSource = .shortName
        flow?.draftSession.updateSelectedSubject(updatedDraft)

        flow?.saveChanges()

        #expect(
            persistedSubject?.expressionSubjectSource
            == .shortName
        )
        #expect(
            liveSession.state.selectedSubject?.expressionSubjectSource
            == .shortName
        )
    }
}
#endif
