import Foundation
import Testing
@testable import MemoMark

@Suite("Durable media runtime", .serialized)
@MainActor
struct DurableBatchTaskExecutionRuntimeTests {
    @Test("An independent owner's cancellation is visible before the next media event")
    func observesExternalCancellation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = BatchQueuePersistence(backend: FileBatchQueuePersistenceBackend(baseDirectoryURL: directory))
        let worker = BatchQueueDurableLedger.bootstrap(persistence: persistence).ledger
        let controller = BatchQueueDurableLedger.bootstrap(persistence: persistence).ledger
        var job = makeJob()
        job.executionSessionID = UUID()
        _ = await worker.admit(job)
        let reference = BatchTaskReference(jobID: job.id, taskID: job.tasks[0].id)
        let runtime = DurableBatchTaskExecutionRuntime(ledger: worker, jobIDs: [job.id])
        #expect(await runtime.executionState(at: reference)?.task.phase == .queued)
        _ = await controller.cancelExecutionSession(job.executionSessionID ?? job.id)
        #expect(await runtime.executionState(at: reference)?.task.phase == .cancelled)
        #expect(await runtime.accept(.processingStarted(progress: .init(currentUnit: 1, totalUnits: 5, stage: .readingOriginal)), at: reference) == false)
        #expect(await worker.refreshedSnapshot().jobs.first?.tasks.first?.phase == .cancelled)
    }

    @Test("An executor cannot mutate a different Share request")
    func rejectsForeignJob() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let ledger = BatchQueueDurableLedger.bootstrap(persistence: .init(backend: FileBatchQueuePersistenceBackend(baseDirectoryURL: directory))).ledger
        let first = makeJob(), second = makeJob()
        _ = await ledger.admit(first)
        _ = await ledger.admit(second)
        let runtime = DurableBatchTaskExecutionRuntime(ledger: ledger, jobIDs: [first.id])
        let reference = BatchTaskReference(jobID: second.id, taskID: second.tasks[0].id)
        #expect(await runtime.executionState(at: reference) == nil)
        #expect(await runtime.accept(.processingStarted(progress: .init(currentUnit: 1, totalUnits: 5, stage: .readingOriginal)), at: reference) == false)
        #expect(await ledger.refreshedSnapshot().jobs.first(where: { $0.id == second.id })?.tasks.first?.phase == .queued)
    }

    private func makeJob() -> BatchJob {
        .init(title: "Share", state: .queued,
              configuration: .init(template: .classicWhite, badge: nil, anchor: nil,
                                   shouldWritePhotoDescription: false, photoDescriptionOverride: "", selectedAlbumIdentifier: ""),
              tasks: [.init(sourceURL: URL(fileURLWithPath: "/tmp/\(UUID()).jpg"))])
    }
}
