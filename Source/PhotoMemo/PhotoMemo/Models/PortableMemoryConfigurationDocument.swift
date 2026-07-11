#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum PortableAssetValidationError:
    Error,
    Equatable {

    case emptyPath
    case absolutePath(String)
    case escapingPath(String)
}

struct PortableAssetReference:
    Codable,
    Hashable {

    let relativePath: String

    init(
        relativePath: String
    ) throws {
        self.relativePath = try Self.validated(
            relativePath
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.relativePath = try Self.validated(
            container.decode(String.self)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(relativePath)
    }

    static func isValid(
        _ path: String
    ) -> Bool {
        (try? validated(path)) != nil
    }

    private static func validated(
        _ path: String
    ) throws -> String {
        let trimmed = path.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            throw PortableAssetValidationError.emptyPath
        }
        guard !trimmed.hasPrefix("/"),
              !trimmed.hasPrefix("~"),
              !trimmed.contains("\\"),
              !trimmed.contains(":"),
              URL(string: trimmed)?.scheme == nil
        else {
            throw PortableAssetValidationError
                .absolutePath(trimmed)
        }

        let components = trimmed.split(
            separator: "/",
            omittingEmptySubsequences: false
        )
        guard !components.contains("."),
              !components.contains(".."),
              !components.contains("")
        else {
            throw PortableAssetValidationError
                .escapingPath(trimmed)
        }

        return trimmed
    }
}

struct PortableAssetManifest:
    Codable,
    Hashable {

    enum Role:
        String,
        Codable,
        Hashable {

        case subjectAvatar
        case subjectAvatarBadge
        case subjectAvatarPreview
        case customLogo
    }

    struct Entry:
        Identifiable,
        Codable,
        Hashable {

        let id: UUID
        let role: Role
        let reference: PortableAssetReference
        let originalFileName: String?
        let checksum: String?

        init(
            id: UUID = UUID(),
            role: Role,
            reference: PortableAssetReference,
            originalFileName: String? = nil,
            checksum: String? = nil
        ) {
            self.id = id
            self.role = role
            self.reference = reference
            self.originalFileName = originalFileName
            self.checksum = checksum
        }
    }

    var entries: [Entry]

    init(
        entries: [Entry]
    ) {
        self.entries = entries
    }

    var validationIssues:
        [ConfigurationRecordValidationIssue] {
        var issues: [ConfigurationRecordValidationIssue] = []
        var seenIDs: Set<UUID> = []
        var reportedIDs: Set<UUID> = []
        var seenPaths: Set<String> = []
        var reportedPaths: Set<String> = []

        for entry in entries {
            if !seenIDs.insert(entry.id).inserted,
               reportedIDs.insert(entry.id).inserted {
                issues.append(
                    .duplicateManifestEntryID(entry.id)
                )
            }
            let path = entry.reference.relativePath
            if !seenPaths.insert(path).inserted,
               reportedPaths.insert(path).inserted {
                issues.append(
                    .duplicateManifestPath(path)
                )
            }
        }
        return issues
    }
}

enum ConfigurationDocumentCompatibilityResult<Document>:
    Equatable where Document: Equatable {

    case compatible(Document)
    case unsupportedOlderSchema(
        found: Int,
        earliestSupported: Int
    )
    case unsupportedFutureSchema(
        found: Int,
        latestSupported: Int
    )
    case invalidDocument(String)
}

enum ConfigurationSchemaDecodingError:
    Error,
    Equatable {

    case unsupportedOlderSchema(
        found: Int,
        earliestSupported: Int
    )
    case unsupportedFutureSchema(
        found: Int,
        latestSupported: Int
    )
}

enum ConfigurationSchemaCompatibility {

    static func requireSupportedSchema(
        _ schemaVersion: Int,
        earliestSupported: Int,
        latestSupported: Int
    ) throws {
        if schemaVersion < earliestSupported {
            throw ConfigurationSchemaDecodingError
                .unsupportedOlderSchema(
                    found: schemaVersion,
                    earliestSupported: earliestSupported
                )
        }
        if schemaVersion > latestSupported {
            throw ConfigurationSchemaDecodingError
                .unsupportedFutureSchema(
                    found: schemaVersion,
                    latestSupported: latestSupported
                )
        }
    }
}

enum ConfigurationRecordValidationResult:
    Equatable {

    case valid
    case invalid([ConfigurationRecordValidationIssue])
}

nonisolated enum ConfigurationRecordValidationIssue:
    Hashable {

    case missingActiveSubject(UUID)
    case missingActiveConfiguration(UUID)
    case selectedAnchorNotOwned(
        subjectID: UUID,
        configurationID: UUID,
        anchorID: UUID
    )
    case absoluteSubjectAsset(
        subjectID: UUID,
        path: String
    )
    case configurationNotOwned(
        subjectID: UUID,
        configurationID: UUID
    )
    case missingManifestAsset(
        path: String,
        expectedRole: PortableAssetManifest.Role
    )
    case duplicateManifestEntryID(UUID)
    case duplicateManifestPath(String)
    case manifestRoleMismatch(
        path: String,
        expectedRole: PortableAssetManifest.Role,
        actualRole: PortableAssetManifest.Role
    )
    case activeConfigurationWithoutActiveSubject(UUID)
    case duplicateSubjectID(UUID)
    case duplicateConfigurationID(UUID)
    case invalidLibraryRevision(Int)
    case invalidConfigurationRevision(
        configurationID: UUID,
        revision: Int
    )
}

struct PortableMemoryConfigurationDocument:
    Codable,
    Hashable {

    static let earliestSchemaVersion = 1
    static let latestSchemaVersion = 1

    let schemaVersion: Int
    let appVersion: String
    let subject: MemorySubject
    let configuration: MemoryConfigurationRecord
    let assetManifest: PortableAssetManifest
    let documentChecksum: String

    init(
        appVersion: String,
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord,
        assetManifest: PortableAssetManifest,
        documentChecksum: String
    ) {
        self.schemaVersion = Self.latestSchemaVersion
        self.appVersion = appVersion
        self.subject = subject
        self.configuration = configuration
        self.assetManifest = assetManifest
        self.documentChecksum = documentChecksum
    }

    var validationResult:
        ConfigurationRecordValidationResult {
        var issues: [ConfigurationRecordValidationIssue] = []

        if let selectedTimeAnchorID =
            configuration.selectedTimeAnchorID,
           subject.timeAnchor(id: selectedTimeAnchorID) == nil {
            issues.append(
                .selectedAnchorNotOwned(
                    subjectID: subject.id,
                    configurationID: configuration.id,
                    anchorID: selectedTimeAnchorID
                )
            )
        }
        if !MemoryConfigurationRecord
            .isValidRevision(configuration.revision) {
            issues.append(
                .invalidConfigurationRevision(
                    configurationID: configuration.id,
                    revision: configuration.revision
                )
            )
        }
        issues.append(contentsOf: Self.subjectAssetIssues(subject))
        issues.append(
            contentsOf: Self.manifestIssues(
                subject: subject,
                configurations: [configuration],
                manifest: assetManifest
            )
        )

        return issues.isEmpty ? .valid : .invalid(issues)
    }

    static func compatibilityResult(
        decoding data: Data
    ) -> ConfigurationDocumentCompatibilityResult<Self> {
        compatibilityResult(
            decoding: data,
            as: Self.self,
            earliestSupported:
                earliestSchemaVersion,
            latestSupported: latestSchemaVersion
        )
    }

    private enum CodingKeys:
        String,
        CodingKey {

        case schemaVersion
        case appVersion
        case subject
        case configuration
        case assetManifest
        case documentChecksum
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        let schemaVersion = try container.decode(
            Int.self,
            forKey: .schemaVersion
        )
        try ConfigurationSchemaCompatibility
            .requireSupportedSchema(
                schemaVersion,
                earliestSupported:
                    Self.earliestSchemaVersion,
                latestSupported:
                    Self.latestSchemaVersion
            )

        self.schemaVersion = schemaVersion
        self.appVersion = try container.decode(
            String.self,
            forKey: .appVersion
        )
        self.subject = try container.decode(
            MemorySubject.self,
            forKey: .subject
        )
        self.configuration = try container.decode(
            MemoryConfigurationRecord.self,
            forKey: .configuration
        )
        self.assetManifest = try container.decode(
            PortableAssetManifest.self,
            forKey: .assetManifest
        )
        self.documentChecksum = try container.decode(
            String.self,
            forKey: .documentChecksum
        )
    }
}

extension PortableMemoryConfigurationDocument {

    private struct ExpectedAssetReference {

        let path: String
        let role: PortableAssetManifest.Role
    }

    static func subjectAssetIssues(
        _ subject: MemorySubject
    ) -> [ConfigurationRecordValidationIssue] {
        [
            subject.identity.avatarImagePath,
            subject.identity.avatarBadgeImagePath,
            subject.identity.avatarPreviewImagePath
        ]
        .compactMap { path in
            guard let path,
                  !PortableAssetReference.isValid(path)
            else {
                return nil
            }
            return .absoluteSubjectAsset(
                subjectID: subject.id,
                path: path
            )
        }
    }

    static func manifestIssues(
        subject: MemorySubject,
        configurations: [MemoryConfigurationRecord],
        manifest: PortableAssetManifest
    ) -> [ConfigurationRecordValidationIssue] {
        var issues = manifest.validationIssues
        var expectedReferences: [ExpectedAssetReference] = []

        func append(
            path: String?,
            role: PortableAssetManifest.Role
        ) {
            guard let path,
                  PortableAssetReference.isValid(path)
            else {
                return
            }
            expectedReferences.append(
                .init(path: path, role: role)
            )
        }

        append(
            path: subject.identity.avatarImagePath,
            role: .subjectAvatar
        )
        append(
            path: subject.identity.avatarBadgeImagePath,
            role: .subjectAvatarBadge
        )
        append(
            path: subject.identity.avatarPreviewImagePath,
            role: .subjectAvatarPreview
        )
        for configuration in configurations {
            append(
                path: configuration.presentation
                    .logo.badge?.assetReference?
                    .relativePath,
                role: .customLogo
            )
        }

        for expected in expectedReferences {
            let matches = manifest.entries.filter {
                $0.reference.relativePath == expected.path
            }
            guard let entry = matches.first else {
                issues.append(
                    .missingManifestAsset(
                        path: expected.path,
                        expectedRole: expected.role
                    )
                )
                continue
            }
            if matches.count == 1,
               entry.role != expected.role {
                issues.append(
                    .manifestRoleMismatch(
                        path: expected.path,
                        expectedRole: expected.role,
                        actualRole: entry.role
                    )
                )
            }
        }
        return issues
    }

    static func compatibilityResult<Document>(
        decoding data: Data,
        as type: Document.Type,
        earliestSupported: Int,
        latestSupported: Int
    ) -> ConfigurationDocumentCompatibilityResult<Document>
    where Document: Decodable & Equatable {
        do {
            let envelope = try JSONDecoder().decode(
                SchemaEnvelope.self,
                from: data
            )
            if envelope.schemaVersion < earliestSupported {
                return .unsupportedOlderSchema(
                    found: envelope.schemaVersion,
                    earliestSupported: earliestSupported
                )
            }
            if envelope.schemaVersion > latestSupported {
                return .unsupportedFutureSchema(
                    found: envelope.schemaVersion,
                    latestSupported: latestSupported
                )
            }
            return .compatible(
                try JSONDecoder().decode(type, from: data)
            )
        } catch {
            return .invalidDocument(
                String(describing: error)
            )
        }
    }

    private struct SchemaEnvelope:
        Decodable {

        let schemaVersion: Int
    }
}
#endif
