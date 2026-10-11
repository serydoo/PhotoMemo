/// Chooses the execution handoff only after intake has been durably persisted.
/// An accepted system request is an execution opportunity, not a save receipt.
@MainActor
enum ShareProcessingHandoff: Equatable {
    case background
    case foreground
    case handoffFailed

    static func perform(
        requiresPhotoAuthorization: Bool,
        submitContinued: () async -> Bool,
        openHost: () async -> Bool
    ) async -> Self {
        if !requiresPhotoAuthorization, await submitContinued() {
            return .background
        }
        return await openHost() ? .foreground : .handoffFailed
    }
}
