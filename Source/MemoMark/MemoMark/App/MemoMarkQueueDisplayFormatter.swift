#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum MemoMarkQueueDisplayFormatter {
    static func title(
        startedAt: Date,
        photoCount: Int,
        language: MemoMarkLanguage = .interfaceStored,
        now: Date = Date()
    ) -> String {

        let count =
            max(photoCount, 0)
        let formatter =
            DateFormatter()
        formatter.locale =
            language.locale

        let calendar =
            Calendar.current

        if calendar.isDate(
            startedAt,
            inSameDayAs:
                now
        ) {
            formatter.dateFormat =
                language.localized(
                    key: "processing.background.queue.date_format.today",
                    fallback: "HH:mm"
                )
        } else if let yesterday =
            calendar.date(
                byAdding: .day,
                value: -1,
                to: now
            ),
            calendar.isDate(
                startedAt,
                inSameDayAs:
                    yesterday
            ) {
            formatter.dateFormat =
                language.localized(
                    key: "processing.background.queue.date_format.today",
                    fallback: "HH:mm"
                )
            return localizedFormat(
                language: language,
                key: "processing.background.queue.title_yesterday_format",
                fallback: "昨天 %@（%lld张）",
                formatter.string(from: startedAt),
                Int64(count)
            )
        } else if calendar.component(
            .year,
            from: startedAt
        ) == calendar.component(
            .year,
            from: now
        ) {
            formatter.dateFormat =
                language.localized(
                    key: "processing.background.queue.date_format.same_year",
                    fallback: "M月d日 HH:mm"
                )
        } else {
            formatter.dateFormat =
                language.localized(
                    key: "processing.background.queue.date_format.past_year",
                    fallback: "yyyy年M月d日 HH:mm"
                )
        }

        return localizedFormat(
            language: language,
            key: "processing.background.queue.title_format",
            fallback: "%@（%lld张）",
            formatter.string(from: startedAt),
            Int64(count)
        )
    }

    private static func localizedFormat(
        language: MemoMarkLanguage,
        key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: language.localized(
                key: key,
                fallback: fallback
            ),
            locale: language.locale,
            arguments: arguments
        )
    }
}
#endif
