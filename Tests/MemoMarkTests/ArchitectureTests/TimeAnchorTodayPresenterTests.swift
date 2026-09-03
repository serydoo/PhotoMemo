#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 time anchor today presenter")
struct TimeAnchorTodayPresenterTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("birthday presents the subject age after the anchor date")
    func birthdayPresentsCurrentAge() {
        let anchor = MemorySubject.TimeAnchor(
            title: "途途生日",
            date: date(2025, 5, 26),
            note: "生日",
            anchorType: .birthday
        )

        let presentation = TimeAnchorTodayPresenter.presentation(
            anchor: anchor,
            subjectName: "途途",
            referenceDate: date(2026, 8, 9),
            calendar: calendar
        )

        #expect(presentation.title == "途途生日")
        #expect(presentation.value == "今天 · 1岁2个月14天")
        #expect(presentation.accessibilityText.contains("途途生日"))
    }

    @Test("future anchor presents a countdown without inventing a prose style")
    func futureAnchorPresentsCountdown() {
        let anchor = MemorySubject.TimeAnchor(
            title: "重要日子",
            date: date(2026, 8, 19),
            note: "自定义",
            anchorType: .custom
        )

        let presentation = TimeAnchorTodayPresenter.presentation(
            anchor: anchor,
            subjectName: "途途",
            referenceDate: date(2026, 8, 9),
            calendar: calendar
        )

        #expect(presentation.value == "还有10天")
    }

    @Test("anchor day is described as today")
    func anchorDayPresentsToday() {
        let anchor = MemorySubject.TimeAnchor(
            title: "重要日子",
            date: date(2026, 8, 9),
            note: "自定义",
            anchorType: .custom
        )

        let presentation = TimeAnchorTodayPresenter.presentation(
            anchor: anchor,
            subjectName: "途途",
            referenceDate: date(2026, 8, 9),
            calendar: calendar
        )

        #expect(presentation.value == "就是今天")
    }

    @Test("Photos action describes the album as a save result instead of a deep-link destination")
    func photoLibraryActionDoesNotPromiseAlbumDeepLink() {
        let link = TaskPhotoLibraryLink(
            albumName: "整理水印相册",
            assetIdentifier: "asset-local-id"
        )

        #expect(link.actionTitle == "打开照片 App 查看")
        #expect(link.saveDestinationText == "已保存到「整理水印相册」")
        #expect(link.accessibilityHint == "打开照片 App 后查看「整理水印相册」")
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: 12
            )
        )!
    }
}
#endif
