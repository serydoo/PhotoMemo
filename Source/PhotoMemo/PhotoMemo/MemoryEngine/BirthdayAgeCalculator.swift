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
                calendar: calendar
            )

        return MemorySemanticResult(
            kind: .birthdayAge,
            displayText:
                relativeSnapshot.ageText,
            relativeSnapshot:
                relativeSnapshot
        )
    }
}
#endif
