import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemoShareIntakeDiagnostics")
struct PhotoMemoShareIntakeDiagnosticsTests {

    @Test("Captures nested underlying NSError summaries")
    func capturesNestedUnderlyingNSErrorSummaries() {

        let leafError =
            NSError(
                domain: "LeafDomain",
                code: 99,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Leaf failure"
                ]
            )

        let rootError =
            NSError(
                domain: "RootDomain",
                code: 12,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Root failure",
                    NSUnderlyingErrorKey:
                        leafError
                ]
            )

        let summary =
            PhotoMemoShareIntakeNSErrorSummary(
                nsError: rootError
            )

        #expect(summary.domain == "RootDomain")
        #expect(summary.code == 12)
        #expect(summary.localizedDescription == "Root failure")
        #expect(summary.underlyingError?.domain == "LeafDomain")
        #expect(summary.underlyingError?.code == 99)
        #expect(summary.underlyingError?.localizedDescription == "Leaf failure")
    }
}
