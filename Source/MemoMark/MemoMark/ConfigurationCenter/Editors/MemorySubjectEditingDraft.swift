#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// The non-avatar portion of the Memory Subject editor's local transaction.
///
/// `MemorySubject` remains durable configuration truth. This value only keeps
/// fields that must change together while an inspector is visible, then
/// projects them through the editor's established session update boundary.
struct MemorySubjectEditingDraft: Equatable {

    static let maximumTimeAnchorCount = 5
    static let minimumTimeAnchorCount = 1

    var displayName: String
    var shortName: String
    var relationshipRole: String
    var relationshipLabel: String
    var definition: String
    var timeAnchors: [MemorySubject.TimeAnchor]
    var expressionSubjectSource: MemorySubjectExpressionSubjectSource
    var selectedTimeAnchorID: UUID?

    init(
        displayName: String = "",
        shortName: String = "",
        relationshipRole: String = "",
        relationshipLabel: String = "",
        definition: String = "",
        timeAnchors: [MemorySubject.TimeAnchor] = [],
        expressionSubjectSource: MemorySubjectExpressionSubjectSource = .displayName,
        selectedTimeAnchorID: UUID? = nil
    ) {
        self.displayName = displayName
        self.shortName = shortName
        self.relationshipRole = relationshipRole
        self.relationshipLabel = relationshipLabel
        self.definition = definition
        self.timeAnchors = timeAnchors
        self.expressionSubjectSource = expressionSubjectSource
        self.selectedTimeAnchorID = selectedTimeAnchorID
    }

    init(
        subject: MemorySubject,
        timeAnchors: [MemorySubject.TimeAnchor]
    ) {
        self.init(
            displayName: subject.identity.displayName,
            shortName: subject.identity.shortName,
            relationshipRole: subject.relationship.role,
            relationshipLabel: subject.relationship.label,
            definition: subject.definition,
            timeAnchors: timeAnchors,
            expressionSubjectSource: subject.expressionSubjectSource,
            selectedTimeAnchorID:
                subject.primaryTimeAnchor?.id
                ?? subject.timeAnchors.first?.id
                ?? timeAnchors.first?.id
        )
    }

    /// Returns the editor's compatibility defaults without mutating durable
    /// subject truth. The editor may present these anchors in a draft and only
    /// projects them to `MemorySubject` through its existing session boundary.
    static func defaultedTimeAnchors(
        for subject: MemorySubject,
        calendar: Calendar = .current
    ) -> [MemorySubject.TimeAnchor] {
        var anchors = subject.timeAnchors
        guard anchors.isEmpty else {
            return anchors
        }

        let referenceDate =
            subject.primaryTimeAnchor?.date
            ?? subject.referenceDate

        appendDefaultAnchorIfNeeded(
            title: "生日",
            date: referenceDate,
            note: "对象最重要的起点时间。",
            type: .birthday,
            anchors: &anchors
        )
        appendDefaultAnchorIfNeeded(
            title: "百天",
            date:
                calendar.date(
                    byAdding: .day,
                    value: 99,
                    to: referenceDate
                ) ?? referenceDate,
            note: "对象出生后的第 100 天。",
            type: .birthday,
            anchors: &anchors
        )
        appendDefaultAnchorIfNeeded(
            title: "重要日子",
            date:
                calendar.date(
                    byAdding: .month,
                    value: 6,
                    to: referenceDate
                ) ?? referenceDate,
            note: "自定义纪念日或重要时间点。",
            type: .custom,
            anchors: &anchors
        )

        return anchors
    }

    /// Adds one editor-only anchor when the configured cardinality allows it.
    /// Returning the new identifier keeps selection concerns at the call site
    /// while avoiding duplicate construction logic in SwiftUI views.
    @discardableResult
    mutating func appendTimeAnchor(
        now: Date = Date()
    ) -> UUID? {
        guard timeAnchors.count < Self.maximumTimeAnchorCount else {
            return nil
        }

        let anchor = MemorySubject.TimeAnchor(
            title: "新锚点 \(timeAnchors.count + 1)",
            date: now,
            note: "自定义时间锚点",
            anchorType: .custom,
            expressionStyle: .defaultStyle(for: .custom)
        ).normalizedForEditing
        timeAnchors.append(anchor)
        return anchor.id
    }

    /// Removes an editor anchor while preserving the invariant that at least
    /// one anchor remains. If the active anchor is removed, selection falls
    /// back to the first remaining anchor, matching the established editor
    /// behavior.
    @discardableResult
    mutating func removeTimeAnchor(
        id: UUID
    ) -> Bool {
        guard timeAnchors.count > Self.minimumTimeAnchorCount,
              timeAnchors.contains(where: { $0.id == id })
        else {
            return false
        }

        timeAnchors.removeAll { $0.id == id }
        if selectedTimeAnchorID == id {
            selectedTimeAnchorID = timeAnchors.first?.id
        }
        return true
    }

    func applyingCoreFields(
        to subject: inout MemorySubject
    ) {
        subject.identity.displayName = displayName
        subject.identity.shortName = shortName
        subject.relationship.role = relationshipRole
        subject.relationship.label = relationshipLabel
        subject.definition = definition
        subject.timeAnchors = timeAnchors
        subject.expressionSubjectSource = expressionSubjectSource

        guard let selectedAnchor = timeAnchors.first(where: {
            $0.id == selectedTimeAnchorID
        }) else {
            return
        }

        subject.activeTimeAnchorID = selectedAnchor.id
        subject.behavior.primaryAnchor = selectedAnchor.title
        subject.referenceDate = selectedAnchor.date
    }

    private static func appendDefaultAnchorIfNeeded(
        title: String,
        date: Date,
        note: String,
        type: AnchorType,
        anchors: inout [MemorySubject.TimeAnchor]
    ) {
        guard !anchors.contains(where: { $0.title == title }) else {
            return
        }

        anchors.append(
            MemorySubject.TimeAnchor(
                title: title,
                date: date,
                note: note,
                anchorType: type,
                expressionStyle: .defaultStyle(for: type)
            )
        )
    }
}
#endif
