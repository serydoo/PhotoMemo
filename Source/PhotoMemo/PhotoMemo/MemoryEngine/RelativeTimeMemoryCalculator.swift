import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct RelativeTimeMemoryCalculator:
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

        let anchorType =
            anchor.anchorType ?? .birthday
        let relativeSnapshot =
            MemoryAnchorRelativeSnapshot
            .resolve(
                anchorDate: anchor.date,
                captureDate: captureDate,
                calendar: Calendar.current
            )

        return MemorySemanticResult(
            kind:
                MemoryAnchorExpressionResolver
                .semanticKind(
                    anchorType: anchorType,
                    relativeSnapshot:
                        relativeSnapshot
                ),
            displayText:
                MemoryAnchorExpressionResolver
                .semanticDisplayText(
                    anchorType: anchorType,
                    relativeSnapshot:
                        relativeSnapshot
                ),
            relativeSnapshot:
                relativeSnapshot
        )
    }
}
#endif
