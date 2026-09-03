#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@MainActor
@Suite("Configuration Center initial library", .serialized)
struct ConfigurationCenterInitialLibraryTests {

    @Test("Fresh installation defaults have canonical configuration records")
    func freshInstallationDefaultsHaveCanonicalConfigurationRecords() throws {
        let suiteName =
            "MemoMark.ConfigurationCenterInitialLibraryTests.fresh.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let bootstrap = Self.makeBootstrapState(
            defaults: defaults,
            rootURL: rootURL
        )
        let aggregate = try #require(
            bootstrap.configurationLibrary
        )

        #expect(
            aggregate.subjects.flatMap(\.configurations).map(\.id)
            == bootstrap.memoryPresets.map(\.id)
        )
        #expect(aggregate.activeSubjectID == bootstrap.selectedSubjectID)
        #expect(
            aggregate.activeConfigurationID
            == bootstrap.selectedMemoryPresetID
        )
    }

    @Test("Fresh installation defaults can enter the durable deletion flow")
    func freshInstallationDefaultsCanEnterDurableDeletionFlow() throws {
        let suiteName =
            "MemoMark.ConfigurationCenterInitialLibraryTests.delete.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let bootstrap = Self.makeBootstrapState(
            defaults: defaults,
            rootURL: rootURL
        )
        let preset = try #require(bootstrap.memoryPresets.first)
        let decision = ConfigurationLibraryActions().decide(
            .delete(
                ConfigurationLibraryDeletionRequest(
                    preset: preset,
                    aggregate: bootstrap.configurationLibrary,
                    subjectID: bootstrap.selectedSubjectID,
                    selectedConfigurationID:
                        bootstrap.selectedMemoryPresetID,
                    isCurrentConfigurationDirty: false,
                    visibleConfigurationIDs:
                        bootstrap.memoryPresets.map(\.id)
                )
            )
        )

        guard case .persistDeletion(let result) = decision else {
            Issue.record(
                "Expected a fresh default configuration to enter durable deletion"
            )
            return
        }
        #expect(result.deletedPreset.id == preset.id)
        #expect(
            result.candidate.subjects
                .flatMap(\.configurations)
                .contains(where: { $0.id == preset.id })
            == false
        )
    }

    @Test("Legacy installation defaults migrate to a canonical configuration library")
    func legacyInstallationDefaultsMigrateToCanonicalConfigurationLibrary() throws {
        let suiteName =
            "MemoMark.ConfigurationCenterInitialLibraryTests.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let state = ConfigurationCenterMockSeed.makeState()
        let legacy = V1SubjectLibraryRecord(
            subjects: state.subjects,
            selectedSubjectID: state.selectedSubjectID,
            memoryPresets: state.memoryPresets,
            selectedMemoryPresetID: state.selectedMemoryPresetID
        )
        defaults.set(
            try JSONEncoder().encode(legacy),
            forKey: "photomemo.v1.subjectLibrary"
        )

        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let bootstrap = Self.makeBootstrapState(
            defaults: defaults,
            rootURL: rootURL
        )
        let aggregate = try #require(
            bootstrap.configurationLibrary
        )

        #expect(
            aggregate.subjects.flatMap(\.configurations).map(\.id)
            == state.memoryPresets.map(\.id)
        )
        #expect(
            aggregate.activeConfigurationID
            == state.selectedMemoryPresetID
        )
    }

    @Test("Corrupted canonical storage does not synthesize default configurations")
    func corruptedCanonicalStorageDoesNotSynthesizeDefaults() throws {
        let suiteName =
            "MemoMark.ConfigurationCenterInitialLibraryTests.corrupt.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let libraryURL = rootURL
            .appendingPathComponent("ConfigurationLibrary", isDirectory: true)
        try FileManager.default.createDirectory(
            at: libraryURL,
            withIntermediateDirectories: true
        )
        try Data("corrupted-primary".utf8).write(
            to: libraryURL.appendingPathComponent("primary.json")
        )
        try Data("corrupted-last-known-good".utf8).write(
            to: libraryURL.appendingPathComponent("last-known-good.json")
        )

        let bootstrap = Self.makeBootstrapState(
            defaults: defaults,
            rootURL: rootURL
        )

        #expect(bootstrap.configurationLibrary == nil)
        #expect(bootstrap.configurationLibraryRecoveryFailed)
    }

    @Test("Corrupted canonical storage does not synthesize a readable legacy subject library")
    func corruptedCanonicalStorageDoesNotSynthesizeLegacyLibrary() throws {
        let suiteName =
            "MemoMark.ConfigurationCenterInitialLibraryTests.corruptLegacy.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let state = ConfigurationCenterMockSeed.makeState()
        let legacy = V1SubjectLibraryRecord(
            subjects: state.subjects,
            selectedSubjectID: state.selectedSubjectID,
            memoryPresets: state.memoryPresets,
            selectedMemoryPresetID: state.selectedMemoryPresetID
        )
        defaults.set(
            try JSONEncoder().encode(legacy),
            forKey: "photomemo.v1.subjectLibrary"
        )

        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let libraryURL = rootURL
            .appendingPathComponent("ConfigurationLibrary", isDirectory: true)
        try FileManager.default.createDirectory(
            at: libraryURL,
            withIntermediateDirectories: true
        )
        try Data("corrupted-primary".utf8).write(
            to: libraryURL.appendingPathComponent("primary.json")
        )
        try Data("corrupted-last-known-good".utf8).write(
            to: libraryURL.appendingPathComponent("last-known-good.json")
        )

        let bootstrap = Self.makeBootstrapState(
            defaults: defaults,
            rootURL: rootURL
        )

        #expect(bootstrap.configurationLibrary == nil)
        #expect(bootstrap.configurationLibraryRecoveryFailed)
        #expect(bootstrap.subjects == legacy.subjects)
    }
}

private extension ConfigurationCenterInitialLibraryTests {

    static func makeBootstrapState(
        defaults: UserDefaults,
        rootURL: URL
    ) -> ConfigurationBootstrapState {
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

        return SettingsRepository(
            settingsService: settings
        ).loadConfigurationBootstrapState()
    }
}
#endif
