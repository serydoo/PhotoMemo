#if !MEMOMARK_SHARE_EXTENSION
import Foundation

nonisolated struct BatchTaskReference:
    Hashable,
    Sendable {

    let jobID: UUID

    let taskID: UUID
}
#endif
