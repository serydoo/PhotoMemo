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
        "\(subjectText)今天\(semanticResult.displayText)啦！"
    }
}
#endif
