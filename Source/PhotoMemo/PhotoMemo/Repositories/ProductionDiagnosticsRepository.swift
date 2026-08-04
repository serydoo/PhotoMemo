import Foundation
import OSLog

final class ProductionDiagnosticsRepository {

    private let store: ProductionDiagnosticsStore

    private let logger = Logger(
        subsystem: "com.serydoo.PhotoMemo",
        category: "ProductionDiagnostics"
    )

    init(
        store: ProductionDiagnosticsStore = .shared
    ) {
        self.store = store
    }

    func record(
        _ event: ProductionDiagnosticEvent
    ) async {
        let code = event.errorCode?.rawValue ?? "none"
        logger.log(
            level: logLevel(for: event.outcome),
            "stage=\(event.stage, privacy: .public) outcome=\(event.outcome.rawValue, privacy: .public) operationID=\(event.operationID.uuidString, privacy: .public) errorCode=\(code, privacy: .public)"
        )
        do {
            try await store.record(event)
        } catch {
            let nsError = error as NSError
            logger.error(
                "diagnosticPersistenceFailed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
        }
    }

    func makeExport() async throws -> URL {
        let operationID = UUID()
        await record(
            ProductionDiagnosticEvent(
                operationID: operationID,
                category: .diagnostics,
                stage: "diagnostics.export",
                outcome: .started
            )
        )
        do {
            let exportURL = try await store.makeExport(
                metadata: .current(),
                legacyEvents:
                    PhotoMemoShareDiagnostics.loadEvents()
            )
            await record(
                ProductionDiagnosticEvent(
                    operationID: operationID,
                    category: .diagnostics,
                    stage: "diagnostics.export",
                    outcome: .succeeded
                )
            )
            return exportURL
        } catch {
            let nsError = error as NSError
            logger.error(
                "diagnosticExportFailed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            let failure = ProductionDiagnosticFailureClassifier
                .diagnosticsExport(
                    error,
                    operationID: operationID,
                    language: .interfaceStored
                )
            await record(
                ProductionDiagnosticEvent(
                    operationID: operationID,
                    category: .diagnostics,
                    stage: "diagnostics.export",
                    outcome: .failed,
                    errorCode: failure.code,
                    systemError: failure.systemError
                )
            )
            throw PhotoMemoError(
                code: .persistenceWriteFailed,
                message: failure.userMessage,
                diagnosticCode: failure.code.rawValue,
                supportID: failure.supportID
            )
        }
    }

    func loadEvents()
    async -> [ProductionDiagnosticEvent] {
        do {
            return try await store.loadEvents()
        } catch {
            let nsError = error as NSError
            logger.error(
                "diagnosticReadFailed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            return []
        }
    }

    private func logLevel(
        for outcome: ProductionDiagnosticOutcome
    ) -> OSLogType {
        switch outcome {
        case .failed:
            return .error
        case .degraded:
            return .default
        case .started,
             .succeeded,
             .cancelled:
            return .info
        }
    }
}
