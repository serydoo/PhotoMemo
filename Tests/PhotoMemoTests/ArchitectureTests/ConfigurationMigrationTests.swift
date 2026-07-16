#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration migration", .serialized)
struct ConfigurationMigrationTests {

    @MainActor
    @Test(
        "Legacy template presets migrate through saved configuration loading",
        arguments: [
            "template1",
            "template2",
            "template3",
            "immersWhite"
        ]
    )
    func legacyTemplatePresetsMigrateThroughSavedConfigurationLoading(
        rawValue: String
    ) throws {
        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.legacyPreset.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let expected =
            Template.classicWhite
            .renamed("Preserved Configuration")
        let encoded = try JSONEncoder().encode(expected)
        var object = try #require(
            JSONSerialization.jsonObject(
                with: encoded
            ) as? [String: Any]
        )
        object["preset"] = rawValue
        defaults.set(
            try JSONSerialization.data(
                withJSONObject: object
            ),
            forKey: "photomemo.selectedTemplate"
        )

        let result =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )
            .loadTemplateResult()

        switch result {
        case .success(let template):
            #expect(
                template
                == expected.normalizedForEditing
            )
        case .noValue:
            Issue.record(
                "Expected a migrated template, got no value"
            )
        case .decodingFailed(let failure):
            Issue.record(
                "Expected a migrated template, got \(failure)"
            )
        }
    }

    @MainActor
    @Test("SaveV1ConfigurationIntent persists template badge photo-description and editor-state through configuration seams")
    func saveV1ConfigurationIntentPersistsTemplateBadgePhotoDescriptionAndEditorState() async throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.save.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let template =
            Template.classicWhite
            .renamed("成长卡片")
        var subject =
            ConfigurationCenterState
            .mock
            .selectedSubject
        if let primaryAnchorIndex =
            subject?.timeAnchors.indices.first {
            let primaryAnchorID =
                subject?.timeAnchors[primaryAnchorIndex]
                .id
            subject?.activeTimeAnchorID =
                primaryAnchorID
            subject?.timeAnchors[primaryAnchorIndex]
                .anchorType = .birthday
            subject?.timeAnchors[primaryAnchorIndex]
                .expressionStyle =
                    .birthdayAgeToday
        }
        let request =
            V1ConfigurationSaveRequest(
                subject: subject,
                template: template,
                badge: .family,
                locationDisplayConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: "provinceCityDistrict"
                    ),
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "第一次一起看海",
                timeAnchor:
                    .init(
                        title: "示例昵称",
                        date: Date(
                            timeIntervalSince1970:
                                1_725_206_400
                        )
                    ),
                albumSelection:
                    .init(
                        identifier: "album-88",
                        title: "成长记录"
                    )
            )

        let result =
            await SaveV1ConfigurationIntent(
                request: request,
                coordinator: coordinator
            )
            .execute()

        let receipt =
            try Self.requireSuccess(
                result,
                failurePrefix:
                    "Expected configuration save to succeed"
            )
        let snapshot =
            try Self.requireSuccess(
                coordinator
                .loadDefaultBatchConfigurationSnapshot(),
                failurePrefix:
                    "Expected saved configuration snapshot to load"
            )
        let settings =
            SettingsService(defaults: defaults)
        let bootstrap =
            try Self.requireSuccess(
                await LoadV1ConfigurationBootstrapIntent(
                    coordinator: coordinator
                )
                .execute(),
                failurePrefix:
                    "Expected bootstrap state to load after subject save"
            )

        #expect(
            snapshot.template
            == template.normalizedForEditing
        )
        #expect(
            snapshot.locationDisplayConfiguration
            == LocationDisplayInspectorPresenter
                .configuration(
                    for: "provinceCityDistrict"
                )
        )
        #expect(snapshot.badge == .family)
        #expect(
            snapshot.anchor
            == receipt.anchor
        )
        #expect(
            snapshot.shouldWritePhotoDescription
            == true
        )
        #expect(
            snapshot.photoDescriptionOverride
            == "第一次一起看海"
        )
        #expect(
            snapshot.selectedAlbumIdentifier
            == "album-88"
        )
        #expect(
            snapshot.memorySubjectText
            == request.subject?
                .resolvedExpressionSubjectText
        )
        #expect(
            settings.selectedAlbumTitle
            == "成长记录"
        )
        #expect(
            settings.selectedAnchorIDString
            == receipt.anchor.id.uuidString
        )
        #expect(
            bootstrap.selectedSubject
            == request.subject
        )
        #expect(
            bootstrap.locationDisplayConfiguration
            == LocationDisplayInspectorPresenter
                .configuration(
                    for: "provinceCityDistrict"
                )
        )
        #expect(
            bootstrap.selectedSubject?
                .primaryTimeAnchor?
                .expressionStyle
            == .birthdayAgeToday
        )
        #expect(
            receipt.anchor.title
            == request.subject?
                .primaryTimeAnchor?
                .title
        )
        #expect(
            receipt.anchor.expressionStyle
            == .birthdayAgeToday
        )
    }

    @MainActor
    @Test("SaveV1ConfigurationIntent keeps automatic album output normalized and preserves a cleared photo-description state")
    func saveV1ConfigurationIntentKeepsAutomaticAlbumOutputNormalizedAndPreservesClearedPhotoDescriptionState() async throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.normalization.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let request =
            V1ConfigurationSaveRequest(
                template:
                    Template.classicWhite
                    .renamed("默认分享配置"),
                badge: Badge.none,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                timeAnchor:
                    .init(
                        title: "记忆对象",
                        date: Date(
                            timeIntervalSince1970:
                                1_704_067_200
                        )
                    ),
                albumSelection:
                    .init(
                        identifier:
                            PhotoMemoAlbumSelection
                            .automaticIdentifier,
                        title:
                            PhotoMemoAlbumSelection
                            .defaultAlbumTitle
                    )
            )

        let result =
            await SaveV1ConfigurationIntent(
                request: request,
                coordinator: coordinator
            )
            .execute()

        _ =
            try Self.requireSuccess(
                result,
                failurePrefix:
                    "Expected normalized configuration save to succeed"
            )
        let snapshot =
            try Self.requireSuccess(
                coordinator
                .loadDefaultBatchConfigurationSnapshot(),
                failurePrefix:
                    "Expected normalized configuration snapshot to load"
            )
        let settings =
            SettingsService(defaults: defaults)

        #expect(snapshot.badge == nil)
        #expect(
            snapshot.shouldWritePhotoDescription
            == false
        )
        #expect(
            snapshot.photoDescriptionOverride
            .isEmpty
        )
        #expect(
            snapshot.selectedAlbumIdentifier
            .isEmpty
        )
        #expect(
            settings.selectedAlbumIdentifier
            == PhotoMemoAlbumSelection
            .automaticIdentifier
        )
        #expect(
            settings.selectedAlbumTitle
            == PhotoMemoAlbumSelection
            .defaultAlbumTitle
        )
    }

    @MainActor
    @Test("SaveV1ConfigurationIntent preserves saved location display when a save request has no location update")
    func saveV1ConfigurationIntentPreservesSavedLocationDisplayWhenRequestHasNoLocationUpdate() async throws {
        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.preserveLocationDisplay.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let existingConfiguration =
            LocationDisplayInspectorPresenter
            .configuration(
                for: "cityDistrict"
            )
        SettingsService(defaults: defaults)
            .saveLocationDisplayConfiguration(
                existingConfiguration
            )

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let request =
            V1ConfigurationSaveRequest(
                template:
                    Template.classicWhite
                    .renamed("默认分享配置"),
                badge: Badge.none,
                locationDisplayConfiguration: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                timeAnchor:
                    .init(
                        title: "生日",
                        date:
                            Date(
                                timeIntervalSince1970:
                                    1_704_067_200
                            )
                    ),
                albumSelection:
                    .init(
                        identifier:
                            PhotoMemoAlbumSelection
                            .automaticIdentifier,
                        title:
                            PhotoMemoAlbumSelection
                            .defaultAlbumTitle
                    )
            )

        _ =
            try Self.requireSuccess(
                await SaveV1ConfigurationIntent(
                    request: request,
                    coordinator: coordinator
                )
                .execute(),
                failurePrefix:
                    "Expected configuration save without a location update to succeed"
            )

        let snapshot =
            try Self.requireSuccess(
                coordinator
                .loadDefaultBatchConfigurationSnapshot(),
                failurePrefix:
                    "Expected saved configuration snapshot to load"
            )
        let bootstrap =
            try Self.requireSuccess(
                await LoadV1ConfigurationBootstrapIntent(
                    coordinator: coordinator
                )
                .execute(),
                failurePrefix:
                    "Expected bootstrap state to load"
            )

        #expect(
            snapshot.locationDisplayConfiguration
            == existingConfiguration
        )
        #expect(
            bootstrap.locationDisplayConfiguration
            == existingConfiguration
        )
    }

    @MainActor
    @Test("ConfigurationCoordinator saveV1Configuration updates an existing birthday anchor in place and resets countdown semantics")
    func configurationCoordinatorSaveV1ConfigurationUpdatesExistingBirthdayAnchorInPlaceAndResetsCountdownSemantics() throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.anchor.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let settings =
            SettingsService(defaults: defaults)
        let originalBirthdayAnchor =
            Anchor(
                id: UUID(),
                type: .birthday,
                title: "旧称呼",
                date: Date(timeIntervalSince1970: 1_640_995_200),
                isCountdown: true
            )
        let unrelatedAnchor =
            Anchor(
                type: .custom,
                title: "旅行",
                date: Date(timeIntervalSince1970: 1_704_067_200)
            )

        settings.anchors = [
            originalBirthdayAnchor,
            unrelatedAnchor
        ]
        settings.saveAnchors()
        settings.saveEditorState(
            selectedAnchorID:
                unrelatedAnchor.id
        )

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let updatedBirthday =
            Date(timeIntervalSince1970: 1_725_206_400)
        let request =
            V1ConfigurationSaveRequest(
                template: .classicWhite,
                badge: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                timeAnchor:
                    .init(
                        title: "示例昵称",
                        date: updatedBirthday
                    ),
                albumSelection:
                    .init(
                        identifier: "",
                        title: ""
                    )
            )

        let result =
            coordinator
            .saveV1Configuration(
                request
            )
        let receipt =
            try Self.requireSuccess(
                result,
                failurePrefix:
                    "Expected coordinator save to succeed"
            )

        let reloadedSettings =
            SettingsService(defaults: defaults)
        let persistedBirthdayAnchor =
            try #require(
                reloadedSettings.anchors.first {
                    $0.type == .birthday
                }
            )

        #expect(
            reloadedSettings.anchors.count
            == 2
        )
        #expect(
            receipt.anchor.id
            == originalBirthdayAnchor.id
        )
        #expect(
            persistedBirthdayAnchor.id
            == originalBirthdayAnchor.id
        )
        #expect(
            persistedBirthdayAnchor.title
            == "示例昵称"
        )
        #expect(
            persistedBirthdayAnchor.date
            == updatedBirthday
        )
        #expect(
            persistedBirthdayAnchor.isCountdown
            == false
        )
        #expect(
            reloadedSettings.selectedAnchorIDString
            == originalBirthdayAnchor.id.uuidString
        )
    }

    @MainActor
    @Test("ConfigurationCoordinator saveV1Configuration refreshes live runtime snapshots immediately")
    func configurationCoordinatorSaveV1ConfigurationRefreshesLiveRuntimeSnapshotsImmediately() throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.liveSnapshot.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        var syncedSnapshot:
            BatchConfigurationSnapshot?
        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults,
                applyLiveDefaultConfiguration: {
                    snapshot in
                    syncedSnapshot = snapshot
                }
            )
        let request =
            V1ConfigurationSaveRequest(
                template:
                    Template.classicWhite
                    .renamed("V1 默认配置"),
                badge: .family,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride:
                    "今天小宝18天",
                timeAnchor:
                    .init(
                        title: "生日",
                        date: Date(
                            timeIntervalSince1970:
                                1_725_206_400
                        )
                    ),
                albumSelection:
                    .init(
                        identifier: "album-live",
                        title: "实时同步"
                    )
            )

        _ =
            try Self.requireSuccess(
                coordinator
                .saveV1Configuration(
                    request
                ),
                failurePrefix:
                    "Expected live-snapshot save to succeed"
            )
        let snapshot =
            try #require(
                syncedSnapshot
            )

        #expect(
            snapshot.template
            == request.template
            .normalizedForEditing
        )
        #expect(snapshot.badge == .family)
        #expect(
            snapshot.photoDescriptionOverride
            == "今天小宝18天"
        )
        #expect(
            snapshot.selectedAlbumIdentifier
            == "album-live"
        )
        #expect(
            snapshot.anchor?.title
            == "生日"
        )
    }

    @MainActor
    @Test("LoadV1ConfigurationBootstrapIntent restores custom logo and existing-album bootstrap state through configuration seams")
    func loadV1ConfigurationBootstrapIntentRestoresCustomLogoAndExistingAlbumBootstrapState() async throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.bootstrapCustom.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let settings =
            SettingsService(defaults: defaults)
        let customBadge =
            Badge(
                name: "自选标识",
                type: .customUpload,
                imagePath: "/tmp/custom-logo.png"
            )
        settings.selectedBadge = customBadge
        settings.saveBadge()
        settings.saveEditorState(
            selectedAlbumIdentifier:
                "album-existing",
            selectedAlbumTitle:
                "成长记录"
        )

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let result =
            await LoadV1ConfigurationBootstrapIntent(
                coordinator: coordinator
            )
            .execute()
        let bootstrap =
            try Self.requireSuccess(
                result,
                failurePrefix:
                    "Expected bootstrap load to succeed"
            )

        #expect(
            bootstrap.logoMode
            == .customUpload
        )
        #expect(
            bootstrap.customLogoBadge
            == customBadge
        )
        #expect(
            bootstrap.outputTarget
            == .existingAlbum
        )
        #expect(
            bootstrap.selectedExistingAlbumIdentifier
            == "album-existing"
        )
        #expect(
            bootstrap.suggestedNewAlbumName
            == "成长记录"
        )
    }

    @MainActor
    @Test("SaveV1ConfigurationIntent persists subject-avatar logo into the default output snapshot")
    func saveV1ConfigurationIntentPersistsSubjectAvatarLogoIntoTheDefaultOutputSnapshot() async throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.subjectAvatar.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "示例对象",
                    shortName: "小宝",
                    avatarImagePath: "/tmp/avatar-display.png",
                    avatarBadgeImagePath: "/tmp/avatar-badge.png",
                    avatarPreviewImagePath: "/tmp/avatar-preview.png"
                ),
                relationship: .init(
                    role: "宝宝",
                    label: "妈妈眼里的宝宝"
                ),
                definition: "测试对象",
                referenceDate: Date(
                    timeIntervalSince1970:
                        1_716_825_600
                ),
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: Date(
                            timeIntervalSince1970:
                                1_716_825_600
                        ),
                        note: "出生日期",
                        anchorType: .birthday
                    )
                ],
                activeTimeAnchorID: nil,
                expressionSubjectSource: .shortName,
                behavior: MemoryBehavior(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .autoMatch,
                    memoryExpression: MemoryExpression(
                        title: "生日记忆",
                        blocks: []
                    )
                ),
                decorations: []
            )
        let subjectAvatarBadge =
            Badge(
                name:
                    OptimizedSubjectAvatarAsset
                    .subjectAvatarBadgeName,
                type: .customUpload,
                imagePath: "/tmp/avatar-badge.png"
            )
        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let request =
            V1ConfigurationSaveRequest(
                subject: subject,
                template:
                    Template.classicWhite
                    .renamed("对象头像配置"),
                badge: subjectAvatarBadge,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                timeAnchor:
                    .init(
                        title: "生日",
                        date: subject.referenceDate
                    ),
                albumSelection:
                    .init(
                        identifier:
                            PhotoMemoAlbumSelection
                            .automaticIdentifier,
                        title:
                            PhotoMemoAlbumSelection
                            .defaultAlbumTitle
                    )
            )

        let result =
            await SaveV1ConfigurationIntent(
                request: request,
                coordinator: coordinator
            )
            .execute()

        _ =
            try Self.requireSuccess(
                result,
                failurePrefix:
                    "Expected subject-avatar configuration save to succeed"
            )
        let snapshot =
            try Self.requireSuccess(
                coordinator
                .loadDefaultBatchConfigurationSnapshot(),
                failurePrefix:
                    "Expected saved subject-avatar snapshot to load"
            )
        let bootstrap =
            try Self.requireSuccess(
                await LoadV1ConfigurationBootstrapIntent(
                    coordinator: coordinator
                )
                .execute(),
                failurePrefix:
                    "Expected subject-avatar bootstrap state to load"
            )

        #expect(
            snapshot.badge
            == subjectAvatarBadge
        )
        #expect(
            bootstrap.logoMode
            == .subjectAvatar
        )
        #expect(
            bootstrap.customLogoBadge
            == nil
        )
        #expect(
            bootstrap.selectedSubject
            == subject
        )
    }

    @MainActor
    @Test("LoadV1ConfigurationBootstrapIntent normalizes automatic and system-library bootstrap state")
    func loadV1ConfigurationBootstrapIntentNormalizesAutomaticAndSystemLibraryBootstrapState() async throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.bootstrapNormalization.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let settings =
            SettingsService(defaults: defaults)
        settings.saveEditorState(
            selectedAlbumIdentifier:
                PhotoMemoAlbumSelection
                .systemLibraryIdentifier,
            selectedAlbumTitle:
                "系统图库"
        )

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let systemResult =
            await LoadV1ConfigurationBootstrapIntent(
                coordinator: coordinator
            )
            .execute()
        let systemBootstrap =
            try Self.requireSuccess(
                systemResult,
                failurePrefix:
                    "Expected system bootstrap load to succeed"
            )

        #expect(
            systemBootstrap.outputTarget
            == .applePhotos
        )
        #expect(
            systemBootstrap.selectedExistingAlbumIdentifier
            .isEmpty
        )
        #expect(
            systemBootstrap.suggestedNewAlbumName
            == nil
        )

        settings.saveEditorState(
            selectedAlbumIdentifier:
                PhotoMemoAlbumSelection
                .automaticIdentifier,
            selectedAlbumTitle:
                PhotoMemoAlbumSelection
                .defaultAlbumTitle
        )

        let automaticResult =
            await LoadV1ConfigurationBootstrapIntent(
                coordinator: coordinator
            )
            .execute()
        let automaticBootstrap =
            try Self.requireSuccess(
                automaticResult,
                failurePrefix:
                    "Expected automatic bootstrap load to succeed"
            )

        #expect(
            automaticBootstrap.outputTarget
            == .automatic
        )
        #expect(
            automaticBootstrap.selectedExistingAlbumIdentifier
            .isEmpty
        )
        #expect(
            automaticBootstrap.suggestedNewAlbumName
            == "时光记"
        )
    }

    @MainActor
    @Test("LoadV1ConfigurationBootstrapIntent keeps existing-album bootstrap state when the saved badge payload is corrupted")
    func loadV1ConfigurationBootstrapIntentKeepsExistingAlbumStateWhenBadgePayloadIsCorrupted() async throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.bootstrapCorruptedBadge.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        defaults.set(
            Data("corrupted-badge".utf8),
            forKey: "photomemo.selectedBadge"
        )

        let settings =
            SettingsService(defaults: defaults)
        settings.saveEditorState(
            selectedAlbumIdentifier:
                "album-existing",
            selectedAlbumTitle:
                "成长记录"
        )

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let result =
            await LoadV1ConfigurationBootstrapIntent(
                coordinator: coordinator
            )
            .execute()
        let bootstrap =
            try Self.requireSuccess(
                result,
                failurePrefix:
                    "Expected corrupted-badge bootstrap load to succeed"
            )

        #expect(
            bootstrap.logoMode
            == .appleMini
        )
        #expect(
            bootstrap.customLogoBadge
            == nil
        )
        #expect(
            bootstrap.outputTarget
            == .existingAlbum
        )
        #expect(
            bootstrap.selectedExistingAlbumIdentifier
            == "album-existing"
        )
        #expect(
            bootstrap.suggestedNewAlbumName
            == "成长记录"
        )
    }

    @MainActor
    @Test("LoadV1ConfigurationBootstrapIntent preserves subject-library decode failure diagnostics")
    func loadV1ConfigurationBootstrapIntentPreservesSubjectLibraryDecodeFailureDiagnostics() async throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.subjectLibraryFailure.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        defaults.set(
            Data("corrupted-subject-library".utf8),
            forKey: "photomemo.v1.subjectLibrary"
        )

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let bootstrap =
            try Self.requireSuccess(
                await LoadV1ConfigurationBootstrapIntent(
                    coordinator: coordinator
                )
                .execute(),
                failurePrefix:
                    "Expected bootstrap to surface corrupted subject-library diagnostics"
            )

        #expect(bootstrap.subjects == nil)
        #expect(bootstrap.selectedSubjectID == nil)
        #expect(
            bootstrap.subjectLibraryReadFailure?
                .storageKey
            == "photomemo.v1.subjectLibrary"
        )
        #expect(
            bootstrap.subjectLibraryReadFailure?
                .payloadByteCount
            == Data("corrupted-subject-library".utf8).count
        )
    }

    @MainActor
    @Test("SaveV1ConfigurationIntent can preserve an existing subject library when requested")
    func saveV1ConfigurationIntentCanPreserveExistingSubjectLibraryWhenRequested() async throws {

        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.preserveSubjectLibrary.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let originalSubject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        let originalRecord =
            V1SubjectLibraryRecord(
                subjects: [originalSubject],
                selectedSubjectID:
                    originalSubject.id
            )
        defaults.set(
            try JSONEncoder().encode(
                originalRecord
            ),
            forKey: "photomemo.v1.subjectLibrary"
        )

        var replacementSubject =
            originalSubject
        replacementSubject.identity.displayName =
            "不应覆盖对象库"

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let request =
            V1ConfigurationSaveRequest(
                subject: replacementSubject,
                subjects: [replacementSubject],
                selectedSubjectID:
                    replacementSubject.id,
                shouldSaveSubjectLibrary: false,
                template: .classicWhite,
                badge: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                timeAnchor:
                    .init(
                        title: "生日",
                        date: Date(
                            timeIntervalSince1970:
                                1_725_206_400
                        )
                    ),
                albumSelection:
                    .init(
                        identifier: "",
                        title: ""
                    )
            )

        _ =
            try Self.requireSuccess(
                await SaveV1ConfigurationIntent(
                    request: request,
                    coordinator: coordinator
                )
                .execute(),
                failurePrefix:
                    "Expected save to succeed while preserving existing subject library"
            )

        let reloadedRecord =
            try JSONDecoder().decode(
                V1SubjectLibraryRecord.self,
                from:
                    try #require(
                        defaults.data(
                            forKey:
                                "photomemo.v1.subjectLibrary"
                        )
                    )
            )

        #expect(reloadedRecord == originalRecord)
    }

    @MainActor
    @Test("SaveV1ConfigurationIntent keeps selected subject in stale subject library saves")
    func saveV1ConfigurationIntentKeepsSelectedSubjectInStaleSubjectLibrarySaves() async throws {
        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.staleSubjectLibrarySave.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

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

        var selectedSubject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        selectedSubject.identity.displayName = "小宝"
        selectedSubject.identity.shortName = "小宝"

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let request =
            V1ConfigurationSaveRequest(
                subject: selectedSubject,
                subjects: [staleSubject],
                selectedSubjectID:
                    selectedSubject.id,
                shouldSaveSubjectLibrary: true,
                template: .classicWhite,
                badge: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                timeAnchor:
                    .init(
                        title: "生日",
                        date:
                            selectedSubject
                            .primaryTimeAnchor?
                            .date
                            ?? Date(
                                timeIntervalSince1970:
                                    1_704_067_200
                            )
                    ),
                albumSelection:
                    .init(
                        identifier: "",
                        title: ""
                    )
            )

        _ =
            try Self.requireSuccess(
                await SaveV1ConfigurationIntent(
                    request: request,
                    coordinator: coordinator
                )
                .execute(),
                failurePrefix:
                    "Expected stale subject-library save to keep the selected subject"
            )

        let reloadedRecord =
            try JSONDecoder().decode(
                V1SubjectLibraryRecord.self,
                from:
                    try #require(
                        defaults.data(
                            forKey:
                                "photomemo.v1.subjectLibrary"
                        )
                    )
            )
        let reloadedSubject =
            try #require(
                reloadedRecord
                    .subjects
                    .first {
                        $0.id == selectedSubject.id
                    }
            )

        #expect(
            reloadedRecord.selectedSubjectID
            == selectedSubject.id
        )
        #expect(
            reloadedSubject
                .resolvedExpressionSubjectText
            == "小宝"
        )
        #expect(
            defaults.string(
                forKey:
                    "photomemo.selectedMemorySubjectText"
            )
            == "小宝"
        )
    }

    @MainActor
    @Test("aggregate save projects legacy settings only after durable receipt")
    func aggregateSaveProjectsLegacySettingsAfterDurableReceipt() async throws {
        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.aggregateProjection.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        var callbackReceipt:
            ConfigurationLibrarySaveReceipt?
        var appliedPairs: [(
            snapshot: BatchConfigurationSnapshot,
            receipt: ConfigurationLibrarySaveReceipt
        )] = []
        let coordinator = Self.makeConfigurationCoordinator(
            defaults: defaults,
            applyConfigurationLibrarySnapshot: {
                snapshot,
                receipt in
                appliedPairs.append((snapshot, receipt))
            },
            onConfigurationLibrarySaved: {
                callbackReceipt = $0
            }
        )
        let aggregate = Self.makeConfigurationLibraryAggregate()

        let receipt = try await coordinator
            .saveConfigurationLibrary(aggregate)
        let loaded = try await coordinator
            .loadConfigurationLibrary()
        let projectedLibrary = try JSONDecoder().decode(
            V1SubjectLibraryRecord.self,
            from: try #require(
                defaults.data(
                    forKey: "photomemo.v1.subjectLibrary"
                )
            )
        )
        let projectedTemplate = try JSONDecoder().decode(
            Template.self,
            from: try #require(
                defaults.data(
                    forKey: "photomemo.selectedTemplate"
                )
            )
        )
        let projectedBadge = try JSONDecoder().decode(
            Badge.self,
            from: try #require(
                defaults.data(
                    forKey: "photomemo.selectedBadge"
                )
            )
        )
        let projectedLocation = try JSONDecoder().decode(
            ExpressionModuleConfiguration.self,
            from: try #require(
                defaults.data(
                    forKey:
                        "photomemo.locationDisplayConfiguration"
                )
            )
        )

        #expect(receipt.revision == 1)
        #expect(callbackReceipt == receipt)
        #expect(appliedPairs.count == 1)
        #expect(
            appliedPairs.first?.snapshot.template.name
            == "Aggregate Preset"
        )
        #expect(appliedPairs.first?.receipt == receipt)
        #expect(loaded.source == .primary)
        #expect(loaded.aggregate.revision == receipt.revision)
        #expect(
            projectedLibrary.selectedSubjectID
            == receipt.subjectID
        )
        #expect(
            projectedLibrary.selectedMemoryPresetID
            == receipt.configurationID
        )
        #expect(projectedTemplate.name == "Aggregate Preset")
        #expect(projectedBadge.name == "Family")
        #expect(projectedLocation.token == "{{location}}")
        #expect(
            defaults.string(
                forKey: "photomemo.selectedAlbumIdentifier"
            ) == "album-aggregate"
        )
        #expect(
            defaults.string(
                forKey: "photomemo.selectedAlbumTitle"
            ) == "成长记录"
        )
        #expect(
            defaults.bool(
                forKey:
                    "photomemo.shouldWritePhotoDescription"
            )
        )
        #expect(
            defaults.string(
                forKey: "photomemo.photoDescriptionOverride"
            ) == "Aggregate Description"
        )
        #expect(
            defaults.string(
                forKey: "photomemo.v1.mediaOutputMode"
            ) == V1MediaOutputMode.originalFormat.rawValue
        )
    }

    @MainActor
    @Test("aggregate success projects the active configuration into the current legacy slot DTO")
    func aggregateSuccessProjectsCurrentLegacySlotDTO() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateLegacySlotProjection"
        )
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL: rootURL,
            legacyDefaults: nil
        )
        let settings = SettingsService(
            defaults: defaults,
            configurationLibraryRepository:
                ConfigurationLibraryRepository(
                    persistence: ConfigurationLibraryPersistence(
                        storage: storage
                    )
                ),
            configurationLibraryStorage: storage
        )
        settings.activeConfigurationSlotID = .slot2
        settings.saveConfigurationSlots()

        let receipt = try await settings.saveConfigurationLibrary(
            Self.makeConfigurationLibraryAggregate(
                title: "Aggregate Slot Projection"
            )
        )
        let slots = try JSONDecoder().decode(
            [WorkspaceConfigurationSlot].self,
            from: try #require(
                defaults.data(
                    forKey: "photomemo.configurationSlots"
                )
            )
        )
        let projected = try #require(
            slots.first { $0.id == .slot2 }
        )

        #expect(projected.snapshot?.template.name == "Aggregate Slot Projection")
        #expect(projected.snapshot?.configurationID == receipt.configurationID)
        #expect(
            projected.snapshot?.configurationRevision
            == receipt.configurationRevision
        )
        #expect(projected.updatedAt != nil)
        #expect(slots.first { $0.id == .slot1 }?.snapshot == nil)
        #expect(slots.first { $0.id == .slot3 }?.snapshot == nil)
    }

    @MainActor
    @Test("aggregate bootstrap ignores a tampered active legacy slot")
    func aggregateBootstrapIgnoresTamperedLegacySlot() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateIgnoresTamperedSlot"
        )
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL: rootURL,
            legacyDefaults: nil
        )
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
        let settings = SettingsService(
            defaults: defaults,
            configurationLibraryRepository: repository,
            configurationLibraryStorage: storage
        )
        _ = try await settings.saveConfigurationLibrary(
            Self.makeConfigurationLibraryAggregate(
                title: "Aggregate Truth"
            )
        )
        var tamperedSnapshot = settings.buildBatchConfigurationSnapshot()
        tamperedSnapshot.template =
            tamperedSnapshot.template.renamed("Tampered Slot")
        let tamperedSlots = WorkspaceConfigurationSlot.defaultSlots.map {
            slot -> WorkspaceConfigurationSlot in
            guard slot.id == .slot3 else {
                return slot
            }
            var result = slot
            result.snapshot = tamperedSnapshot
            result.updatedAt = Date(timeIntervalSince1970: 999)
            return result
        }
        defaults.set(
            WorkspaceConfigurationSlotID.slot3.rawValue,
            forKey: "photomemo.activeConfigurationSlotID"
        )
        defaults.set(
            try JSONEncoder().encode(tamperedSlots),
            forKey: "photomemo.configurationSlots"
        )

        let restarted = SettingsService(
            defaults: defaults,
            configurationLibraryRepository:
                ConfigurationLibraryRepository(
                    persistence: ConfigurationLibraryPersistence(
                        storage: storage
                    )
                ),
            configurationLibraryStorage: storage
        )
        let bootstrap = SettingsRepository(
            settingsService: restarted
        ).loadV1ConfigurationBootstrapState()

        #expect(bootstrap.configurationLibrary != nil)
        #expect(bootstrap.draftProjection?.title == "Aggregate Truth")
        #expect(bootstrap.draftProjection?.title != "Tampered Slot")
    }

    @MainActor
    @Test("changing the active legacy slot ID does not mutate aggregate truth")
    func changingLegacySlotIDDoesNotMutateAggregate() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "legacySlotIDDoesNotMutateAggregate"
        )
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL: rootURL,
            legacyDefaults: nil
        )
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
        let settings = SettingsService(
            defaults: defaults,
            configurationLibraryRepository: repository,
            configurationLibraryStorage: storage
        )
        _ = try await settings.saveConfigurationLibrary(
            Self.makeConfigurationLibraryAggregate(
                title: "Immutable Aggregate"
            )
        )
        let primaryBefore = try #require(
            try storage.loadPrimaryData()
        )
        let settingsRepository = SettingsRepository(
            settingsService: settings
        )

        settingsRepository.updateActiveConfigurationSlotID(.slot3)

        #expect(settingsRepository.activeConfigurationSlotID() == .slot3)
        #expect(try storage.loadPrimaryData() == primaryBefore)
        #expect(
            try await repository.load().aggregate.subjects[0]
                .configurations[0].title == "Immutable Aggregate"
        )
    }

    @MainActor
    @Test("aggregate validation failure does not refresh production or emit a success receipt")
    func aggregateValidationFailureSkipsRefreshAndCallback() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateValidationFailure"
        )
        var refreshCount = 0
        var callbackCount = 0
        let coordinator = Self.makeConfigurationCoordinator(
            defaults: defaults,
            applyConfigurationLibrarySnapshot: { _, _ in
                refreshCount += 1
            },
            onConfigurationLibrarySaved: { _ in
                callbackCount += 1
            }
        )
        var aggregate = Self.makeConfigurationLibraryAggregate()
        aggregate.activeConfigurationID = UUID()

        await #expect(
            throws: ConfigurationLibraryPersistenceError.self
        ) {
            _ = try await coordinator
                .saveConfigurationLibrary(aggregate)
        }

        #expect(refreshCount == 0)
        #expect(callbackCount == 0)
    }

    @MainActor
    @Test("aggregate encode failure does not refresh production or emit a success receipt")
    func aggregateEncodeFailureSkipsRefreshAndCallback() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateEncodeFailure"
        )
        let storage = CoordinatorConfigurationLibraryStorage()
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            ),
            encoder: CoordinatorFailingConfigurationLibraryEncoder()
        )
        var refreshCount = 0
        var callbackCount = 0
        let coordinator = Self.makeConfigurationCoordinator(
            defaults: defaults,
            configurationLibraryRepository: repository,
            applyConfigurationLibrarySnapshot: { _, _ in
                refreshCount += 1
            },
            onConfigurationLibrarySaved: { _ in
                callbackCount += 1
            }
        )

        await #expect(
            throws: ConfigurationLibraryPersistenceError.self
        ) {
            _ = try await coordinator.saveConfigurationLibrary(
                Self.makeConfigurationLibraryAggregate()
            )
        }

        #expect(refreshCount == 0)
        #expect(callbackCount == 0)
        #expect(storage.writeCount == 0)
    }

    @MainActor
    @Test("aggregate write failure does not refresh production or emit a success receipt")
    func aggregateWriteFailureSkipsRefreshAndCallback() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateWriteFailure"
        )
        let storage = CoordinatorConfigurationLibraryStorage()
        storage.shouldFailWrites = true
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
        var refreshCount = 0
        var callbackCount = 0
        let coordinator = Self.makeConfigurationCoordinator(
            defaults: defaults,
            configurationLibraryRepository: repository,
            applyConfigurationLibrarySnapshot: { _, _ in
                refreshCount += 1
            },
            onConfigurationLibrarySaved: { _ in
                callbackCount += 1
            }
        )

        await #expect(
            throws: ConfigurationLibraryPersistenceError.self
        ) {
            _ = try await coordinator.saveConfigurationLibrary(
                Self.makeConfigurationLibraryAggregate()
            )
        }

        #expect(refreshCount == 0)
        #expect(callbackCount == 0)
        #expect(storage.writeCount == 0)
    }

    @MainActor
    @Test("aggregate projection failure reports primary success without refreshing production")
    func aggregateProjectionFailureSkipsRefreshButEmitsReceipt() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateProjectionFailure"
        )
        let storage = CoordinatorConfigurationLibraryStorage()
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
        var refreshCount = 0
        var callbackReceipt:
            ConfigurationLibrarySaveReceipt?
        let coordinator = Self.makeConfigurationCoordinator(
            defaults: defaults,
            configurationLibraryRepository: repository,
            configurationLibraryProjection: { _ in
                throw CoordinatorConfigurationLibraryFailure.projection
            },
            applyConfigurationLibrarySnapshot: { _, _ in
                refreshCount += 1
            },
            onConfigurationLibrarySaved: {
                callbackReceipt = $0
            }
        )

        let receipt = try await coordinator.saveConfigurationLibrary(
            Self.makeConfigurationLibraryAggregate()
        )

        #expect(receipt.revision == 1)
        #expect(receipt.compatibilityProjectionFailure != nil)
        #expect(callbackReceipt == receipt)
        #expect(refreshCount == 0)
        #expect(storage.writeCount == 1)
    }

    @MainActor
    @Test("concurrent aggregate saves pair each production snapshot with its own receipt revision")
    func concurrentAggregateSavesPreserveSnapshotReceiptPairing() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateConcurrentPairing"
        )
        var publishedPairs: [Int: PublishedConfigurationPair] = [:]
        var callbackReceipts:
            [ConfigurationLibrarySaveReceipt] = []
        let coordinator = Self.makeConfigurationCoordinator(
            defaults: defaults,
            applyConfigurationLibrarySnapshot: {
                snapshot,
                receipt in
                publishedPairs[receipt.revision] =
                    PublishedConfigurationPair(
                        title: snapshot.template.name,
                        configurationID:
                            snapshot.configurationID,
                        configurationRevision:
                            snapshot.configurationRevision
                    )
            },
            onConfigurationLibrarySaved: {
                callbackReceipts.append($0)
            }
        )

        let completedSaves = try await withThrowingTaskGroup(
            of: (
                revision: Int,
                configurationRevision: Int,
                title: String
            ).self
        ) { group in
            for index in 0..<12 {
                let title = "Concurrent Aggregate \(index)"
                group.addTask { @MainActor in
                    let receipt = try await coordinator
                        .saveConfigurationLibrary(
                            Self.makeConfigurationLibraryAggregate(
                                title: title
                            )
                        )
                    return (
                        receipt.revision,
                        receipt.configurationRevision,
                        title
                    )
                }
            }

            var saves: [(
                revision: Int,
                configurationRevision: Int,
                title: String
            )] = []
            for try await save in group {
                saves.append(save)
            }
            return saves
        }
        let expectedPairs = Dictionary(
            uniqueKeysWithValues:
                completedSaves.map {
                    (
                        $0.revision,
                        PublishedConfigurationPair(
                            title: $0.title,
                            configurationID: UUID(
                                uuidString:
                                    "72727272-7272-7272-7272-727272727272"
                            ),
                            configurationRevision:
                                $0.configurationRevision
                        )
                    )
                }
        )

        #expect(
            completedSaves.map(\.revision).sorted()
            == Array(1...12)
        )
        #expect(publishedPairs == expectedPairs)
        #expect(callbackReceipts.count == 12)
        #expect(
            Set(callbackReceipts.map(\.revision))
            == Set(1...12)
        )
        #expect(
            Set(callbackReceipts.map(\.configurationRevision))
            == [1]
        )
    }

    @Test("legacy batch and canonical snapshots decode without configuration identity")
    func legacySnapshotsDecodeWithoutConfigurationIdentity() throws {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let canonical = ConfigurationSnapshotBuilder.build(
            from: subject
        )
        let batch = BatchConfigurationSnapshot(
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: true,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
        .withCanonicalProductionSnapshot(canonical)
        let encoded = try JSONEncoder().encode(batch)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: Any]
        )
        object.removeValue(forKey: "configurationID")
        object.removeValue(forKey: "configurationRevision")
        if var frozen = object["frozenConfigurationSnapshot"]
            as? [String: Any] {
            frozen.removeValue(forKey: "configurationID")
            frozen.removeValue(forKey: "configurationRevision")
            object["frozenConfigurationSnapshot"] = frozen
        }

        let legacyData = try JSONSerialization.data(
            withJSONObject: object
        )
        let decoded = try JSONDecoder().decode(
            BatchConfigurationSnapshot.self,
            from: legacyData
        )

        #expect(decoded.configurationID == nil)
        #expect(decoded.configurationRevision == nil)
        #expect(
            decoded.canonicalProductionSnapshot?.configurationID
            == nil
        )
        #expect(
            decoded.canonicalProductionSnapshot?
                .configurationRevision
            == nil
        )
    }

    @MainActor
    @Test("SettingsService restart replays one aggregate over torn legacy projections")
    func settingsRestartRepairsTornLegacyProjections() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateRestartReplay"
        )
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL: rootURL,
            legacyDefaults: nil
        )
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
        let settings = SettingsService(
            defaults: defaults,
            configurationLibraryRepository: repository,
            configurationLibraryStorage: storage
        )
        let aggregate = Self.makeConfigurationLibraryAggregate(
            title: "Restart Aggregate"
        )
        let receipt = try await settings
            .saveConfigurationLibrary(aggregate)
        let primaryBeforeRestart = try #require(
            try storage.loadPrimaryData()
        )

        defaults.set(
            try JSONEncoder().encode(
                Template.classicWhite.renamed("Torn Template")
            ),
            forKey: "photomemo.selectedTemplate"
        )
        defaults.set(
            try JSONEncoder().encode(Badge.travel),
            forKey: "photomemo.selectedBadge"
        )
        defaults.set(
            try JSONEncoder().encode(
                ExpressionModuleConfiguration(
                    token: "{{torn_location}}",
                    options: [:]
                )
            ),
            forKey:
                "photomemo.locationDisplayConfiguration"
        )
        defaults.set(
            false,
            forKey: "photomemo.shouldWritePhotoDescription"
        )
        defaults.set(
            "Torn Description",
            forKey: "photomemo.photoDescriptionOverride"
        )
        defaults.set(
            "torn-album",
            forKey: "photomemo.selectedAlbumIdentifier"
        )
        defaults.set(
            "Torn Album",
            forKey: "photomemo.selectedAlbumTitle"
        )
        defaults.set(
            V1MediaOutputMode.staticImage.rawValue,
            forKey: "photomemo.v1.mediaOutputMode"
        )
        defaults.set(
            Data("torn-subject-library".utf8),
            forKey: "photomemo.v1.subjectLibrary"
        )

        let restarted = SettingsService(
            defaults: defaults,
            configurationLibraryRepository:
                ConfigurationLibraryRepository(
                    persistence:
                        ConfigurationLibraryPersistence(
                            storage: storage
                        )
                ),
            configurationLibraryStorage: storage
        )
        let projectedLibrary = try JSONDecoder().decode(
            V1SubjectLibraryRecord.self,
            from: try #require(
                defaults.data(
                    forKey: "photomemo.v1.subjectLibrary"
                )
            )
        )

        #expect(receipt.revision == 1)
        #expect(
            restarted.selectedTemplate?.name
            == "Restart Aggregate"
        )
        #expect(restarted.selectedBadge?.name == "Family")
        #expect(restarted.shouldWritePhotoDescription)
        #expect(
            restarted.photoDescriptionOverride
            == "Aggregate Description"
        )
        #expect(
            restarted.selectedAlbumIdentifier
            == "album-aggregate"
        )
        #expect(restarted.selectedAlbumTitle == "成长记录")
        #expect(restarted.mediaOutputMode == .originalFormat)
        #expect(
            restarted.loadLocationDisplayConfiguration()?
                .token == "{{location}}"
        )
        #expect(
            projectedLibrary.selectedMemoryPresetID
            == receipt.configurationID
        )
        #expect(
            try storage.loadPrimaryData()
            == primaryBeforeRestart
        )
    }

    @MainActor
    @Test("SettingsService restart replays last-known-good when primary is corrupt")
    func settingsRestartReplaysLastKnownGoodFallback() async throws {
        let defaults = try Self.makeDefaults(
            suffix: "aggregateRestartLastKnownGood"
        )
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL: rootURL,
            legacyDefaults: nil
        )
        let settings = SettingsService(
            defaults: defaults,
            configurationLibraryRepository:
                ConfigurationLibraryRepository(
                    persistence:
                        ConfigurationLibraryPersistence(
                            storage: storage
                        )
                ),
            configurationLibraryStorage: storage
        )
        _ = try await settings.saveConfigurationLibrary(
            Self.makeConfigurationLibraryAggregate(
                title: "Last Known Good"
            )
        )
        _ = try await settings.saveConfigurationLibrary(
            Self.makeConfigurationLibraryAggregate(
                title: "Corrupted Primary"
            )
        )
        let corruptData = Data("corrupt-primary".utf8)
        let primaryURL = rootURL
            .appendingPathComponent("ConfigurationLibrary")
            .appendingPathComponent("primary.json")
        try corruptData.write(to: primaryURL, options: .atomic)
        defaults.set(
            try JSONEncoder().encode(
                Template.classicWhite.renamed("Torn Template")
            ),
            forKey: "photomemo.selectedTemplate"
        )

        let restarted = SettingsService(
            defaults: defaults,
            configurationLibraryRepository:
                ConfigurationLibraryRepository(
                    persistence:
                        ConfigurationLibraryPersistence(
                            storage: storage
                        )
                ),
            configurationLibraryStorage: storage
        )
        let recovered = try await restarted
            .loadConfigurationLibrary()

        #expect(recovered.source == .lastKnownGood)
        #expect(recovered.aggregate.revision == 1)
        #expect(
            restarted.selectedTemplate?.name
            == "Last Known Good"
        )
        #expect(try storage.loadPrimaryData() == corruptData)
    }

    @MainActor
    @Test("SettingsService defaults initializer ignores simulated App Group primary")
    func settingsDefaultsInitializerDoesNotReadSimulatedAppGroupPrimary() async throws {
        let simulatedAppGroupRoot = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let isolatedRoot = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(
                at: simulatedAppGroupRoot
            )
            try? FileManager.default.removeItem(at: isolatedRoot)
        }
        let simulatedAppGroupStorage =
            FileConfigurationLibraryStorage(
                baseDirectoryURL: simulatedAppGroupRoot,
                legacyDefaults: nil
            )
        let simulatedAppGroupRepository =
            ConfigurationLibraryRepository(
                persistence: ConfigurationLibraryPersistence(
                    storage: simulatedAppGroupStorage
                )
            )
        _ = try await simulatedAppGroupRepository.save(
            Self.makeConfigurationLibraryAggregate(
                title: "Simulated App Group"
            )
        )
        let primaryBefore = try #require(
            try simulatedAppGroupStorage.loadPrimaryData()
        )
        let isolatedDefaults = try Self.makeDefaults(
            suffix: "isolatedDefaultsIgnoresAppGroup"
        )
        isolatedDefaults.set(
            try JSONEncoder().encode(
                Template.classicWhite.renamed("Isolated Legacy")
            ),
            forKey: "photomemo.selectedTemplate"
        )

        let settings = SettingsService(
            defaults: isolatedDefaults,
            configurationLibraryBaseDirectoryURL:
                isolatedRoot
        )

        #expect(
            settings.selectedTemplate?.name
            == "Isolated Legacy"
        )
        #expect(
            try simulatedAppGroupStorage.loadPrimaryData()
            == primaryBefore
        )
        #expect(
            try FileConfigurationLibraryStorage(
                baseDirectoryURL: isolatedRoot,
                legacyDefaults: nil
            ).loadPrimaryData() == nil
        )
    }

    @MainActor
    @Test("independent defaults initializers keep aggregate files and projections isolated")
    func settingsDefaultsInitializersDoNotCrossContaminate() async throws {
        let rootA = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let rootB = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootA)
            try? FileManager.default.removeItem(at: rootB)
        }
        let defaultsA = try Self.makeDefaults(
            suffix: "isolatedDefaultsA"
        )
        let defaultsB = try Self.makeDefaults(
            suffix: "isolatedDefaultsB"
        )
        let settingsA = SettingsService(
            defaults: defaultsA,
            configurationLibraryBaseDirectoryURL: rootA
        )
        let settingsB = SettingsService(
            defaults: defaultsB,
            configurationLibraryBaseDirectoryURL: rootB
        )

        let receiptA = try await settingsA
            .saveConfigurationLibrary(
                Self.makeConfigurationLibraryAggregate(
                    title: "Isolated A"
                )
            )
        let primaryA = try #require(
            try FileConfigurationLibraryStorage(
                baseDirectoryURL: rootA,
                legacyDefaults: nil
            ).loadPrimaryData()
        )

        do {
            _ = try await settingsB.loadConfigurationLibrary()
            Issue.record(
                "Expected isolated B to have no aggregate"
            )
        } catch let error as
            ConfigurationLibraryPersistenceError {
            guard case .noStoredAggregate = error else {
                Issue.record(
                    "Expected noStoredAggregate, got \(error)"
                )
                return
            }
        }

        let receiptB = try await settingsB
            .saveConfigurationLibrary(
                Self.makeConfigurationLibraryAggregate(
                    title: "Isolated B"
                )
            )

        #expect(receiptA.revision == 1)
        #expect(receiptB.revision == 1)
        #expect(
            defaultsA.data(
                forKey: "photomemo.selectedTemplate"
            ) != defaultsB.data(
                forKey: "photomemo.selectedTemplate"
            )
        )
        #expect(
            try FileConfigurationLibraryStorage(
                baseDirectoryURL: rootA,
                legacyDefaults: nil
            ).loadPrimaryData() == primaryA
        )
    }
}

