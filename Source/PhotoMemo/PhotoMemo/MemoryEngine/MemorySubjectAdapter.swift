import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemorySubjectAdapter {

    private static let unspecifiedReferenceDate =
        Date(timeIntervalSince1970: 0)

    static func adapt(
        profile: PersonalProfile,
        anchors: [Anchor],
        selectedAnchorID: UUID? = nil,
        referenceDate: Date? = nil
    ) -> MemorySubject {
        let normalizedProfile =
            profile.normalized
        let subjectName =
            normalizedProfile.babyNickname
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        let resolvedName =
            subjectName.isEmpty
            ? normalizedProfile.resolvedRelationshipLabel
            : subjectName
        let resolvedReferenceDate =
            referenceDate
            ?? normalizedProfile.babyBirthday
            ?? anchors.first?.date
            ?? unspecifiedReferenceDate
        let primaryAnchor =
            anchors.first {
                $0.id == selectedAnchorID
            } ?? anchors.first

        return MemorySubject(
            identity:
                .init(
                    displayName: resolvedName,
                    shortName: resolvedName,
                    avatarImagePath: nil
                ),
            relationship:
                .init(
                    role: "家庭",
                    label:
                        normalizedProfile
                        .resolvedRelationshipLabel
                ),
            definition:
                "\(normalizedProfile.resolvedRelationshipLabel)的长期记忆对象。",
            referenceDate: resolvedReferenceDate,
            timeAnchors:
                anchors.map {
                    MemorySubject.TimeAnchor(
                        id: $0.id,
                        title: $0.title,
                        date: $0.date,
                        note: $0.type.displayName,
                        anchorType: $0.type,
                        expressionStyle:
                            $0.expressionStyle
                    )
                },
            activeTimeAnchorID:
                primaryAnchor?.id
                ?? anchors.first?.id,
            expressionSubjectSource:
                .displayName,
            behavior:
                MemoryBehavior(
                    primaryAnchor:
                        primaryAnchor?.title
                        ?? anchors.first?.title
                        ?? "时间锚点",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .autoMatch,
                    memoryExpression:
                        MemoryExpression(
                            title: "默认记忆表达",
                            blocks: [
                                .text(resolvedName)
                            ]
                        )
                ),
            decorations: []
        )
    }
}
#endif
