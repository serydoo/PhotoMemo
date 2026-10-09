import Foundation

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
