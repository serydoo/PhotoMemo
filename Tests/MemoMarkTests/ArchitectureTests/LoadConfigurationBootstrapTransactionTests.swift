#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration bootstrap load transaction")
struct LoadConfigurationBootstrapTransactionTests {

    @Test("returns the canonical bootstrap state without adding presentation fallback semantics")
    func returnsCanonicalBootstrapState() {
        let expected = ConfigurationBootstrapState(
            customLogoBadge: .appleClassic,
            logoMode: .customUpload,
            outputTarget: .existingAlbum,
            selectedExistingAlbumIdentifier: "album-1",
            suggestedNewAlbumName: "成长记录"
        )
        let transaction = LoadConfigurationBootstrapTransaction(
            loadBootstrapState: { .success(expected) }
        )

        switch transaction.apply() {
        case .success(let state):
            #expect(state == expected)
        case .failure(let error):
            Issue.record("Expected canonical bootstrap state, got \(error)")
        }
    }

    @Test("preserves storage failure for the presentation adapter to handle")
    func preservesStorageFailure() {
        let expected = MemoMarkError(
            code: .persistenceReadFailed,
            message: "Configuration storage is unavailable."
        )
        let transaction = LoadConfigurationBootstrapTransaction(
            loadBootstrapState: { .failure(expected) }
        )

        switch transaction.apply() {
        case .success:
            Issue.record("Expected bootstrap storage failure.")
        case .failure(let error):
            #expect(error == expected)
        }
    }
}
#endif
