import Foundation
import Testing
@testable import MemoMark

@Suite("Execution session suspension")
@MainActor struct ExecutionSessionSuspensionTests {
    @Test("Held admission does not join or suspend an unrelated active session")
    func heldAdmissionHasIndependentSession() {
        let active = job(phase: .queued)
        var held = job(phase: .queued)
        held.executionSuspendedAt = Date()
        var jobs = [active]
        let admission = BatchQueueTransitionPolicy().admit(held, into: &jobs)
        #expect(admission.job.executionSessionID != (active.executionSessionID ?? active.id))
        #expect(jobs.first(where: { $0.id == active.id })?.executionSuspendedAt == nil)
        #expect(ExecutionSessionSuspensionPolicy.executablePendingTaskCount(in: jobs) == 1)
    }

    @Test("Late admitted continuation cannot reopen cancelled or deleted history")
    func lateAdmissionHonorsClosedSession() {
        for deleted in [false, true] {
            let sessionID = UUID()
            var closed = job(phase: .cancelled)
            closed.executionSessionID = sessionID
            if deleted { closed.historyDeletedAt = Date() }
            var late = job(phase: .queued)
            late.executionSessionID = sessionID
            var jobs = [closed]
            let admission = BatchQueueTransitionPolicy().admit(late, into: &jobs)
            #expect(admission.job.tasks.allSatisfy { $0.phase == .cancelled })
            #expect((admission.job.historyDeletedAt != nil) == deleted)
            #expect(ExecutionSessionSuspensionPolicy.executablePendingTaskCount(in: jobs) == 0)
        }
    }

    @Test("Background scheduling counts runnable work while preserving visible pending work")
    func runnablePendingCountExcludesHeldAndDeletedJobs() {
        var held = job(phase: .queued)
        held.executionSuspendedAt = Date()
        var deleted = job(phase: .queued)
        deleted.historyDeletedAt = Date()
        let fresh = job(phase: .queued)
        let done = job(phase: .completed)
        #expect(ExecutionSessionSuspensionPolicy.executablePendingTaskCount(in: [held, deleted, fresh, done]) == 1)
        #expect(ExecutionSessionSuspensionPolicy.executablePendingTaskCount(in: [held, deleted]) == 0)
        var resumed = [held]
        #expect(ExecutionSessionSuspensionPolicy.resume(held.executionSessionID ?? held.id, in: &resumed))
        #expect(ExecutionSessionSuspensionPolicy.executablePendingTaskCount(in: resumed) == 1)
    }

    @Test("System stop suspends only its session, retains save evidence, and survives encoding")
    func suspensionRetainsEvidence() throws {
        let id = UUID()
        var stopped = job(phase: .savingToPhotoLibrary)
        stopped.executionSessionID = id
        stopped.tasks[0].savedAssetIdentifier = "submitted-placeholder"
        stopped.tasks.append(BatchTask(sourceURL: URL(fileURLWithPath: "/tmp/saved.jpg"),
            phase: .completed, savedAssetIdentifier: "committed-output"))
        let fresh = job(phase: .queued)
        var jobs = [stopped, fresh]
        #expect(ExecutionSessionSuspensionPolicy.suspend(id, in: &jobs))
        let restored = try JSONDecoder().decode([BatchJob].self, from: JSONEncoder().encode(jobs))
        #expect(restored[0].executionSuspendedAt != nil)
        #expect(restored[0].tasks == stopped.tasks)
        #expect(restored[1].executionSuspendedAt == nil)
        #expect(BatchQueueExecution().nextPendingTaskReference(in: restored)?.jobID == fresh.id)
    }

    @Test("Explicit resume clears only the selected hold and protects an ambiguous PhotoKit save")
    func explicitResume() {
        let id = UUID()
        var stopped = job(phase: .exporting)
        stopped.executionSessionID = id
        stopped.tasks.append(BatchTask(sourceURL: URL(fileURLWithPath: "/tmp/pending.jpg"),
            phase: .savingToPhotoLibrary, savedAssetIdentifier: "placeholder"))
        var other = job(phase: .queued)
        other.executionSuspendedAt = Date()
        var jobs = [stopped, other]
        #expect(ExecutionSessionSuspensionPolicy.suspend(id, in: &jobs))
        #expect(ExecutionSessionSuspensionPolicy.resume(id, in: &jobs))
        #expect(jobs[0].executionSuspendedAt == nil)
        #expect(jobs[0].tasks[0].phase == .queued)
        #expect(jobs[0].tasks[1].phase == .savingToPhotoLibrary)
        #expect(jobs[0].tasks[1].savedAssetIdentifier == "placeholder")
        #expect(jobs[1].executionSuspendedAt != nil)
    }

    @Test("Legacy jobs decode without a hold and fresh shares do not join a suspended session")
    func migrationAndFreshAdmission() throws {
        var stopped = job(phase: .queued)
        stopped.executionSessionID = UUID()
        stopped.executionSuspendedAt = Date()
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(stopped)) as? [String: Any])
        object.removeValue(forKey: "executionSuspendedAt")
        let legacy = try JSONDecoder().decode(BatchJob.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(legacy.executionSuspendedAt == nil)
        var jobs = [stopped]
        let admitted = BatchQueueTransitionPolicy().admit(job(phase: .queued), into: &jobs).job
        #expect(admitted.executionSessionID != stopped.executionSessionID)
    }

    @Test("Independent ledger instances observe a persisted hold and explicit resume")
    func durableHold() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = BatchQueuePersistence(backend: FileBatchQueuePersistenceBackend(baseDirectoryURL: directory))
        let worker = BatchQueueDurableLedger.bootstrap(persistence: persistence).ledger
        let controller = BatchQueueDurableLedger.bootstrap(persistence: persistence).ledger
        let admission = await worker.admit(job(phase: .queued))
        let snapshot: BatchQueueDurableSnapshot
        switch admission {
        case .committed(_, let state), .unchanged(_, let state): snapshot = state
        case .failure: Issue.record("Admission failed"); return
        }
        let member = try #require(snapshot.jobs.first)
        let id = member.executionSessionID ?? member.id
        _ = await worker.suspendExecutionSession(id)
        #expect(await controller.refreshedSnapshot().jobs.first?.executionSuspendedAt != nil)
        _ = await controller.resumeExecutionSession(id)
        #expect(await worker.refreshedSnapshot().jobs.first?.executionSuspendedAt == nil)
    }

    private func job(phase: BatchTaskPhase) -> BatchJob {
        BatchJob(title: "QA", configuration: SettingsService().buildBatchConfigurationSnapshot(),
            tasks: [BatchTask(sourceURL: URL(fileURLWithPath: "/tmp/input.jpg"), phase: phase)])
    }
}
