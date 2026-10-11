#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import Foundation

enum ShareContinuedProcessingDiagnostics {
    static func record(_ event: String, detail: @autoclosure () -> String = "") {
#if DEBUG
        MemoMarkBackgroundProbe.record(event, detail: detail())
#else
        MemoMarkShareDiagnostics.record(stage: .init(rawValue: event), message: detail())
#endif
    }

    static func record(_ event: String, identifier: String, error: Error) {
#if DEBUG
        MemoMarkBackgroundProbe.record(event, detail: "identifier=\(identifier);code=\((error as NSError).code)")
#else
        MemoMarkShareDiagnostics.record(stage: .init(rawValue: event),
            message: "identifier=\(identifier);domain=\((error as NSError).domain);code=\((error as NSError).code)")
#endif
    }
}
#endif
