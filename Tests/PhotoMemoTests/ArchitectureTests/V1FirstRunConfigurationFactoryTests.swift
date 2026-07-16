import Foundation
import Testing
@testable import PhotoMemo

struct V1FirstRunConfigurationFactoryTests {

    @Test
    func firstRunSubjectUsesUserNameAndOneNaturalBirthdayAnchor() throws {
        let date = try #require(
            Calendar(identifier: .gregorian).date(
                from: DateComponents(
                    year: 2024,
                    month: 5,
                    day: 20
                )
            )
        )

        let subject = V1SubjectLibraryFactory.makeFirstRunSubject(
            name: "  示例昵称  ",
            birthday: date
        )

        #expect(subject.identity.displayName == "示例昵称")
        #expect(subject.identity.shortName == "示例昵称")
        #expect(subject.referenceDate == date)
        #expect(subject.timeAnchors.count == 3)

        let anchor = try #require(subject.timeAnchors.first)
        #expect(anchor.title == "生日")
        #expect(anchor.date == date)
        #expect(anchor.anchorType == .birthday)
        #expect(anchor.expressionStyle == .birthdayNatural)
        #expect(subject.activeTimeAnchorID == anchor.id)
        #expect(subject.behavior.primaryAnchor == anchor.title)
        #expect(subject.timeAnchors[1].title == "百天")
        #expect(subject.timeAnchors[1].anchorType == .birthday)
        #expect(subject.timeAnchors[1].date == Calendar.current.date(
            byAdding: .day,
            value: 99,
            to: date
        ))
        #expect(subject.timeAnchors[2].title == "重要日子")
        #expect(subject.timeAnchors[2].anchorType == .custom)
    }

    @Test
    func firstRunSubjectFallsBackToMemorySubjectName() {
        let subject = V1SubjectLibraryFactory.makeFirstRunSubject(
            name: "   ",
            birthday: Date(timeIntervalSince1970: 0)
        )

        #expect(subject.identity.displayName == "记忆主角")
        #expect(subject.identity.shortName == "记忆主角")
    }
}
