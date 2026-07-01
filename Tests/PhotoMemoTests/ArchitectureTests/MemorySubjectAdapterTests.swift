#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Memory subject adapter")
struct MemorySubjectAdapterTests {

    @Test("adapts a personal profile and anchors into a memory subject foundation")
    func adaptsProfileIntoMemorySubject() {
        let birthday = Date(timeIntervalSince1970: 1_717_257_600)
        let travel = Date(timeIntervalSince1970: 1_743_292_800)
        let profile =
            PersonalProfile(
                relationshipRole: .mother,
                babyNickname: "途途",
                babyBirthday: birthday
            )
        let anchors = [
            Anchor(
                type: .birthday,
                title: "生日",
                date: birthday
            ),
            Anchor(
                type: .custom,
                title: "第一次旅行",
                date: travel
            )
        ]

        let subject =
            MemorySubjectAdapter.adapt(
                profile: profile,
                anchors: anchors,
                selectedAnchorID: anchors[1].id
            )

        #expect(subject.identity.displayName == "途途")
        #expect(subject.identity.shortName == "途途")
        #expect(subject.relationship.role == "家庭")
        #expect(subject.relationship.label == "妈妈")
        #expect(subject.referenceDate == birthday)
        #expect(subject.timeAnchors.count == 2)
        #expect(subject.primaryTimeAnchor?.title == "第一次旅行")
        #expect(subject.behavior.primaryAnchor == "第一次旅行")
        #expect(subject.activeTimeAnchorID == anchors[1].id)
        #expect(subject.timeAnchors.first?.anchorType == .birthday)
        #expect(subject.expressionSubjectSource == .displayName)
    }
}
#endif
