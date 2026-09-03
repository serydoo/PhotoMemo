#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@MainActor
@Suite("V1 subject persistence runtime coordinator")
struct SubjectPersistenceTransactionSchedulerTests {

    @Test("a request without an aggregate candidate synchronizes without writing")
    func noCandidateSynchronizesWithoutWriting() async {
        var saveCount = 0
        var updates: [SubjectPersistenceUpdate] = []
        let coordinator = SubjectPersistenceTransactionScheduler {
            _ in
            saveCount += 1
            throw TestFailure(message: "unexpected save")
        }

        coordinator.submit(candidate: nil) {
            updates.append($0)
        }
        await waitUntil { updates.count == 1 }

        #expect(saveCount == 0)
        #expect(
            updates == [
                .completed(
                    .init(
                        durableCandidate: nil,
                        status: .subjectSynced
                    )
                )
            ]
        )
    }

    @Test("a durable receipt publishes the saved revision")
    func durableReceiptPublishesRevision() async throws {
        let aggregate = try Self.makeAggregate(revision: 11)
        var updates: [SubjectPersistenceUpdate] = []
        let coordinator = SubjectPersistenceTransactionScheduler {
            candidate in
            Self.receipt(for: candidate, revision: 12)
        }

        coordinator.submit(candidate: aggregate) {
            updates.append($0)
        }
        await waitUntil {
            updates.contains(where: \.isCompleted)
        }

        #expect(updates.first == .saving)
        let completion = try #require(updates.last?.completion)
        #expect(completion.durableCandidate?.revision == 12)
        #expect(completion.status == .subjectSynced)
    }

    @Test("a newer request supersedes a delayed completion and saves latest snapshot")
    func newerRequestSupersedesDelayedCompletion() async throws {
        let first = try Self.makeAggregate(revision: 11)
        let second = first
        let saver = ControlledSaver()
        var firstUpdates: [SubjectPersistenceUpdate] = []
        var secondUpdates: [SubjectPersistenceUpdate] = []
        let coordinator = SubjectPersistenceTransactionScheduler {
            try await saver.save($0)
        }

        coordinator.submit(candidate: first) {
            firstUpdates.append($0)
        }
        await waitUntil { saver.candidates.count == 1 }

        coordinator.submit(candidate: second) {
            secondUpdates.append($0)
        }
        #expect(secondUpdates == [.queued])

        saver.succeedNext(revision: 12)
        await waitUntil { saver.candidates.count == 2 }
        #expect(firstUpdates == [.saving])
        #expect(saver.candidates.map(\.revision) == [11, 12])

        saver.succeedNext(revision: 13)
        await waitUntil {
            secondUpdates.contains(where: \.isCompleted)
        }

        #expect(secondUpdates.first == .queued)
        #expect(secondUpdates.contains(.saving))
        let completion = try #require(secondUpdates.last?.completion)
        #expect(completion.durableCandidate?.revision == 13)
        #expect(completion.status == .subjectSynced)
    }

    @Test("a queued edit reverted to the baseline still overwrites a successful intermediate save")
    func queuedRevertStillWritesAfterIntermediateSuccess() async throws {
        let baseline = try Self.makeAggregate(revision: 14)
        let saver = ControlledSaver()
        var updates: [SubjectPersistenceUpdate] = []
        let coordinator = SubjectPersistenceTransactionScheduler {
            try await saver.save($0)
        }

        coordinator.submit(candidate: baseline) { _ in }
        await waitUntil { saver.candidates.count == 1 }
        coordinator.submit(
            candidate: baseline,
            requiresWrite: false
        ) {
            updates.append($0)
        }
        #expect(updates == [.queued])

        saver.succeedNext(revision: 15)
        await waitUntil { saver.candidates.count == 2 }
        #expect(saver.candidates.map(\.revision) == [14, 15])

        saver.succeedNext(revision: 16)
        await waitUntil {
            updates.contains(where: \.isCompleted)
        }
        #expect(
            updates.last?.completion?.durableCandidate?.revision
                == 16
        )
    }

    @Test("a stale failure cannot replace the newer request status")
    func staleFailureDoesNotPublish() async throws {
        let first = try Self.makeAggregate(revision: 31)
        let second = first
        let saver = ControlledSaver()
        var firstUpdates: [SubjectPersistenceUpdate] = []
        var secondUpdates: [SubjectPersistenceUpdate] = []
        let coordinator = SubjectPersistenceTransactionScheduler {
            try await saver.save($0)
        }

        coordinator.submit(candidate: first) {
            firstUpdates.append($0)
        }
        await waitUntil { saver.candidates.count == 1 }
        coordinator.submit(candidate: second) {
            secondUpdates.append($0)
        }

        saver.failNext(TestFailure(message: "stale failure"))
        await waitUntil { saver.candidates.count == 2 }
        #expect(firstUpdates == [.saving])

        saver.succeedNext(revision: 42)
        await waitUntil {
            secondUpdates.contains(where: \.isCompleted)
        }
        #expect(
            !secondUpdates.contains {
                $0.completion?.status
                    == .failure(message: "stale failure")
            }
        )
        #expect(
            secondUpdates.last?.completion?.status
                == .subjectSynced
        )
    }

    @Test("a compatibility projection failure keeps the durable result with a warning")
    func compatibilityProjectionFailureReturnsWarning() async throws {
        let aggregate = try Self.makeAggregate(revision: 45)
        let operationID = UUID()
        var updates: [SubjectPersistenceUpdate] = []
        let coordinator = SubjectPersistenceTransactionScheduler {
            candidate in
            ConfigurationLibrarySaveReceipt(
                revision: 46,
                subjectID: candidate.activeSubjectID!,
                configurationID: candidate.activeConfigurationID!,
                configurationRevision: 2,
                compatibilityProjectionFailure:
                    ConfigurationLibraryProjectionFailure(
                        underlyingDescription: "projection failed"
                    ),
                diagnosticOperationID: operationID
            )
        }

        coordinator.submit(candidate: aggregate) {
            updates.append($0)
        }
        await waitUntil {
            updates.contains(where: \.isCompleted)
        }

        let completion = try #require(updates.last?.completion)
        #expect(completion.durableCandidate?.revision == 46)
        guard case .savedWithWarning(let message) = completion.status else {
            Issue.record("Expected the durable save warning status.")
            return
        }
        let expected = ProductionDiagnosticFailureClassifier
            .compatibilityProjection(
                operationID: operationID,
                language: .interfaceStored
            )
        #expect(message == expected.userMessage)
    }

    @Test("a current failure is retryable and preserves its message")
    func currentFailureAllowsRetry() async throws {
        let aggregate = try Self.makeAggregate(revision: 51)
        var attempts = 0
        var updates: [SubjectPersistenceUpdate] = []
        let coordinator = SubjectPersistenceTransactionScheduler {
            candidate in
            attempts += 1
            if attempts == 1 {
                throw MemoMarkError(
                    code: .invalidState,
                    message: "请稍后重试"
                )
            }
            return Self.receipt(for: candidate, revision: 52)
        }

        coordinator.submit(candidate: aggregate) {
            updates.append($0)
        }
        await waitUntil {
            updates.contains(where: \.isCompleted)
        }
        #expect(
            updates.last?.completion?.status
                == .failure(message: "请稍后重试")
        )

        coordinator.submit(candidate: aggregate) {
            updates.append($0)
        }
        await waitUntil {
            updates.filter(\.isCompleted).count == 2
        }
        #expect(attempts == 2)
        #expect(
            updates.last?.completion?.status
                == .subjectSynced
        )
    }
}

