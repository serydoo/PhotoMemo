#if !PHOTOMEMO_SHARE_EXTENSION
import CryptoKit
import Foundation

enum ConfigurationAssetPackagingError:
    Error,
    Equatable {

    case missingSource(PortableAssetManifest.Role)
    case readFailed(String)
    case writeFailed(String)
    case checksumMismatch(
        path: String,
        expected: String,
        actual: String
    )
    case pathEscapesRoot(
        path: String,
        root: String
    )
}

struct PackagedConfigurationAssets {

    let subject: MemorySubject
    let configuration: MemoryConfigurationRecord
    let manifest: PortableAssetManifest
}

struct RestoredConfigurationAssets {

    let subject: MemorySubject
    let configuration: MemoryConfigurationRecord
    private let assetURLs:
        [PortableAssetManifest.Role: URL]

    init(
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord,
        assetURLs: [PortableAssetManifest.Role: URL]
    ) {
        self.subject = subject
        self.configuration = configuration
        self.assetURLs = assetURLs
    }

    func assetURL(
        for role: PortableAssetManifest.Role
    ) -> URL? {
        assetURLs[role]
    }
}

enum ConfigurationSubjectAssetMappingError: Error, Equatable {

    case assetOutsideManagedRoot(String)
    case duplicateAssetPath(String)
}

struct PortableConfigurationSubjectAssets {

    let subject: MemorySubject
    let manifest: PortableAssetManifest
}

struct ConfigurationSubjectAssetMapper {

    let baseDirectoryURL: URL

    init(
        baseDirectoryURL: URL =
            PhotoMemoSharedContainer.baseDirectoryURL
    ) {
        self.baseDirectoryURL =
            baseDirectoryURL.standardizedFileURL
    }

    func makePortable(
        subject: MemorySubject,
        manifest: PortableAssetManifest
    ) throws -> PortableConfigurationSubjectAssets {
        var portableSubject = subject
        var portableManifest = manifest

        portableSubject.identity.avatarImagePath =
            try portablePath(
                subject.identity.avatarImagePath,
                role: .subjectAvatar,
                subjectID: subject.id,
                manifest: &portableManifest
            )
        portableSubject.identity.avatarBadgeImagePath =
            try portablePath(
                subject.identity.avatarBadgeImagePath,
                role: .subjectAvatarBadge,
                subjectID: subject.id,
                manifest: &portableManifest
            )
        portableSubject.identity.avatarPreviewImagePath =
            try portablePath(
                subject.identity.avatarPreviewImagePath,
                role: .subjectAvatarPreview,
                subjectID: subject.id,
                manifest: &portableManifest
            )

        return PortableConfigurationSubjectAssets(
            subject: portableSubject,
            manifest: portableManifest
        )
    }

    func makeRuntime(
        subject: MemorySubject
    ) -> MemorySubject {
        var runtimeSubject = subject
        runtimeSubject.identity.avatarImagePath =
            makeRuntimePath(subject.identity.avatarImagePath)
        runtimeSubject.identity.avatarBadgeImagePath =
            makeRuntimePath(subject.identity.avatarBadgeImagePath)
        runtimeSubject.identity.avatarPreviewImagePath =
            makeRuntimePath(subject.identity.avatarPreviewImagePath)
        return runtimeSubject
    }

    func makeRuntimePath(
        _ path: String?
    ) -> String? {
        guard let path,
              PortableAssetReference.isValid(path)
        else {
            return path
        }
        return baseDirectoryURL
            .appendingPathComponent(path)
            .standardizedFileURL
            .path
    }
}

private extension ConfigurationSubjectAssetMapper {

    func portablePath(
        _ path: String?,
        role: PortableAssetManifest.Role,
        subjectID: UUID,
        manifest: inout PortableAssetManifest
    ) throws -> String? {
        let previousEntry = manifest.entries.first {
            $0.role == role
        }
        manifest.entries.removeAll { $0.role == role }

        guard let path else {
            return nil
        }
        let trimmed = path.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            return nil
        }

        let relativePath: String
        if PortableAssetReference.isValid(trimmed) {
            relativePath = trimmed
        } else {
            let sourceURL = URL(fileURLWithPath: trimmed)
                .standardizedFileURL
            let rootComponents = baseDirectoryURL.pathComponents
            let sourceComponents = sourceURL.pathComponents
            guard sourceComponents.count > rootComponents.count,
                  sourceComponents.starts(with: rootComponents)
            else {
                throw ConfigurationSubjectAssetMappingError
                    .assetOutsideManagedRoot(trimmed)
            }
            relativePath = sourceComponents
                .dropFirst(rootComponents.count)
                .joined(separator: "/")
        }

