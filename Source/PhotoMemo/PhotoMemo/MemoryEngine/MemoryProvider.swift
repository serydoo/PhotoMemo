import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryProvider:
    ExpressionProvider {

    static let memoryToken =
        ExpressionToken(rawValue: "memory")

    private let engine: MemoryExpressionEngine

    private let presentationAdapter:
        MemoryResultPresentationAdapter

    init(
        engine: MemoryExpressionEngine = MemoryExpressionEngine(),
        presentationAdapter:
            MemoryResultPresentationAdapter =
                MemoryResultPresentationAdapter()
    ) {
        self.engine =
            engine
        self.presentationAdapter =
            presentationAdapter
    }

    var canonicalTokens: Set<ExpressionToken> {
        [
            Self.memoryToken
        ]
    }

    func expressionValue(
        for token: ExpressionToken,
        context: MemoryExpressionContext
    ) -> ExpressionValue? {

        guard token == Self.memoryToken else {
            return nil
        }

        let result =
            engine
            .generateResult(
                context: context
            )
        let module =
            presentationAdapter
            .makeModule(
                result: result,
                context: context
            )

        return ExpressionValue(
            token: token,
            resolvedText:
                module.renderedText
        )
    }
}
#endif
