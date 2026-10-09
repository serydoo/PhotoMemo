import Foundation

nonisolated struct BatchTaskReference:
    Hashable,
    Sendable {

    let jobID: UUID

    let taskID: UUID
}
