#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Tracks the newest subject persistence request without making the session
/// itself a second persistence owner. A completion may only publish its
/// candidate when it is still the newest request.
struct V1SubjectPersistenceRequestGate: Equatable {

    enum BeginResult: Equatable {
        case started(generation: Int)
        case queued(generation: Int)
    }

    enum Completion: Equatable {
        case current
        case superseded
    }

    private(set) var generation = 0
    private(set) var activeGeneration: Int?

    mutating func begin() -> BeginResult {
        generation &+= 1
        guard activeGeneration == nil else {
            return .queued(generation: generation)
        }

        activeGeneration = generation
        return .started(generation: generation)
    }

    mutating func complete(generation completedGeneration: Int)
        -> Completion {
        guard activeGeneration == completedGeneration else {
            return .superseded
        }

        activeGeneration = nil
        return completedGeneration == generation
            ? .current
            : .superseded
    }

    mutating func cancel(generation cancelledGeneration: Int) {
        guard activeGeneration == cancelledGeneration else {
            return
        }

        activeGeneration = nil
    }
}
#endif
