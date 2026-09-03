#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("Batch task execution transition policy")
struct BatchTaskExecutionTransitionPolicyTests {

    private let policy =
        BatchTaskExecutionTransitionPolicy()

    @Test("static and Live Photo production paths accept their established transitions")
    func acceptsEstablishedProductionPaths() {
        #expect(policy.canApply(.startProcessing, from: .queued))
        #expect(policy.canApply(.recordMetadata, from: .importing))
        #expect(policy.canApply(.recordPreview, from: .metadataReady))
        #expect(policy.canApply(.startExport, from: .previewReady))
        #expect(policy.canApply(.startExport, from: .importing))
        #expect(policy.canApply(.startPhotoLibrarySave, from: .exporting))
        #expect(policy.canApply(.complete, from: .savingToPhotoLibrary))
        #expect(policy.canApply(.complete, from: .exporting))
    }

    @Test("recovery and failure transitions retain their established semantics")
    func acceptsRecoveryAndFailureTransitions() {
        #expect(policy.canApply(.awaitPhotoLibraryReadback, from: .savingToPhotoLibrary))
        #expect(policy.canApply(.awaitPhotoLibraryReadback, from: .exporting))
        #expect(policy.canApply(.fail, from: .importing))
        #expect(policy.canApply(.fail, from: .savingToPhotoLibrary))
        #expect(policy.canApply(.disableRetry, from: .failed))
    }

    @Test("stale, regressive, and post-terminal execution events are rejected")
    func rejectsInvalidTransitions() {
        #expect(!policy.canApply(.recordMetadata, from: .queued))
        #expect(!policy.canApply(.startProcessing, from: .exporting))
        #expect(!policy.canApply(.complete, from: .previewReady))
        #expect(!policy.canApply(.startExport, from: .completed))
        #expect(!policy.canApply(.fail, from: .cancelled))
        #expect(!policy.canApply(.disableRetry, from: .completed))
    }
}
#endif
