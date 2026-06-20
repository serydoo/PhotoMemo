import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemoShareWorkflowSummary")
struct PhotoMemoShareWorkflowSummaryTests {

    @Test("Uses the template name when available")
    func usesTemplateNameForConfigurationTitle() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()

        let snapshot =
            BatchConfigurationSnapshot(
                template: Template(
                    preset: .template1,
                    name: "宝宝成长卡",
                    leftTopArea: .leftTop,
                    leftBottomArea: .leftBottom,
                    rightTopArea: TemplateArea(
                        name: "Right Top",
                        items: [.cameraSummary]
                    ),
                    rightBottomArea: TemplateArea(
                        name: "Right Bottom",
                        items: [.anchorAgeSentence]
                    ),
                    badgeArea: .badge
                ),
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )

        let summary =
            builder.build(from: snapshot)

        #expect(summary.configurationTitle == "宝宝成长卡")
        #expect(summary.anchorTitle == "不使用时间点")
        #expect(summary.outputTitle == "自动存入 PhotoMemo")
    }

    @Test("Falls back to preset name when the template name is blank")
    func fallsBackToPresetNameWhenTemplateNameIsBlank() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()

        let snapshot =
            BatchConfigurationSnapshot(
                template: Template(
                    preset: .template1,
                    name: "   ",
                    leftTopArea: .leftTop,
                    leftBottomArea: .leftBottom,
                    rightTopArea: TemplateArea(
                        name: "Right Top",
                        items: [.cameraSummary]
                    ),
                    rightBottomArea: TemplateArea(
                        name: "Right Bottom",
                        items: [.anchorAgeSentence]
                    ),
                    badgeArea: .badge
                ),
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )

        let summary =
            builder.build(from: snapshot)

        #expect(summary.configurationTitle == "模板 1")
    }

    @Test("Formats countdown anchors and custom album output")
    func formatsCountdownAnchorsAndCustomAlbumOutput() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder {
                identifier in
                identifier == "custom-album-id"
                    ? "家庭相册"
                    : nil
            }

        let snapshot =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: Anchor(
                    type: .exam,
                    title: "高考",
                    date: Date(),
                    isCountdown: true
                ),
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: "custom-album-id"
            )

        let summary =
            builder.build(from: snapshot)

        #expect(summary.anchorTitle == "高考 · 倒计时")
        #expect(summary.outputTitle == "存入“家庭相册”")
    }

    @Test("Falls back to generic custom album wording when no album title is available")
    func fallsBackToGenericCustomAlbumWordingWhenAlbumTitleIsUnavailable() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()

        let snapshot =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: "custom-album-id"
            )

        let summary =
            builder.build(from: snapshot)

        #expect(summary.outputTitle == "按当前选定相册保存")
    }

    @Test("Uses system library wording for the system destination sentinel")
    func usesSystemLibraryWordingForSystemDestination() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()

        let snapshot =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier:
                    PhotoMemoAlbumSelection
                    .systemLibraryIdentifier
            )

        let summary =
            builder.build(from: snapshot)

        #expect(summary.outputTitle == "写入系统相册")
    }
}
