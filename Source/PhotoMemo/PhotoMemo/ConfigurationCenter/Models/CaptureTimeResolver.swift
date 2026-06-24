#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct CaptureTimeResolver {

    func resolve(
        captureDate: Date,
        referenceDate: Date
    ) -> DateComponents {
        Calendar.current.dateComponents(
            [.year, .month, .day],
            from: referenceDate,
            to: captureDate
        )
    }
}
#endif
