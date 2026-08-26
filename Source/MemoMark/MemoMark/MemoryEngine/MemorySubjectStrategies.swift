import Foundation

#if !MEMOMARK_SHARE_EXTENSION
struct ConfiguredSubjectStrategy:
    SubjectStrategy {

    func resolveSubjectText(
        from subject: MemorySubject
    ) -> String {
        subject.resolvedExpressionSubjectText
    }
}
#endif
