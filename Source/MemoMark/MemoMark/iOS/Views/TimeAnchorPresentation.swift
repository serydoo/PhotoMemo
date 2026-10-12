#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum UserFacingDateFormatter {

    private static func makeFormatter(
        dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style,
        locale: Locale?
    ) -> DateFormatter {
        let formatter = DateFormatter()
        // UI dates follow the system's region when the interface follows the
        // system. Explicit interface language choices retain their own locale.
        formatter.locale = locale ?? (MemoMarkLanguage.interfacePreference == .system
            ? Locale.current : MemoMarkLanguage.interfaceStored.locale)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter
    }

    static func date(_ date: Date, locale: Locale? = nil) -> String {
        makeFormatter(dateStyle: .medium, timeStyle: .none, locale: locale).string(from: date)
    }

    static func dateTime(_ date: Date, locale: Locale? = nil) -> String {
        makeFormatter(dateStyle: .medium, timeStyle: .short, locale: locale).string(from: date)
    }

    static func compactDateTime(_ date: Date, locale: Locale? = nil) -> String {
        let formatter = makeFormatter(dateStyle: .none, timeStyle: .none, locale: locale)
        formatter.setLocalizedDateFormatFromTemplate("MMMdHm")
        return formatter.string(from: date)
    }

}

enum TimeAnchorPresentation {

    static func title(
        subject: MemorySubject?,
        fallback: String = "时间锚点"
    ) -> String {

        let resolved =
            normalizedOptionalText(
                subject?
                .primaryTimeAnchor?
                .title
            )
            ?? normalizedOptionalText(
                subject?
                .behavior
                .primaryAnchor
            )
            ?? normalizedOptionalText(
                fallback
            )

        return resolved
        ?? "时间锚点"
    }

    static func dateLabel(
        _ date: Date?
    ) -> String {
        guard let date else {
            return "未设置"
        }

        return UserFacingDateFormatter.date(date)
    }

    private static func normalizedOptionalText(
        _ text: String?
    ) -> String? {

        let trimmed =
            text?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
#endif
