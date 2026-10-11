#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import Foundation

enum ShareContinuedProcessingDiagnostics {
    static func record(_ event: String, detail: @autoclosure () -> String = "") {
#if DEBUG
        MemoMarkBackgroundProbe.record(event, detail: detail())
#else
        _ = event
#endif
    }

    static func record(_ event: String, identifier: String, error: Error) {
#if DEBUG
        MemoMarkBackgroundProbe.record(event, detail: "identifier=\(identifier);code=\((error as NSError).code)")
#else
        _ = event
        _ = identifier
        _ = error
#endif
    }
}
#endif
