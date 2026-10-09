import Foundation

enum BatchNotificationMessageFormatter {

    nonisolated
    static func finishedTitle(
        completedCount: Int,
        failedCount: Int,
        finishedAt: Date,
        calendar: Calendar = .current,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        finishedTitle(
            completedCount: completedCount,
            needsAttentionCount: failedCount,
            finishedAt: finishedAt,
            calendar: calendar,
            language: language
        )
    }

    nonisolated
    static func finishedTitle(
        completedCount: Int,
        needsAttentionCount: Int,
        finishedAt: Date,
        calendar: Calendar = .current,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        let timeText =
            shortTimeText(
                for: finishedAt,
                calendar: calendar
            )

        if needsAttentionCount == 0 {
            return String(
                format: language.localized(
                    key: "notification.batch.finished.complete",
                    fallback: "%@ Processed %d Photos"
                ),
                locale: language.locale,
                timeText,
                completedCount
            )
        }

        if completedCount == 0 {
            return String(
                format: language.localized(
                    key: "notification.batch.finished.attention_only",
                    fallback: "%@ %d Photos Need Attention"
                ),
                locale: language.locale,
                timeText,
                needsAttentionCount
            )
        }

        return String(
            format: language.localized(
                key: "notification.batch.finished.partial",
                fallback: "%@ %d Complete, %d Need Attention"
            ),
            locale: language.locale,
            timeText,
            completedCount,
            needsAttentionCount
        )
    }

    nonisolated
    static func finishedMessage(
        completedCount: Int,
        failedCount: Int,
        totalCount: Int,
        savedAlbumName: String? = nil,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        finishedMessage(
            completedCount: completedCount,
            needsAttentionCount: failedCount,
            totalCount: totalCount,
            savedAlbumName: savedAlbumName,
            language: language
        )
    }

    nonisolated
    static func finishedMessage(
        completedCount: Int,
        needsAttentionCount: Int,
        totalCount: Int,
        savedAlbumName: String? = nil,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        if needsAttentionCount == 0 {
            return savedAlbumName
                .flatMap(normalizedAlbumName)
                .map {
                    String(
                        format: language.localized(
                            key: "notification.batch.finished.saved_to_album",
                            fallback: "Saved to \"%@\"."
                        ),
                        locale: language.locale,
                        $0
                    )
                }
                ?? language.localized(
                    key: "notification.batch.finished.generated",
                    fallback: "MemoMark generated new photos."
                )
        }

        if completedCount == 0 {
            return language.localized(
                key: "notification.batch.finished.return_to_app",
                fallback: "Return to MemoMark to review the reason and continue."
            )
        }

        if Double(completedCount)
            / Double(max(1, totalCount))
            >= 0.8 {
            if let albumName =
                savedAlbumName
                .flatMap(normalizedAlbumName) {
                return String(
                    format: language.localized(
                        key: "notification.batch.finished.mostly_saved_to_album",
                        fallback: "Most results were saved to \"%@\". %d still need attention in MemoMark."
                    ),
                    locale: language.locale,
                    albumName,
                    needsAttentionCount
                )
            }

            return String(
                format: language.localized(
                    key: "notification.batch.finished.mostly_saved",
                    fallback: "Most results are complete. %d still need attention in MemoMark."
                ),
                locale: language.locale,
                needsAttentionCount
            )
        }

        if let albumName =
            savedAlbumName
            .flatMap(normalizedAlbumName) {
            return String(
                format: language.localized(
                    key: "notification.batch.finished.partial_saved_to_album",
                    fallback: "%d saved to \"%@\". %d still need attention."
                ),
                locale: language.locale,
                completedCount,
                albumName,
                needsAttentionCount
            )
        }

        return String(
            format: language.localized(
                key: "notification.batch.finished.partial_saved",
                fallback: "%d complete. %d still need attention."
            ),
            locale: language.locale,
            completedCount,
            needsAttentionCount
        )
    }

    nonisolated
    static func normalizedAlbumName(
        _ value: String
    ) -> String? {

        let trimmed =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }

    nonisolated
    private static func shortTimeText(
        for date: Date,
        calendar: Calendar
    ) -> String {

        let hour =
            calendar.component(
                .hour,
                from: date
            )
        let minute =
            calendar.component(
                .minute,
                from: date
            )

        return String(
            format: "%02d:%02d",
            hour,
            minute
        )
    }
}
