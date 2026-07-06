#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration migration", .serialized)
struct ConfigurationMigrationTests {

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
            Template.immersWhite
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
                        title: "团团",
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
                    Template.immersWhite
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
                template: .template1,
                badge: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                timeAnchor:
                    .init(
                        title: "团团",
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
            == "团团"
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
                    Template.immersWhite
                    .renamed("V1 默认配置"),
                badge: .family,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride:
                    "这一天，途途18天",
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
            == "这一天，途途18天"
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
                    displayName: "王途途",
                    shortName: "途途",
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
                    Template.immersWhite
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
            == "photomemo"
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
                template: .template1,
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
}

private extension ConfigurationMigrationTests {

    @MainActor
    static func makeConfigurationCoordinator(
        defaults: UserDefaults,
        applyLiveDefaultConfiguration:
            @escaping (BatchConfigurationSnapshot) -> Void = { _ in }
    ) -> ConfigurationCoordinator {

        let settingsService =
            SettingsService(defaults: defaults)

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
                applyLiveDefaultConfiguration
        )
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
