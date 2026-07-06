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
        "这一天，\(subjectText)\(semanticResult.displayText)"
    }
}
#endif
