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
            title: "时间锚点",
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
            title: "时间锚点",
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

    @Test("one simulated time anchor is localized across before, on, and after contexts")
    func simulatedTimeAnchorIsLocalizedAcrossTemporalContexts() {
        let anchor = MemorySubject.TimeAnchor(
            title: "途途生日",
            date: date(2025, 5, 26),
            note: "生日",
            anchorType: .birthday
        )

        let expectedAfter: [MemoMarkLanguage: String] = [
            .simplifiedChinese: "今天 · 1岁2个月14天",
            .english: "Today · 1 year, 2 months, and 14 days",
            .japanese: "今日 · 1歳2か月14日",
            .korean: "오늘 · 1년 2개월 14일"
        ]

        for language in MemoMarkLanguage.allCases {
            let after = TimeAnchorTodayPresenter.presentation(
                anchor: anchor,
                subjectName: "途途",
                referenceDate: date(2026, 8, 9),
                calendar: calendar,
                outputLanguage: language
            )

            #expect(after.value == expectedAfter[language])
        }

        let futureAnchor = MemorySubject.TimeAnchor(
            title: "入园",
            date: date(2026, 8, 19),
            note: "未来时间锚点",
            anchorType: .custom
        )
        let futureExpected: [MemoMarkLanguage: String] = [
            .simplifiedChinese: "还有10天",
            .english: "10 days left",
            .japanese: "あと10日",
            .korean: "10일 남음"
        ]

        for language in MemoMarkLanguage.allCases {
            let before = TimeAnchorTodayPresenter.presentation(
                anchor: futureAnchor,
                subjectName: "途途",
                referenceDate: date(2026, 8, 9),
                calendar: calendar,
                outputLanguage: language
            )

            #expect(before.value == futureExpected[language])
        }

        let onDateExpected: [MemoMarkLanguage: String] = [
            .simplifiedChinese: "就是今天",
            .english: "Today",
            .japanese: "今日はこの日",
            .korean: "오늘이에요"
        ]

        for language in MemoMarkLanguage.allCases {
            let onDate = TimeAnchorTodayPresenter.presentation(
                anchor: futureAnchor,
                subjectName: "途途",
                referenceDate: date(2026, 8, 19),
                calendar: calendar,
                outputLanguage: language
            )

            #expect(onDate.value == onDateExpected[language])
        }
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
