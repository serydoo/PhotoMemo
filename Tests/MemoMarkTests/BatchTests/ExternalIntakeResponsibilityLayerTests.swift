import Foundation
import Synchronization
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import MemoMark

@Suite("External intake responsibility layers")
struct ExternalIntakeResponsibilityLayerTests {

    @Test("Intake hold persists without dropping sources and old requests remain runnable")
    func durableIntakeHold() throws {
        let suite = "IntakeHold-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let request = ExternalPhotoIntakeRequest(launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/preserved-source.jpg")], configurationSnapshot: Self.configurationSnapshot)
        let store = ExternalIntakeRequestStore(defaults: defaults)
        #expect(store.persistRequest(request, diagnosticsSeed: .init()) == nil)
        let date = Date(timeIntervalSince1970: 100)
        guard case .success = store.suspendRequest(request.id, at: date) else {
            Issue.record("Hold must persist"); return
        }
        let restored = ExternalIntakeRequestStore(defaults: defaults).loadRequestsForProcessing()
        #expect(restored.count == 1)
        #expect(restored.first?.executionSuspendedAt == date)
        #expect(restored.first?.urls == request.urls)
        #expect(restored.first?.configurationSnapshot == request.configurationSnapshot)
        var legacy = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
        legacy.removeValue(forKey: "executionSuspendedAt")
        let decoded = try JSONDecoder().decode(ExternalPhotoIntakeRequest.self, from: JSONSerialization.data(withJSONObject: legacy))
        #expect(decoded.executionSuspendedAt == nil)
    }

    @Test("Corrupt intake metadata is never replaced by a suspension write")
    func corruptIntakeHoldFailsClosed() throws {
        let suite = "CorruptIntakeHold-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let evidence = Data("unreadable intake evidence".utf8)
        defaults.set(evidence, forKey: ExternalIntakeRequestStore.storageKey)
        let store = ExternalIntakeRequestStore(defaults: defaults)
        guard case .encodingFailed = store.suspendRequest(UUID()) else {
            Issue.record("Corrupt metadata must reject hold mutation"); return
        }
        #expect(defaults.data(forKey: ExternalIntakeRequestStore.storageKey) == evidence)
    }

    @Test("Repeated holds preserve the initial timestamp and a later Share")
    func repeatedHoldPreservesLaterRequest() throws {
        let suite = "RepeatedIntakeHold-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = ExternalPhotoIntakeRequest(launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/first-held.jpg")], configurationSnapshot: Self.configurationSnapshot)
        let next = ExternalPhotoIntakeRequest(launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/next-runnable.jpg")], configurationSnapshot: Self.configurationSnapshot)
        let store = ExternalIntakeRequestStore(defaults: defaults)
        #expect(store.persistRequest(first, diagnosticsSeed: .init()) == nil)
        let initial = Date(timeIntervalSince1970: 100)
        guard case .success = store.suspendRequest(first.id, at: initial) else {
            Issue.record("Initial hold failed"); return
        }
        #expect(store.persistRequest(next, diagnosticsSeed: .init()) == nil)
        guard case .success = store.suspendRequest(first.id, at: Date(timeIntervalSince1970: 200)) else {
            Issue.record("Repeated hold failed"); return
        }
        let requests = store.loadRequestsForProcessing()
        #expect(requests.count == 2)
        #expect(requests.first(where: { $0.id == first.id })?.executionSuspendedAt == initial)
        #expect(requests.first(where: { $0.id == next.id }) == next)
    }

    @Test("Multiple Share requests reserve one continuation and close atomically after drain")
    func continuationCoalescesAndDrains() throws {
        let suite = "ContinuationDrain-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ExternalIntakeRequestStore(defaults: defaults)
        let secondStore = ExternalIntakeRequestStore(defaults: defaults)
        let first = UUID(), next = UUID()
        let now = Date(timeIntervalSince1970: 100)
        #expect(try store.reserveContinuation(requestID: first, identifier: "owner-one", now: now) == "owner-one")
        #expect(try store.nextContinuation(identifier: "owner-one", now: now) == first)
        #expect(try secondStore.reserveContinuation(requestID: next, identifier: "owner-two", now: now) == "owner-one")
        #expect(try secondStore.reserveContinuation(requestID: next, identifier: "owner-three", now: now) == "owner-one")
        #expect(try store.nextContinuation(identifier: "owner-one", now: now) == next)
        #expect(try store.nextContinuation(identifier: "owner-one", now: now) == nil)
        #expect(try secondStore.reserveContinuation(requestID: UUID(), identifier: "after-close", now: now) == "after-close")
        #expect(try store.finishContinuation(identifier: "owner-one").isEmpty)
    }

    @Test("Continuation stop retains all accepted request IDs and stale registration can recover")
    func continuationStopAndStaleRecovery() throws {
        let suite = "ContinuationStop-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ExternalIntakeRequestStore(defaults: defaults)
        let first = UUID(), next = UUID(), replacement = UUID()
        let now = Date(timeIntervalSince1970: 100)
        _ = try store.reserveContinuation(requestID: first, identifier: "stopped", now: now)
        _ = try store.nextContinuation(identifier: "stopped", now: now)
        _ = try store.reserveContinuation(requestID: next, identifier: "joined", now: now)
        #expect(Set(try store.finishContinuation(identifier: "stopped")) == Set([first, next]))
        _ = try store.reserveContinuation(requestID: replacement, identifier: "new", now: now)
        #expect(try store.reserveContinuation(requestID: UUID(), identifier: "stale-replacement", now: now.addingTimeInterval(181)) == "stale-replacement")
        #expect(try store.finishContinuation(identifier: "new").isEmpty)
    }

    @Test("Stopping a continuation holds every durable intake before closing the route")
    func continuationStopPersistsAllHolds() throws {
        let suite = "ContinuationAtomicHold-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ExternalIntakeRequestStore(defaults: defaults)
        let requests = (0..<2).map { index in
            ExternalPhotoIntakeRequest(launchSource: .shareExtension,
                urls: [URL(fileURLWithPath: "/tmp/atomic-hold-\(index).jpg")],
                configurationSnapshot: Self.configurationSnapshot)
        }
        for request in requests {
            #expect(store.persistRequest(request, diagnosticsSeed: .init()) == nil)
            _ = try store.reserveContinuation(requestID: request.id, identifier: "owner")
        }
        let stoppedAt = Date(timeIntervalSince1970: 100)
        #expect(Set(try store.finishContinuation(identifier: "owner", suspendRequestsAt: stoppedAt)) == Set(requests.map(\.id)))
        let restored = ExternalIntakeRequestStore(defaults: defaults).loadRequestsForProcessing()
        #expect(restored.count == 2)
        #expect(restored.allSatisfy { $0.executionSuspendedAt == stoppedAt })
        #expect(restored.map(\.urls) == requests.map(\.urls))
        #expect(defaults.data(forKey: ExternalIntakeRequestStore.continuationKey) == nil)
    }

    @Test("Concurrent independent Share stores append once to a single continuation")
    func concurrentContinuationReservations() throws {
        let suite = "ConcurrentContinuation-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let lockURL = FileManager.default.temporaryDirectory.appendingPathComponent(suite + ".lock")
        defer { try? FileManager.default.removeItem(at: lockURL) }
        let store = ExternalIntakeRequestStore(defaults: defaults, lockURL: lockURL)
        let first = UUID(), additional = (0..<24).map { _ in UUID() }
        _ = try store.reserveContinuation(requestID: first, identifier: "one-owner")
        let results = Mutex<[String]>([])
        DispatchQueue.concurrentPerform(iterations: additional.count * 2) { index in
            do {
                guard let otherDefaults = UserDefaults(suiteName: suite) else { return }
                let independent = ExternalIntakeRequestStore(defaults: otherDefaults, lockURL: lockURL)
                let owner = try independent.reserveContinuation(requestID: additional[index % additional.count], identifier: "candidate-\(index)")
                results.withLock { $0.append(owner) }
            } catch { results.withLock { $0.append("failed") } }
        }
        #expect(results.withLock { $0.count } == additional.count * 2)
        #expect(results.withLock { $0.allSatisfy { $0 == "one-owner" } })
        var drained: [UUID] = []
        while let next = try store.nextContinuation(identifier: "one-owner") { drained.append(next) }
        #expect(drained.count == additional.count + 1)
        #expect(Set(drained) == Set(additional + [first]))
    }

    @Test("Interrupted continuation metadata write recovers the associated durable Share")
    func interruptedContinuationAppendRecovers() throws {
        let suite = "InterruptedContinuation-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ExternalIntakeRequestStore(defaults: defaults)
        let first = ExternalPhotoIntakeRequest(launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/first-recovery.jpg")], configurationSnapshot: Self.configurationSnapshot)
        let next = ExternalPhotoIntakeRequest(launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/next-recovery.jpg")], configurationSnapshot: Self.configurationSnapshot)
        #expect(store.persistRequest(first, diagnosticsSeed: .init()) == nil)
        _ = try store.reserveContinuation(requestID: first.id, identifier: "owner")
        #expect(store.persistRequest(next, diagnosticsSeed: .init()) == nil)
        let original = try #require(defaults.data(forKey: ExternalIntakeRequestStore.continuationKey))
        let fault = ExternalIntakeRequestStore(defaults: defaults, synchronizeDefaults: {
            defaults.set(original, forKey: ExternalIntakeRequestStore.continuationKey)
            return true
        })
        #expect(throws: (any Error).self) {
            _ = try fault.reserveContinuation(requestID: next.id, identifier: "other")
        }
        #expect(defaults.data(forKey: ExternalIntakeRequestStore.continuationKey) == original)
        #expect(store.loadRequestsForProcessing().first(where: { $0.id == next.id })?.continuedExecutionSessionID == first.id)
        #expect(try store.nextContinuation(identifier: "owner") == first.id)
        #expect(try store.nextContinuation(identifier: "owner") == next.id)
        #expect(try store.nextContinuation(identifier: "owner") == nil)
        #expect(store.loadRequestsForProcessing().map(\.urls) == [first.urls, next.urls])
    }

    @Test("Corrupt continuation evidence fails closed without losing durable intake")
    func corruptContinuationIsPreserved() throws {
        let suite = "CorruptContinuation-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ExternalIntakeRequestStore(defaults: defaults)
        let request = ExternalPhotoIntakeRequest(launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/protected.jpg")], configurationSnapshot: Self.configurationSnapshot)
        #expect(store.persistRequest(request, diagnosticsSeed: .init()) == nil)
        let evidence = Data("corrupted continuation".utf8)
        defaults.set(evidence, forKey: ExternalIntakeRequestStore.continuationKey)
        #expect(throws: (any Error).self) { _ = try store.reserveContinuation(requestID: request.id, identifier: "replacement") }
        #expect(throws: (any Error).self) { _ = try store.finishContinuation(identifier: "replacement", suspendRequestsAt: Date()) }
        #expect(defaults.data(forKey: ExternalIntakeRequestStore.continuationKey) == evidence)
        #expect(store.loadRequestsForProcessing() == [request])
    }

    @Test("Request store preserves the existing JSON request contract when persisting and draining")
    func requestStorePreservesJSONContract() throws {

        let suiteName =
            "MemoMark.ExternalIntakeResponsibilityLayerTests.Requests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let request =
            ExternalPhotoIntakeRequest(
                id: UUID(),
                launchSource: .shareExtension,
                urls: [
                    URL(fileURLWithPath: "/tmp/ExternalIntake/managed.heic")
                ],
                configurationSnapshot:
                    Self.configurationSnapshot,
                importSummary:
                    ExternalPhotoImportSummary(
                        importedCount: 1,
                        skippedCount: 0,
                        failedCount: 0
                    )
            )
        let store =
            ExternalIntakeRequestStore(
                defaults: defaults
            )

        let failure =
            store.persistRequest(
                request,
                diagnosticsSeed: .init()
            )

        #expect(failure == nil)
        let persistedData =
            try #require(
                defaults.data(
                    forKey:
                        ExternalIntakeRequestStore
                        .storageKey
                )
            )
        #expect(
            try JSONDecoder().decode(
                [ExternalPhotoIntakeRequest].self,
                from: persistedData
            )
            == [request]
        )

        let drainResult =
            store.drainRequestsResult()

        #expect(drainResult.requests == [request])
        switch drainResult.clearPersistedRequestsResult {
        case .success:
            break
        case .encodingFailed:
            Issue.record(
                "Expected draining persisted requests to clear request storage."
            )
        case nil:
            Issue.record(
                "Expected a persistence result when draining a stored request."
            )
        }
        #expect(
            try JSONDecoder().decode(
                [ExternalPhotoIntakeRequest].self,
                from: try #require(
                    defaults.data(
                        forKey:
                            ExternalIntakeRequestStore
                            .storageKey
                    )
                )
            )
            .isEmpty
        )

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Acknowledging one request preserves requests appended after the drain")
    func acknowledgingOneRequestPreservesLaterRequests() throws {

        let suiteName =
            "MemoMark.ExternalIntakeResponsibilityLayerTests.Ack.\(UUID().uuidString)"
        let defaults =
            try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = ExternalIntakeRequestStore(defaults: defaults)
        let firstRequest = ExternalPhotoIntakeRequest(
            id: UUID(),
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/first.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )
        let laterRequest = ExternalPhotoIntakeRequest(
            id: UUID(),
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/later.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )

        #expect(
            store.persistRequest(firstRequest, diagnosticsSeed: .init()) == nil
        )
        _ = store.loadRequestsForProcessing()
        #expect(
            store.persistRequest(laterRequest, diagnosticsSeed: .init()) == nil
        )

        switch store.acknowledgeRequests(Set([firstRequest.id])) {
        case .success:
            break
        case .encodingFailed:
            Issue.record("Expected request acknowledgement to persist")
        }

        switch store.loadRequestsResult() {
        case .success(let requests):
            #expect(requests == [laterRequest])
        case .noValue, .decodingFailed:
            Issue.record("Expected the later request to remain persisted")
        }
    }

    @Test("Persisting a new request does not overwrite a corrupted request payload")
    func persistingRequestPreservesCorruptedPayload() throws {

        let suiteName =
            "MemoMark.ExternalIntakeResponsibilityLayerTests.CorruptedAppend.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let corruptedPayload = Data("corrupted-intake".utf8)
        defaults.set(
            corruptedPayload,
            forKey: ExternalIntakeRequestStore.storageKey
        )
        let store = ExternalIntakeRequestStore(defaults: defaults)
        let request = ExternalPhotoIntakeRequest(
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/new-request.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )

        let failure = store.persistRequest(
            request,
            diagnosticsSeed: .init()
        )

        #expect(failure != nil)
        #expect(
            defaults.data(
                forKey: ExternalIntakeRequestStore.storageKey
            ) == corruptedPayload
        )
    }

    @Test("Managed file store keeps already-managed identity and deduplicates normalized inputs")
    func managedFileStorePreservesManagedIdentityAndDeduplication() throws {

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "MemoMark.ExternalIntakeResponsibilityLayerTests.Managed.\(UUID().uuidString)",
                isDirectory: true
            )
        let intakeDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
        let requestDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
        let managedURL =
            requestDirectoryURL
            .appendingPathComponent(
                "IMG_9558.HEIC"
            )

        try FileManager.default.createDirectory(
            at: requestDirectoryURL,
            withIntermediateDirectories: true
        )
        try Self.smallJPEGData().write(
            to: managedURL
        )

        let store =
            ManagedIntakeFileStore(
                intakeDirectoryURL:
                    intakeDirectoryURL
            )
        let result =
            store.createManagedCopyDetailed(
                from: managedURL,
                requestID: UUID(),
                index: 0
            )

        #expect(
            result.managedURL
            == managedURL.standardizedFileURL
        )
        #expect(
            result.temporaryCopyResult
            == "already-managed"
        )
        #expect(
            store.uniqueStandardizedURLs(
                from: [managedURL, managedURL]
            )
            == [managedURL.standardizedFileURL]
        )

        try? FileManager.default.removeItem(
            at: rootDirectoryURL
        )
    }

    @Test("Cleanup service removes only unreferenced managed content")
    func cleanupServicePreservesReferencesAndExternalFiles() throws {

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "MemoMark.ExternalIntakeResponsibilityLayerTests.Cleanup.\(UUID().uuidString)",
                isDirectory: true
            )
        let intakeDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
        let retainedDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                "retained-request",
                isDirectory: true
            )
        let orphanDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                "orphan-request",
                isDirectory: true
            )
        let retainedURL =
            retainedDirectoryURL
            .appendingPathComponent("retained.jpg")
        let orphanSiblingURL =
            retainedDirectoryURL
            .appendingPathComponent("orphan.jpg")
        let orphanRequestURL =
            orphanDirectoryURL
            .appendingPathComponent("orphan.jpg")
        let prefixSiblingDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "ExternalIntake-Originals",
                isDirectory: true
            )
        let externalURL =
            prefixSiblingDirectoryURL
            .appendingPathComponent("original.jpg")

        for directoryURL in [
            retainedDirectoryURL,
            orphanDirectoryURL,
            prefixSiblingDirectoryURL
        ] {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }
        for fileURL in [
            retainedURL,
            orphanSiblingURL,
            orphanRequestURL,
            externalURL
        ] {
            try Data([1]).write(
                to: fileURL
            )
        }

        let service =
            IntakeCleanupService(
                intakeDirectoryURL:
                    intakeDirectoryURL
            )

        service.cleanupOrphanedManagedContent(
            keepingReferencedURLs: [
                retainedURL
            ]
        )
        service.cleanupManagedSourceIfNeeded(
            at: externalURL
        )

        #expect(
            FileManager.default.fileExists(
                atPath: retainedURL.path
            )
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: orphanSiblingURL.path
            )
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: orphanDirectoryURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: externalURL.path
            )
        )

        service.cleanupManagedSourceIfNeeded(
            at: retainedURL
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: retainedURL.path
            )
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: retainedDirectoryURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: externalURL.path
            )
        )

        try? FileManager.default.removeItem(
            at: rootDirectoryURL
        )
    }

    @Test("Request store keeps intake unacknowledged when the shared lock cannot be acquired")
    func requestStoreReportsLockFailureWithoutPersistingOrDroppingTheRequest() throws {

        let suiteName =
            "MemoMark.ExternalIntakeResponsibilityLayerTests.LockFailure.\(UUID().uuidString)"
        let defaults =
            try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let blockerURL =
            FileManager.default.temporaryDirectory
                .appendingPathComponent(suiteName)
        try Data("lock-parent-is-a-file".utf8).write(to: blockerURL)
        defer {
            try? FileManager.default.removeItem(at: blockerURL)
        }

        let request = ExternalPhotoIntakeRequest(
            id: UUID(),
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/managed-lock-failure.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )
        let store = ExternalIntakeRequestStore(
            defaults: defaults,
            lockURL: blockerURL.appendingPathComponent("requests.lock")
        )

        let failure = store.persistRequest(request, diagnosticsSeed: .init())

        #expect(failure != nil)
        #expect(
            defaults.data(forKey: ExternalIntakeRequestStore.storageKey)
            == nil
        )
    }

    @Test("Request persistence trusts verified read-back when synchronize reports false")
    func requestStoreDoesNotTreatSynchronizeFalseAsWriteFailure() throws {
        let suiteName =
            "MemoMark.ExternalIntakeResponsibilityLayerTests.SynchronizeFalse.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let request = ExternalPhotoIntakeRequest(
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/managed-synchronize-false.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )
        let store = ExternalIntakeRequestStore(
            defaults: defaults,
            synchronizeDefaults: { false }
        )

        let failure = store.persistRequest(
            request,
            diagnosticsSeed: .init()
        )

        #expect(failure == nil)
        switch store.loadRequestsResult() {
        case .success(let requests):
            #expect(requests == [request])
        case .noValue,
             .decodingFailed:
            Issue.record("Expected persisted request after verified read-back")
        }
    }
}

private extension ExternalIntakeResponsibilityLayerTests {

    static var configurationSnapshot:
        BatchConfigurationSnapshot {

        BatchConfigurationSnapshot(
            template:
                .classicWhite.normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
    }

    static func smallJPEGData() throws -> Data {

        let colorSpace =
            try #require(
                CGColorSpace(
                    name:
                        CGColorSpace.sRGB
                )
            )
        let context =
            try #require(
                CGContext(
                    data: nil,
                    width: 1,
                    height: 1,
                    bitsPerComponent: 8,
                    bytesPerRow: 4,
                    space: colorSpace,
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )
        context.setFillColor(
            CGColor(
                red: 0.4,
                green: 0.5,
                blue: 0.6,
                alpha: 1
            )
        )
        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: 1,
                height: 1
            )
        )

        let image =
            try #require(
                context.makeImage()
            )
        let data =
            NSMutableData()
        let destination =
            try #require(
                CGImageDestinationCreateWithData(
                    data,
                    UTType.jpeg.identifier
                        as CFString,
                    1,
                    nil
                )
            )
        CGImageDestinationAddImage(
            destination,
            image,
            nil
        )
        #expect(
            CGImageDestinationFinalize(
                destination
            )
        )
        return data as Data
    }
}
