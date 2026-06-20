import Foundation

enum PersonalRelationshipRole:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case mother

    case father

    case familyMember

    case custom
}

extension PersonalRelationshipRole {

    var title: String {

        switch self {

        case .mother:
            return "妈妈"

        case .father:
            return "爸爸"

        case .familyMember:
            return "家人"

        case .custom:
            return "自定义"
        }
    }
}

enum PersonalProfileSaveDestination:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case systemLibrary

    case photoMemoAlbum

    case selectedAlbum
}

struct PersonalProfile:
    Codable,
    Hashable {

    var relationshipRole:
        PersonalRelationshipRole

    var customRelationshipLabel: String

    var babyNickname: String

    var babyBirthday: Date?

    var defaultStyleIdentifier: String

    var defaultSaveDestination:
        PersonalProfileSaveDestination

    var selectedAlbumIdentifier: String

    var selectedAlbumTitle: String

    init(
        relationshipRole:
            PersonalRelationshipRole = .familyMember,
        customRelationshipLabel: String = "",
        babyNickname: String = "",
        babyBirthday: Date? = nil,
        defaultStyleIdentifier: String = "slot1",
        defaultSaveDestination:
            PersonalProfileSaveDestination = .photoMemoAlbum,
        selectedAlbumIdentifier: String = "",
        selectedAlbumTitle: String = ""
    ) {
        self.relationshipRole =
            relationshipRole
        self.customRelationshipLabel =
            customRelationshipLabel
        self.babyNickname = babyNickname
        self.babyBirthday = babyBirthday
        self.defaultStyleIdentifier =
            defaultStyleIdentifier
        self.defaultSaveDestination =
            defaultSaveDestination
        self.selectedAlbumIdentifier =
            selectedAlbumIdentifier
        self.selectedAlbumTitle =
            selectedAlbumTitle
    }
}

extension PersonalProfile {

    static let recommendedStyleTitle =
        "宝宝成长"

    var resolvedRelationshipLabel: String {

        let trimmedCustomLabel =
            customRelationshipLabel
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if relationshipRole == .custom,
           !trimmedCustomLabel.isEmpty {
            return trimmedCustomLabel
        }

        return relationshipRole.title
    }

    var normalized: PersonalProfile {

        PersonalProfile(
            relationshipRole:
                relationshipRole,
            customRelationshipLabel:
                customRelationshipLabel
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            babyNickname:
                babyNickname
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            babyBirthday:
                babyBirthday,
            defaultStyleIdentifier:
                defaultStyleIdentifier
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
                ? "slot1"
                : defaultStyleIdentifier
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            defaultSaveDestination:
                defaultSaveDestination,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            selectedAlbumTitle:
                selectedAlbumTitle
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
        )
    }
}
