#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 iOS home projection")
struct V1IOSHomeProjectionTests {

    @Test("subject summary prefers short name and reflects current anchor context")
    func subjectSummaryPrefersShortName() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "途途成长记录",
                    shortName: "途途"
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

        #expect(projection.title == "途途")
        #expect(projection.subtitle == "成长记录")
        #expect(projection.anchorTitle == "生日")
        #expect(projection.anchorCountLabel == "2 个时间锚点")
    }

    @Test("subject summary falls back when no subject is available")
    func subjectSummaryFallsBackWithoutSubject() {
        let projection =
            V1IOSHomeProjection
            .subjectSummary(
                subject: nil,
                selectedAnchorTitle: nil
            )

        #expect(projection.title == "当前记忆对象")
        #expect(projection.subtitle == "补充主角与时间锚点")
        #expect(projection.anchorTitle == "未设置")
        #expect(projection.anchorCountLabel == "0 个时间锚点")
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
        #expect(projection.detail == "系统图库 + photomemo 相册")
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
                configurationLabel: "途途 · 生日",
                presetSummary: "底栏四槽位",
                activeConfigurationMessage: "",
                isApplied: true
            )

        #expect(projection.title == "Classic White")
        #expect(projection.subtitle == "途途 · 生日")
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
                activeConfigurationMessage: "有未保存修改",
                isApplied: false
            )

        #expect(projection.title == "记忆预设")
        #expect(projection.subtitle == "当前配置")
        #expect(projection.detail == "当前区域组合")
        #expect(projection.statusLabel == "有未保存修改")
        #expect(!projection.emphasizesAppliedState)
    }
}
#endif
