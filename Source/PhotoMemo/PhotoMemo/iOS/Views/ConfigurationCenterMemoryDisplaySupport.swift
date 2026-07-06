#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationCenterMemoryDisplaySupport {

    static func selectedStyle(
        subject: MemorySubject?
    ) -> MemoryAnchorExpressionStyle? {
        subject?.primaryTimeAnchor?.resolvedExpressionStyle
    }

    static func availableStyles(
        subject: MemorySubject?
    ) -> [MemoryAnchorExpressionStyle] {
        guard let anchor = subject?.primaryTimeAnchor else {
            return []
        }

        return MemoryAnchorExpressionStyle
            .availableStyles(
                for: anchor.resolvedAnchorType
            )
    }

    static func summaryValue(
        subject: MemorySubject?
    ) -> String {
        selectedStyle(subject: subject)?
            .displayTitle
            ?? "未设置"
    }

    static func summaryDetail(
        subject: MemorySubject?
    ) -> String {
        guard
            let subject,
            let anchor = subject.primaryTimeAnchor
        else {
            return "先选择记忆对象和当前生效锚点，再决定这张卡片要用哪一种表达方式。"
        }

        return anchor
            .resolvedExpressionStyle
            .formulaPreview(
                subjectText:
                    subject
                    .resolvedExpressionSubjectText,
                anchorTitle: anchor.title
            )
    }
}
#endif