private extension ConfigurationMigrationTests {

    @MainActor
    static func makeConfigurationCoordinator(
        defaults: UserDefaults,
        configurationLibraryRepository:
            ConfigurationLibraryRepository? = nil,
        configurationLibraryStorage:
            (any ConfigurationLibraryDataStorage)? = nil,
        configurationLibraryProjection:
            (@MainActor (ConfigurationLibraryRecord) throws -> Void)? = nil,
        applyLiveDefaultConfiguration:
            @escaping (BatchConfigurationSnapshot) -> Void = { _ in },
        applyConfigurationLibrarySnapshot:
            (@MainActor (
                BatchConfigurationSnapshot,
                ConfigurationLibrarySaveReceipt
            ) -> Void)? = nil,
        onConfigurationLibrarySaved:
            @escaping (ConfigurationLibrarySaveReceipt) -> Void = { _ in }
    ) -> ConfigurationCoordinator {

        let settingsService: SettingsService
        if let configurationLibraryRepository {
            settingsService = SettingsService(
                defaults: defaults,
                configurationLibraryRepository:
                    configurationLibraryRepository,
                configurationLibraryStorage:
                    configurationLibraryStorage,
                configurationLibraryProjection:
                    configurationLibraryProjection
            )
        } else {
            let isolatedStorage =
                FileConfigurationLibraryStorage(
                    baseDirectoryURL:
                        FileManager.default.temporaryDirectory
                        .appendingPathComponent(
                            UUID().uuidString
                        ),
                    legacyDefaults: nil
                )
            settingsService = SettingsService(
                defaults: defaults,
                configurationLibraryRepository:
                    ConfigurationLibraryRepository(
                        persistence:
                            ConfigurationLibraryPersistence(
                                storage: isolatedStorage
                            )
                    ),
                configurationLibraryStorage:
                    isolatedStorage
            )
        }

        return ConfigurationCoordinator(
            settingsRepository:
                SettingsRepository(
                    settingsService:
                        settingsService
                ),
            configurationRepository:
                ConfigurationRepository(
                    settingsService:
                        settingsService,
                    sharedSnapshotService:
                        SharedBatchConfigurationSnapshotService(
                            defaults: defaults
                        )
                ),
            applyLiveDefaultConfiguration:
                applyLiveDefaultConfiguration,
            applyConfigurationLibrarySnapshot:
                applyConfigurationLibrarySnapshot,
            onConfigurationLibrarySaved:
                onConfigurationLibrarySaved
        )
    }

