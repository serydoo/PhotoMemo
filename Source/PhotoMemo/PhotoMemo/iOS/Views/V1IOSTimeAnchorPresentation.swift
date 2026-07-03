#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1IOSTimeAnchorPresentation {

    private static let anchorDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

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

        return anchorDateFormatter.string(from: date)
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
