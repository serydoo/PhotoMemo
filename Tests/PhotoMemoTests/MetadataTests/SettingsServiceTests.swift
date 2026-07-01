import Foundation
import Testing
@testable import PhotoMemo

@Suite("SettingsService")
struct SettingsServiceTests {

    @Test("Persists selected album title alongside the selected album identifier")
    @MainActor
    func persistsSelectedAlbumTitleAlongsideIdentifier() {

        let suiteName =
            "PhotoMemo.SettingsServiceTests.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let settings =
            SettingsService(defaults: defaults)

        settings.saveEditorState(
            selectedAlbumIdentifier: "album-123",
            selectedAlbumTitle: "家庭相册"
        )

        let reloadedSettings =
            SettingsService(defaults: defaults)

        #expect(reloadedSettings.selectedAlbumIdentifier == "album-123")
        #expect(reloadedSettings.selectedAlbumTitle == "家庭相册")

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("loadV1BootstrapReadState preserves typed badge read failures while still surfacing editor-state values")
    @MainActor
    func loadV1BootstrapReadStatePreservesTypedBadgeFailures() throws {

        let suiteName =
            "PhotoMemo.SettingsServiceTests.bootstrapReadState.\(UUID().uuidString)"

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
            Data("not-a-badge".utf8),
            forKey: "photomemo.selectedBadge"
        )
        defaults.set(
            "album-typed-read",
            forKey: "photomemo.selectedAlbumIdentifier"
        )
        defaults.set(
            "家庭相册",
            forKey: "photomemo.selectedAlbumTitle"
        )

        let settings =
            SettingsService(defaults: defaults)
        let readState =
            settings.loadV1BootstrapReadState()

        switch readState.badgeResult {
        case .decodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.selectedBadge"
            )
            #expect(
                failure.payloadByteCount
                == Data("not-a-badge".utf8).count
            )

        default:
            Issue.record(
                "Expected the typed bootstrap read to preserve the corrupted badge decoding failure."
            )
        }

        #expect(
            readState.selectedAlbumIdentifier
            == "album-typed-read"
        )
        #expect(
            readState.selectedAlbumTitle
            == "家庭相册"
        )
    }

    @Test("loadV1BootstrapReadState restores the persisted memory subject")
    @MainActor
    func loadV1BootstrapReadStateRestoresPersistedMemorySubject() throws {

        let suiteName =
            "PhotoMemo.SettingsServiceTests.bootstrapSubject.\(UUID().uuidString)"

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
        let subject =
            try #require(
                ConfigurationCenterState.mock.selectedSubject
            )

        settings.saveSelectedMemorySubject(
            subject
        )

        let readState =
            SettingsService(defaults: defaults)
            .loadV1BootstrapReadState()

        switch readState.subjectResult {
        case .success(let restoredSubject):
            #expect(restoredSubject == subject)

        default:
            Issue.record(
                "Expected persisted memory subject to load successfully."
            )
        }
    }
}
