import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
enum MemoryExpressionPreviewResolver {

    static let defaultCaptureDate: Date = {
        var components =
            DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 24
        components.hour = 14
        components.minute = 33
        components.second = 13
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

        let renderedText =
            MemoryExpressionEngine()
            .generateModule(
                context:
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
