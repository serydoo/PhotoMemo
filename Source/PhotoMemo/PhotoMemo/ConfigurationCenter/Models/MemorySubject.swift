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

struct MemorySubjectExpressionSubjectResolution: Equatable {

    let text: String
    let source: MemorySubjectExpressionSubjectSource?
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
        resolvedExpressionSubject.text
    }

    var resolvedExpressionSubject:
        MemorySubjectExpressionSubjectResolution {
        Self.resolveExpressionSubject(
            source: expressionSubjectSource,
            displayName: identity.displayName,
            shortName: identity.shortName,
            relationshipRole: relationship.role,
            relationshipLabel: relationship.label
        )
    }

    static func resolveExpressionSubjectText(
        source: MemorySubjectExpressionSubjectSource,
        displayName: String,
        shortName: String,
        relationshipRole: String,
        relationshipLabel: String
    ) -> String {
        resolveExpressionSubject(
            source: source,
            displayName: displayName,
            shortName: shortName,
            relationshipRole: relationshipRole,
            relationshipLabel: relationshipLabel
        ).text
    }

    static func resolveExpressionSubject(
        source: MemorySubjectExpressionSubjectSource,
        displayName: String,
        shortName: String,
        relationshipRole: String,
        relationshipLabel: String
    ) -> MemorySubjectExpressionSubjectResolution {
        let candidates: [MemorySubjectExpressionSubjectSource: String] = [
            .displayName:
                displayName,
            .shortName:
                shortName,
            .relationshipRole:
                relationshipRole,
            .relationshipLabel:
                relationshipLabel
        ]

        let preferred =
            normalizedOptionalText(
                candidates[
                    source
                ]
            )

        if let preferred {
            return MemorySubjectExpressionSubjectResolution(
                text: preferred,
                source: source
            )
        }

        let fallbackSources: [MemorySubjectExpressionSubjectSource] = [
            .displayName,
            .shortName,
            .relationshipRole,
            .relationshipLabel
        ]

        for fallbackSource in fallbackSources {
            if let text = normalizedOptionalText(candidates[fallbackSource]) {
                return MemorySubjectExpressionSubjectResolution(
                    text: text,
                    source: fallbackSource
                )
            }
        }

        return MemorySubjectExpressionSubjectResolution(
            text: "记忆对象",
            source: nil
        )
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

    private static func normalizedOptionalText(
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
