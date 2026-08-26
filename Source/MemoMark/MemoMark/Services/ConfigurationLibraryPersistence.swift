#if !MEMOMARK_SHARE_EXTENSION
import Foundation

nonisolated protocol ConfigurationLibraryDataStorage:
    Sendable {

    func loadPrimaryData() throws -> Data?

    func loadLastKnownGoodData() throws -> Data?

    func replacePrimaryData(
        _ data: Data,
        lastKnownGoodData: Data?
    ) throws

    func compareAndReplacePrimaryData(
        _ data: Data,
        expectedPrimaryData: Data?,
        lastKnownGoodData: Data?
    ) throws -> Bool
}

nonisolated extension ConfigurationLibraryDataStorage {

    func compareAndReplacePrimaryData(
        _ data: Data,
        expectedPrimaryData: Data?,
        lastKnownGoodData: Data?
    ) throws -> Bool {
        guard try loadPrimaryData() == expectedPrimaryData else {
            return false
        }
        try replacePrimaryData(
            data,
            lastKnownGoodData: lastKnownGoodData
        )
        return true
    }
}

nonisolated protocol ConfigurationLibraryFileSystem:
    Sendable {

    func createDirectory(at url: URL) throws

    func readData(at url: URL) throws -> Data?

    func writeDataAtomically(
        _ data: Data,
        to url: URL
    ) throws
}

nonisolated struct FoundationConfigurationLibraryFileSystem:
    ConfigurationLibraryFileSystem {

    func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
    }

    func readData(at url: URL) throws -> Data? {
        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return nil
        }
        return try Data(contentsOf: url)
    }

    func writeDataAtomically(
        _ data: Data,
        to url: URL
    ) throws {
        try data.write(to: url, options: .atomic)
    }
}

nonisolated final class FileConfigurationLibraryStorage:
    ConfigurationLibraryDataStorage,
    @unchecked Sendable {

    private let directoryURL: URL
    private let primaryURL: URL
    private let lastKnownGoodURL: URL
    private let legacyDefaults: UserDefaults?
    private let fileSystem:
        any ConfigurationLibraryFileSystem

    private static let replacementLock = NSLock()

    private enum LegacyKeys {
        static let primary =
            "photomemo.configurationLibrary.primary"
        static let lastKnownGood =
            "photomemo.configurationLibrary.lastKnownGood"
    }

    init(
        baseDirectoryURL: URL =
            MemoMarkSharedContainer.baseDirectoryURL,
        legacyDefaults: UserDefaults? =
            MemoMarkSharedContainer.sharedUserDefaults,
        fileSystem: any ConfigurationLibraryFileSystem =
            FoundationConfigurationLibraryFileSystem()
    ) {
        let directoryURL = baseDirectoryURL
            .appendingPathComponent(
                "ConfigurationLibrary",
                isDirectory: true
            )
        self.directoryURL = directoryURL
        self.primaryURL = directoryURL
            .appendingPathComponent("primary.json")
        self.lastKnownGoodURL = directoryURL
            .appendingPathComponent("last-known-good.json")
        self.legacyDefaults = legacyDefaults
        self.fileSystem = fileSystem
    }

    nonisolated func loadPrimaryData() throws -> Data? {
        if let data = try fileSystem.readData(at: primaryURL) {
            return data
        }
        try migrateLegacyDefaultsIfPossible()
        return try fileSystem.readData(at: primaryURL)
    }

    nonisolated func loadLastKnownGoodData() throws -> Data? {
        try fileSystem.readData(at: lastKnownGoodURL)
    }

    nonisolated func replacePrimaryData(
        _ data: Data,
        lastKnownGoodData: Data?
    ) throws {
        try fileSystem.createDirectory(at: directoryURL)
        if let lastKnownGoodData {
            try fileSystem.writeDataAtomically(
                lastKnownGoodData,
                to: lastKnownGoodURL
            )
        }
        try fileSystem.writeDataAtomically(
            data,
            to: primaryURL
        )
        removeMigratedLegacyDefaults()
    }

    nonisolated func compareAndReplacePrimaryData(
        _ data: Data,
        expectedPrimaryData: Data?,
        lastKnownGoodData: Data?
    ) throws -> Bool {
        try Self.replacementLock.withLock {
            guard try fileSystem.readData(at: primaryURL)
                    == expectedPrimaryData else {
                return false
            }
            try replacePrimaryData(
                data,
                lastKnownGoodData: lastKnownGoodData
            )
            return true
        }
    }

    private nonisolated func migrateLegacyDefaultsIfPossible() throws {
        guard let legacyDefaults,
              let primaryData = legacyDefaults.data(
                  forKey: LegacyKeys.primary
              )
        else {
            return
        }
        try fileSystem.createDirectory(at: directoryURL)
        if let lastKnownGoodData = legacyDefaults.data(
            forKey: LegacyKeys.lastKnownGood
        ) {
            try fileSystem.writeDataAtomically(
                lastKnownGoodData,
                to: lastKnownGoodURL
            )
        }
        try fileSystem.writeDataAtomically(
            primaryData,
            to: primaryURL
        )
        removeMigratedLegacyDefaults()
    }

    private nonisolated func removeMigratedLegacyDefaults() {
        legacyDefaults?.removeObject(
            forKey: LegacyKeys.primary
        )
        legacyDefaults?.removeObject(
            forKey: LegacyKeys.lastKnownGood
        )
    }
}

nonisolated struct ConfigurationLibraryPersistenceSnapshot:
    Sendable {

    let primaryData: Data?
    let lastKnownGoodData: Data?
}

nonisolated enum ConfigurationLibraryPersistenceTransportError:
    Error,
    Sendable {

    case readFailed(String)
    case writeFailed(String)
    case primaryChanged
}

nonisolated enum ConfigurationLibrarySynchronousStorageLoader {

    static func snapshot(
        from storage: any ConfigurationLibraryDataStorage
    ) throws -> ConfigurationLibraryPersistenceSnapshot {
        do {
            return ConfigurationLibraryPersistenceSnapshot(
                primaryData:
                    try storage.loadPrimaryData(),
                lastKnownGoodData:
                    try storage.loadLastKnownGoodData()
            )
        } catch {
            let error = error as NSError
            throw ConfigurationLibraryPersistenceTransportError
                .readFailed(
                    "domain=\(error.domain);code=\(error.code)"
                )
        }
    }
}

actor ConfigurationLibraryPersistence {

    private let storage:
        any ConfigurationLibraryDataStorage

    init(
        storage: any ConfigurationLibraryDataStorage =
            FileConfigurationLibraryStorage()
    ) {
        self.storage = storage
    }

    func snapshot()
    throws -> ConfigurationLibraryPersistenceSnapshot {
        try ConfigurationLibrarySynchronousStorageLoader
            .snapshot(from: storage)
    }

    func replacePrimaryData(
        _ data: Data,
        expectedPrimaryData: Data?,
        lastKnownGoodData: Data?
    ) throws {
        do {
            guard try storage.compareAndReplacePrimaryData(
                data,
                expectedPrimaryData: expectedPrimaryData,
                lastKnownGoodData: lastKnownGoodData
            ) else {
                throw ConfigurationLibraryPersistenceTransportError
                    .primaryChanged
            }
        } catch let error as
            ConfigurationLibraryPersistenceTransportError {
            throw error
        } catch {
            let error = error as NSError
            throw ConfigurationLibraryPersistenceTransportError
                .writeFailed(
                    "domain=\(error.domain);code=\(error.code)"
                )
        }
    }
}
#endif
