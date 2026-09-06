#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum ConfigurationCenterMemoryDisplaySupport {

    static func selectedStyle(
        subject: MemorySubject?
    ) -> MemoryAnchorExpressionStyle? {
        subject?.primaryTimeAnchor?.resolvedExpressionStyle
    }

    static func availableStyles(
        subject: MemorySubject?,
        accessSource _: MemoMarkCommerceAccessSource = .free
    ) -> [MemoryAnchorExpressionStyle] {
        guard let anchor = subject?.primaryTimeAnchor else {
            return []
        }

        // Keep the full first-party catalog visible. The caller marks paid
        // styles as locked and owns the current-surface purchase flow; free
        // users should be able to understand what MemoMark+ unlocks.
        return MemoryAnchorExpressionStyle.availableStyles(
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
        subject: MemorySubject?,
        style: MemoryAnchorExpressionStyle? = nil
    ) -> String {
        guard
            let subject,
            let anchor = subject.primaryTimeAnchor
        else {
            return "先选择记忆对象和当前生效时间锚点，再决定这张卡片要用哪一种表达方式。"
        }

        if let style,
           style != anchor.resolvedExpressionStyle {
            var previewSubject = subject
            if let anchorIndex = previewSubject.timeAnchors.firstIndex(
                where: { $0.id == anchor.id }
            ) {
                previewSubject.timeAnchors[anchorIndex].expressionStyle = style
                return MemoryExpressionPreviewResolver
                    .previewText(subject: previewSubject)
                    ?? "\(previewSubject.resolvedExpressionSubjectText) · \(anchor.title)"
            }
        }

        return MemoryExpressionPreviewResolver
            .previewText(subject: subject)
            ?? "\(subject.resolvedExpressionSubjectText) · \(anchor.title)"
    }
}
#endif
