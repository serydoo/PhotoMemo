#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Resolves the shared recovery facts for an interrupted managed intake file.
/// It deliberately does not normalize queue state or persist anything: both
/// the startup adapter and runtime recovery feed these facts into their own
/// appropriate durable boundary.
@MainActor
struct BatchQueueResumeSourceInspector {

    private let fileManager: FileManager

    private let intakeRoot: URL

    init(
        fileManager: FileManager = .default,
        intakeRoot: URL = MemoMarkSharedContainer.externalIntakeDirectoryURL
    ) {
        self.fileManager = fileManager
        self.intakeRoot = intakeRoot.standardizedFileURL
    }

    func isMissingManagedSource(
        _ url: URL
    ) -> Bool {
        let normalizedURL = url.standardizedFileURL
        guard MemoMarkPathContainment.contains(
            normalizedURL,
            root: intakeRoot
        ) else {
            return false
        }
        return !fileManager.fileExists(
            atPath: normalizedURL.path
        )
    }

    func missingSourceFailure(
        phase: BatchTaskPhase,
        taskID: UUID
    ) -> BatchTaskFailure {
        let diagnostic = ProductionDiagnosticFailureClassifier.processing(
            phase: phase.rawValue,
            classification: BatchTaskFailure.Classification.interrupted.rawValue,
            operationID: taskID,
            error: CocoaError(.fileNoSuchFile),
            language: .interfaceStored
        )
        return BatchTaskFailure(
            phase: phase,
            message: diagnostic.userMessage,
            classification: .interrupted,
            canRetry: false,
            diagnosticCode: diagnostic.code.rawValue,
            supportID: diagnostic.supportID
        )
    }
}
#endif
