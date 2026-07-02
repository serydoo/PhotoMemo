import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct ConfiguredSubjectStrategy:
    SubjectStrategy {

    func resolveSubjectText(
        from subject: MemorySubject
    ) -> String {
        subject.resolvedExpressionSubjectText
    }
}

struct DefaultMemoryOutputStrategy:
    OutputStrategy {

    func makeModule(
        title: String,
        blocks: [MemoryBlock],
        renderedText: String,
        sourceAnchor: MemoryAnchor?,
        preferredRegion: CardRegion?
    ) -> MemoryModule {
        MemoryModule(
            title: title,
            blocks: blocks,
            renderedText: renderedText,
            sourceAnchor: sourceAnchor,
            preferredRegion: preferredRegion
        )
    }
}
#endif
