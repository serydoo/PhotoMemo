#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum MemorySubjectExpressionSubjectSource:
    String,
    Codable,
    Hashable,
    CaseIterable,
    Identifiable {

    case displayName
    case shortName
    case relationshipRole
    case relationshipLabel

    var id: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .displayName:
            return "显示名称"
        case .shortName:
            return "昵称"
        case .relationshipRole:
            return "关系"
        case .relationshipLabel:
            return "关系备注"
        }
    }
}

struct MemorySubject:
    Identifiable,
    Codable,
    Hashable {

    struct Identity:
        Codable,
        Hashable {

        var displayName: String
        var shortName: String
        var avatarImagePath: String?
        var avatarBadgeImagePath: String?
        var avatarPreviewImagePath: String?

        init(
            displayName: String,
            shortName: String,
            avatarImagePath: String? = nil,
            avatarBadgeImagePath: String? = nil,
            avatarPreviewImagePath: String? = nil
        ) {
            self.displayName = displayName
            self.shortName = shortName
            self.avatarImagePath = avatarImagePath
            self.avatarBadgeImagePath = avatarBadgeImagePath
            self.avatarPreviewImagePath = avatarPreviewImagePath
        }
    }

    struct Relationship:
        Codable,
        Hashable {

        var role: String
        var label: String
    }

    struct TimeAnchor:
        Identifiable,
        Codable,
        Hashable {

        let id: UUID
        var title: String
        var date: Date
        var note: String
        var anchorType: AnchorType?
        var expressionStyle:
            MemoryAnchorExpressionStyle?

        init(
            id: UUID = UUID(),
            title: String,
            date: Date,
            note: String,
            anchorType: AnchorType? = nil,
            expressionStyle:
                MemoryAnchorExpressionStyle? = nil
        ) {
            self.id = id
            self.title = title
            self.date = date
            self.note = note
            self.anchorType = anchorType
            self.expressionStyle =
                expressionStyle
        }
    }

    let id: UUID
    var identity: Identity
    var relationship: Relationship
    var definition: String
    var referenceDate: Date
    var timeAnchors: [TimeAnchor]
    var activeTimeAnchorID: UUID?
    var expressionSubjectSource:
        MemorySubjectExpressionSubjectSource
    var behavior: MemoryBehavior
    var decorations: [DecorationAsset]

    init(
        id: UUID = UUID(),
        identity: Identity,
        relationship: Relationship,
        definition: String = "",
        referenceDate: Date,
        timeAnchors: [TimeAnchor] = [],
        activeTimeAnchorID: UUID? = nil,
        expressionSubjectSource:
            MemorySubjectExpressionSubjectSource = .displayName,
        behavior: MemoryBehavior,
        decorations: [DecorationAsset]
    ) {
        self.id = id
        self.identity = identity
        self.relationship = relationship
        self.definition = definition
        self.referenceDate = referenceDate
        self.timeAnchors = timeAnchors
        self.activeTimeAnchorID =
            activeTimeAnchorID
        self.expressionSubjectSource =
            expressionSubjectSource
        self.behavior = behavior
        self.decorations = decorations
    }
}

extension MemorySubject {

    var resolvedShortName: String {
        identity.shortName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
        ? identity.displayName
        : identity.shortName
    }

    var resolvedExpressionSubjectText: String {
        let candidates: [MemorySubjectExpressionSubjectSource: String] = [
            .displayName:
                identity.displayName,
            .shortName:
                identity.shortName,
            .relationshipRole:
                relationship.role,
            .relationshipLabel:
                relationship.label
        ]

        let preferred =
            normalizedOptionalText(
                candidates[
                    expressionSubjectSource
                ]
            )

        if let preferred {
            return preferred
        }

        return normalizedOptionalText(
            identity.displayName
        )
        ?? normalizedOptionalText(
            identity.shortName
        )
        ?? normalizedOptionalText(
            relationship.role
        )
        ?? normalizedOptionalText(
            relationship.label
        )
        ?? "记忆对象"
    }

    var primaryTimeAnchor: TimeAnchor? {
        if let activeTimeAnchorID {
            if let activeAnchor =
                timeAnchor(id: activeTimeAnchorID) {
                return activeAnchor
            }
        }

        return timeAnchor(
            named: behavior.primaryAnchor
        )
        ?? timeAnchors.first
    }

    func timeAnchor(
        id: UUID
    ) -> TimeAnchor? {
        timeAnchors.first {
            $0.id == id
        }
    }

    func timeAnchor(
        named title: String
    ) -> TimeAnchor? {
        timeAnchors.first {
            $0.title == title
        }
    }

    private func normalizedOptionalText(
        _ text: String?
    ) -> String? {
        guard let text else {
            return nil
        }

        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
#endif
