#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1TimeAnchorEntryPresentation: Hashable {
    let rowSubtitle: String
    let rowValue: String
    let anchorPickerTitle: String
    let formulaTitle: String
    let formulaPreviewText: String
}

enum V1TimeAnchorEntryPresenter {

    static func presentation(
        subject: MemorySubject?,
        anchorTitle: String
    ) -> V1TimeAnchorEntryPresentation {
        let resolvedAnchor =
            resolvedAnchor(
                subject: subject,
                anchorTitle: anchorTitle
            )
        let resolvedSubject =
            normalizedText(
                subject?.resolvedExpressionSubjectText
            )
            ?? "记忆对象"
        let resolvedAnchorTitle =
            normalizedText(anchorTitle)
            ?? normalizedText(
                resolvedAnchor?.title
            )
            ?? "时间锚点"
        let resolvedStyle =
            resolvedAnchor?
            .resolvedExpressionStyle
            ?? MemoryAnchorExpressionStyle
            .birthdayAgeToday
        let formulaPreviewText =
            resolvedStyle
            .formulaPreview(
                subjectText: resolvedSubject,
                anchorTitle: resolvedAnchorTitle
            )

        return V1TimeAnchorEntryPresentation(
            rowSubtitle: "主体与当前生效锚点",
            rowValue:
                "\(resolvedSubject) · \(resolvedAnchorTitle)",
            anchorPickerTitle: resolvedAnchorTitle,
            formulaTitle: "本锚点对应输出公式如下",
            formulaPreviewText:
                formulaPreviewText
        )
    }

    private static func normalizedText(
        _ text: String?
    ) -> String? {
        guard let text else {
            return nil
        }

        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }

    private static func resolvedAnchor(
        subject: MemorySubject?,
        anchorTitle: String
    ) -> MemorySubject.TimeAnchor? {
        if let primaryAnchor =
            subject?.primaryTimeAnchor {
            return primaryAnchor
        }

        guard
            let normalizedAnchorTitle =
                normalizedText(anchorTitle)
        else {
            return nil
        }

        return subject?.timeAnchor(
            named: normalizedAnchorTitle
        )
    }
}
#endif