    static func makeConfigurationLibraryAggregate(
        title: String = "Aggregate Preset"
    )
    -> ConfigurationLibraryRecord {
        let subject = MemorySubject(
            id: UUID(
                uuidString:
                    "71717171-7171-7171-7171-717171717171"
            )!,
            identity: .init(
                displayName: "示例对象",
                shortName: "小宝"
            ),
            relationship: .init(
                role: "宝宝",
                label: "妈妈眼里的宝宝"
            ),
            referenceDate: Date(
                timeIntervalSince1970: 1_716_825_600
            ),
            timeAnchors: [],
            activeTimeAnchorID: nil,
            expressionSubjectSource: .shortName,
            behavior: MemoryBehavior(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .autoMatch,
                memoryExpression: MemoryExpression(
                    title: "成长",
                    blocks: []
                )
            ),
            decorations: []
        )
        let configuration = MemoryConfigurationRecord(
            id: UUID(
                uuidString:
                    "72727272-7272-7272-7272-727272727272"
            )!,
            title: title,
            revision: 1,
            savedAt: Date(
                timeIntervalSince1970: 1_725_206_400
            ),
            selectedTimeAnchorID: nil,
            editor: .init(
                template:
                    Template.classicWhite
                        .renamed(title),
                regionTemplateIDs: [
                    .slotA: "recorder.configuration1"
                ],
                memoryCopy: .init(
                    usesCustomText: true,
                    customText: "Aggregate Memory"
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: .init(
                    token: "{{location}}",
                    options: ["displayStyle": "city"]
                ),
                logo: .init(
                    mode: .appleMini,
                    badge: .init(
                        id: Badge.family.id,
                        name: Badge.family.name,
                        type: Badge.family.type,
                        systemSymbol:
                            Badge.family.systemSymbol,
                        isSystemDefault: true
                    )
                )
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: true,
                    overrideText:
                        "Aggregate Description"
                ),
                album: .init(
                    destination: .existingAlbum,
                    identifier: "album-aggregate",
                    title: "成长记录"
                )
            )
        )
        return ConfigurationLibraryRecord(
            revision: 999,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )
    }

