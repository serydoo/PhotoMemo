#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class LocalConfigurationLibraryCoordinator {

    private let repository:
        LocalConfigurationLibraryRepository
    private let assetPackager: ConfigurationAssetPackager
    private let appVersion: String

    init(
        repository: LocalConfigurationLibraryRepository =
            LocalConfigurationLibraryRepository(),
        appVersion: String
    ) {
        self.repository = repository
        self.assetPackager = ConfigurationAssetPackager()
        self.appVersion = appVersion
    }

    init(
        repository: LocalConfigurationLibraryRepository,
        assetPackager: ConfigurationAssetPackager,
        appVersion: String
    ) {
        self.repository = repository
        self.assetPackager = assetPackager
        self.appVersion = appVersion
    }

    func backup(
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord,
        sourceURLs: [PortableAssetManifest.Role: URL]
    ) async throws -> LocalConfigurationBackupReceipt {
        let subjectRootURL = repository.subjectRootURL(
            subjectID: subject.id
        )
        let package = try assetPackager.package(
            subject: subject,
            configuration: configuration,
            sourceURLs: sourceURLs,
            destinationRootURL: subjectRootURL
        )
        let document = PortableMemoryConfigurationDocument(
            appVersion: appVersion,
            subject: package.subject,
            configuration: package.configuration,
            assetManifest: package.manifest,
            documentChecksum: "pending"
        )
        return try await repository.save(document)
    }

    func listBackups(
        subjectID: UUID
    ) async throws -> [LocalConfigurationBackupRecord] {
        try await repository.list(subjectID: subjectID)
    }

    func restore(
        subjectID: UUID,
        configurationID: UUID,
        destinationRootURL: URL
    ) async throws -> RestoredConfigurationAssets {
        let document = try await repository.load(
            subjectID: subjectID,
            configurationID: configurationID
        )
        let subjectRootURL = repository.subjectRootURL(
            subjectID: subjectID
        )
        return try assetPackager.restoreAssets(
            in: document,
            sourceRootURL: subjectRootURL,
            destinationRootURL: destinationRootURL
        )
    }

    func deleteBackup(
        subjectID: UUID,
        configurationID: UUID
    ) async throws -> LocalConfigurationBackupDeletionReceipt {
        try await repository.deleteBackup(
            subjectID: subjectID,
            configurationID: configurationID
        )
    }
}
#endif
