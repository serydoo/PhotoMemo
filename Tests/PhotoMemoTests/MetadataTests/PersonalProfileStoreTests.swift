import Foundation
import Testing
@testable import PhotoMemo

@Suite("PersonalProfileStore")
struct PersonalProfileStoreTests {

    @Test("Completing first run persists profile and backfills compatible settings")
    @MainActor
    func completingFirstRunPersistsProfileAndBackfillsCompatibleSettings() {

        let suiteName =
            "PhotoMemo.PersonalProfileStoreTests.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let store =
            PersonalProfileStore(defaults: defaults)

        #expect(store.requiresFirstRun == true)

        let birthday =
            Date(timeIntervalSince1970: 1_735_689_600)

        store.completeFirstRun(
            with: PersonalProfile(
                relationshipRole: .father,
                customRelationshipLabel: "",
                babyNickname: "小满",
                babyBirthday: birthday,
                defaultStyleIdentifier: "slot1",
                defaultSaveDestination: .photoMemoAlbum,
                selectedAlbumIdentifier: "",
                selectedAlbumTitle: ""
            )
        )

        let reloadedStore =
            PersonalProfileStore(defaults: defaults)
        let reloadedSettings =
            SettingsService(defaults: defaults)

        #expect(reloadedStore.requiresFirstRun == false)
        #expect(reloadedStore.profile.relationshipRole == .father)
        #expect(reloadedStore.profile.babyNickname == "小满")
        #expect(reloadedStore.profile.babyBirthday == birthday)
        #expect(reloadedStore.profile.defaultStyleIdentifier == "slot1")
        #expect(reloadedStore.profile.defaultSaveDestination == .photoMemoAlbum)

        let birthdayAnchor =
            reloadedSettings.anchors.first {
                $0.type == .birthday
            }

        #expect(birthdayAnchor?.title == "小满")
        #expect(birthdayAnchor?.date == birthday)
        #expect(reloadedSettings.selectedAnchorIDString == birthdayAnchor?.id.uuidString)
        #expect(reloadedSettings.activeConfigurationSlotID.rawValue == "slot1")
        #expect(reloadedSettings.selectedAlbumIdentifier == "")

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Backfills an existing birthday anchor and album choice into the new profile")
    @MainActor
    func backfillsExistingBirthdayAnchorAndAlbumChoiceIntoTheNewProfile() {

        let suiteName =
            "PhotoMemo.PersonalProfileStoreTests.\(UUID().uuidString)"

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

        let birthday =
            Date(timeIntervalSince1970: 1_704_067_200)
        let birthdayAnchor =
            Anchor(
                type: .birthday,
                title: "糖糖",
                date: birthday
            )

        settings.anchors = [birthdayAnchor]
        settings.saveAnchors()
        settings.activeConfigurationSlotID = .slot3
        settings.saveConfigurationSlots()
        settings.saveEditorState(
            selectedAnchorID: birthdayAnchor.id,
            selectedAlbumIdentifier: "album-42",
            selectedAlbumTitle: "家庭相册"
        )

        let store =
            PersonalProfileStore(defaults: defaults)

        #expect(store.requiresFirstRun == true)
        #expect(store.profile.babyNickname == "糖糖")
        #expect(store.profile.babyBirthday == birthday)
        #expect(store.profile.defaultStyleIdentifier == "slot3")
        #expect(store.profile.defaultSaveDestination == .selectedAlbum)
        #expect(store.profile.selectedAlbumIdentifier == "album-42")
        #expect(store.profile.selectedAlbumTitle == "家庭相册")

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Completing first run with system library keeps the system destination sentinel")
    @MainActor
    func completingFirstRunWithSystemLibraryPersistsSystemDestination() {

        let suiteName =
            "PhotoMemo.PersonalProfileStoreTests.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let store =
            PersonalProfileStore(defaults: defaults)

        store.completeFirstRun(
            with: PersonalProfile(
                relationshipRole: .mother,
                customRelationshipLabel: "",
                babyNickname: "可乐",
                babyBirthday: Date(timeIntervalSince1970: 1_725_206_400),
                defaultStyleIdentifier: "slot1",
                defaultSaveDestination: .systemLibrary,
                selectedAlbumIdentifier: "",
                selectedAlbumTitle: ""
            )
        )

        let reloadedStore =
            PersonalProfileStore(defaults: defaults)
        let reloadedSettings =
            SettingsService(defaults: defaults)

        #expect(reloadedStore.profile.defaultSaveDestination == .systemLibrary)
        #expect(
            reloadedSettings.selectedAlbumIdentifier
            == PhotoMemoAlbumSelection.systemLibraryIdentifier
        )
        #expect(reloadedSettings.selectedAlbumTitle == "系统相册")

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Updating the profile store save destination persists selected album details")
    @MainActor
    func updatingProfileStoreSaveDestinationPersistsSelectedAlbumDetails() {

        let suiteName =
            "PhotoMemo.PersonalProfileStoreTests.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let store =
            PersonalProfileStore(defaults: defaults)

        store.completeFirstRun(
            with: PersonalProfile()
        )

        store.updateSaveDestination(
            defaultSaveDestination: .selectedAlbum,
            selectedAlbumIdentifier: "album-88",
            selectedAlbumTitle: "成长记录"
        )

        let reloadedStore =
            PersonalProfileStore(defaults: defaults)
        let reloadedSettings =
            SettingsService(defaults: defaults)

        #expect(reloadedStore.profile.defaultSaveDestination == .selectedAlbum)
        #expect(reloadedStore.profile.selectedAlbumIdentifier == "album-88")
        #expect(reloadedStore.profile.selectedAlbumTitle == "成长记录")
        #expect(reloadedSettings.selectedAlbumIdentifier == "album-88")
        #expect(reloadedSettings.selectedAlbumTitle == "成长记录")

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Updating the profile store default style persists the selected style slot")
    @MainActor
    func updatingProfileStoreDefaultStylePersistsSelectedStyleSlot() {

        let suiteName =
            "PhotoMemo.PersonalProfileStoreTests.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let store =
            PersonalProfileStore(defaults: defaults)

        store.completeFirstRun(
            with: PersonalProfile()
        )

        store.updateDefaultStyleIdentifier("slot3")

        let reloadedStore =
            PersonalProfileStore(defaults: defaults)
        let reloadedSettings =
            SettingsService(defaults: defaults)

        #expect(reloadedStore.profile.defaultStyleIdentifier == "slot3")
        #expect(reloadedSettings.activeConfigurationSlotID == .slot3)

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }
}
