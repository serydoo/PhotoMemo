import Foundation

/// Serializes Photo Library commit transactions across static-photo and
/// Live Photo writers while preserving cancellation for queued operations.
actor PhotoLibrarySaveGate {

    static let shared = PhotoLibrarySaveGate()

    private struct Waiter {

        let id: UUID
        let continuation:
            CheckedContinuation<Void, any Error>
    }

    private var isSaving = false
    private var waiters: [Waiter] = []

    func run<Result>(
        _ operation: () async throws -> Result
    ) async throws -> Result {

        try await acquire()

        do {
            try Task.checkCancellation()
            let result = try await operation()
            release()
            return result
        } catch {
            release()
            throw error
        }
    }

    private func acquire() async throws {
        try Task.checkCancellation()

        guard !isSaving else {
            let waiterID = UUID()
            try await withTaskCancellationHandler(
                operation: {
                    try await withCheckedThrowingContinuation {
                        (continuation:
                            CheckedContinuation<
                                Void,
                                any Error
                            >) in

                        guard !Task.isCancelled else {
                            continuation.resume(
                                throwing:
                                    CancellationError()
                            )
                            return
                        }

                        waiters.append(
                            Waiter(
                                id: waiterID,
                                continuation: continuation
                            )
                        )
                    }
                },
                onCancel: {
                    Task<Void, Never> {
                        await self.cancelWaiter(
                            id: waiterID
                        )
                    }
                }
            )
            return
        }

        isSaving = true
    }

    private func release() {
        guard !waiters.isEmpty else {
            isSaving = false
            return
        }

        let waiter = waiters.removeFirst()
        waiter.continuation.resume()
    }

    private func cancelWaiter(id: UUID) {
        guard let index = waiters.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        let waiter = waiters.remove(at: index)
        waiter.continuation.resume(
            throwing: CancellationError()
        )
    }
}
