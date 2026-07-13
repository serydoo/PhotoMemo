#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1UserFacingDateFormatter {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter
    }()

    private static let compactDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    static func compactDateTime(_ date: Date) -> String {
        compactDateTimeFormatter.string(from: date)
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
