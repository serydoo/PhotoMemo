#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration apply request builder")
struct V1ConfigurationApplyRequestBuilderTests {

    @Test("aggregate candidate replaces active record from the complete current draft")
    func aggregateCandidateReplacesActiveRecordFromCompleteDraft() throws {
        let state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        let existing = MemoryConfigurationRecord(
            id: UUID(uuidString: "A1A1A1A1-A1A1-A1A1-A1A1-A1A1A1A1A1A1")!,
            title: "Before",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 300),
            selectedTimeAnchorID: nil,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [.slotA: "before.recorder"],
                memoryCopy: .init(usesCustomText: false, customText: "")
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(mode: .appleMini, badge: nil)
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(isEnabled: false, overrideText: ""),
                album: .automatic
            )
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 7,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [existing],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: existing.id
        )
        let anchorID = try #require(subject.primaryTimeAnchor?.id)
        let input = V1ConfigurationAggregateDraft(
            title: "After",
            regionDrafts: [
                .slotA: V1EditorDraft(items: [
                    .text("Recorder "),
                    V1ContentItem(
                        id: UUID(),
                        kind: .token,
                        title: "Date",
                        value: "2026.07.11",
                        savedValue: "{{capture_date}}",
                        systemImage: "calendar"
                    )
                ]),
                .slotD: V1EditorDraft(items: [.text("Memory")])
            ],
            regionTemplateIDs: [.slotA: "after.recorder"],
            locationConfiguration: .init(
                token: "{{location}}",
                options: ["displayStyle": "cityDistrict"]
            ),
            logoMode: .customUpload,
            badge: .travel,
            usesCustomMemoryWriteText: true,
            customMemoryWriteText: "Memory Copy",
            shouldWritePhotosDescription: true,
            photosDescriptionOverride: "Photos Description",
            outputTarget: .existingAlbum,
            selectedAlbumIdentifier: "album-after",
            albumTitle: "After Album",
            mediaOutputMode: .originalFormat,
            livePhotoPolicy: .preserveMotion,
            selectedTimeAnchorID: anchorID,
            savedAt: Date(timeIntervalSince1970: 800)
        )

        let result = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: input
        )

        #expect(result.configuration.id == existing.id)
        #expect(result.configuration.revision == 4)
        #expect(result.configuration.title == "After")
        #expect(result.configuration.editor.template.leftTopArea.items.count == 2)
        #expect(result.configuration.editor.template.leftTopArea.items[1].value == "{{capture_date}}")
        #expect(result.configuration.editor.regionTemplateIDs[.slotA] == "after.recorder")
        #expect(result.configuration.presentation.locationConfiguration == input.locationConfiguration)
        #expect(result.configuration.presentation.logo.mode == .customUpload)
        #expect(result.configuration.presentation.logo.badge?.id == Badge.travel.id)
        #expect(result.configuration.editor.memoryCopy.customText == "Memory Copy")
        #expect(result.configuration.output.photosDescriptionPolicy.overrideText == "Photos Description")
        #expect(result.configuration.output.album.identifier == "album-after")
        #expect(result.configuration.output.mediaMode == .originalFormat)
        #expect(result.configuration.output.livePhotoPolicy == .preserveMotion)
        #expect(result.configuration.selectedTimeAnchorID == anchorID)
        #expect(result.aggregate.activeConfigurationID == existing.id)
        #expect(result.aggregate.revision == aggregate.revision)
    }

    @Test("build request uses complete candidate without conflating memory copy and Photos description")
    func buildRequestUsesCompleteCandidateWithoutConflatingCopyAndDescription() throws {
        let state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        var template = Template.classicWhite
        template.name = "完整配置"
        template.leftTopArea.items = [
            TemplateItem(
                type: .text,
                name: "第一项",
                value: "保留一",
                isEnabled: true
            ),
            TemplateItem(
                type: .variable,
                name: "第二项",
                value: "保留二",
                isEnabled: false
            )
        ]
        let candidate = MemoryConfigurationRecord(
            title: "完整配置",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 400),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: template,
                regionTemplateIDs: [.slotA: "complete.recorder"],
                memoryCopy: .init(
                    usesCustomText: true,
                    customText: "Memory Card 文案"
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: .init(
                    token: "{{location}}",
                    options: ["displayStyle": "cityDistrict"]
                ),
                logo: .init(
                    mode: .subjectAvatar,
                    badge: .init(
                        id: Badge.travel.id,
                        name: Badge.travel.name,
                        type: Badge.travel.type,
                        imageName: Badge.travel.imageName,
                        systemSymbol: Badge.travel.systemSymbol,
                        isSystemDefault: Badge.travel.isSystemDefault
                    )
                )
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: "Photos 独立说明"
                ),
                album: .init(
                    destination: .existingAlbum,
                    identifier: "album-complete",
                    title: "完整相册"
                )
            )
        )

        let request = V1ConfigurationApplyRequestBuilder.buildRequest(
            from: V1ConfigurationApplyBuildInput(
                selectedSubject: subject,
                subjects: state.subjects,
                selectedSubjectID: subject.id,
                shouldSaveSubjectLibrary: true,
                memoryPresets: state.memoryPresets,
                selectedMemoryPresetID: candidate.id,
                candidateConfiguration: candidate,
                presetTitle: "不应使用",
                templateTextsByRegion: [.slotA: "不应重建"],
                locationDisplayConfiguration: nil,
                badge: nil,
                usesCustomMemoryWriteText: false,
                customMemoryWriteText: "不应写入 Photos",
                birthdayDate: subject.referenceDate,
                outputTarget: .automatic,
                mediaOutputMode: .staticImage,
                availableAlbums: [],
                selectedExistingAlbumIdentifier: "",
                newAlbumName: ""
            )
        )

        #expect(request.template == template)
        #expect(request.template.leftTopArea.items.count == 2)
        #expect(request.badge?.id == Badge.travel.id)
        #expect(request.locationDisplayConfiguration == candidate.presentation.locationConfiguration)
        #expect(request.shouldWritePhotoDescription == false)
        #expect(request.photoDescriptionOverride == "Photos 独立说明")
        #expect(request.selectedExistingAlbumIdentifier == "album-complete")
        #expect(request.mediaOutputMode == .originalFormat)
    }

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
        let resolvedAnchorDate =
            baseState
            .selectedSubject?
            .primaryTimeAnchor?
            .date
            ?? birthdayDate

        let request = V1ConfigurationApplyRequestBuilder.buildRequest(
            from: V1ConfigurationApplyBuildInput(
                selectedSubject: baseState.selectedSubject,
                subjects: baseState.subjects,
                selectedSubjectID: baseState.selectedSubjectID,
                shouldSaveSubjectLibrary: true,
                memoryPresets: baseState.memoryPresets,
                selectedMemoryPresetID:
                    baseState.selectedMemoryPresetID,
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
                mediaOutputMode: .originalFormat,
                availableAlbums: albums,
                selectedExistingAlbumIdentifier: "album-1",
                newAlbumName: "成长记录"
            )
        )

        let expectedSubject =
            V1ConfigurationApplyRequestBuilder
            .alignedSelectedSubject(
                from: baseState.selectedSubject,
                birthdayDate: resolvedAnchorDate
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
        #expect(request.memoryPresets == baseState.memoryPresets)
        #expect(
            request.selectedMemoryPresetID
            == baseState.selectedMemoryPresetID
        )
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
        #expect(request.timeAnchorDate == resolvedAnchorDate)
    }

    @Test("build request preserves preselected location display without inserting a location module")
    func buildRequestPreservesPreselectedLocationDisplayWithoutLocationModule() {
        let baseState = ConfigurationCenterState.mock
        let locationConfiguration =
            LocationDisplayInspectorPresenter
            .configuration(for: "cityDistrict")

        let request = V1ConfigurationApplyRequestBuilder.buildRequest(
            from: V1ConfigurationApplyBuildInput(
                selectedSubject: baseState.selectedSubject,
                subjects: baseState.subjects,
                selectedSubjectID: baseState.selectedSubjectID,
                shouldSaveSubjectLibrary: false,
                memoryPresets: baseState.memoryPresets,
                selectedMemoryPresetID:
                    baseState.selectedMemoryPresetID,
                presetTitle: "位置预选配置",
                templateTextsByRegion: [
                    .slotA: "记录者内容",
                    .slotB: "时间线内容",
                    .slotC: "",
                    .slotD: "智能模块内容"
                ],
                locationDisplayConfiguration:
                    locationConfiguration,
                badge: nil,
                usesCustomMemoryWriteText: false,
                customMemoryWriteText: "",
                birthdayDate:
                    Date(timeIntervalSince1970: 1_735_689_600),
                outputTarget: .applePhotos,
                mediaOutputMode: .staticImage,
                availableAlbums: [],
                selectedExistingAlbumIdentifier: "",
                newAlbumName: ""
            )
        )

        #expect(
            request.locationDisplayConfiguration
            == locationConfiguration
        )
        #expect(
            request.template.rightTopArea.items.first?.value
            == ""
        )
    }

    @Test("build request preserves the selected subject anchor date over stale transient birthday state")
    func buildRequestPreservesSelectedSubjectAnchorDateOverStaleTransientBirthdayState() throws {
        var subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let anchorDate =
            try #require(
                Calendar.current.date(
                    from:
                        DateComponents(
                            year: 2025,
                            month: 5,
                            day: 26
                        )
                )
            )
        let staleBirthdayDate =
            try #require(
                Calendar.current.date(
                    from:
                        DateComponents(
                            year: 2024,
                            month: 1,
                            day: 1
                        )
                )
            )
        let anchor = MemorySubject.TimeAnchor(
            title: "途途生日",
            date: anchorDate,
            note: "对象页锚点",
            anchorType: .birthday,
            expressionStyle: .birthdayNatural
        )

        subject.timeAnchors = [anchor]
        subject.activeTimeAnchorID = anchor.id
        subject.referenceDate = anchorDate
        subject.behavior.primaryAnchor = anchor.title

        let request =
            V1ConfigurationApplyRequestBuilder
            .buildRequest(
                from: V1ConfigurationApplyBuildInput(
                    selectedSubject: subject,
                    subjects: [subject],
                    selectedSubjectID: subject.id,
                    shouldSaveSubjectLibrary: true,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil,
                    presetTitle: "当前配置",
                    templateTextsByRegion: [
                        .slotD: "{{memory_summary}}啦！"
                    ],
                    locationDisplayConfiguration: nil,
                    badge: nil,
                    usesCustomMemoryWriteText: false,
                    customMemoryWriteText: "",
                    birthdayDate: staleBirthdayDate,
                    outputTarget: .automatic,
                    mediaOutputMode: .originalFormat,
                    availableAlbums: [],
                    selectedExistingAlbumIdentifier: "",
                    newAlbumName:
                        PhotoMemoAlbumSelection
                        .defaultAlbumTitle
                )
            )

        #expect(request.timeAnchorDate == anchorDate)
        #expect(request.subject?.primaryTimeAnchor?.date == anchorDate)
        #expect(request.subject?.referenceDate == anchorDate)
    }

    @Test("build request appends the selected subject when the library is stale")
    func buildRequestAppendsSelectedSubjectWhenLibraryIsStale() throws {
        var selectedSubject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        selectedSubject.identity.displayName = "途途"
        selectedSubject.identity.shortName = "途途"

        let staleSubject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "旧对象",
                        shortName: "家人"
                    ),
                relationship:
                    .init(
                        role: "家庭",
                        label: "家人"
                    ),
                referenceDate:
                    Date(timeIntervalSince1970: 1_704_067_200),
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .fixed,
                        memoryExpression:
                            MemoryExpression(
                                title: "旧表达",
                                blocks: []
                            )
                    ),
                decorations: []
            )

        let request =
            V1ConfigurationApplyRequestBuilder
            .buildRequest(
                from: V1ConfigurationApplyBuildInput(
                    selectedSubject: selectedSubject,
                    subjects: [staleSubject],
                    selectedSubjectID: selectedSubject.id,
                    shouldSaveSubjectLibrary: true,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil,
                    presetTitle: "当前配置",
                    templateTextsByRegion: [
                        .slotD: "{{memory_summary}}啦！"
                    ],
                    locationDisplayConfiguration: nil,
                    badge: nil,
                    usesCustomMemoryWriteText: false,
                    customMemoryWriteText: "",
                    birthdayDate:
                        selectedSubject
                        .primaryTimeAnchor?
                        .date
                        ?? Date(timeIntervalSince1970: 1_704_067_200),
                    outputTarget: .automatic,
                    mediaOutputMode: .originalFormat,
                    availableAlbums: [],
                    selectedExistingAlbumIdentifier: "",
                    newAlbumName:
                        PhotoMemoAlbumSelection
                        .defaultAlbumTitle
                )
            )

        #expect(
            request.subjects.contains {
                $0.id == selectedSubject.id
            }
        )
        #expect(
            request.subjects.first {
                $0.id == selectedSubject.id
            }?
            .resolvedExpressionSubjectText
            == "途途"
        )
    }

    @Test("build request keeps smart memory writing enabled by default and falls back to stored selection when subject is nil")
    func buildRequestKeepsSmartMemoryWritingEnabledByDefaultAndFallsBackToStoredSelectionWhenSubjectIsNil() {
        let baseState = ConfigurationCenterState.mock

        let request = V1ConfigurationApplyRequestBuilder.buildRequest(
            from: V1ConfigurationApplyBuildInput(
                selectedSubject: nil,
                subjects: baseState.subjects,
                selectedSubjectID: baseState.selectedSubjectID,
                shouldSaveSubjectLibrary: false,
                memoryPresets: baseState.memoryPresets,
                selectedMemoryPresetID:
                    baseState.selectedMemoryPresetID,
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
                mediaOutputMode: .originalFormat,
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
        #expect(request.shouldWritePhotoDescription == true)
        #expect(request.photoDescriptionOverride.isEmpty)
    }
}
#endif
