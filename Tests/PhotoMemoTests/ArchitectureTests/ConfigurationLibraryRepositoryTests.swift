#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration library repository", .serialized)
struct ConfigurationLibraryRepositoryTests {

    @MainActor
    @Test("atomic save replaces the complete primary value and preserves the previous revision")
    func atomicSaveReplacesPrimaryAndPreservesPreviousRevision() async throws {
        let storage = TestConfigurationLibraryStorage()
        let repository = Self.makeRepository(storage: storage)

        let firstReceipt = try await repository.save(
            Self.makeAggregate(title: "第一版")
        )
        let firstData = try #require(storage.primaryData)

        var secondAggregate = Self.makeAggregate(title: "第二版")
        secondAggregate.revision = firstReceipt.revision
        let secondReceipt = try await repository.save(
            secondAggregate
        )
        let secondData = try #require(storage.primaryData)
        let lastKnownGoodData = try #require(
            storage.lastKnownGoodData
        )

        #expect(firstReceipt.revision == 1)
        #expect(firstReceipt.configurationRevision == 1)
        #expect(secondReceipt.revision == 2)
        #expect(secondReceipt.configurationRevision == 1)
        #expect(secondData != firstData)
        #expect(lastKnownGoodData == firstData)
        #expect(
            try JSONDecoder().decode(
                ConfigurationLibraryRecord.self,
                from: secondData
            ).revision == 2
        )
        #expect(
            try JSONDecoder().decode(
                ConfigurationLibraryRecord.self,
                from: lastKnownGoodData
            ).revision == 1
        )
    }

    @MainActor
    @Test("validation and encoding failures do not touch durable storage")
    func validationAndEncodingFailuresDoNotWrite() async throws {
        let storage = TestConfigurationLibraryStorage()
        let repository = Self.makeRepository(storage: storage)
        var invalid = Self.makeAggregate(title: "无效")
        invalid.activeConfigurationID = UUID()

        await #expect(
            throws: ConfigurationLibraryPersistenceError.self
        ) {
            _ = try await repository.save(invalid)
        }
        #expect(storage.writeCount == 0)

        let failingRepository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            ),
            encoder: FailingConfigurationLibraryEncoder()
        )

        await #expect(
            throws: ConfigurationLibraryPersistenceError.self
        ) {
            _ = try await failingRepository.save(
                Self.makeAggregate(title: "编码失败")
            )
        }
        #expect(storage.writeCount == 0)
    }

    @MainActor
    @Test("write failure preserves primary last-known-good and skips projections")
    func writeFailurePreservesDurableStateAndSkipsProjection() async throws {
        let storage = TestConfigurationLibraryStorage()
        let repository = Self.makeRepository(storage: storage)
        _ = try await repository.save(
            Self.makeAggregate(title: "稳定版")
        )
        let primaryBeforeFailure = storage.primaryData
        let lastKnownGoodBeforeFailure = storage.lastKnownGoodData
        storage.shouldFailWrites = true
        var projectionCallCount = 0
        var failedAggregate = Self.makeAggregate(title: "失败版")
        failedAggregate.revision = 1

        await #expect(
            throws: ConfigurationLibraryPersistenceError.self
        ) {
            _ = try await repository.save(
                failedAggregate,
                compatibilityProjection: { _, _ in
                    projectionCallCount += 1
                }
            )
        }

        #expect(storage.primaryData == primaryBeforeFailure)
        #expect(
            storage.lastKnownGoodData
            == lastKnownGoodBeforeFailure
        )
        #expect(projectionCallCount == 0)
    }

    @MainActor
    @Test("corrupt primary loads the last-known-good aggregate without default reset")
    func corruptPrimaryLoadsLastKnownGood() async throws {
        let storage = TestConfigurationLibraryStorage()
        let repository = Self.makeRepository(storage: storage)
        _ = try await repository.save(
            Self.makeAggregate(title: "可恢复版本")
        )
        let validData = try #require(storage.primaryData)
        storage.primaryData = Data("corrupt-primary".utf8)
        storage.lastKnownGoodData = validData

        let loadReceipt = try await repository.load()

        #expect(loadReceipt.source == .lastKnownGood)
        #expect(loadReceipt.aggregate.revision == 1)
        #expect(
            loadReceipt.aggregate.subjects[0]
                .configurations[0].title
            == "可恢复版本"
        )
        #expect(storage.primaryData == Data("corrupt-primary".utf8))
    }

    @MainActor
    @Test("repository rejects a stale aggregate instead of overwriting newer content")
    func staleAggregateDoesNotOverwriteNewerContent() async throws {
        let storage = TestConfigurationLibraryStorage()
        let repository = Self.makeRepository(storage: storage)
        let initialReceipt = try await repository.save(
            Self.makeAggregate(title: "初始版本")
        )
        var firstEdit = Self.makeAggregate(title: "较新修改")
        firstEdit.revision = initialReceipt.revision
        var staleEdit = Self.makeAggregate(title: "过期修改")
        staleEdit.revision = initialReceipt.revision

        let newerReceipt = try await repository.save(firstEdit)
        do {
            _ = try await repository.save(staleEdit)
            Issue.record("Expected stale aggregate rejection")
        } catch let error as ConfigurationLibraryPersistenceError {
            guard case .staleAggregate(
                let candidateRevision,
                let storedRevision
            ) = error else {
                Issue.record("Expected staleAggregate, got \(error)")
                return
            }
            #expect(candidateRevision == initialReceipt.revision)
            #expect(storedRevision == newerReceipt.revision)
        }

        let saved = try JSONDecoder().decode(
            ConfigurationLibraryRecord.self,
            from: try #require(storage.primaryData)
        )

        #expect(saved.revision == newerReceipt.revision)
        #expect(
            saved.subjects[0].configurations[0].title
            == "较新修改"
        )
        #expect(storage.writeCount == 2)
    }

    @MainActor
    @Test("projection failure is diagnosed after primary success")
    func projectionFailureDoesNotRollbackPrimary() async throws {
        let storage = TestConfigurationLibraryStorage()
        let repository = Self.makeRepository(storage: storage)

        let receipt = try await repository.save(
            Self.makeAggregate(title: "主记录成功"),
            compatibilityProjection: { _, _ in
                throw TestFailure.projection
            }
        )

        #expect(receipt.revision == 1)
        #expect(receipt.compatibilityProjectionFailure != nil)
        #expect(storage.primaryData != nil)
        #expect(
            try JSONDecoder().decode(
                ConfigurationLibraryRecord.self,
                from: try #require(storage.primaryData)
            ).revision == 1
        )
    }

    @MainActor
    @Test("revision overflow fails without replacing the current aggregate")
    func revisionOverflowDoesNotWrite() async throws {
        let storage = TestConfigurationLibraryStorage()
        var maximumValid = Self.makeAggregate(
            title: "最大 revision"
        )
        maximumValid.revision = Int.max - 1
        storage.primaryData = try JSONEncoder().encode(
            maximumValid
        )
        let primaryBeforeSave = storage.primaryData
        let repository = Self.makeRepository(storage: storage)

        await #expect(
            throws: ConfigurationLibraryPersistenceError.self
        ) {
            _ = try await repository.save(
                Self.makeAggregate(title: "不应写入")
            )
        }

        #expect(storage.primaryData == primaryBeforeSave)
        #expect(storage.writeCount == 0)
    }

    @MainActor
    @Test("file storage atomically replaces primary and preserves last-known-good")
    func fileStorageRoundTripsAtomicReplacement() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }
        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL: rootURL,
            legacyDefaults: nil
        )
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )

        let firstReceipt = try await repository.save(
            Self.makeAggregate(title: "File One")
        )
        let firstData = try #require(
            try storage.loadPrimaryData()
        )
        var secondAggregate = Self.makeAggregate(title: "File Two")
        secondAggregate.revision = firstReceipt.revision
        let secondReceipt = try await repository.save(
            secondAggregate
        )
        let primaryData = try #require(
            try storage.loadPrimaryData()
        )
        let lastKnownGoodData = try #require(
            try storage.loadLastKnownGoodData()
        )

        #expect(firstReceipt.revision == 1)
        #expect(secondReceipt.revision == 2)
        #expect(lastKnownGoodData == firstData)
        #expect(
            try JSONDecoder().decode(
                ConfigurationLibraryRecord.self,
                from: primaryData
            ).subjects[0].configurations[0].title
            == "File Two"
        )
        #expect(
            FileManager.default.fileExists(
                atPath: rootURL
                    .appendingPathComponent("ConfigurationLibrary")
                    .appendingPathComponent("primary.json")
                    .path
            )
        )
    }

    @MainActor
    @Test("file storage write failure maps to typed failure before receipt or projection")
    func fileStorageWriteFailureDoesNotIssueReceipt() async throws {
        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL:
                FileManager.default.temporaryDirectory,
            legacyDefaults: nil,
            fileSystem:
                FailingConfigurationLibraryFileSystem()
        )
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
        var projectionCount = 0

        do {
            _ = try await repository.save(
                Self.makeAggregate(title: "Must Fail"),
                compatibilityProjection: { _, _ in
                    projectionCount += 1
                }
            )
            Issue.record(
                "Expected file storage write failure"
            )
        } catch let error as
            ConfigurationLibraryPersistenceError {
            guard case .writeFailed = error else {
                Issue.record(
                    "Expected typed writeFailed, got \(error)"
                )
                return
            }
        }

        #expect(projectionCount == 0)
    }

    @MainActor
    @Test("separate file repositories cannot overwrite the same revision")
    func separateFileRepositoriesUseAtomicComparison() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let firstRepository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: FileConfigurationLibraryStorage(
                    baseDirectoryURL: rootURL,
                    legacyDefaults: nil
                )
            )
        )
        let secondRepository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: FileConfigurationLibraryStorage(
                    baseDirectoryURL: rootURL,
                    legacyDefaults: nil
                )
            )
        )
        let initialReceipt = try await firstRepository.save(
            Self.makeAggregate(title: "Initial")
        )
        var firstCandidate = Self.makeAggregate(title: "First")
        firstCandidate.revision = initialReceipt.revision
        var secondCandidate = Self.makeAggregate(title: "Second")
        secondCandidate.revision = initialReceipt.revision

        let outcomes = await withTaskGroup(of: Bool.self) { group in
            group.addTask { @MainActor in
                (try? await firstRepository.save(firstCandidate)) != nil
            }
            group.addTask { @MainActor in
                (try? await secondRepository.save(secondCandidate)) != nil
            }
            var values: [Bool] = []
            for await value in group {
                values.append(value)
            }
            return values
        }

        #expect(outcomes.filter { $0 }.count == 1)
        let durable = try await firstRepository.load().aggregate
        #expect(durable.revision == 2)
        #expect(
            ["First", "Second"].contains(
                durable.subjects[0].configurations[0].title
            )
        )
    }
}

