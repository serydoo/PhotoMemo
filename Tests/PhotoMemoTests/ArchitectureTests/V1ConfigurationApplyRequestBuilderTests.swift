#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration apply request builder")
struct V1ConfigurationApplyRequestBuilderTests {

    @Test("build request uses aligned subject resolved library preset drafts and output selection")
    func buildRequestUsesAlignedSubjectResolvedLibraryPresetDraftsAndOutputSelection() {
        let baseState = ConfigurationCenterState.mock
        let birthdayDate = Date(timeIntervalSince1970: 1_735_689_600)
        let albums = [
            PhotoAlbumOption(
                id: "album-1",
                title: "成长记录",
                localIdentifier: "album-1"
            )
        ]

        let request = V1ConfigurationApplyRequestBuilder.buildRequest(
            from: V1ConfigurationApplyBuildInput(
                selectedSubject: baseState.selectedSubject,
                subjects: baseState.subjects,
                selectedSubjectID: baseState.selectedSubjectID,
                shouldSaveSubjectLibrary: true,
                presetTitle: "V1.0 默认配置",
                templateTextsByRegion: [
                    .slotA: "记录者内容",
                    .slotB: "时间线内容",
                    .slotC: "拍摄参数内容",
                    .slotD: "智能模块内容"
                ],
                locationDisplayConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: "cityDistrict"
                    ),
                badge: .family,
                usesCustomMemoryWriteText: true,
                customMemoryWriteText: "第一次一起看海",
                birthdayDate: birthdayDate,
                outputTarget: .existingAlbum,
                availableAlbums: albums,
                selectedExistingAlbumIdentifier: "album-1",
                newAlbumName: "成长记录"
            )
        )

        let expectedSubject =
            V1ConfigurationApplyRequestBuilder
            .alignedSelectedSubject(
                from: baseState.selectedSubject,
                birthdayDate: birthdayDate
            )

        #expect(request.subject == expectedSubject)
        #expect(
            request.subjects
            == V1SubjectLibraryResolver.subjectsForSaving(
                selectedSubject: expectedSubject,
                subjects: baseState.subjects
            )
        )
        #expect(request.selectedSubjectID == expectedSubject?.id)
        #expect(request.template.name == "V1.0 默认配置")
        #expect(request.template.leftTopArea.items.first?.value == "记录者内容")
        #expect(request.template.leftBottomArea.items.first?.value == "时间线内容")
        #expect(request.template.rightTopArea.items.first?.value == "拍摄参数内容")
        #expect(request.template.rightBottomArea.items.first?.value == "智能模块内容")
        #expect(
            request.locationDisplayConfiguration
            == LocationDisplayInspectorPresenter
                .configuration(
                    for: "cityDistrict"
                )
        )
        #expect(request.badge == .family)
        #expect(request.outputTarget == .existingAlbum)
        #expect(request.availableAlbums == albums)
        #expect(request.selectedExistingAlbumIdentifier == "album-1")
        #expect(request.newAlbumName == "成长记录")
        #expect(
            request.timeAnchorTitle
            == V1ResolvedMemoryWriteTextPresenter
            .legacyBirthdayAnchorTitle(
                subject: expectedSubject
            )
        )
        #expect(request.timeAnchorDate == birthdayDate)
    }

    @Test("build request clears photo description override when custom write text is off and falls back to stored selection when subject is nil")
    func buildRequestClearsPhotoDescriptionOverrideWhenCustomWriteTextIsOffAndFallsBackToStoredSelectionWhenSubjectIsNil() {
        let baseState = ConfigurationCenterState.mock

        let request = V1ConfigurationApplyRequestBuilder.buildRequest(
            from: V1ConfigurationApplyBuildInput(
                selectedSubject: nil,
                subjects: baseState.subjects,
                selectedSubjectID: baseState.selectedSubjectID,
                shouldSaveSubjectLibrary: false,
                presetTitle: "V1.0",
                templateTextsByRegion: [
                    .slotA: "A"
                ],
                locationDisplayConfiguration: nil,
                badge: nil,
                usesCustomMemoryWriteText: false,
                customMemoryWriteText: "不会被保存",
                birthdayDate: Date(timeIntervalSince1970: 1_704_067_200),
                outputTarget: .automatic,
                availableAlbums: [],
                selectedExistingAlbumIdentifier: "",
                newAlbumName: PhotoMemoAlbumSelection.defaultAlbumTitle
            )
        )

        #expect(request.subject == nil)
        #expect(request.subjects == baseState.subjects)
        #expect(
            request.selectedSubjectID
            == baseState.selectedSubjectID
        )
        #expect(request.shouldWritePhotoDescription == false)
        #expect(request.photoDescriptionOverride.isEmpty)
    }
}
#endif
