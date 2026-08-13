#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration apply request builder")
struct V1ConfigurationApplyRequestBuilderTests {

    @Test("subject avatar logo does not reuse its asset as a custom logo")
    func subjectAvatarLogoDoesNotReuseAssetAsCustomLogo() throws {
        let state = ConfigurationCenterState.mock
        var subject = try #require(state.selectedSubject)
        let configurationID = UUID()
        let relativePath = "SubjectAssets/avatar-badge.png"
        let reference = try PortableAssetReference(
            relativePath: relativePath
        )
        subject.identity.avatarBadgeImagePath = relativePath

        let existing = MemoryConfigurationRecord(
            id: configurationID,
            title: "对象头像",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(mode: .appleMini, badge: nil)
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [existing],
                    assetManifest: .init(
                        entries: [
                            .init(
                                role: .subjectAvatarBadge,
                                reference: reference
                            )
                        ]
                    )
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configurationID
        )
        let runtimePath = PhotoMemoSharedContainer
            .baseDirectoryURL
            .appendingPathComponent(relativePath)
            .standardizedFileURL
            .path
        let draft = V1ConfigurationAggregateDraft(
            title: "对象头像",
            regionDrafts: [:],
            regionTemplateIDs: [:],
            locationConfiguration: nil,
            logoMode: .subjectAvatar,
            badge: Badge(
                name: OptimizedSubjectAvatarAsset
                    .subjectAvatarBadgeName,
                type: .customUpload,
                imagePath: runtimePath,
                isSystemDefault: false
            ),
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "",
            outputTarget: .automatic,
            selectedAlbumIdentifier: "",
            albumTitle: "",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .staticImageOnly,
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 200)
        )

        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: draft
        )

        #expect(candidate.aggregate.validationResult == .valid)
        #expect(
            candidate.configuration.presentation.logo.badge?
                .assetReference == nil
        )
    }

    @Test("subject-avatar mode without an available avatar falls back to Apple")
    func subjectAvatarWithoutAvailableAssetFallsBackToApple() throws {
        let state = ConfigurationCenterState.mock
        var subject = try #require(state.selectedSubject)
        subject.identity.avatarImagePath = nil
        subject.identity.avatarBadgeImagePath = nil
        let configurationID = UUID()
        let existing = MemoryConfigurationRecord(
            id: configurationID,
            title: "无头像对象",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
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
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [existing],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configurationID
        )
        let draft = V1ConfigurationAggregateDraft(
            title: "无头像对象",
            regionDrafts: [:],
            regionTemplateIDs: [:],
            locationConfiguration: nil,
            logoMode: .subjectAvatar,
            badge: Badge(
                name: OptimizedSubjectAvatarAsset.subjectAvatarBadgeName,
                type: .customUpload,
                imagePath: nil,
                isSystemDefault: false
            ),
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "",
            outputTarget: .automatic,
            selectedAlbumIdentifier: "",
            albumTitle: "",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .staticImageOnly,
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 200)
        )

        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: draft
        )

        #expect(candidate.configuration.presentation.logo.mode == .appleMini)
        #expect(candidate.configuration.presentation.logo.badge == nil)
        #expect(candidate.aggregate.validationResult == .valid)
    }

    @Test("logo mode switches keep subject and configuration asset ownership separate")
    func logoModeSwitchesKeepAssetOwnershipSeparate() throws {
        let state = ConfigurationCenterState.mock
        var subject = try #require(state.selectedSubject)
        let configurationID = UUID()
        let avatarPath = "SubjectAssets/avatar-badge.png"
        let customLogoPath = "Assets/customLogo/custom-logo.png"
        subject.identity.avatarBadgeImagePath = avatarPath

        let avatarReference = try PortableAssetReference(
            relativePath: avatarPath
        )
        let customLogoReference = try PortableAssetReference(
            relativePath: customLogoPath
        )
        let existing = MemoryConfigurationRecord(
            id: configurationID,
            title: "Logo 切换",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(
                    mode: .customUpload,
                    badge: .init(
                        id: UUID(),
                        name: "自选标识",
                        type: .customUpload,
                        assetReference: customLogoReference
                    )
                )
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 4,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [existing],
                    assetManifest: .init(
                        entries: [
                            .init(
                                role: .subjectAvatarBadge,
                                reference: avatarReference
                            ),
                            .init(
                                role: .customLogo,
                                reference: customLogoReference
                            )
                        ]
                    )
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configurationID
        )

        let avatarDraft = V1ConfigurationAggregateDraft(
            title: "头像 Logo",
            regionDrafts: [:],
            regionTemplateIDs: [:],
            locationConfiguration: nil,
            logoMode: .subjectAvatar,
            badge: Badge(
                name: OptimizedSubjectAvatarAsset.subjectAvatarBadgeName,
                type: .customUpload,
                imagePath: PhotoMemoSharedContainer
                    .baseDirectoryURL
                    .appendingPathComponent(avatarPath)
                    .path,
                isSystemDefault: false
            ),
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "",
            outputTarget: .automatic,
            selectedAlbumIdentifier: "",
            albumTitle: "",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .staticImageOnly,
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 200)
        )
        let avatarCandidate = try V1ConfigurationAggregateCandidateBuilder
            .build(from: aggregate, draft: avatarDraft)

        #expect(avatarCandidate.aggregate.validationResult == .valid)
        #expect(avatarCandidate.configuration.presentation.logo.badge == nil)
        #expect(
            avatarCandidate.aggregate.subjects[0].assetManifest.entries
                .contains {
                    $0.role == .subjectAvatarBadge
                    && $0.reference == avatarReference
                }
        )
        #expect(
            !avatarCandidate.aggregate.subjects[0].assetManifest.entries
                .contains {
                    $0.role == .customLogo
                    && $0.reference == customLogoReference
                }
        )

        let customDraft = V1ConfigurationAggregateDraft(
            title: "自选 Logo",
            regionDrafts: [:],
            regionTemplateIDs: [:],
            locationConfiguration: nil,
            logoMode: .customUpload,
            badge: Badge(
                name: "自选标识",
                type: .customUpload,
                imagePath: PhotoMemoSharedContainer
                    .baseDirectoryURL
                    .appendingPathComponent(customLogoPath)
                    .path,
                isSystemDefault: false
            ),
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "",
            outputTarget: .automatic,
            selectedAlbumIdentifier: "",
            albumTitle: "",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .staticImageOnly,
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 300)
        )
        let customCandidate = try V1ConfigurationAggregateCandidateBuilder
            .build(
                from: avatarCandidate.aggregate,
                draft: customDraft
            )

        #expect(customCandidate.aggregate.validationResult == .valid)
        #expect(
            customCandidate.configuration.presentation.logo.badge?
                .assetReference == customLogoReference
        )
        #expect(
            customCandidate.aggregate.subjects[0].assetManifest.entries
                .contains {
                    $0.role == .customLogo
                    && $0.reference == customLogoReference
                }
        )

        let appleDraft = V1ConfigurationAggregateDraft(
            title: "Apple Logo",
            regionDrafts: [:],
            regionTemplateIDs: [:],
            locationConfiguration: nil,
            logoMode: .appleMini,
            badge: .appleClassic,
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "",
            outputTarget: .automatic,
            selectedAlbumIdentifier: "",
            albumTitle: "",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .staticImageOnly,
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 400)
        )
        let appleCandidate = try V1ConfigurationAggregateCandidateBuilder
            .build(from: customCandidate.aggregate, draft: appleDraft)

        #expect(appleCandidate.aggregate.validationResult == .valid)
        #expect(
            appleCandidate.configuration.presentation.logo.badge?
                .assetReference == nil
        )
        #expect(
            !appleCandidate.aggregate.subjects[0].assetManifest.entries
                .contains { $0.role == .customLogo }
        )
    }

    @Test("subject-avatar projection does not expose a stale descriptor as a custom logo")
    func subjectAvatarProjectionDropsStaleConfigurationDescriptor() throws {
        var subject = try #require(ConfigurationCenterState.mock.selectedSubject)
        subject.identity.avatarBadgeImagePath = "SubjectAssets/avatar-badge.png"
        let staleReference = try PortableAssetReference(
            relativePath: "SubjectAssets/avatar-badge.png"
        )
        let configuration = MemoryConfigurationRecord(
            id: UUID(),
            title: "旧头像配置",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(usesCustomText: false, customText: "")
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(
                    mode: .subjectAvatar,
                    badge: .init(
                        id: UUID(),
                        name: "对象头像",
                        type: .customUpload,
                        assetReference: staleReference
                    )
                )
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )

        let projection = V1ConfigurationDraftProjection(
            configuration: configuration
        )

        #expect(projection.logoMode == .subjectAvatar)
        #expect(projection.badge == nil)
    }

    @Test("custom logo survives aggregate save and returns as a runtime path")
    func customLogoSurvivesSaveAndReload() throws {
        let state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        let configurationID = UUID()
        let existing = MemoryConfigurationRecord(
            id: configurationID,
            title: "自选标识",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
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
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [existing],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configurationID
        )
        let relativePath = "LogoAssets/custom-logo.png"
        let runtimePath = PhotoMemoSharedContainer.baseDirectoryURL
            .appendingPathComponent(relativePath)
            .standardizedFileURL
            .path
        let draft = V1ConfigurationAggregateDraft(
            title: "自选标识",
            regionDrafts: [:],
            regionTemplateIDs: [:],
            locationConfiguration: nil,
            logoMode: .customUpload,
            badge: Badge(
                name: "自选标识",
                type: .customUpload,
                imagePath: runtimePath
            ),
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "",
            outputTarget: .automatic,
            selectedAlbumIdentifier: "",
            albumTitle: "",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .staticImageOnly,
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 200)
        )

        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: draft
        )
        #expect(
            candidate.configuration.presentation.logo.badge?
                .assetReference?.relativePath == relativePath
        )
        #expect(candidate.aggregate.validationResult == .valid)
        #expect(
            candidate.aggregate.subjects.first?.assetManifest.entries
                .contains(where: {
                    $0.role == .customLogo
                    && $0.reference.relativePath == relativePath
                }) == true
        )

        let projection = V1ConfigurationDraftProjection(
            configuration: candidate.configuration
        )
        #expect(projection.badge?.imagePath == runtimePath)
    }

    @Test("custom-logo mode without a managed asset falls back to Apple before persistence")
    func customLogoWithoutManagedAssetFallsBackToApple() throws {
        let state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        let configurationID = UUID()
        let existing = MemoryConfigurationRecord(
            id: configurationID,
            title: "未选择自选标识",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
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
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [existing],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configurationID
        )
        let draft = V1ConfigurationAggregateDraft(
            title: "未选择自选标识",
            regionDrafts: [:],
            regionTemplateIDs: [:],
            locationConfiguration: nil,
            logoMode: .customUpload,
            badge: Badge.none,
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "",
            outputTarget: .automatic,
            selectedAlbumIdentifier: "",
            albumTitle: "",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .staticImageOnly,
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 200)
        )

        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: draft
        )

        #expect(candidate.configuration.presentation.logo.mode == .appleMini)
        #expect(candidate.configuration.presentation.logo.badge == nil)
        #expect(
            !candidate.aggregate.subjects[0].assetManifest.entries.contains {
                $0.role == .customLogo
            }
        )
        #expect(candidate.aggregate.validationResult == .valid)
    }

    @Test("multi-item module drafts survive normalization and reload")
    func multiItemModuleDraftsSurviveNormalizationAndReload() throws {
        let state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        let configurationID = UUID()
        let existing = MemoryConfigurationRecord(
            id: configurationID,
            title: "模块配置",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
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
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [existing],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configurationID
        )
        let locationConfiguration = LocationDisplayInspectorPresenter
            .configuration(for: "cityDistrict")
        let draft = V1ConfigurationAggregateDraft(
            title: "模块配置",
            regionDrafts: [
                .slotA: V1EditorDraft(items: [
                    .text("他爹手持"),
                    .token(
                        IOSInsertableModule.cameraModel.title,
                        value: "iPhone 17 Pro Max",
                        templateValue: IOSInsertableModule.cameraModel.rendererToken,
                        systemImage: IOSInsertableModule.cameraModel.systemImage
                    )
                ]),
                .slotB: V1EditorDraft(items: [
                    .text("记录于"),
                    .token(
                        IOSInsertableModule.captureDate.title,
                        value: "2026.06.01",
                        templateValue: IOSInsertableModule.captureDate.rendererToken,
                        systemImage: IOSInsertableModule.captureDate.systemImage
                    )
                ]),
                .slotC: V1EditorDraft(items: [
                    .token(
                        IOSInsertableModule.location.title,
                        value: "示例市 · 示例区",
                        templateValue: IOSInsertableModule.location.rendererToken,
                        systemImage: IOSInsertableModule.location.systemImage
                    )
                ]),
                .slotD: V1EditorDraft(items: [
                    .token(
                        IOSInsertableModule.smartTime.title,
                        value: "今天小宝1岁1个月15天",
                        templateValue: IOSInsertableModule.smartTime.rendererToken,
                        systemImage: IOSInsertableModule.smartTime.systemImage
                    ),
                    .text("啦！")
                ])
            ],
            regionTemplateIDs: [:],
            locationConfiguration: locationConfiguration,
            logoMode: .appleMini,
            badge: .appleClassic,
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "",
            outputTarget: .automatic,
            selectedAlbumIdentifier: "",
            albumTitle: "",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .staticImageOnly,
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 200)
        )

        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: draft
        )
        var reloadedConfiguration = candidate.configuration
        reloadedConfiguration.editor.template =
            candidate.configuration.editor.template.normalizedForEditing
        #expect(
            reloadedConfiguration.editor.template.leftTopArea.items.map(\.value)
            == ["他爹手持", IOSInsertableModule.cameraModel.rendererToken]
        )
        #expect(
            reloadedConfiguration.editor.template.leftBottomArea.items.map(\.value)
            == ["记录于", IOSInsertableModule.captureDate.rendererToken]
        )
        #expect(
            reloadedConfiguration.editor.template.rightTopArea.items.map(\.value)
            == [IOSInsertableModule.location.rendererToken]
        )
        #expect(
            reloadedConfiguration.editor.template.rightBottomArea.items.map(\.value)
            == [IOSInsertableModule.smartTime.rendererToken, "啦！"]
        )
        let projection = V1ConfigurationDraftProjection(
            configuration: reloadedConfiguration
        )

        #expect(projection.regionDrafts[.slotA]?.items.count == 3)
        #expect(projection.regionDrafts[.slotB]?.items.count == 3)
        #expect(projection.regionDrafts[.slotC]?.items.first?.title == IOSInsertableModule.location.title)
        #expect(projection.regionDrafts[.slotC]?.items.first?.systemImage == IOSInsertableModule.location.systemImage)
        #expect(projection.regionDrafts[.slotD]?.items.prefix(2).map(\.templateValue) == [
            IOSInsertableModule.smartTime.rendererToken,
            "啦！"
        ])
    }

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
        let customLogoPath = PhotoMemoSharedContainer.baseDirectoryURL
            .appendingPathComponent("LogoAssets/complete-draft.png")
            .standardizedFileURL.path
        let customLogo = Badge(
            id: Badge.travel.id,
            name: "自选标识",
            type: .customUpload,
            imagePath: customLogoPath,
            isSystemDefault: false
        )
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
            badge: customLogo,
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
        #expect(result.configuration.presentation.logo.badge?.id == customLogo.id)
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
        #expect(request.badge == nil)
        #expect(request.locationDisplayConfiguration == candidate.presentation.locationConfiguration)
        #expect(request.shouldWritePhotoDescription == false)
        #expect(request.photoDescriptionOverride == "Photos 独立说明")
        #expect(request.selectedExistingAlbumIdentifier == "album-complete")
        #expect(request.mediaOutputMode == .originalFormat)
    }

    @Test("subject-avatar candidate resolves the selected subject instead of stale custom-logo input")
    func subjectAvatarCandidateDoesNotFallBackToStaleInputBadge() throws {
        let state = ConfigurationCenterState.mock
        var subject = try #require(state.selectedSubject)
        let avatarPath = "SubjectAssets/current-avatar-badge.png"
        subject.identity.avatarBadgeImagePath = avatarPath
        let candidate = Self.makeLogoCandidate(
            mode: .subjectAvatar,
            badge: nil
        )
        let staleBadge = Badge(
            name: "上一个配置的自选标识",
            type: .customUpload,
            imagePath: "/tmp/stale-logo.png"
        )

        let request = V1ConfigurationApplyRequestBuilder.buildRequest(
            from: Self.makeLogoBuildInput(
                subject: subject,
                candidate: candidate,
                badge: staleBadge
            )
        )

        #expect(request.badge?.name == "对象头像")
        #expect(
            request.badge?.imagePath
            == PhotoMemoSharedContainer.baseDirectoryURL
                .appendingPathComponent(avatarPath)
                .standardizedFileURL.path
        )
        #expect(request.badge?.imagePath != staleBadge.imagePath)
    }

    @Test("Apple-logo candidate ignores stale descriptors and stale custom-logo input")
    func appleCandidateDoesNotReuseStaleBadgeState() throws {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let candidate = Self.makeLogoCandidate(
            mode: .appleMini,
            badge: .family
        )
        let staleBadge = Badge(
            name: "上一个配置的自选标识",
            type: .customUpload,
            imagePath: "/tmp/stale-logo.png"
        )

        let request = V1ConfigurationApplyRequestBuilder.buildRequest(
            from: Self.makeLogoBuildInput(
                subject: subject,
                candidate: candidate,
                badge: staleBadge
            )
        )

        #expect(request.badge == nil)
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
            title: "小宝生日",
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
        selectedSubject.identity.displayName = "小宝"
        selectedSubject.identity.shortName = "小宝"

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
            == "小宝"
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

    private static func makeLogoCandidate(
        mode: V1LogoMode,
        badge: Badge?
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            title: "Logo candidate",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: nil,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(
                    mode: mode,
                    badge: badge.map {
                        .init(
                            id: $0.id,
                            name: $0.name,
                            type: $0.type,
                            imageName: $0.imageName,
                            systemSymbol: $0.systemSymbol,
                            isSystemDefault: $0.isSystemDefault
                        )
                    }
                )
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
    }

    private static func makeLogoBuildInput(
        subject: MemorySubject,
        candidate: MemoryConfigurationRecord,
        badge: Badge?
    ) -> V1ConfigurationApplyBuildInput {
        V1ConfigurationApplyBuildInput(
            selectedSubject: subject,
            subjects: [subject],
            selectedSubjectID: subject.id,
            shouldSaveSubjectLibrary: true,
            memoryPresets: [],
            selectedMemoryPresetID: candidate.id,
            candidateConfiguration: candidate,
            presetTitle: "Logo candidate",
            templateTextsByRegion: [:],
            locationDisplayConfiguration: nil,
            badge: badge,
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            birthdayDate: subject.referenceDate,
            outputTarget: .automatic,
            mediaOutputMode: .staticImage,
            availableAlbums: [],
            selectedExistingAlbumIdentifier: "",
            newAlbumName: ""
        )
    }
}
#endif
