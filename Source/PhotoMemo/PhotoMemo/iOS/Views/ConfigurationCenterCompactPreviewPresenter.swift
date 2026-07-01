#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterCompactPreviewPresenter {

    static func formattedCaptureSummaryText(
        from summaryText: String,
        allowedFactCount: Int
    ) -> String {
        let facts =
            summaryText
            .split(separator: " ")
            .map(String.init)
            .prefix(allowedFactCount)

        guard !facts.isEmpty else {
            return summaryText
        }

        return facts.joined(separator: " ")
    }

    static func selectedBadgeName(
        subject: MemorySubject?
    ) -> String {
        subject?
            .decorations
            .first(where: { $0.kind == .badge })?
            .systemSymbolName
            ?? "apple.logo"
    }
}
#endif
