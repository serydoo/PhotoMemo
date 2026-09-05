#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Memory Subject editing draft")
struct MemorySubjectEditingDraftTests {

    @Test("draft projects identity, expression, and active anchor as one edit")
    func draftProjectsCoreFieldsAndSelectedAnchor() {
        let originalAnchor = anchor(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "生日",
            date: Date(timeIntervalSince1970: 1_000)
        )
        let selectedAnchor = anchor(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "入园",
            date: Date(timeIntervalSince1970: 2_000)
        )
        var subject = makeSubject(anchors: [originalAnchor])
        let draft = MemorySubjectEditingDraft(
            displayName: "小宝",
            shortName: "宝宝",
            relationshipRole: "孩子",
            relationshipLabel: "我们的小朋友",
            definition: "成长记录",
            timeAnchors: [originalAnchor, selectedAnchor],
            expressionSubjectSource: .relationshipLabel,
            selectedTimeAnchorID: selectedAnchor.id
        )

        draft.applyingCoreFields(to: &subject)

        #expect(subject.identity.displayName == "小宝")
        #expect(subject.identity.shortName == "宝宝")
        #expect(subject.relationship.role == "孩子")
        #expect(subject.relationship.label == "我们的小朋友")
        #expect(subject.definition == "成长记录")
        #expect(subject.timeAnchors == [originalAnchor, selectedAnchor])
        #expect(subject.expressionSubjectSource == .relationshipLabel)
        #expect(subject.activeTimeAnchorID == selectedAnchor.id)
        #expect(subject.behavior.primaryAnchor == "入园")
        #expect(subject.referenceDate == selectedAnchor.date)
    }

    @Test("missing selected anchor preserves the prior active anchor facts")
    func missingSelectedAnchorPreservesPriorActiveAnchorFacts() {
        let activeAnchor = anchor(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "生日",
            date: Date(timeIntervalSince1970: 3_000)
        )
        var subject = makeSubject(anchors: [activeAnchor])
        let draft = MemorySubjectEditingDraft(
            displayName: "新名称",
            timeAnchors: [],
            selectedTimeAnchorID: UUID()
        )

        draft.applyingCoreFields(to: &subject)

        #expect(subject.identity.displayName == "新名称")
        #expect(subject.timeAnchors.isEmpty)
        #expect(subject.activeTimeAnchorID == activeAnchor.id)
        #expect(subject.behavior.primaryAnchor == "生日")
        #expect(subject.referenceDate == activeAnchor.date)
    }

    @Test("loading a newly selected subject replaces every draft field together")
    func loadingNewlySelectedSubjectReplacesEveryDraftFieldTogether() {
        let firstAnchor = anchor(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "生日",
            date: Date(timeIntervalSince1970: 4_000)
        )
        let secondAnchor = anchor(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            title: "入园",
            date: Date(timeIntervalSince1970: 5_000)
        )
        let firstSubject = makeSubject(anchors: [firstAnchor])
        var secondSubject = makeSubject(anchors: [secondAnchor])
        secondSubject.identity = .init(
            displayName: "第二个对象",
            shortName: "小二"
        )
        secondSubject.relationship = .init(
            role: "同学",
            label: "幼儿园"
        )
        secondSubject.definition = "第二段回忆"
        secondSubject.expressionSubjectSource = .shortName

        let firstDraft = MemorySubjectEditingDraft(
            subject: firstSubject,
            timeAnchors: [firstAnchor]
        )
        let loadedDraft = MemorySubjectEditingDraft(
            subject: secondSubject,
            timeAnchors: [secondAnchor]
        )

        #expect(firstDraft.displayName == "原名称")
        #expect(loadedDraft.displayName == "第二个对象")
        #expect(loadedDraft.shortName == "小二")
        #expect(loadedDraft.relationshipRole == "同学")
        #expect(loadedDraft.relationshipLabel == "幼儿园")
        #expect(loadedDraft.definition == "第二段回忆")
        #expect(loadedDraft.timeAnchors == [secondAnchor])
        #expect(loadedDraft.expressionSubjectSource == .shortName)
        #expect(loadedDraft.selectedTimeAnchorID == secondAnchor.id)
    }

    @Test("draft supplies the stable default time anchors for a subject without anchors")
    func draftSuppliesDefaultTimeAnchors() throws {
        let referenceDate = Date(timeIntervalSince1970: 10_000)
        var subject = makeSubject(anchors: [])
        subject.referenceDate = referenceDate
        let calendar = Calendar(identifier: .gregorian)

        let anchors = MemorySubjectEditingDraft.defaultedTimeAnchors(
            for: subject,
            calendar: calendar
        )

        let hundredthDay = try #require(
            calendar.date(
                byAdding: .day,
                value: 99,
                to: referenceDate
            )
        )
        let halfYear = try #require(
            calendar.date(
                byAdding: .month,
                value: 6,
                to: referenceDate
            )
        )

        #expect(anchors.map(\.title) == ["生日", "百天", "时间锚点"])
        #expect(anchors[0].date == referenceDate)
        #expect(anchors[1].date == hundredthDay)
        #expect(anchors[2].date == halfYear)
    }

    @Test("draft enforces time anchor cardinality and keeps selection valid")
    func draftEnforcesTimeAnchorCardinalityAndSelection() {
        let anchors = (0..<5).map { index in
            anchor(
                id: UUID(),
                title: "锚点 \(index + 1)",
                date: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        var draft = MemorySubjectEditingDraft(
            timeAnchors: anchors,
            selectedTimeAnchorID: anchors[2].id
        )

        #expect(draft.appendTimeAnchor(now: Date()) == nil)
        #expect(draft.timeAnchors.count == 5)
        let removedSelectedAnchor = draft.removeTimeAnchor(id: anchors[2].id)
        #expect(removedSelectedAnchor)
        #expect(draft.timeAnchors.count == 4)
        #expect(draft.selectedTimeAnchorID == draft.timeAnchors.first?.id)
        let removedMissingAnchor = draft.removeTimeAnchor(id: UUID())
        #expect(!removedMissingAnchor)
        let firstAnchorID = draft.timeAnchors.first!.id
        let removedFirstAnchor = draft.removeTimeAnchor(id: firstAnchorID)
        #expect(removedFirstAnchor)
        #expect(draft.timeAnchors.count == 3)
    }

    private func makeSubject(
        anchors: [MemorySubject.TimeAnchor]
    ) -> MemorySubject {
        MemorySubject(
            identity: .init(displayName: "原名称", shortName: "原昵称"),
            relationship: .init(role: "家人", label: "原称呼"),
            definition: "原定义",
            referenceDate: anchors.first?.date ?? .distantPast,
            timeAnchors: anchors,
            activeTimeAnchorID: anchors.first?.id,
            behavior: .init(
                primaryAnchor: anchors.first?.title ?? "",
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )
    }

    private func anchor(
        id: UUID,
        title: String,
        date: Date
    ) -> MemorySubject.TimeAnchor {
        MemorySubject.TimeAnchor(
            id: id,
            title: title,
            date: date,
            note: "",
            anchorType: .birthday,
            expressionStyle: .defaultStyle(for: .birthday)
        )
    }
}
#endif