        guard !manifest.entries.contains(where: {
            $0.reference.relativePath == relativePath
        }) else {
            throw ConfigurationSubjectAssetMappingError
                .duplicateAssetPath(relativePath)
        }
        let reference = try PortableAssetReference(
            relativePath: relativePath
        )
        let preservedEntry = previousEntry.flatMap {
            $0.reference == reference ? $0 : nil
        }
        manifest.entries.append(
            preservedEntry
            ?? PortableAssetManifest.Entry(
                id: MemoryConfigurationRecord.deterministicUUID(
                    basedOn: subjectID,
                    discriminator: discriminator(for: role)
                ),
                role: role,
                reference: reference,
                originalFileName:
                    URL(fileURLWithPath: trimmed).lastPathComponent
            )
        )
        return relativePath
    }

    func discriminator(
        for role: PortableAssetManifest.Role
    ) -> UInt8 {
        switch role {
        case .subjectAvatar:
            return 0xA1
        case .subjectAvatarBadge:
            return 0xA2
        case .subjectAvatarPreview:
            return 0xA3
        case .customLogo:
            return 0xA4
        }
    }
}

struct ConfigurationAssetPackager {

    func package(
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord,
        sourceURLs: [PortableAssetManifest.Role: URL],
        destinationRootURL: URL
    ) throws -> PackagedConfigurationAssets {
        var packagedSubject = subject
        var packagedConfiguration = configuration
        var entries: [PortableAssetManifest.Entry] = []

        for role in Self.roles {
            guard let sourceURL = sourceURLs[role] else {
                continue
            }
            let data = try readData(at: sourceURL)
            let reference = try PortableAssetReference(
                relativePath: relativePath(
                    for: role,
                    sourceURL: sourceURL,
                    data: data
                )
            )
            let destinationURL = destinationRootURL
                .appendingPathComponent(reference.relativePath)
            try write(data, to: destinationURL)
            remap(
                role: role,
                reference: reference,
                subject: &packagedSubject,
                configuration: &packagedConfiguration
            )
            entries.append(
                PortableAssetManifest.Entry(
                    id: manifestID(
                        role: role,
                        subjectID: subject.id,
                        configurationID: configuration.id
                    ),
                    role: role,
                    reference: reference,
                    originalFileName: sourceURL.lastPathComponent,
                    checksum: checksum(for: data)
                )
            )
        }

        return PackagedConfigurationAssets(
            subject: packagedSubject,
            configuration: packagedConfiguration,
            manifest: PortableAssetManifest(entries: entries)
        )
    }

    func restoreAssets(
        in document: PortableMemoryConfigurationDocument,
        sourceRootURL: URL,
        destinationRootURL: URL
    ) throws -> RestoredConfigurationAssets {
        var subject = document.subject
        let configuration = document.configuration
        var restoredURLs:
            [PortableAssetManifest.Role: URL] = [:]

        for entry in document.assetManifest.entries {
            let sourceURL = try containedURL(
                sourceRootURL.appendingPathComponent(
                    entry.reference.relativePath
                ),
                within: sourceRootURL
            )
            let destinationURL = try containedURL(
                destinationRootURL.appendingPathComponent(
                    entry.reference.relativePath
                ),
                within: destinationRootURL
            )
            let data = try readData(at: sourceURL)
            if let expected = entry.checksum {
                let actual = checksum(for: data)
                guard actual == expected else {
                    throw ConfigurationAssetPackagingError
                        .checksumMismatch(
                            path: entry.reference.relativePath,
                            expected: expected,
                            actual: actual
                        )
                }
            }
            try write(data, to: destinationURL)
            restoredURLs[entry.role] = destinationURL
            remapRestoredSubject(
                role: entry.role,
                absolutePath: destinationURL.path,
                subject: &subject
            )
        }

        return RestoredConfigurationAssets(
            subject: subject,
            configuration: configuration,
            assetURLs: restoredURLs
        )
    }
}

private extension ConfigurationAssetPackager {

    static let roles: [PortableAssetManifest.Role] = [
        .subjectAvatar,
        .subjectAvatarBadge,
        .subjectAvatarPreview,
        .customLogo
    ]

