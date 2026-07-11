#if !PHOTOMEMO_SHARE_EXTENSION
import CryptoKit
import Foundation

@MainActor
final class ConfigurationImportCoordinator {

    private let makeConfigurationID: () -> UUID
    private let applyAggregate:
        ((ConfigurationLibraryRecord) async throws ->
            ConfigurationLibrarySaveReceipt)?

    init(
        makeConfigurationID: @escaping () -> UUID = UUID.init,
        applyAggregate: ((
            ConfigurationLibraryRecord
        ) async throws -> ConfigurationLibrarySaveReceipt)? = nil
    ) {
        self.makeConfigurationID = makeConfigurationID
        self.applyAggregate = applyAggregate
    }

    func resolveImport(
        data: Data,
        assetRootURL: URL?,
        availableAlbumIdentifiers: Set<String>,
        liveSubject: MemorySubject? = nil
    ) throws -> ConfigurationImportResolution {
        let document = try decode(data)
        try validateChecksum(document)
        try validateUnrecoverableIssues(document)

        var importedSubject = document.subject
        var configuration = document.configuration
        var manifest = document.assetManifest
        var warnings: [ConfigurationImportWarning] = []

        resolveAlbum(
            configuration: &configuration,
            availableAlbumIdentifiers:
                availableAlbumIdentifiers,
            warnings: &warnings
        )
        resolveAssets(
            subject: &importedSubject,
            configuration: &configuration,
            manifest: &manifest,
            assetRootURL: assetRootURL,
            warnings: &warnings
        )
        var subject: MemorySubject
        if let liveSubject,
           liveSubject.id == importedSubject.id {
            subject = mergedSubject(
                imported: importedSubject,
                existing: liveSubject
            )
        } else {
            subject = importedSubject
        }
        resolveAnchors(
            subject: &subject,
            configuration: &configuration,
            warnings: &warnings
        )

        let validationDocument =
            PortableMemoryConfigurationDocument(
                appVersion: document.appVersion,
                subject: validationSubject(
                    importedSubject,
                    anchorSource: subject
                ),
                configuration: configuration,
                assetManifest: manifest,
                documentChecksum: document.documentChecksum
            )
        try validateResolvedDocument(validationDocument)

        return ConfigurationImportResolution(
            subject: subject,
            configuration: configuration,
            assetManifest: manifest,
            warnings: warnings
        )
    }

    func restore(
        _ resolution: ConfigurationImportResolution,
        into aggregate: ConfigurationLibraryRecord
    ) -> ConfigurationImportRestoreReceipt {
        var candidate = aggregate
        var configuration = resolution.configuration
        var manifest = resolution.assetManifest
        var warnings = resolution.warnings
        let originalConfigurationID = configuration.id
        let usedConfigurationIDs = Set(
            candidate.subjects.flatMap {
                $0.configurations.map(\.id)
            }
        )

        if usedConfigurationIDs.contains(configuration.id) {
            let restoredID = nextAvailableConfigurationID(
                excluding: usedConfigurationIDs
            )
            configuration = copiedConfiguration(
                configuration,
                id: restoredID
            )
            manifest = remappedCustomLogoManifest(
                manifest,
                configurationID: restoredID
            )
            warnings.append(
                .configurationRestoredAsCopy(
                    originalID: originalConfigurationID,
                    restoredID: restoredID
                )
            )
        }

        if let subjectIndex = candidate.subjects.firstIndex(
            where: { $0.subject.id == resolution.subject.id }
        ) {
            let existing = candidate.subjects[subjectIndex]
            candidate.subjects[subjectIndex] =
                SubjectConfigurationRecord(
                    subject: mergedSubject(
                        imported: resolution.subject,
                        existing: existing.subject
                    ),
                    configurations:
                        existing.configurations
                        + [configuration],
                    assetManifest: mergedManifest(
                        existing.assetManifest,
                        importing: manifest
                    )
                )
        } else {
            candidate.subjects.append(
                SubjectConfigurationRecord(
                    subject: resolution.subject,
                    configurations: [configuration],
                    assetManifest: manifest
                )
            )
        }

        return ConfigurationImportRestoreReceipt(
            aggregate: candidate,
            restoredSubjectID: resolution.subject.id,
            restoredConfigurationID: configuration.id,
            warnings: warnings
        )
    }

