import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryResultPresentationAdapter {

    private let subjectStrategy:
        any SubjectStrategy

    init(
        subjectStrategy:
            any SubjectStrategy = ConfiguredSubjectStrategy()
    ) {
        self.subjectStrategy =
            subjectStrategy
    }

    func makeModule(
        result: MemoryResult,
        context: MemoryExpressionContext
    ) -> MemoryModule {
        let renderedText =
            renderedText(
                result: result,
                context: context
            )

        return MemoryModule(
            title:
                context.snapshot.expression.title,
            blocks:
                context.snapshot.expression.blocks,
            renderedText: renderedText,
            sourceAnchor:
                context.snapshot.primaryAnchor,
            preferredRegion:
                context.snapshot
                .smartModuleCarrierRegion
        )
    }
}

private extension MemoryResultPresentationAdapter {

    func renderedText(
        result: MemoryResult,
        context: MemoryExpressionContext
    ) -> String {
        guard
            let anchor =
                context.snapshot.primaryAnchor,
            let anchorResult =
                result.primaryAnchorResult,
            anchorResult.status == .resolved
        else {
            return fallbackRenderedText(
                context: context
            )
        }

        return MemoryAnchorExpressionResolver
            .renderedText(
                subjectText:
                    subjectStrategy
                    .resolveSubjectText(
                        from: context.subject
                    ),
                anchorTitle: anchor.title,
                anchorType:
                    anchor.anchorType
                    ?? .birthday,
                expressionStyle:
                    anchor.expressionStyle,
                relativeSnapshot:
                    anchorResult
                    .elapsed
                    .relativeSnapshot
            )
    }

    func fallbackRenderedText(
        context: MemoryExpressionContext
    ) -> String {
        let expressionText =
            context.snapshot.expression.displayText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !expressionText.isEmpty {
            return expressionText
        }

        let subjectName =
            context.subject
            .resolvedExpressionSubjectText

        if let captureDate =
            context.captureDate {
            let formattedDate =
                captureDate.formatted(
                    .dateTime
                        .year()
                        .month()
                        .day()
                )
            return "\(subjectName) · \(formattedDate)"
        }

        if let anchor =
            context.snapshot.primaryAnchor {
            return "\(subjectName) · \(anchor.title)"
        }

        return subjectName
    }
}
#endif
