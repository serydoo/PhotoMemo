import Foundation
import CryptoKit

/// Versioned output intent. Provider paths, intake UUIDs and snapshot timestamps
/// are transport details and cannot distinguish otherwise identical intentions.
nonisolated struct ProcessingIdentity: Codable, Hashable, Sendable {
    static let receiptPrefix = "processing-intent-v1-"
    let schemaVersion: Int
    let sourceDigest: String
    let semanticsDigest: String

    init(sourceDigest: String, semanticsDigest: String) {
        schemaVersion = 1
        self.sourceDigest = sourceDigest
        self.semanticsDigest = semanticsDigest
    }

    private enum CodingKeys: String, CodingKey { case schemaVersion, sourceDigest, semanticsDigest }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        guard schemaVersion == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .schemaVersion, in: container,
                debugDescription: "Unsupported processing identity schema; preserve queue for recovery.")
        }
        sourceDigest = try container.decode(String.self, forKey: .sourceDigest)
        semanticsDigest = try container.decode(String.self, forKey: .semanticsDigest)
    }

    var receiptKey: String {
        Self.receiptPrefix + Self.digest(Data((sourceDigest + ":" + semanticsDigest).utf8))
    }

    var accountingID: UUID? {
        let hex = String(receiptKey.dropFirst(Self.receiptPrefix.count).prefix(32))
        let offsets = [0, 8, 12, 16, 20, 32]
        let parts = zip(offsets, offsets.dropFirst()).map { start, end in
            String(hex[hex.index(hex.startIndex, offsetBy: start)..<hex.index(hex.startIndex, offsetBy: end)])
        }
        return UUID(uuidString: parts.joined(separator: "-"))
    }

    static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func canonicalSemantics(_ encodedSnapshot: Data) throws -> Data {
        guard var object = try JSONSerialization.jsonObject(with: encodedSnapshot) as? [String: Any] else {
            throw CocoaError(.coderReadCorrupt)
        }
        object.removeValue(forKey: "id")
        object.removeValue(forKey: "createdAt")
        // The Share adapter reconstructs Badge with a new UUID. Its visual
        // fields and referenced bytes remain fully part of output intent.
        if var badge = object["badge"] as? [String: Any] {
            badge.removeValue(forKey: "id")
            object["badge"] = badge
        }
        if var frozen = object["frozenConfigurationSnapshot"] as? [String: Any] {
            frozen.removeValue(forKey: "id")
            frozen.removeValue(forKey: "createdAt")
            object["frozenConfigurationSnapshot"] = frozen
        }
        // FilmMark also transports a canonical snapshot encoded as Data.
        if let base64 = object["frozenCanonicalSnapshotData"] as? String,
           let data = Data(base64Encoded: base64) {
            object["frozenCanonicalSnapshotData"] = try JSONSerialization.jsonObject(with: canonicalSemantics(data))
        }
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}

/// File reads are serialized outside the main actor and bounded to 1 MiB per
/// chunk. An unreadable source never receives a guessed global identity.
actor ProcessingIdentityBuilder {
    static let shared = ProcessingIdentityBuilder()

    func identities(sourceURLs: [URL], semantics: Data, sourceVersions: [String?] = [], assetBaseURL: URL? = nil) throws -> [ProcessingIdentity?] {
        let object = try JSONSerialization.jsonObject(with: semantics)
        let resolved = try fingerprintReferencedFiles(object, assetBaseURL: assetBaseURL)
        let semanticsDigest = ProcessingIdentity.digest(
            try JSONSerialization.data(withJSONObject: resolved, options: [.sortedKeys])
        )
        var identities: [ProcessingIdentity?] = []
        for (index, url) in sourceURLs.enumerated() {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                guard sourceVersions.indices.contains(index), let version = sourceVersions[index] else { identities.append(nil); continue }
                identities.append(ProcessingIdentity(sourceDigest: ProcessingIdentity.digest(Data(version.utf8)), semanticsDigest: semanticsDigest))
                continue
            }
            let digest: String
            if sourceVersions.indices.contains(index), let version = sourceVersions[index] {
                // Share may materialize a regenerated JPEG and recover the
                // original Live Photo ID. A verified asset version takes
                // precedence for files as well as resource directories.
                digest = ProcessingIdentity.digest(Data(version.utf8))
            } else if isDirectory.boolValue {
                let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey])
                    .filter { try $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true }
                guard !files.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
                let resources = try files.map { file in
                    file.pathExtension.lowercased() + ":" + (try fileDigest(file))
                }.sorted()
                digest = ProcessingIdentity.digest(Data(resources.joined(separator: "\n").utf8))
            } else {
                digest = try fileDigest(url)
            }
            identities.append(ProcessingIdentity(sourceDigest: digest, semanticsDigest: semanticsDigest))
        }
        return identities
    }

    private func fingerprintReferencedFiles(_ value: Any, field: String? = nil, assetBaseURL: URL? = nil) throws -> Any {
        if let dictionary = value as? [String: Any] {
            return try Dictionary(uniqueKeysWithValues: dictionary.map { key, value in
                (key, try fingerprintReferencedFiles(value, field: key, assetBaseURL: assetBaseURL))
            })
        }
        if let array = value as? [Any] {
            return try array.map { try fingerprintReferencedFiles($0, assetBaseURL: assetBaseURL) }
        }
        let assetFields: Set<String> = ["imagePath", "avatarImagePath", "avatarBadgeImagePath", "avatarPreviewImagePath"]
        if let field, assetFields.contains(field), let string = value as? String {
            let path = string.hasPrefix("file://") ? URL(string: string)?.path : string
            guard let path, !path.isEmpty else { return value }
            let url: URL
            if path.hasPrefix("/") {
                url = URL(fileURLWithPath: path)
            } else {
                guard let assetBaseURL, !path.split(separator: "/").contains("..") else { return value }
                url = assetBaseURL.appendingPathComponent(path)
            }
            // A frozen asset's bytes, not its mutable filesystem location, are
            // part of output semantics. Missing assets block identity creation.
            return ["assetSHA256": try fileDigest(url)]
        }
        return value
    }

    private func fileDigest(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hash = SHA256()
        while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
            try Task.checkCancellation()
            hash.update(data: chunk)
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