    func restoreAndMakeCurrent(
        _ resolution: ConfigurationImportResolution,
        into aggregate: ConfigurationLibraryRecord
    ) async throws -> ConfigurationImportApplyReceipt {
        let restored = restore(resolution, into: aggregate)
        var candidate = restored.aggregate
        candidate.activeSubjectID = restored.restoredSubjectID
        candidate.activeConfigurationID =
            restored.restoredConfigurationID
        try validateAggregate(candidate)

        guard let applyAggregate else {
            throw ConfigurationImportError
                .aggregateApplyUnavailable
        }
        let saveReceipt = try await applyAggregate(candidate)
        let currentReceipt = ConfigurationImportRestoreReceipt(
            aggregate: candidate,
            restoredSubjectID: restored.restoredSubjectID,
            restoredConfigurationID:
                restored.restoredConfigurationID,
            warnings: restored.warnings
        )
        return ConfigurationImportApplyReceipt(
            restoreReceipt: currentReceipt,
            saveReceipt: saveReceipt
        )
    }
}

private extension ConfigurationImportCoordinator {

    func decode(
        _ data: Data
    ) throws -> PortableMemoryConfigurationDocument {
        switch PortableMemoryConfigurationDocument
            .compatibilityResult(decoding: data) {
        case .compatible(let document):
            return document
        case .unsupportedOlderSchema(
            let found,
            let earliestSupported
        ):
            throw ConfigurationImportError
                .unsupportedOlderSchema(
                    found: found,
                    earliestSupported: earliestSupported
                )
        case .unsupportedFutureSchema(
            let found,
            let latestSupported
        ):
            throw ConfigurationImportError
                .unsupportedFutureSchema(
                    found: found,
                    latestSupported: latestSupported
                )
        case .invalidDocument(let description):
            throw ConfigurationImportError
                .corruptDocument(description)
        }
    }