private extension ConfigurationLibraryRepositoryTests {

    @MainActor
    static func makeRepository(
        storage: TestConfigurationLibraryStorage
    ) -> ConfigurationLibraryRepository {
        ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(
                storage: storage
            )
        )
    }

    static func makeAggregate(
        title: String
    ) -> ConfigurationLibraryRecord {
        let subject = MemorySubject(
            id: UUID(
                uuidString:
                    "11111111-1111-1111-1111-111111111111"
            )!,
            identity: .init(
                displayName: "示例对象",
                shortName: "小宝"
            ),
            relationship: .init(
                role: "宝宝",
                label: "妈妈眼里的宝宝"
            ),
            referenceDate: Date(
                timeIntervalSince1970: 1_716_825_600
            ),
            timeAnchors: [],
            activeTimeAnchorID: nil,
            expressionSubjectSource: .shortName,
            behavior: MemoryBehavior(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .autoMatch,
                memoryExpression: MemoryExpression(
                    title: "成长",
                    blocks: []
                )
            ),
            decorations: []
        )
        let configuration = MemoryConfigurationRecord(
            id: UUID(
                uuidString:
                    "22222222-2222-2222-2222-222222222222"
            )!,
            title: title,
            revision: 1,
            savedAt: Date(
                timeIntervalSince1970: 1_725_206_400
            ),
            selectedTimeAnchorID: nil,
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
                logo: .init(
                    mode: .appleMini,
                    badge: nil
                )
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: true,
                    overrideText: ""
                ),
                album: .automatic
            )
        )

        return ConfigurationLibraryRecord(
            revision: 0,
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

private final class TestConfigurationLibraryStorage:
    ConfigurationLibraryDataStorage,
    @unchecked Sendable {

    var primaryData: Data?
    var lastKnownGoodData: Data?
    var shouldFailWrites = false
    private(set) var writeCount = 0

    func loadPrimaryData() throws -> Data? {
        primaryData
    }

    func loadLastKnownGoodData() throws -> Data? {
        lastKnownGoodData
    }

    func replacePrimaryData(
        _ data: Data,
        lastKnownGoodData: Data?
    ) throws {
        if shouldFailWrites {
            throw TestFailure.write
        }
        self.lastKnownGoodData = lastKnownGoodData
        primaryData = data
        writeCount += 1
    }
}

private struct FailingConfigurationLibraryEncoder:
    ConfigurationLibraryRecordEncoding {

    func encode(
        _ aggregate: ConfigurationLibraryRecord
    ) throws -> Data {
        throw TestFailure.encoding
    }
}

private enum TestFailure: Error {
    case encoding
    case write
    case projection
}

private struct FailingConfigurationLibraryFileSystem:
    ConfigurationLibraryFileSystem {

    func createDirectory(at url: URL) throws {}

    func readData(at url: URL) throws -> Data? {
        nil
    }

    func writeDataAtomically(
        _ data: Data,
        to url: URL
    ) throws {
        throw TestFailure.write
    }
}
#endif
