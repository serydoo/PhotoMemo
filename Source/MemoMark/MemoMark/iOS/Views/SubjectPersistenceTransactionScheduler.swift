#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct SubjectPersistenceCompletion: Equatable {
    let durableCandidate: ConfigurationLibraryRecord?
    let status: ConfigurationPersistenceStatus
}

enum SubjectPersistenceUpdate: Equatable {
    case queued
    case saving
    case completed(SubjectPersistenceCompletion)
}

/// Serializes aggregate writes for subject edits without owning subject or
/// configuration truth. When edits arrive during a write, only the newest
/// candidate is persisted next and stale success/failure results are ignored.
@MainActor
final class SubjectPersistenceTransactionScheduler {

    private struct Request {
        let id = UUID()
        let candidate: ConfigurationLibraryRecord?
        let requiresWrite: Bool
        let update: (SubjectPersistenceUpdate) -> Void

        func rebased(
            onto revision: Int
        ) -> Request {
            guard var candidate else {
                return self
            }
            candidate.revision = revision
            return Request(
                candidate: candidate,
                requiresWrite: true,
                update: update
            )
        }
    }

    private let saveConfigurationLibrary:
        (ConfigurationLibraryRecord) async throws ->
            ConfigurationLibrarySaveReceipt

    private var activeRequestID: UUID?
    private var pendingRequest: Request?

    init(
        saveConfigurationLibrary: @escaping (
            ConfigurationLibraryRecord
        ) async throws -> ConfigurationLibrarySaveReceipt
    ) {
        self.saveConfigurationLibrary = saveConfigurationLibrary
    }

    func submit(
        candidate: ConfigurationLibraryRecord?,
        requiresWrite: Bool = true,
        update: @escaping (
            SubjectPersistenceUpdate
        ) -> Void
    ) {
        let request = Request(
            candidate: candidate,
            requiresWrite: requiresWrite,
            update: update
        )

        guard activeRequestID == nil else {
            pendingRequest = request
            update(.queued)
            return
        }

        start(request)
    }

    private func start(_ request: Request) {
        guard let candidate = request.candidate,
              request.requiresWrite else {
            request.update(
                .completed(
                    SubjectPersistenceCompletion(
                        durableCandidate: nil,
                        status: .subjectSynced
                    )
                )
            )
            return
        }

        activeRequestID = request.id
        request.update(.saving)

        Task { [weak self] in
            guard let self else { return }
            let result: Result<
                ConfigurationLibrarySaveReceipt,
                Error
            >
            do {
                result = .success(
                    try await saveConfigurationLibrary(candidate)
                )
            } catch {
                result = .failure(error)
            }
            finish(
                request,
                candidate: candidate,
                result: result
            )
        }
    }

    private func finish(
        _ request: Request,
        candidate: ConfigurationLibraryRecord,
        result: Result<ConfigurationLibrarySaveReceipt, Error>
    ) {
        guard activeRequestID == request.id else {
            return
        }

        activeRequestID = nil

        if let pendingRequest {
            self.pendingRequest = nil
            switch result {
            case .success(let receipt):
                start(
                    pendingRequest.rebased(
                        onto: receipt.revision
                    )
                )
            case .failure:
                start(pendingRequest)
            }
            return
        }

        request.update(
            .completed(
                completion(
                    candidate: candidate,
                    result: result
                )
            )
        )
    }

    private func completion(
        candidate: ConfigurationLibraryRecord,
        result: Result<ConfigurationLibrarySaveReceipt, Error>
    ) -> SubjectPersistenceCompletion {
        switch result {
        case .success(let receipt):
            var durableCandidate = candidate
            durableCandidate.revision = receipt.revision

            let status: ConfigurationPersistenceStatus
            if receipt.compatibilityProjectionFailure != nil,
               let operationID = receipt.diagnosticOperationID {
                let failure =
                    ProductionDiagnosticFailureClassifier
                    .compatibilityProjection(
                        operationID: operationID,
                        language: .interfaceStored
                    )
                status = .savedWithWarning(
                    message: failure.userMessage
                )
            } else {
                status = .subjectSynced
            }

            return SubjectPersistenceCompletion(
                durableCandidate: durableCandidate,
                status: status
            )

        case .failure(let error):
            return SubjectPersistenceCompletion(
                durableCandidate: nil,
                status: .failure(
                    message: resolvedFailureMessage(error)
                )
            )
        }
    }

    private func resolvedFailureMessage(
        _ error: Error
    ) -> String {
        return (error as? MemoMarkError)?.message
            ?? MemoMarkLanguage.interfaceStored.localized(
                key: "subject.save_failed",
                fallback: "记忆对象保存失败，请重试。"
            )
    }
}
#endif
