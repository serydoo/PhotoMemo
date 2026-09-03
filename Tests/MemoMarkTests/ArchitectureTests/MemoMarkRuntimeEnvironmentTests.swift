import Foundation
import Testing
@testable import MemoMark

@Suite("Runtime environment presentation policy")
struct MemoMarkRuntimeEnvironmentTests {

    @Test("production environment does not opt into UI-test affordances")
    func productionDefaultsToRealWorkflow() {
        let environment = MemoMarkRuntimeEnvironment(
            isUITestingHarness: false
        )

        #expect(!environment.isUITestingHarness)
    }

    @Test("UI automation is process-scoped and does not mutate durable state")
    func uiAutomationEnvironmentIsExplicit() {
        let environment = MemoMarkRuntimeEnvironment(
            isUITestingHarness: true
        )

        #expect(environment.isUITestingHarness)
        #expect(environment != MemoMarkRuntimeEnvironment(
            isUITestingHarness: false
        ))
    }
}
