import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct BirthdayAgeExpressionProvider:
    MemoryExpressionProvider {

    func renderedText(
        subjectText: String,
        semanticResult: MemorySemanticResult,
        anchor: MemoryAnchor,
        context: MemoryExpressionContext
    ) -> String {
        let snapshot = semanticResult.relativeSnapshot
        let ageComponents = MemoryAgeComponents(
            years: snapshot.years,
            months: snapshot.months,
            days: snapshot.days
        )

        return MemoryNarrativeFormatter.format(
            context: MemoryNarrativeContext(
                anchorType: .birthday,
                subjectDisplayName: subjectText,
                anchorTitle: anchor.title,
                occurrence: semanticResult.narrativeOccurrence,
                ageComponents: ageComponents,
                durationComponents: MemoryDurationComponents(
                    years: snapshot.years,
                    months: snapshot.months,
                    days: snapshot.days,
                    totalDays: snapshot.totalDays
                ),
                countdownComponents: semanticResult.kind == .countdown
                    ? MemoryCountdownComponents(
                        totalDays: snapshot.totalDays
                    )
                    : nil,
                expressionStyle: .birthdayNatural,
                captureDate: context.captureDate,
                language: context.language,
                formattingMode: .legacyCompatible
            )
        )
    }
}
#endif
