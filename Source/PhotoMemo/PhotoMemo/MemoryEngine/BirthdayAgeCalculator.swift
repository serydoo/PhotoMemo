import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct BirthdayAgeCalculator:
    MemoryCalculator {

    func calculate(
        context: MemoryExpressionContext,
        anchor: MemoryAnchor
    ) -> MemorySemanticResult? {
        guard let captureDate =
            context.captureDate
        else {
            return nil
        }

        let calendar = Calendar.current

        let relativeSnapshot =
            MemoryAnchorRelativeSnapshot
            .resolve(
                anchorDate: anchor.date,
                captureDate: captureDate,
                calendar: calendar,
                comparesByCalendarDay: true
            )

        return MemorySemanticResult(
            kind: .birthdayAge,
            displayText:
                MemoryAnchorVariableTextFormatter.babyAgeText(
                    from:
                        MemoryElapsedTime(
                            relativeSnapshot:
                                relativeSnapshot
                        ),
                    language:
                        context.language
                ),
            relativeSnapshot:
                relativeSnapshot
        )
    }
}
#endif