    static func makeDefaults(
        suffix: String
    ) throws -> UserDefaults {
        let suiteName =
            "PhotoMemo.ConfigurationMigrationTests.\(suffix).\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    static func requireSuccess<Value>(
        _ result: PhotoMemoResult<Value>,
        failurePrefix: String
    ) throws -> Value {

        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            Issue.record(
                "\(failurePrefix), got \(error.message)"
            )
            throw Failure()
        }
    }

    struct Failure: Error {}
}

private final class CoordinatorConfigurationLibraryStorage:
    ConfigurationLibraryDataStorage,
    @unchecked Sendable {

    var primaryData: Data?
    var lastKnownGoodData: Data?
    var shouldFailWrites = false
    private(set) var writeCount = 0

    func loadPrimaryData() throws -> Data? {
        primaryData
    }

    func loadLastKnownGoodData() throws -> Data? {
        lastKnownGoodData
    }

    func replacePrimaryData(
        _ data: Data,
        lastKnownGoodData: Data?
    ) throws {
        guard !shouldFailWrites else {
            throw CoordinatorConfigurationLibraryFailure.write
        }
        self.lastKnownGoodData = lastKnownGoodData
        primaryData = data
        writeCount += 1
    }
}

private struct CoordinatorFailingConfigurationLibraryEncoder:
    ConfigurationLibraryRecordEncoding {

    func encode(
        _ aggregate: ConfigurationLibraryRecord
    ) throws -> Data {
        throw CoordinatorConfigurationLibraryFailure.encoding
    }
}

private enum CoordinatorConfigurationLibraryFailure: Error {
    case encoding
    case write
    case projection
}

private struct PublishedConfigurationPair: Equatable {
    let title: String
    let configurationID: UUID?
    let configurationRevision: Int?
}

private extension Template {

    func renamed(
        _ name: String
    ) -> Template {

        var template = self
        template.name = name
        return template
    }
}
#endif
