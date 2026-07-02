import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
protocol MemoryCalculator {

    func calculate(
        context: MemoryExpressionContext,
        anchor: MemoryAnchor
    ) -> MemorySemanticResult?
}

protocol MemoryExpressionProvider {

    func renderedText(
        subjectText: String,
        semanticResult: MemorySemanticResult,
        anchor: MemoryAnchor,
        context: MemoryExpressionContext
    ) -> String
}

protocol SubjectStrategy {

    func resolveSubjectText(
        from subject: MemorySubject
    ) -> String
}

protocol OutputStrategy {

    func makeModule(
        title: String,
        blocks: [MemoryBlock],
        renderedText: String,
        sourceAnchor: MemoryAnchor?,
        preferredRegion: CardRegion?
    ) -> MemoryModule
}
#endif
