import Foundation
import Testing
@testable import MemoMark

@Suite("Batch queue resume source inspection")
struct BatchQueueResumeSourceInspectorTests {

    @Test("Only a missing managed intake copy becomes a recovery failure")
    @MainActor
    func onlyMissingManagedIntakeCopyIsReported() {
        let intakeRoot = URL(
            fileURLWithPath: "/tmp/MemoMarkResumeInspector.\(UUID().uuidString)",
            isDirectory: true
        )
        let inspector = BatchQueueResumeSourceInspector(
            intakeRoot: intakeRoot
        )

        #expect(
            inspector.isMissingManagedSource(
                intakeRoot.appendingPathComponent("missing.jpg")
            )
        )
        #expect(
            !inspector.isMissingManagedSource(
                URL(fileURLWithPath: "/tmp/outside-intake.jpg")
            )
        )
    }

    @Test("Missing managed input uses the established interrupted diagnostic")
    @MainActor
    func missingManagedInputUsesInterruptedDiagnostic() {
        let failure = BatchQueueResumeSourceInspector()
            .missingSourceFailure(
                phase: .exporting,
                taskID: UUID()
            )

        #expect(failure.phase == .exporting)
        #expect(failure.classification == .interrupted)
        #expect(failure.canRetry == false)
        #expect(failure.diagnosticCode == "processing.source.missing")
    }
}
