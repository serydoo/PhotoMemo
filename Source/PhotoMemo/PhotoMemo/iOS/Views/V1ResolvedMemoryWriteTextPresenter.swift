#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1ResolvedMemoryWriteTextPresenter {

    static func resolvedText(
        subject: MemorySubject?,
        usesCustomText: Bool,
        customText: String,
        smartModuleCarrierRegion: CardRegion = .slotD,
        captureDate: Date = MemoryExpressionPreviewResolver.defaultCaptureDate
    ) -> String {
        let trimmedCustomText =
            customText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if usesCustomText,
           !trimmedCustomText.isEmpty {
            return trimmedCustomText
        }

        let resolvedText =
            MemoryExpressionPreviewResolver
            .previewText(
                subject: subject,
                captureDate: captureDate,
                smartModuleCarrierRegion:
                    smartModuleCarrierRegion
            )?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            let resolvedText,
            !resolvedText.isEmpty
        else {
            return "当前智能模块暂无内容"
        }

        return resolvedText
    }

    static func legacyBirthdayAnchorTitle(
        subject: MemorySubject?
    ) -> String {
        guard let subject else {
            return "记忆对象"
        }

        let resolvedTitle =
            subject
            .resolvedExpressionSubjectText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return resolvedTitle.isEmpty
            ? "记忆对象"
            : resolvedTitle
    }
}
#endif