private extension SubjectPersistenceTransactionSchedulerTests {

    struct TestFailure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    @MainActor
    final class ControlledSaver {
        private(set) var candidates: [ConfigurationLibraryRecord] = []
        private var pendingCandidates: [ConfigurationLibraryRecord] = []
        private var continuations: [
            CheckedContinuation<ConfigurationLibrarySaveReceipt, Error>
        ] = []

        func save(
            _ candidate: ConfigurationLibraryRecord
        ) async throws -> ConfigurationLibrarySaveReceipt {
            candidates.append(candidate)
            pendingCandidates.append(candidate)
            return try await withCheckedThrowingContinuation {
                continuations.append($0)
            }
        }

        func succeedNext(revision: Int) {
            let candidate = pendingCandidates.removeFirst()
            continuations.removeFirst().resume(
                returning: SubjectPersistenceTransactionSchedulerTests
                    .receipt(for: candidate, revision: revision)
            )
        }

        func failNext(_ error: Error) {
            pendingCandidates.removeFirst()
            continuations.removeFirst().resume(throwing: error)
        }
    }

    func waitUntil(
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        for _ in 0..<200 where !condition() {
            await Task.yield()
        }
        #expect(condition())
    }

    static func receipt(
        for aggregate: ConfigurationLibraryRecord,
        revision: Int
    ) -> ConfigurationLibrarySaveReceipt {
        ConfigurationLibrarySaveReceipt(
            revision: revision,
            subjectID: aggregate.activeSubjectID!,
            configurationID: aggregate.activeConfigurationID!,
            configurationRevision: 1,
            compatibilityProjectionFailure: nil
        )
    }

    static func makeAggregate(
        revision: Int
    ) throws -> ConfigurationLibraryRecord {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let configuration = MemoryConfigurationRecord(
            id: UUID(),
            title: "对象配置",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 300),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(mode: .appleMini, badge: nil)
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
        return ConfigurationLibraryRecord(
            revision: revision,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )
    }
}

private extension SubjectPersistenceUpdate {
    var isCompleted: Bool {
        completion != nil
    }

    var completion: SubjectPersistenceCompletion? {
        guard case .completed(let completion) = self else {
            return nil
        }
        return completion
    }
}
#endif
