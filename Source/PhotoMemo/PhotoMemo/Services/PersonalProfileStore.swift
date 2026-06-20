import Foundation
import Combine

#if !PHOTOMEMO_SHARE_EXTENSION
@MainActor
final class PersonalProfileStore:
    ObservableObject {

    private enum Keys {

        static let profile =
            "photomemo.personalProfile"

        static let firstRunCompleted =
            "photomemo.personalProfile.firstRunCompleted"
    }

    private let defaults: UserDefaults

    @Published
    private(set) var profile:
        PersonalProfile

    @Published
    private(set) var requiresFirstRun: Bool

    init(
        defaults: UserDefaults? = nil
    ) {
        let resolvedDefaults =
            defaults
            ?? PhotoMemoSharedContainer
            .sharedUserDefaults

        self.defaults = resolvedDefaults

        let persistedProfile =
            Self.loadProfile(
                from: resolvedDefaults
            )
        let backfilledProfile =
            Self.backfilledProfile(
                from: resolvedDefaults
            )

        self.profile =
            persistedProfile
            ?? backfilledProfile
        self.requiresFirstRun =
            !resolvedDefaults.bool(
                forKey:
                    Keys.firstRunCompleted
            )
    }

    func completeFirstRun(
        with profile: PersonalProfile
    ) {

        let normalizedProfile =
            profile.normalized

        self.profile =
            normalizedProfile
        requiresFirstRun = false

        persist(
            profile: normalizedProfile,
            isCompleted: true
        )
        applyCompatibilitySettings(
            using: normalizedProfile
        )
    }
}

private extension PersonalProfileStore {

    func persist(
        profile: PersonalProfile,
        isCompleted: Bool
    ) {

        if let data =
            try? JSONEncoder().encode(
                profile
            ) {
            defaults.set(
                data,
                forKey: Keys.profile
            )
        }

        defaults.set(
            isCompleted,
            forKey: Keys.firstRunCompleted
        )
    }

    func applyCompatibilitySettings(
        using profile: PersonalProfile
    ) {

        let settings =
            SettingsService(defaults: defaults)

        let defaultSlotID =
            WorkspaceConfigurationSlotID(
                rawValue:
                    profile.defaultStyleIdentifier
            ) ?? .slot1

        settings.activeConfigurationSlotID =
            defaultSlotID

        if defaultSlotID == .slot1,
           settings.configurationSlot(
            for: .slot1
           )?.resolvedCustomTitle == nil {
            settings.renameConfigurationSlot(
                .slot1,
                customTitle:
                    PersonalProfile
                    .recommendedStyleTitle
            )
        }

        let birthdayAnchor =
            upsertBirthdayAnchor(
                using: profile,
                settings: settings
            )

        let albumIdentifier =
            compatibilityAlbumIdentifier(
                for: profile
            )
        let albumTitle =
            compatibilityAlbumTitle(
                for: profile
            )

        settings.selectedAlbumIdentifier =
            albumIdentifier
        settings.selectedAlbumTitle =
            albumTitle

        settings.saveAnchors()
        settings.saveConfigurationSlots()
        settings.saveEditorState(
            selectedAnchorID:
                birthdayAnchor?.id,
            selectedAlbumIdentifier:
                albumIdentifier,
            selectedAlbumTitle:
                albumTitle
        )
        settings.saveAll()
    }

    func upsertBirthdayAnchor(
        using profile: PersonalProfile,
        settings: SettingsService
    ) -> Anchor? {

        guard let babyBirthday =
            profile.babyBirthday
        else {
            settings.selectedAnchorIDString = ""
            return nil
        }

        let anchorTitle =
            profile.babyNickname
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
            ? AnchorType.birthday
            .suggestedTitle
            : profile.babyNickname
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let existingIndex =
            settings.anchors.firstIndex(
                where: {
                    $0.type == .birthday
                }
            ) {

            settings.anchors[existingIndex] =
                Anchor(
                    id:
                        settings.anchors[
                            existingIndex
                        ].id,
                    type: .birthday,
                    title: anchorTitle,
                    date: babyBirthday,
                    isCountdown: false
                )

            settings.selectedAnchorIDString =
                settings.anchors[
                    existingIndex
                ].id.uuidString

            return settings.anchors[
                existingIndex
            ]
        }

        let anchor =
            Anchor(
                type: .birthday,
                title: anchorTitle,
                date: babyBirthday,
                isCountdown: false
            )

        settings.anchors.append(anchor)
        settings.selectedAnchorIDString =
            anchor.id.uuidString

        return anchor
    }

    func compatibilityAlbumIdentifier(
        for profile: PersonalProfile
    ) -> String {

        switch profile.defaultSaveDestination {

        case .photoMemoAlbum:
            return ""

        case .systemLibrary:
            return PhotoMemoAlbumSelection
                .systemLibraryIdentifier

        case .selectedAlbum:
            return profile.selectedAlbumIdentifier
        }
    }

    func compatibilityAlbumTitle(
        for profile: PersonalProfile
    ) -> String {

        switch profile.defaultSaveDestination {

        case .photoMemoAlbum:
            return ""

        case .systemLibrary:
            return "系统相册"

        case .selectedAlbum:
            return profile.selectedAlbumTitle
        }
    }

    static func loadProfile(
        from defaults: UserDefaults
    ) -> PersonalProfile? {

        guard
            let data = defaults.data(
                forKey: Keys.profile
            ),
            let profile =
                try? JSONDecoder().decode(
                    PersonalProfile.self,
                    from: data
                )
        else {
            return nil
        }

        return profile.normalized
    }

    static func backfilledProfile(
        from defaults: UserDefaults
    ) -> PersonalProfile {

        let settings =
            SettingsService(defaults: defaults)

        let birthdayAnchor =
            settings.anchors.first {
                $0.type == .birthday
            }

        let albumIdentifier =
            settings.selectedAlbumIdentifier
        let defaultSaveDestination:
            PersonalProfileSaveDestination

        if albumIdentifier
            == PhotoMemoAlbumSelection
            .systemLibraryIdentifier {
            defaultSaveDestination =
                .systemLibrary
        } else if albumIdentifier
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            defaultSaveDestination =
                .photoMemoAlbum
        } else {
            defaultSaveDestination =
                .selectedAlbum
        }

        return PersonalProfile(
            relationshipRole: .familyMember,
            customRelationshipLabel: "",
            babyNickname:
                birthdayAnchor?.title ?? "",
            babyBirthday:
                birthdayAnchor?.date,
            defaultStyleIdentifier:
                settings
                .activeConfigurationSlotID
                .rawValue,
            defaultSaveDestination:
                defaultSaveDestination,
            selectedAlbumIdentifier:
                settings
                .selectedAlbumIdentifier,
            selectedAlbumTitle:
                settings.selectedAlbumTitle
        )
    }
}
#endif
