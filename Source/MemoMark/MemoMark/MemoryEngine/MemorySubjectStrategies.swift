import Foundation

struct ConfiguredSubjectStrategy:
    SubjectStrategy {

    func resolveSubjectText(
        from subject: MemorySubject
    ) -> String {
        subject.resolvedExpressionSubjectText
    }
}
