#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct RestoreConfigurationLibraryCommand {

    let fileURL: URL
    let assetRootURL: URL?
    let makeCurrent: Bool
    let aggregate: ConfigurationLibraryRecord?
    let availableAlbumIdentifiers: Set<String>
    let destinationRootURL: URL
}

struct RestoreConfigurationLibraryReceipt {

    let aggregate: ConfigurationLibraryRecord
    let restoreReceipt: ConfigurationImportRestoreReceipt
    let saveReceipt: ConfigurationLibrarySaveReceipt
    let warnings: [ConfigurationImportWarning]
    let shouldApplyCurrentConfiguration: Bool
}

private actor RestoreConfigurationLibrarySerializationGate {

    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        guard isLocked else {
            isLocked = true
            return
        }
        await withCheckedContinuation {
            waiters.append($0)
        }
    }

    func release() {
        guard !waiters.isEmpty else {
            isLocked = false
            return
        }
        waiters.removeFirst().resume()
    }
}

@MainActor
struct RestoreConfigurationLibraryTransaction {

    struct Dependencies {

        let saveAggregate:
            (ConfigurationLibraryRecord) async throws ->
                ConfigurationLibrarySaveReceipt
        let readData: (URL) throws -> Data
        let startSecurityScopedAccess: (URL) -> Bool
        let stopSecurityScopedAccess: (URL) -> Void
    }

    private static let serializationGate =
        RestoreConfigurationLibrarySerializationGate()

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func apply(
        _ command: RestoreConfigurationLibraryCommand
    ) async throws -> RestoreConfigurationLibraryReceipt {
        await Self.serializationGate.acquire()
        do {
            let receipt = try await applyExclusively(command)
            await Self.serializationGate.release()
            return receipt
        } catch {
            await Self.serializationGate.release()
            throw error
        }
    }

    private func applyExclusively(
        _ command: RestoreConfigurationLibraryCommand
    ) async throws -> RestoreConfigurationLibraryReceipt {
        let didAccessSecurityScopedResource =
            dependencies.startSecurityScopedAccess(command.fileURL)
        defer {
            if didAccessSecurityScopedResource {
                dependencies.stopSecurityScopedAccess(command.fileURL)
            }
        }

        let assetPackager = ConfigurationAssetPackager()
        var newlyCopiedAssetURLs: [URL] = []
        do {
            let data = try dependencies.readData(command.fileURL)
            let importCoordinator = ConfigurationImportCoordinator(
                applyAggregate: dependencies.saveAggregate
            )
            let resolution = try importCoordinator.resolveImport(
                data: data,
                assetRootURL: command.assetRootURL,
                availableAlbumIdentifiers:
                    command.availableAlbumIdentifiers
            )
            if let assetRootURL = command.assetRootURL {
                // Validate the original signed document before copying any
                // managed asset. The resolved document then controls the
                // resource references that become durable after this command.
                let sourceDocument = try JSONDecoder().decode(
                    PortableMemoryConfigurationDocument.self,
                    from: data
                )
                try assetPackager.validateAvailableAssetChecksums(
                    in: sourceDocument,
                    sourceRootURL: assetRootURL
                )
                let document = PortableMemoryConfigurationDocument(
                    appVersion: sourceDocument.appVersion,
                    subject: resolution.subject,
                    configuration: resolution.configuration,
                    assetManifest: resolution.assetManifest,
                    documentChecksum: sourceDocument.documentChecksum
                )
                if !document.assetManifest.entries.isEmpty {
                    let restoredAssets = try assetPackager.restoreAssets(
                        in: document,
                        sourceRootURL: assetRootURL,
                        destinationRootURL: command.destinationRootURL
                    )
                    newlyCopiedAssetURLs =
                        restoredAssets.newlyCreatedAssetURLs
                }
            }

            let isCreatingFirstConfiguration = command.aggregate == nil
            let baseAggregate = command.aggregate
                ?? ConfigurationLibraryRecord(
                    revision: 0,
                    subjects: [],
                    activeSubjectID: nil,
                    activeConfigurationID: nil
                )
            let shouldMakeCurrent = command.makeCurrent
                || isCreatingFirstConfiguration

            let restoreReceipt: ConfigurationImportRestoreReceipt
            let saveReceipt: ConfigurationLibrarySaveReceipt
            if shouldMakeCurrent {
                let applyReceipt = try await importCoordinator
                    .restoreAndMakeCurrent(
                        resolution,
                        into: baseAggregate
                    )
                restoreReceipt = applyReceipt.restoreReceipt
                saveReceipt = applyReceipt.saveReceipt
            } else {
                restoreReceipt = importCoordinator.restore(
                    resolution,
                    into: baseAggregate
                )
                saveReceipt = try await dependencies.saveAggregate(
                    restoreReceipt.aggregate
                )
            }

            var durableAggregate = restoreReceipt.aggregate
            durableAggregate.revision = saveReceipt.revision
            return RestoreConfigurationLibraryReceipt(
                aggregate: durableAggregate,
                restoreReceipt: restoreReceipt,
                saveReceipt: saveReceipt,
                warnings: restoreReceipt.warnings,
                shouldApplyCurrentConfiguration: shouldMakeCurrent
            )
        } catch {
            assetPackager.removeCreatedAssets(newlyCopiedAssetURLs)
            throw error
        }
    }
}
#endif