    func validateChecksum(
        _ document: PortableMemoryConfigurationDocument
    ) throws {
        let unsigned = PortableMemoryConfigurationDocument(
            appVersion: document.appVersion,
            subject: document.subject,
            configuration: document.configuration,
            assetManifest: document.assetManifest,
            documentChecksum: ""
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data: Data
        do {
            data = try encoder.encode(unsigned)
        } catch {
            throw ConfigurationImportError
                .corruptDocument(String(describing: error))
        }
        let actual =
            "sha256:\(SHA256.hash(data: data).importHexString)"
        guard actual == document.documentChecksum else {
            throw ConfigurationImportError.checksumMismatch(
                expected: document.documentChecksum,
                actual: actual
            )
        }
    }

    func validateUnrecoverableIssues(
        _ document: PortableMemoryConfigurationDocument
    ) throws {
        guard case .invalid(let issues) =
            document.validationResult else {
            return
        }
        let unrecoverable = issues.filter { issue in
            switch issue {
            case .selectedAnchorNotOwned,
                 .missingManifestAsset:
                return false
            default:
                return true
            }
        }
        guard !unrecoverable.isEmpty else {
            return
        }
        throw ConfigurationImportError
            .invalidDocument(unrecoverable)
    }

    func validateResolvedDocument(
        _ document: PortableMemoryConfigurationDocument
    ) throws {
        guard case .invalid(let issues) =
            document.validationResult else {
            return
        }
        throw ConfigurationImportError.invalidDocument(issues)
    }

    func validateAggregate(
        _ aggregate: ConfigurationLibraryRecord
    ) throws {
        guard case .invalid(let issues) =
            aggregate.validationResult else {
            return
        }
        throw ConfigurationImportError.invalidDocument(issues)
    }

    func resolveAnchors(
        subject: inout MemorySubject,
        configuration: inout MemoryConfigurationRecord,
        warnings: inout [ConfigurationImportWarning]
    ) {
        if let activeAnchorID = subject.activeTimeAnchorID,
           subject.timeAnchor(id: activeAnchorID) == nil {
            subject.activeTimeAnchorID = nil
            appendMissingAnchorWarning(
                activeAnchorID,
                warnings: &warnings
            )
        }
        if let selectedAnchorID =
            configuration.selectedTimeAnchorID,
           subject.timeAnchor(id: selectedAnchorID) == nil {
            configuration.selectedTimeAnchorID = nil
            appendMissingAnchorWarning(
                selectedAnchorID,
                warnings: &warnings
            )
        }
    }

    func appendMissingAnchorWarning(
        _ anchorID: UUID,
        warnings: inout [ConfigurationImportWarning]
    ) {
        let warning = ConfigurationImportWarning
            .missingAnchor(anchorID)
        if !warnings.contains(warning) {
            warnings.append(warning)
        }
    }

    func resolveAlbum(
        configuration: inout MemoryConfigurationRecord,
        availableAlbumIdentifiers: Set<String>,
        warnings: inout [ConfigurationImportWarning]
    ) {
        let album = configuration.output.album
        guard album.destination == .existingAlbum,
              !availableAlbumIdentifiers.contains(album.identifier)
        else {
            return
        }
        warnings.append(
            .missingAlbum(
                identifier: album.identifier,
                title: album.title
            )
        )
        configuration.output.album = .init(
            destination: .automatic,
            identifier: "",
            title: album.title
        )
    }

    func resolveAssets(
        subject: inout MemorySubject,
        configuration: inout MemoryConfigurationRecord,
        manifest: inout PortableAssetManifest,
        assetRootURL: URL?,
        warnings: inout [ConfigurationImportWarning]
    ) {
        if assetRootURL == nil {
            for entry in manifest.entries {
                let warning = ConfigurationImportWarning
                    .missingAsset(
                        role: entry.role,
                        path: entry.reference.relativePath
                    )
                if !warnings.contains(warning) {
                    warnings.append(warning)
                }
                clearAsset(
                    role: entry.role,
                    subject: &subject,
                    configuration: &configuration
                )
            }
            manifest.entries.removeAll()
        }
        resolveAsset(
            role: .subjectAvatar,
            path: subject.identity.avatarImagePath,
            subject: &subject,
            configuration: &configuration,
            manifest: &manifest,
            assetRootURL: assetRootURL,
            warnings: &warnings
        )
        resolveAsset(
            role: .subjectAvatarBadge,
            path: subject.identity.avatarBadgeImagePath,
            subject: &subject,
            configuration: &configuration,
            manifest: &manifest,
            assetRootURL: assetRootURL,
            warnings: &warnings
        )
        resolveAsset(
            role: .subjectAvatarPreview,
            path: subject.identity.avatarPreviewImagePath,
            subject: &subject,
            configuration: &configuration,
            manifest: &manifest,
            assetRootURL: assetRootURL,
            warnings: &warnings
        )
        resolveAsset(
            role: .customLogo,
            path: configuration.presentation.logo.badge?
                .assetReference?.relativePath,
            subject: &subject,
            configuration: &configuration,
            manifest: &manifest,
            assetRootURL: assetRootURL,
            warnings: &warnings
        )
    }

    func resolveAsset(
        role: PortableAssetManifest.Role,
        path: String?,
        subject: inout MemorySubject,
        configuration: inout MemoryConfigurationRecord,
        manifest: inout PortableAssetManifest,
        assetRootURL: URL?,
        warnings: inout [ConfigurationImportWarning]
    ) {
        guard let path else {
            return
        }
        let matchingEntries = manifest.entries.filter {
            $0.reference.relativePath == path
            && $0.role == role
        }
        let entry = matchingEntries.count == 1
            ? matchingEntries[0]
            : nil
        let isAvailable = entry.map {
            assetIsAvailable(
                $0,
                assetRootURL: assetRootURL
            )
        } ?? false
        guard !isAvailable else {
            return
        }

        warnings.append(
            .missingAsset(role: role, path: path)
        )
        clearAsset(
            role: role,
            subject: &subject,
            configuration: &configuration
        )
        manifest.entries.removeAll {
            $0.reference.relativePath == path
        }
    }

    func assetIsAvailable(
        _ entry: PortableAssetManifest.Entry,
        assetRootURL: URL?
    ) -> Bool {
        guard let assetRootURL else {
            return false
        }
        let url = assetRootURL.appendingPathComponent(
            entry.reference.relativePath
        )
        guard let data = try? Data(contentsOf: url) else {
            return false
        }
        guard let expected = entry.checksum else {
            return true
        }
        let actual =
            "sha256:\(SHA256.hash(data: data).importHexString)"
        return actual == expected
    }

    func clearAsset(
        role: PortableAssetManifest.Role,
        subject: inout MemorySubject,
        configuration: inout MemoryConfigurationRecord
    ) {
        switch role {
        case .subjectAvatar:
            subject.identity.avatarImagePath = nil
            if configuration.presentation.logo.mode
                == .subjectAvatar {
                configuration.presentation.logo.mode = .appleMini
            }
        case .subjectAvatarBadge:
            subject.identity.avatarBadgeImagePath = nil
        case .subjectAvatarPreview:
            subject.identity.avatarPreviewImagePath = nil
        case .customLogo:
            configuration.presentation.logo.badge?
                .assetReference = nil
            if configuration.presentation.logo.mode
                == .customUpload {
                configuration.presentation.logo.mode = .appleMini
            }
        }
    }

    func nextAvailableConfigurationID(
        excluding usedIDs: Set<UUID>
    ) -> UUID {
        var candidate = makeConfigurationID()
        while usedIDs.contains(candidate) {
            candidate = UUID()
        }
        return candidate
    }

    func copiedConfiguration(
        _ configuration: MemoryConfigurationRecord,
        id: UUID
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: id,
            title: configuration.title,
            revision: 1,
            savedAt: configuration.savedAt,
            selectedTimeAnchorID:
                configuration.selectedTimeAnchorID,
            editor: configuration.editor,
            presentation: configuration.presentation,
            output: configuration.output
        )
    }

