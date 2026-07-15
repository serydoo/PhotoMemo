#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Settings persistence layers", .serialized)
struct SettingsPersistenceLayerTests {

    @MainActor
    @Test("Legacy settings store preserves compatibility keys and typed values")
    func legacySettingsStorePreservesCompatibilityKeysAndTypedValues() throws {
        let context = try Self.makeDefaultsContext("legacy")
        defer { context.cleanup() }
        let store = LegacySettingsStore(defaults: context.defaults)
        var template = Template.classicWhite
        template.name = "家庭时光"
        let anchorID = UUID()

        store.saveTemplate(template)
        store.saveEditorState(
            LegacySettingsEditorState(
                selectedAnchorIDString: anchorID.uuidString,
                selectedAlbumIdentifier: "album-123",
                selectedAlbumTitle: "家庭相册"
            )
        )
        store.saveMediaOutputMode(.staticImage)

        #expect(
            context.defaults.data(
                forKey: "photomemo.selectedTemplate"
            ) != nil
        )
        #expect(
            store.loadTemplate()
            == template.normalizedForEditing
        )
        #expect(
            store.loadEditorState()
            == LegacySettingsEditorState(
                selectedAnchorIDString: anchorID.uuidString,
                selectedAlbumIdentifier: "album-123",
                selectedAlbumTitle: "家庭相册"
            )
        )
        #expect(store.loadMediaOutputMode() == .staticImage)
    }

    @MainActor
    @Test("Configuration projection writes the complete active compatibility view")
    func configurationProjectionWritesCompleteActiveCompatibilityView() throws {
        let context = try Self.makeDefaultsContext("projection")
        defer { context.cleanup() }
        let aggregate = try Self.makeAggregate(revision: 23)
        let store = LegacySettingsStore(defaults: context.defaults)
        let service = ConfigurationProjectionService(
            legacyStore: store,
            snapshotProvider: BatchConfigurationSnapshotProvider(
                defaults: context.defaults
            )
        )

        let projection = try service.projectAndPersist(
            aggregate
        )

        #expect(
            projection.subjectLibrary.selectedSubjectID
            == aggregate.activeSubjectID
        )
        #expect(
            projection.subjectLibrary.selectedMemoryPresetID
            == aggregate.activeConfigurationID
        )
        #expect(
            projection.productionConfigurationReference
                .configurationID
            == aggregate.activeConfigurationID
        )
        #expect(
            store.loadTemplate()
            == projection.template
        )
        #expect(store.loadBadge() == projection.badge)
        #expect(
            store.loadLocationDisplayConfiguration()
            == projection.locationDisplayConfiguration
        )
        #expect(
            store.loadEditorState()
            == projection.editorState
        )
        #expect(
            store.loadProductionConfigurationReference()
            == projection.productionConfigurationReference
        )
    }

    @MainActor
    @Test("Configuration library store recovers durable aggregate revision before projection")
    func configurationLibraryStoreRecoversDurableAggregateRevisionBeforeProjection() throws {
        let aggregate = try Self.makeAggregate(revision: 41)
        let storage = SettingsLayerTestConfigurationLibraryStorage(
            primaryData: try JSONEncoder().encode(aggregate)
        )
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
        let store = ConfigurationLibraryStore(
            repository: repository,
            storage: storage
        )
        var projectedRevision: Int?

        store.replayProjectionIfAvailable { recovered in
            projectedRevision = recovered.revision
        }

        #expect(store.recoveredAggregate?.revision == 41)
        #expect(projectedRevision == 41)
        #expect(store.startupRecoveryError == nil)
    }

    @MainActor
    @Test("Startup recovery repairs compatibility state without invoking the save projection hook")
    func startupRecoveryUsesDefaultProjection() throws {
        let context = try Self.makeDefaultsContext("startup-projection")
        defer { context.cleanup() }
        let aggregate = try Self.makeAggregate(revision: 42)
        let storage = SettingsLayerTestConfigurationLibraryStorage(
            primaryData: try JSONEncoder().encode(aggregate)
        )
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
        var saveProjectionCallCount = 0

        let service = SettingsService(
            defaults: context.defaults,
            configurationLibraryRepository: repository,
            configurationLibraryStorage: storage,
            configurationLibraryProjection: { _ in
                saveProjectionCallCount += 1
            }
        )
        let legacyStore = LegacySettingsStore(
            defaults: context.defaults
        )

        #expect(saveProjectionCallCount == 0)
        #expect(service.configurationLibraryStartupRecoveryError == nil)
        #expect(
            service.loadV1BootstrapReadState()
                .configurationLibrary?.revision == 42
        )
        #expect(
            legacyStore.loadProductionConfigurationReference()?
                .configurationID
            == aggregate.activeConfigurationID
        )
        #expect(
            service.selectedTemplate
            == legacyStore.loadTemplate()
        )
    }

    @MainActor
    @Test("Bootstrap reload preserves the current badge when no persisted badge exists")
    func bootstrapReloadPreservesBadgeWithoutStoredValue() throws {
        let context = try Self.makeDefaultsContext("reload-badge")
        defer { context.cleanup() }
        let service = SettingsService(defaults: context.defaults)
        service.selectedBadge = .family
        context.defaults.removeObject(
            forKey: "photomemo.selectedBadge"
        )

        service.reloadV1BootstrapState()

        #expect(service.selectedBadge == .family)
    }
}

