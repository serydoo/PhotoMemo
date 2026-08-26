#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum V1UserFacingDateFormatter {

    private static func makeFormatter(
        dateFormat: String
    ) -> DateFormatter {

        let formatter = DateFormatter()
        formatter.locale = MemoMarkLanguage.interfaceStored.locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = dateFormat
        return formatter
    }

    static func date(_ date: Date) -> String {
        let format =
            MemoMarkLanguage.interfaceStored == .english
            ? "MMM d, yyyy"
            : "yyyy年M月d日"

        return makeFormatter(dateFormat: format).string(from: date)
    }

    static func dateTime(_ date: Date) -> String {
        let format =
            MemoMarkLanguage.interfaceStored == .english
            ? "MMM d, yyyy HH:mm"
            : "yyyy年M月d日 HH:mm"

        return makeFormatter(dateFormat: format).string(from: date)
    }

    static func compactDateTime(_ date: Date) -> String {
        let format =
            MemoMarkLanguage.interfaceStored == .english
            ? "MMM d HH:mm"
            : "M月d日 HH:mm"

        return makeFormatter(dateFormat: format).string(from: date)
    }
}

enum V1IOSTimeAnchorPresentation {

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

        return V1UserFacingDateFormatter.date(date)
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
