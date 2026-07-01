import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryExpressionEngine {

    private let subjectStrategy:
        any SubjectStrategy

    private let outputStrategy:
        any OutputStrategy

    init(
        subjectStrategy:
            any SubjectStrategy = ConfiguredSubjectStrategy(),
        outputStrategy:
            any OutputStrategy = DefaultMemoryOutputStrategy()
    ) {
        self.subjectStrategy =
            subjectStrategy
        self.outputStrategy =
            outputStrategy
    }

    func generateModule(
        context: MemoryExpressionContext
    ) -> MemoryModule {
        let sourceAnchor =
            context.snapshot.primaryAnchor
        let resolvedText =
            resolvedRenderedText(
                subject: context.subject,
                snapshot: context.snapshot,
                captureDate:
                    context.captureDate
            )

        let renderedText: String

        if let sourceAnchor,
           let definition =
            MemoryAnchorTypeRegistry
            .definition(
                for: sourceAnchor.anchorType
            ),
           let semanticResult =
            definition.calculator
            .calculate(
                context: context,
                anchor: sourceAnchor
            ) {
            renderedText =
                definition.expressionProvider
                .renderedText(
                    subjectText:
                        subjectStrategy
                        .resolveSubjectText(
                            from: context.subject
                        ),
                    semanticResult:
                        semanticResult,
                    anchor: sourceAnchor,
                    context: context
                )
        } else {
            renderedText = resolvedText
        }

        return outputStrategy.makeModule(
            title: context.snapshot.expression.title,
            blocks: context.snapshot.expression.blocks,
            renderedText: renderedText,
            sourceAnchor: sourceAnchor,
            preferredRegion: context.snapshot.smartModuleCarrierRegion
        )
    }
}

private extension MemoryExpressionEngine {

    func resolvedRenderedText(
        subject: MemorySubject,
        snapshot: ConfigurationSnapshot,
        captureDate: Date?
    ) -> String {
        let expressionText =
            snapshot.expression.displayText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !expressionText.isEmpty {
            return expressionText
        }

        let subjectName =
            subject.resolvedExpressionSubjectText

        if let captureDate {
            let formattedDate =
                captureDate.formatted(
                    .dateTime
                        .year()
                        .month()
                        .day()
                )
            return "\(subjectName) · \(formattedDate)"
        }

        if let anchor = snapshot.primaryAnchor {
            return "\(subjectName) · \(anchor.title)"
        }

        return subjectName
    }
}
#endif
