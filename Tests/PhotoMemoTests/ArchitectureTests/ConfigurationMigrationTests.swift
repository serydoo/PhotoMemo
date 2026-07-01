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
        let request =
            V1ConfigurationSaveRequest(
                subject:
                    ConfigurationCenterState
                    .mock
                    .selectedSubject,
                template: template,
                badge: .family,
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
            receipt.anchor.title
            == request.timeAnchor.title
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
                    "途途今天18天啦！",
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
            == "途途今天18天啦！"
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
