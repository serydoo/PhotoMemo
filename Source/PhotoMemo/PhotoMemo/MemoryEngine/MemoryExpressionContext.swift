import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryExpressionContext {

    let subject: MemorySubject
    let snapshot: ConfigurationSnapshot
    let captureDate: Date?

    init(
        subject: MemorySubject,
        snapshot: ConfigurationSnapshot,
        captureDate: Date? = nil
    ) {
        self.subject = subject
        self.snapshot = snapshot
        self.captureDate = captureDate
    }
}
#endif
