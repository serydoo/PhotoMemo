import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct ConfiguredAnchorExpressionProvider:
    MemoryExpressionProvider {

    func renderedText(
        subjectText: String,
        semanticResult: MemorySemanticResult,
        anchor: MemoryAnchor,
        context: MemoryExpressionContext
    ) -> String {
        MemoryAnchorExpressionResolver
            .renderedText(
                subjectText: subjectText,
                anchorTitle: anchor.title,
                anchorType:
                    anchor.anchorType
                    ?? .birthday,
                expressionStyle:
                    anchor.expressionStyle,
                relativeSnapshot:
                    semanticResult
                    .relativeSnapshot
            )
    }
}
#endif