    func remappedCustomLogoManifest(
        _ manifest: PortableAssetManifest,
        configurationID: UUID
    ) -> PortableAssetManifest {
        PortableAssetManifest(
            entries: manifest.entries.map { entry in
                guard entry.role == .customLogo else {
                    return entry
                }
                return PortableAssetManifest.Entry(
                    id: MemoryConfigurationRecord
                        .deterministicUUID(
                            basedOn: configurationID,
                            discriminator: 0xA4
                        ),
                    role: entry.role,
                    reference: entry.reference,
                    originalFileName:
                        entry.originalFileName,
                    checksum: entry.checksum
                )
            }
        )
    }

    func mergedSubject(
        imported: MemorySubject,
        existing: MemorySubject
    ) -> MemorySubject {
        var result = existing
        let existingAnchorIDs = Set(
            existing.timeAnchors.map(\.id)
        )
        result.timeAnchors.append(
            contentsOf: imported.timeAnchors.filter {
                !existingAnchorIDs.contains($0.id)
            }
        )
        return result
    }

    func validationSubject(
        _ imported: MemorySubject,
        anchorSource: MemorySubject
    ) -> MemorySubject {
        var result = imported
        result.timeAnchors = anchorSource.timeAnchors
        if let activeTimeAnchorID = result.activeTimeAnchorID,
           result.timeAnchor(id: activeTimeAnchorID) == nil {
            result.activeTimeAnchorID = nil
        }
        return result
    }

    func mergedManifest(
        _ existing: PortableAssetManifest,
        importing imported: PortableAssetManifest
    ) -> PortableAssetManifest {
        var entries = existing.entries
        for entry in imported.entries {
            entries.removeAll {
                $0.id == entry.id
                || $0.reference.relativePath
                    == entry.reference.relativePath
            }
            entries.append(entry)
        }
        return PortableAssetManifest(entries: entries)
    }
}

private extension SHA256.Digest {

    nonisolated var importHexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
