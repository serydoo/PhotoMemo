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
        let anchorType = anchor.anchorType ?? .birthday
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
                    relativeSnapshot: semanticResult.relativeSnapshot,
                    language: context.language
                )
        }

        let elapsed = semanticResult.relativeSnapshot
        let ageComponents = anchorType == .birthday
            ? MemoryAgeComponents(
                years: elapsed.years,
                months: elapsed.months,
                days: elapsed.days
            )
            : nil

        return MemoryNarrativeFormatter.format(
            context: MemoryNarrativeContext(
                anchorType: anchorType,
                subjectDisplayName: subjectText,
                anchorTitle: anchor.title,
                occurrence: semanticResult.narrativeOccurrence,
                ageComponents: ageComponents,
                durationComponents: MemoryDurationComponents(
                    years: elapsed.years,
                    months: elapsed.months,
                    days: elapsed.days,
                    totalDays: elapsed.totalDays
                ),
                countdownComponents: semanticResult.kind == .countdown
                    ? MemoryCountdownComponents(
                        totalDays: elapsed.totalDays
                    )
                    : nil,
                expressionStyle: resolvedStyle,
                captureDate: context.captureDate,
                language: context.language,
                formattingMode: .legacyCompatible
            )
        )
    }
}
#endif
