import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemoShareWorkflowSummary")
struct PhotoMemoShareWorkflowSummaryTests {

    @Test("Uses the template name when available")
    func usesTemplateNameForStyleTitle() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()

        let snapshot =
            BatchConfigurationSnapshot(
                template: Template(
                    preset: .classicWhite,
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

        #expect(summary.styleTitle == "宝宝成长卡")
        #expect(summary.memoryDateTitle == nil)
        #expect(summary.outputTitle == "时光记相册")
    }

    @Test("Falls back to preset name when the template name is blank")
    func fallsBackToPresetNameWhenTemplateNameIsBlank() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()

        let snapshot =
            BatchConfigurationSnapshot(
                template: Template(
                    preset: .classicWhite,
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

        #expect(
            summary.styleTitle
            == TemplatePreset.classicWhite.displayName
        )
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
                template: .classicWhite,
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

        #expect(summary.memoryDateTitle == "高考 · 倒计时")
        #expect(summary.outputTitle == "“家庭相册”相册")
    }

    @Test("Prefers frozen configuration anchor over legacy batch anchor")
    func prefersFrozenConfigurationAnchorOverLegacyBatchAnchor() throws {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()
        let anchorDate =
            Date(
                timeIntervalSince1970:
                    1_725_206_400
            )
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date: anchorDate
            )
        let frozenAnchor =
            MemoryAnchor(
                title: "冻结高考",
                date: anchorDate,
                anchorType: .exam
            )
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder
            .build(from: subject)
        frozenSnapshot.primaryAnchor =
            frozenAnchor
        let snapshot =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )

        let summary =
            builder.build(from: snapshot)

        #expect(summary.memoryDateTitle == "冻结高考 · 倒计时")
    }

    @Test("Treats frozen missing anchor as authoritative")
    func treatsFrozenMissingAnchorAsAuthoritative() throws {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()
        let anchorDate =
            Date(
                timeIntervalSince1970:
                    1_725_206_400
            )
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date: anchorDate
            )
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder
            .build(from: subject)
        frozenSnapshot.primaryAnchor = nil
        let snapshot =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )

        let summary =
            builder.build(from: snapshot)

        #expect(summary.memoryDateTitle == nil)
    }

    @Test("Falls back to generic custom album wording when no album title is available")
    func fallsBackToGenericCustomAlbumWordingWhenAlbumTitleIsUnavailable() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()

        let snapshot =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: "custom-album-id"
            )

        let summary =
            builder.build(from: snapshot)

        #expect(summary.outputTitle == "当前选定相册")
    }

    @Test("Uses system library wording for the system destination sentinel")
    func usesSystemLibraryWordingForSystemDestination() {

        let builder =
            PhotoMemoShareWorkflowSummaryBuilder()

        let snapshot =
            BatchConfigurationSnapshot(
                template: .classicWhite,
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

        #expect(summary.outputTitle == "系统相册")
    }
}
