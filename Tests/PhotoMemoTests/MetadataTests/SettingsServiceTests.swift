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
}
