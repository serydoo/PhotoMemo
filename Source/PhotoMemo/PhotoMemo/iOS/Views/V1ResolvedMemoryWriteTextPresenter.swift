#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum MemoryWriteTextComposer {

    static func compose(
        smartText: String?,
        usesCustomText: Bool,
        customText: String
    ) -> String? {
        let trimmedSmartText = smartText?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCustomText = customText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [
            trimmedSmartText.flatMap { $0.isEmpty ? nil : $0 },
            usesCustomText && !trimmedCustomText.isEmpty
                ? trimmedCustomText
                : nil
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }
}

enum V1ResolvedMemoryWriteTextPresenter {

    static func resolvedText(
        subject: MemorySubject?,
        usesCustomText: Bool,
        customText: String,
        smartModuleCarrierRegion: CardRegion = .slotD,
        captureDate: Date = MemoryExpressionPreviewResolver.defaultCaptureDate
    ) -> String {
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

        return MemoryWriteTextComposer.compose(
            smartText: resolvedText,
            usesCustomText: usesCustomText,
            customText: customText
        ) ?? "当前智能模块暂无内容"
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