private extension SettingsPersistenceLayerTests {

    struct DefaultsContext {
        let suiteName: String
        let defaults: UserDefaults

        func cleanup() {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }
    }

    static func makeDefaultsContext(
        _ suffix: String
    ) throws -> DefaultsContext {
        let suiteName =
            "PhotoMemo.SettingsPersistenceLayerTests.\(suffix).\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        return DefaultsContext(
            suiteName: suiteName,
            defaults: defaults
        )
    }

    static func makeAggregate(
        revision: Int
    ) throws -> ConfigurationLibraryRecord {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let preset = MemoryPreset(
            title: "家庭时光",
            summary: "",
            regionTemplateIDs: [:],
            selectedSubjectID: subject.id,
            selectedTimeAnchorID:
                subject.activeTimeAnchorID
        )
        let legacy = V1SubjectLibraryRecord(
            subjects: [subject],
            selectedSubjectID: subject.id,
            memoryPresets: [preset],
            selectedMemoryPresetID: preset.id
        )
        var template = Template.classicWhite
        template.name = "家庭时光"
        return ConfigurationLibraryRecord.migrating(
            legacy,
            compatibility:
                LegacyConfigurationCompatibilitySettings(
                    template: template,
                    badge: .family,
                    logoMode: .customUpload,
                    locationConfiguration:
                        ExpressionModuleConfiguration(
                            token: "location",
                            options: [
                                "presentationMode":
                                    "provinceCity"
                            ]
                        ),
                    shouldWritePhotosDescription: false,
                    photosDescriptionOverride: "照片说明",
                    selectedAlbumIdentifier: "album-123",
                    selectedAlbumTitle: "家庭相册",
                    mediaOutputMode: .staticImage
                ),
            revision: revision,
            savedAt: Date(
                timeIntervalSince1970: 1_752_508_800
            )
        )
    }
}

private final class SettingsLayerTestConfigurationLibraryStorage:
    ConfigurationLibraryDataStorage,
    @unchecked Sendable {

    private var primaryData: Data?
    private var lastKnownGoodData: Data?

    init(
        primaryData: Data?,
        lastKnownGoodData: Data? = nil
    ) {
        self.primaryData = primaryData
        self.lastKnownGoodData = lastKnownGoodData
    }

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
        self.lastKnownGoodData = lastKnownGoodData
        primaryData = data
    }
}
#endif
