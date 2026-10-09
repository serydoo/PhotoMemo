import Foundation
import Testing
@testable import MemoMark

@Suite("Processing identity migration and intent")
struct ProcessingIdentityTests {
    @Test("Cancelled identity preparation stops before publishing a prepared job")
    @MainActor func cancelledPreparation() async {
        let job = BatchJob(title: "Cancelled intake", configuration: SettingsService().buildBatchConfigurationSnapshot(), tasks: [])
        let operation = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            do {
                _ = try await BatchProcessingIdentityCompiler.prepare(job)
                return false
            } catch is CancellationError {
                return true
            } catch {
                return false
            }
        }
        #expect(await operation.value)
    }

    @Test("transport timestamps and snapshot IDs do not change output intent")
    func canonicalIntent() throws {
        let a = Data(#"{"id":"one","createdAt":1,"customMemoryWriteText":"Hello","selectedAlbumIdentifier":"A"}"#.utf8)
        let b = Data(#"{"selectedAlbumIdentifier":"A","createdAt":2,"id":"two","customMemoryWriteText":"Hello"}"#.utf8)
        #expect(try ProcessingIdentity.canonicalSemantics(a) == ProcessingIdentity.canonicalSemantics(b))
        let changed = Data(#"{"customMemoryWriteText":"Different","selectedAlbumIdentifier":"A"}"#.utf8)
        #expect(try ProcessingIdentity.canonicalSemantics(a) != ProcessingIdentity.canonicalSemantics(changed))
    }

    @Test("share-generated badge identity is transport, badge appearance is semantic")
    func badgeIdentity() throws {
        let a = Data(#"{"badge":{"id":"first","text":"same"}}"#.utf8)
        let b = Data(#"{"badge":{"id":"second","text":"same"}}"#.utf8)
        let c = Data(#"{"badge":{"id":"second","text":"changed"}}"#.utf8)
        #expect(try ProcessingIdentity.canonicalSemantics(a) == ProcessingIdentity.canonicalSemantics(b))
        #expect(try ProcessingIdentity.canonicalSemantics(a) != ProcessingIdentity.canonicalSemantics(c))
    }

    @Test("verified PhotoKit version identifies regenerated bundles and distinguishes edits")
    func verifiedSourceVersion() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let first = root.appendingPathComponent("first"), second = root.appendingPathComponent("second")
        try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("export-one".utf8).write(to: first.appendingPathComponent("image.heic"))
        try Data("export-two".utf8).write(to: second.appendingPathComponent("image.heic"))
        let builder = ProcessingIdentityBuilder()
        let same = try await builder.identities(sourceURLs: [first, second], semantics: Data("{}".utf8), sourceVersions: ["photokit:asset:1", "photokit:asset:1"])
        #expect(same[0] == same[1])
        let flat = root.appendingPathComponent("recovered.jpeg")
        try Data("regenerated-flat-photo".utf8).write(to: flat)
        let recovered = try await builder.identities(sourceURLs: [flat], semantics: Data("{}".utf8), sourceVersions: ["photokit:asset:1"])
        #expect(same[0] == recovered[0])
        let edited = try await builder.identities(sourceURLs: [second], semantics: Data("{}".utf8), sourceVersions: ["photokit:asset:2"])
        #expect(same[0] != edited[0])
    }

    @Test("source and semantics both contribute to identity")
    func intentComponents() {
        let a = ProcessingIdentity(sourceDigest: "A", semanticsDigest: "S")
        #expect(a == ProcessingIdentity(sourceDigest: "A", semanticsDigest: "S"))
        #expect(a != ProcessingIdentity(sourceDigest: "B", semanticsDigest: "S"))
        #expect(a != ProcessingIdentity(sourceDigest: "A", semanticsDigest: "T"))
    }

    @Test("old task snapshots retain their exact receipt keys")
    func migration() throws {
        let task = BatchTask(sourceURL: URL(fileURLWithPath: "/tmp/source.jpg"))
        let encoded = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(BatchTask.self, from: encoded)
        #expect(decoded.processingIdentity == nil)
        #expect(decoded.photoLibraryIdempotencyKey == task.id.uuidString)
    }
    @Test("global receipts survive history pruning and block duplicate transactions")
    func globalReceipts() throws {
        let suite = "ProcessingIdentityTests-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PhotoLibrarySaveReceiptStore(defaults: defaults)
        let key = ProcessingIdentity(sourceDigest: "source", semanticsDigest: "semantics").receiptKey
        #expect(store.record(assetIdentifier: "saved", for: key))
        store.pruneReceipts(retaining: [])
        #expect(store.assetIdentifier(for: key) == "saved")
        #expect(!store.recordIntent(for: key))
        store.removeReceipts(for: [key])
        #expect(store.assetIdentifier(for: key) == "saved")
    }

    @Test("managed filenames do not change source identity")
    func materializedSources() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let a = root.appendingPathComponent("one.jpg")
        let b = root.appendingPathComponent("two.jpg")
        try Data("same-photo".utf8).write(to: a)
        try Data("same-photo".utf8).write(to: b)
        let identities = try await ProcessingIdentityBuilder.shared.identities(
            sourceURLs: [a, b], semantics: Data(#"{"output":"still"}"#.utf8))
        #expect(identities[0] == identities[1])
    }

    @Test("mutable badge bytes matter while literal file URL text remains user text")
    func assetSemantics() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source.jpg")
        let badge = root.appendingPathComponent("badge.png")
        try Data("photo".utf8).write(to: source)
        try Data("badge-one".utf8).write(to: badge)
        let semantics = try JSONSerialization.data(withJSONObject: ["badge": ["imagePath": badge.path], "customMemoryWriteText": "file:///does/not/exist"])
        let first = try await ProcessingIdentityBuilder.shared.identities(sourceURLs: [source], semantics: semantics)
        try Data("badge-two".utf8).write(to: badge)
        let second = try await ProcessingIdentityBuilder.shared.identities(sourceURLs: [source], semantics: semantics)
        #expect(first != second)
    }

    @Test("identity wire schema keeps v1 keys and rejects unknown versions")
    func identitySchema() throws {
        let old = Data(#"{"sourceDigest":"A","semanticsDigest":"B"}"#.utf8)
        let decoded = try JSONDecoder().decode(ProcessingIdentity.self, from: old)
        #expect(decoded.schemaVersion == 1)
        #expect(decoded.receiptKey == ProcessingIdentity(sourceDigest: "A", semanticsDigest: "B").receiptKey)
        let unknown = Data(#"{"schemaVersion":99,"sourceDigest":"A","semanticsDigest":"B"}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(ProcessingIdentity.self, from: unknown) }
    }

    @MainActor
    @Test("actual frozen configuration keeps same intent and permits changed output")
    func frozenConfigurationSemantics() throws {
        func snapshot() -> BatchConfigurationSnapshot {
            BatchConfigurationSnapshot(template: .classicWhite, badge: nil, anchor: nil,
                shouldWritePhotoDescription: false, photoDescriptionOverride: "", selectedAlbumIdentifier: "")
        }
        let first = snapshot()
        var second = snapshot()
        #expect(first.id != second.id)
        #expect(try ProcessingIdentity.canonicalSemantics(JSONEncoder().encode(first)) == ProcessingIdentity.canonicalSemantics(JSONEncoder().encode(second)))
        second.customMemoryWriteText = "A different memory"
        second.usesCustomMemoryWriteText = true
        #expect(try ProcessingIdentity.canonicalSemantics(JSONEncoder().encode(first)) != ProcessingIdentity.canonicalSemantics(JSONEncoder().encode(second)))
    }

    @Test("concurrent duplicate intentions acquire exactly one durable save intent")
    func concurrentSaveIntents() async throws {
        let suite = "ConcurrentIntent-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let ledger = PhotoLibrarySaveReceiptLedger(store: PhotoLibrarySaveReceiptStore(defaults: defaults))
        let key = ProcessingIdentity(sourceDigest: "source", semanticsDigest: "same-config").receiptKey
        let acquiredCount = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<8 { group.addTask { await ledger.recordIntent(for: key) } }
            var count = 0
            for await acquired in group { if acquired { count += 1 } }
            return count
        }
        #expect(acquiredCount == 1)
        #expect(await ledger.hasPendingIntent(for: key))
    }

}
