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

        let anchorType = anchor.anchorType ?? .birthday
        let subjectText = subjectStrategy.resolveSubjectText(
            from: context.subject
        )
        let resolvedStyle = MemoryAnchorExpressionStyle.resolvedStyle(
            for: anchorType,
            candidate: anchor.expressionStyle
        )

        guard resolvedStyle.isCanonicalNatural else {
            return MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: subjectText,
                    anchorTitle: anchor.title,
                    anchorType: anchorType,
                    expressionStyle: anchor.expressionStyle,
                    relativeSnapshot: anchorResult.elapsed.relativeSnapshot,
                    language: context.language
                )
        }

        return MemoryNarrativeFormatter.format(
            context: MemoryNarrativeContext(
                anchorType: anchorType,
                subjectDisplayName: subjectText,
                anchorTitle: anchor.title,
                occurrence: anchorResult.narrativeOccurrence(
                    anchorType: anchorType
                ),
                ageComponents: anchorResult.ageComponents(
                    anchorType: anchorType
                ),
                durationComponents: anchorResult.durationComponents,
                countdownComponents: anchorResult.countdownComponents,
                expressionStyle: resolvedStyle,
                captureDate: result.captureDate,
                language: context.language,
                formattingMode: .legacyCompatible
            )
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
                        .locale(context.language.locale)
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

private extension MemoryAnchorResult {

    func narrativeOccurrence(
        anchorType: AnchorType
    ) -> MemoryNarrativeOccurrence {
        switch direction {
        case .beforeAnchor:
            return .countdown
        case .onAnchor:
            return anchorType == .birthday
                ? .birthDay
                : .anchorDay
        case .afterAnchor:
            return .elapsed
        }
    }

    func ageComponents(
        anchorType: AnchorType
    ) -> MemoryAgeComponents? {
        guard anchorType == .birthday else {
            return nil
        }

        return MemoryAgeComponents(
            years: elapsed.years,
            months: elapsed.months,
            days: elapsed.days
        )
    }

    var durationComponents: MemoryDurationComponents {
        MemoryDurationComponents(
            years: elapsed.years,
            months: elapsed.months,
            days: elapsed.days,
            totalDays: elapsed.totalDays
        )
    }

    var countdownComponents: MemoryCountdownComponents? {
        guard direction == .beforeAnchor else {
            return nil
        }

        return MemoryCountdownComponents(
            totalDays: elapsed.totalDays
        )
    }
}
#endif
