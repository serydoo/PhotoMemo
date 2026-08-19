#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 iOS home projection")
struct V1IOSHomeProjectionTests {

    @Test("subject summary reflects the edited object name instead of a stale nickname")
    func subjectSummaryReflectsEditedObjectName() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "小宝",
                    shortName: "儿子啊"
                ),
                relationship: .init(
                    role: "家庭",
                    label: "成长记录"
                ),
                definition: "围绕宝宝成长时间线展开。",
                referenceDate: Date(
                    timeIntervalSince1970: 0
                ),
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: Date(
                            timeIntervalSince1970: 0
                        ),
                        note: "出生日期"
                    ),
                    .init(
                        title: "入园",
                        date: Date(
                            timeIntervalSince1970: 86400
                        ),
                        note: "上幼儿园"
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

        let projection =
            V1IOSHomeProjection
            .subjectSummary(
                subject: subject,
                selectedAnchorTitle: "生日"
            )

        #expect(projection.title == "小宝")
        #expect(projection.subtitle == "成长记录")
        #expect(projection.anchorTitle == "生日")
    }

    @Test("deferred first-run subject edits project current facts to Home")
    @MainActor
    func deferredFirstRunSubjectEditsProjectCurrentFactsToHome() async throws {
        let anchor =
            MemorySubject.TimeAnchor(
                title: "默认锚点",
                date: Date(timeIntervalSince1970: 0),
                note: "默认说明"
            )
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "默认对象",
                    shortName: "儿子啊"
                ),
                relationship: .init(
                    role: "家庭",
                    label: "默认称呼"
                ),
                referenceDate: anchor.date,
                timeAnchors: [anchor],
                activeTimeAnchorID: anchor.id,
                behavior: .init(
                    primaryAnchor: anchor.title,
                    iconStrategy: .autoMatch,
                    badgeStrategy: .fixed,
                    memoryExpression: .init(
                        title: "默认表达",
                        blocks: []
                    )
                ),
                decorations: []
            )
        let session =
            ConfigurationSession(
                state: ConfigurationCenterState(
                    subjects: [subject],
                    selectedSubjectID: subject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil,
                    cardSelection: .init(
                        selectedRegion: .subject
                    ),
                    selectedBlockID: nil,
                    tokenLibrary: .init(),
                    availableDecorations: [],
                    regionPreviewTexts: [:]
                )
            )
        let flow = try #require(
            V1IOSSubjectConfigurationFlowState(
                liveSession: session
            )
        )
        var editedSubject = try #require(
            flow.draftSession.state.selectedSubject
        )
        editedSubject.identity.displayName = "小宝"
        editedSubject.relationship.label = "家人"
        editedSubject.timeAnchors[0].title = "生日"
        editedSubject.behavior.primaryAnchor = "生日"
        flow.draftSession.updateSelectedSubject(
            editedSubject
        )

        #expect(await flow.saveChanges())

        let projection =
            V1IOSHomeProjection
            .subjectSummary(
                subject: session.state.selectedSubject,
                selectedAnchorTitle:
                    session.currentTimeAnchorTitle
            )

        #expect(projection.title == "小宝")
        #expect(projection.subtitle == "家人")
        #expect(projection.anchorTitle == "生日")
    }

    @Test("subject summary falls back when no subject is available")
    func subjectSummaryFallsBackWithoutSubject() {
        let projection =
            V1IOSHomeProjection
            .subjectSummary(
                subject: nil,
                selectedAnchorTitle: nil
            )

        #expect(projection.title == "记忆对象")
        #expect(projection.subtitle == "补充主角信息")
        #expect(projection.anchorTitle == "未设置")
    }

    @Test("output summary uses target title and custom album detail")
    func outputSummaryUsesTargetAndAlbumDetail() {
        let projection =
            V1IOSHomeProjection
            .outputSummary(
                outputTarget: .existingAlbum,
                selectedExistingAlbumTitle: "家庭相册",
                newAlbumName: "",
                writesMemoryDescription: true
            )

        #expect(projection.title == "已有相册")
        #expect(projection.detail == "家庭相册")
        #expect(projection.memoryWriteLabel == "写入说明已开启")
        #expect(
            projection.targetNote
            == V1IOSOutputTarget.existingAlbum.note
        )
        #expect(
            projection.memoryWriteDetail
            == "生成结果会附带当前记忆说明。"
        )
    }

    @Test("output summary falls back for automatic output")
    func outputSummaryFallsBackForAutomaticOutput() {
        let projection =
            V1IOSHomeProjection
            .outputSummary(
                outputTarget: .automatic,
                selectedExistingAlbumTitle: "",
                newAlbumName: "",
                writesMemoryDescription: false
            )

        #expect(projection.title == "自动")
        #expect(projection.detail == "系统图库 + 时光记相册")
        #expect(projection.memoryWriteLabel == "写入说明已关闭")
        #expect(
            projection.targetNote
            == V1IOSOutputTarget.automatic.note
        )
        #expect(
            projection.memoryWriteDetail
            == "生成结果不会额外写入说明文本。"
        )
    }

    @Test("preset summary reflects applied preset state")
    func presetSummaryReflectsAppliedPresetState() {
        let projection =
            V1IOSHomeProjection
            .presetSummary(
                presetTitle: "Classic White",
                configurationLabel: "小宝 · 生日",
                presetSummary: "底栏四槽位",
                activeConfigurationStatus: .idle,
                isApplied: true
            )

        #expect(projection.title == "Classic White")
        #expect(projection.subtitle == "小宝 · 生日")
        #expect(projection.detail == "底栏四槽位")
        #expect(projection.statusLabel == "当前生效")
        #expect(projection.emphasizesAppliedState)
    }

    @Test("preset summary prefers pending status message when unsaved")
    func presetSummaryPrefersPendingStatusMessageWhenUnsaved() {
        let projection =
            V1IOSHomeProjection
            .presetSummary(
                presetTitle: "",
                configurationLabel: "",
                presetSummary: "",
                activeConfigurationStatus: .dirty,
                isApplied: false
            )

        #expect(projection.title == "记忆预设")
        #expect(projection.subtitle == "当前生效配置")
        #expect(projection.detail == "当前生效配置摘要")
        #expect(projection.statusLabel == "有未保存修改")
        #expect(!projection.emphasizesAppliedState)
    }

    @Test("empty preset summary explains that creation stays in the configuration center")
    func emptyPresetSummaryExplainsCreationBoundary() {
        let projection =
            V1IOSHomeProjection
            .emptyPresetSummary(
                configurationLabel: "事件对象 · 纪念日"
            )

        #expect(projection.title == "当前对象还没有配置")
        #expect(projection.subtitle == "事件对象 · 纪念日")
        #expect(
            projection.detail
            == "请先到配置中心底部新建配置，之后这里就能直接下拉切换。"
        )
        #expect(projection.statusLabel == "等待配置")
        #expect(!projection.emphasizesAppliedState)
    }

    @Test("saved status identifies the timestamp as a saved preset in each interface language")
    func savedStatusValueSupportsUnsavedAndSavedStates() {
        #expect(
            V1IOSHomeProjection
                .savedStatusValue(
                    savedAt: nil,
                    language: .simplifiedChinese
                )
            == "尚未保存"
        )

        #expect(
            V1IOSHomeProjection
                .savedStatusValue(
                    savedAt: Date(timeIntervalSince1970: 0),
                    timeZone: TimeZone(secondsFromGMT: 0)!,
                    language: .simplifiedChinese
                )
            == "1月1日 00:00 保存"
        )

        #expect(
            V1IOSHomeProjection
                .savedStatusValue(
                    savedAt: Date(timeIntervalSince1970: 0),
                    timeZone: TimeZone(identifier: "Asia/Shanghai")!,
                    language: .simplifiedChinese
                )
            == "1月1日 08:00 保存"
        )

        #expect(
            V1IOSHomeProjection
                .savedStatusValue(
                    savedAt: Date(timeIntervalSince1970: 0),
                    timeZone: TimeZone(secondsFromGMT: 0)!,
                    language: .english
            )
            == "Saved Jan 1, 00:00"
        )

        #expect(
            V1IOSHomeProjection
                .savedStatusValue(
                    savedAt: Date(timeIntervalSince1970: 0),
                    timeZone: TimeZone(secondsFromGMT: 0)!,
                    language: .japanese
                )
            == "1月1日 00:00に保存"
        )

        #expect(
            V1IOSHomeProjection
                .savedStatusValue(
                    savedAt: Date(timeIntervalSince1970: 0),
                    timeZone: TimeZone(secondsFromGMT: 0)!,
                    language: .korean
                )
            == "1월 1일 00:00 저장"
        )
    }
}
#endif