    func containedURL(
        _ url: URL,
        within rootURL: URL
    ) throws -> URL {
        let resolvedRoot = resolvedURLFollowingExistingSymlinks(
            rootURL
        )
        let resolvedURL = resolvedURLFollowingExistingSymlinks(
            url
        )
        let rootComponents = resolvedRoot.pathComponents
        let pathComponents = resolvedURL.pathComponents
        guard pathComponents.count > rootComponents.count,
              pathComponents.starts(with: rootComponents)
        else {
            throw ConfigurationAssetPackagingError.pathEscapesRoot(
                path: resolvedURL.path,
                root: resolvedRoot.path
            )
        }
        return resolvedURL
    }

    func resolvedURLFollowingExistingSymlinks(
        _ url: URL
    ) -> URL {
        var ancestor = url.standardizedFileURL
        var missingComponents: [String] = []
        let fileManager = FileManager.default

        while ancestor.path != "/",
              !fileManager.fileExists(atPath: ancestor.path) {
            missingComponents.insert(
                ancestor.lastPathComponent,
                at: 0
            )
            ancestor.deleteLastPathComponent()
        }

        return missingComponents.reduce(
            ancestor.resolvingSymlinksInPath()
        ) { resolvedURL, component in
            resolvedURL.appendingPathComponent(component)
        }
        .standardizedFileURL
    }

    func relativePath(
        for role: PortableAssetManifest.Role,
        sourceURL: URL,
        data: Data
    ) -> String {
        let digest = SHA256.hash(data: data).assetHexString
        let fileExtension = safeFileExtension(
            sourceURL.pathExtension
        )
        return "Assets/\(role.rawValue)/sha256-\(digest)\(fileExtension)"
    }

    func safeFileExtension(
        _ pathExtension: String
    ) -> String {
        let normalized = pathExtension.lowercased()
        guard !normalized.isEmpty,
              normalized.count <= 10,
              normalized.unicodeScalars.allSatisfy({
                  CharacterSet.alphanumerics.contains($0)
              })
        else {
            return ""
        }
        return ".\(normalized)"
    }

    func readData(
        at url: URL
    ) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw ConfigurationAssetPackagingError.readFailed(
                String(describing: error)
            )
        }
    }

    func write(
        _ data: Data,
        to url: URL
    ) throws {
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            throw ConfigurationAssetPackagingError.writeFailed(
                String(describing: error)
            )
        }
    }

    func checksum(
        for data: Data
    ) -> String {
        "sha256:\(SHA256.hash(data: data).assetHexString)"
    }

    func manifestID(
        role: PortableAssetManifest.Role,
        subjectID: UUID,
        configurationID: UUID
    ) -> UUID {
        let ownerID = role == .customLogo
            ? configurationID
            : subjectID
        return MemoryConfigurationRecord.deterministicUUID(
            basedOn: ownerID,
            discriminator: discriminator(for: role)
        )
    }

    func discriminator(
        for role: PortableAssetManifest.Role
    ) -> UInt8 {
        switch role {
        case .subjectAvatar:
            return 0xA1
        case .subjectAvatarBadge:
            return 0xA2
        case .subjectAvatarPreview:
            return 0xA3
        case .customLogo:
            return 0xA4
        }
    }

    func remap(
        role: PortableAssetManifest.Role,
        reference: PortableAssetReference,
        subject: inout MemorySubject,
        configuration: inout MemoryConfigurationRecord
    ) {
        switch role {
        case .subjectAvatar:
            subject.identity.avatarImagePath = reference.relativePath
        case .subjectAvatarBadge:
            subject.identity.avatarBadgeImagePath = reference.relativePath
        case .subjectAvatarPreview:
            subject.identity.avatarPreviewImagePath = reference.relativePath
        case .customLogo:
            configuration.presentation.logo.badge?
                .assetReference = reference
        }
    }

    func remapRestoredSubject(
        role: PortableAssetManifest.Role,
        absolutePath: String,
        subject: inout MemorySubject
    ) {
        switch role {
        case .subjectAvatar:
            subject.identity.avatarImagePath = absolutePath
        case .subjectAvatarBadge:
            subject.identity.avatarBadgeImagePath = absolutePath
        case .subjectAvatarPreview:
            subject.identity.avatarPreviewImagePath = absolutePath
        case .customLogo:
            break
        }
    }
}

private extension SHA256.Digest {

    nonisolated var assetHexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
