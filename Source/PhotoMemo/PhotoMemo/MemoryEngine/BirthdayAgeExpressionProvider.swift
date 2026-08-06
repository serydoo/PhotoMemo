import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct BirthdayAgeExpressionProvider:
    MemoryExpressionProvider {

    func renderedText(
        subjectText: String,
        semanticResult: MemorySemanticResult,
        anchor: MemoryAnchor,
        context: MemoryExpressionContext
    ) -> String {
        if semanticResult.relativeSnapshot.isOnAnchorDay {
            return context.language == .english
                ? "\(subjectText) arrived in the world today"
                : "\(subjectText)今天来到这个世界啦！"
        }

        return "今天\(subjectText)\(semanticResult.displayText)"
    }
}
#endif
