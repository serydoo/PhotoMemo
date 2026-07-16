import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
enum MemoryExpressionPreviewResolver {

    static let defaultCaptureDate: Date = {
        var components =
            DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)
            ?? Date()
    }()

    static func previewText(
        subject: MemorySubject?,
        captureDate: Date = defaultCaptureDate,
        smartModuleCarrierRegion: CardRegion = .slotD
    ) -> String? {
        guard let subject else {
            return nil
        }

        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot:
                    ConfigurationSnapshotBuilder
                    .build(
                        from: subject,
                        smartModuleCarrierRegion:
                            smartModuleCarrierRegion
                    ),
                captureDate:
                    captureDate
            )
        let result =
            MemoryExpressionEngine()
            .generateResult(
                context: context
            )
        let renderedText =
            MemoryResultPresentationAdapter()
            .makeModule(
                result: result,
                context: context
            )
            .renderedText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !renderedText.isEmpty else {
            return nil
        }

        return renderedText
    }
}
#endif
