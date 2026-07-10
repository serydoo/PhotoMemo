import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryExpressionContext {

    let subject: MemorySubject
    let snapshot: ConfigurationSnapshot
    let captureDate: Date?
    let captureCalendar: Calendar

    init(
        subject: MemorySubject,
        snapshot: ConfigurationSnapshot,
        captureDate: Date? = nil,
        captureCalendar: Calendar = .current
    ) {
        self.subject = subject
        self.snapshot = snapshot
        self.captureDate = captureDate
        self.captureCalendar = captureCalendar
    }
}
#endif
