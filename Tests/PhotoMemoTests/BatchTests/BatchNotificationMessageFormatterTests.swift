import Foundation
import Testing
@testable import PhotoMemo

@Suite("BatchNotificationMessageFormatter")
struct BatchNotificationMessageFormatterTests {

    @Test("Formats successful completion with clock time and photo count")
    func formatsSuccessfulCompletionWithClockTimeAndPhotoCount() {
        var calendar =
            Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(secondsFromGMT: 8 * 60 * 60)!
        let finishedAt =
            date(
                hour: 15,
                minute: 20,
                calendar: calendar
            )

        #expect(
            BatchNotificationMessageFormatter.finishedTitle(
                completedCount: 2,
                failedCount: 0,
                finishedAt: finishedAt,
                calendar: calendar
            )
            == "15:20 处理 2 张照片已完成"
        )
        #expect(
            BatchNotificationMessageFormatter.finishedMessage(
                completedCount: 2,
                failedCount: 0,
                totalCount: 2,
                savedAlbumName: "家庭相册"
            )
            == "已保存到「家庭相册」。"
        )
    }

    @Test("Formats failed completion without album wording")
    func formatsFailedCompletionWithoutAlbumWording() {
        var calendar =
            Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(secondsFromGMT: 8 * 60 * 60)!
        let finishedAt =
            date(
                hour: 15,
                minute: 20,
                calendar: calendar
            )

        #expect(
            BatchNotificationMessageFormatter.finishedTitle(
                completedCount: 0,
                failedCount: 2,
                finishedAt: finishedAt,
                calendar: calendar
            )
            == "15:20 2 张照片需处理"
        )
        #expect(
            BatchNotificationMessageFormatter.finishedMessage(
                completedCount: 0,
                failedCount: 2,
                totalCount: 2
            )
            == "请回到 PhotoMemo 查看原因，并按提示继续处理。"
        )
    }

    @Test("Formats partial completion as a clear result")
    func formatsPartialCompletionAsAClearResult() {
        var calendar =
            Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(secondsFromGMT: 8 * 60 * 60)!
        let finishedAt =
            date(
                hour: 15,
                minute: 20,
                calendar: calendar
            )

        #expect(
            BatchNotificationMessageFormatter.finishedTitle(
                completedCount: 4,
                failedCount: 1,
                finishedAt: finishedAt,
                calendar: calendar
            )
            == "15:20 已完成 4 张，1 张需处理"
        )
        #expect(
            BatchNotificationMessageFormatter.finishedMessage(
                completedCount: 4,
                failedCount: 1,
                totalCount: 5,
                savedAlbumName: "家庭相册"
            )
            == "大部分结果已保存到「家庭相册」，剩余 1 张可回到 PhotoMemo 查看。"
        )
    }

    @Test("Keeps fallback completion message when album is unavailable")
    func keepsFallbackCompletionMessageWhenAlbumIsUnavailable() {
        #expect(
            BatchNotificationMessageFormatter.finishedMessage(
                completedCount: 1,
                failedCount: 0,
                totalCount: 1,
                savedAlbumName: " "
            )
            == "PhotoMemo 已生成新的照片。"
        )
    }

    private func date(
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {

        calendar.date(
            from:
                DateComponents(
                    timeZone:
                        calendar.timeZone,
                    year: 2026,
                    month: 6,
                    day: 29,
                    hour: hour,
                    minute: minute
                )
        )!
    }
}
