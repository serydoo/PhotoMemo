import Foundation
import Testing
@testable import MemoMark

@Suite("V1 subject persistence request gate")
struct V1SubjectPersistenceRequestGateTests {

    @Test("a request started while another save is active is retained as newer")
    func activeSaveIsSupersededByNewerRequest() {
        var gate = V1SubjectPersistenceRequestGate()

        let first = gate.begin()
        let second = gate.begin()

        #expect(first == .started(generation: 1))
        #expect(second == .queued(generation: 2))
        #expect(gate.complete(generation: 1) == .superseded)
        #expect(gate.begin() == .started(generation: 3))
        #expect(gate.complete(generation: 3) == .current)
    }

    @Test("a stale completion cannot clear a newer in-flight request")
    func staleCompletionDoesNotClearNewerRequest() {
        var gate = V1SubjectPersistenceRequestGate()

        _ = gate.begin()
        _ = gate.begin()

        #expect(gate.complete(generation: 99) == .superseded)
        #expect(gate.begin() == .queued(generation: 3))
    }

    @Test("cancelling a request without a durable candidate releases the gate")
    func cancellationReleasesGate() {
        var gate = V1SubjectPersistenceRequestGate()

        let request = gate.begin()
        guard case .started(let generation) = request else {
            Issue.record("The first request should start immediately")
            return
        }

        gate.cancel(generation: generation)
        #expect(gate.activeGeneration == nil)
        #expect(gate.begin() == .started(generation: 2))
    }
}
