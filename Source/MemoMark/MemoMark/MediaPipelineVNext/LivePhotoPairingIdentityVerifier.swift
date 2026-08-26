import AVFoundation
import Foundation
import ImageIO

struct LivePhotoPairingIdentityPlan:
    Equatable,
    Hashable,
    Sendable {

    let pairingIdentifier: String
}

enum LivePhotoPairingIdentityPlanningError:
    LocalizedError,
    Equatable,
    Sendable {

    case missingPairingIdentifier
    case invalidPairingIdentifier(String)

    var errorDescription: String? {
        switch self {
        case .missingPairingIdentifier:
            return "A generated Live Photo pairing identifier is required."
        case .invalidPairingIdentifier:
            return "A generated Live Photo pairing identifier must be UUID-shaped."
        }
    }
}

struct LivePhotoPairingIdentityPlanner:
    Sendable {

    private let generateIdentifier:
        @Sendable () -> String

    init(
        generateIdentifier:
            @escaping @Sendable () -> String = {
                UUID().uuidString
            }
    ) {
        self.generateIdentifier =
            generateIdentifier
    }

    func plan() throws -> LivePhotoPairingIdentityPlan {
        let identifier =
            generateIdentifier()
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !identifier.isEmpty else {
            throw LivePhotoPairingIdentityPlanningError
                .missingPairingIdentifier
        }

        guard UUID(uuidString: identifier) != nil else {
            throw LivePhotoPairingIdentityPlanningError
                .invalidPairingIdentifier(identifier)
        }

        return LivePhotoPairingIdentityPlan(
            pairingIdentifier:
                identifier
        )
    }
}

struct LivePhotoPairingIdentityReport:
    Equatable,
    Sendable {

    let stillContentIdentifier: String
    let pairedVideoContentIdentifier: String

    var isMatched: Bool {
        stillContentIdentifier == pairedVideoContentIdentifier
    }
}

enum LivePhotoPairingIdentityVerificationError:
    LocalizedError,
    Equatable,
    Sendable {

    case stillPhotoUnreadable(URL)
    case pairedVideoUnreadable(URL)
    case stillContentIdentifierMissing
    case pairedVideoContentIdentifierMissing
    case contentIdentifierMismatch(
        still: String,
        pairedVideo: String
    )

    var errorDescription: String? {
        switch self {
        case .stillPhotoUnreadable:
            return "Unable to read the rendered Live Photo still image metadata."
        case .pairedVideoUnreadable:
            return "Unable to read the rendered Live Photo paired video metadata."
        case .stillContentIdentifierMissing:
            return "The rendered Live Photo still image is missing its pairing identifier."
        case .pairedVideoContentIdentifierMissing:
            return "The rendered Live Photo paired video is missing its pairing identifier."
        case .contentIdentifierMismatch:
            return "The rendered Live Photo still image and paired video identifiers do not match."
        }
    }
}

protocol LivePhotoPairingIdentityVerifying:
    Sendable {

    func verifyPair(
        stillPhotoURL: URL,
        pairedVideoURL: URL
    ) async throws -> LivePhotoPairingIdentityReport
}

struct LivePhotoPairingIdentityVerifier:
    LivePhotoPairingIdentityVerifying {

    func verifyPair(
        stillPhotoURL: URL,
        pairedVideoURL: URL
    ) async throws -> LivePhotoPairingIdentityReport {

        let stillIdentifier =
            try stillContentIdentifier(
                from: stillPhotoURL
            )
        let videoIdentifier =
            try await videoContentIdentifier(
                from: pairedVideoURL
            )

        return try validate(
            stillContentIdentifier: stillIdentifier,
            pairedVideoContentIdentifier: videoIdentifier
        )
    }

    func validate(
        stillContentIdentifier: String,
        pairedVideoContentIdentifier: String
    ) throws -> LivePhotoPairingIdentityReport {

        guard
            stillContentIdentifier
                == pairedVideoContentIdentifier
        else {
            throw LivePhotoPairingIdentityVerificationError
                .contentIdentifierMismatch(
                    still: stillContentIdentifier,
                    pairedVideo: pairedVideoContentIdentifier
                )
        }

        return LivePhotoPairingIdentityReport(
            stillContentIdentifier:
                stillContentIdentifier,
            pairedVideoContentIdentifier:
                pairedVideoContentIdentifier
        )
    }

    static func stillContentIdentifier(
        from metadata: [String: Any]
    ) -> String? {

        guard let makerAppleDictionary =
            makerAppleDictionary(
                from: metadata
            )
        else {
            return nil
        }

        return contentIdentifier(
            fromMakerAppleDictionary:
                makerAppleDictionary
        )
    }

    static func videoContentIdentifier(
        from metadata: [AVMetadataItem]
    ) async throws -> String? {

        guard let item = metadata.first(
            where: {
                $0.identifier
                    == .quickTimeMetadataContentIdentifier
            }
        ) else {
            return nil
        }

        return try await item.load(.stringValue)?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .nilIfEmpty
    }
}

private extension LivePhotoPairingIdentityVerifier {

    func stillContentIdentifier(
        from url: URL
    ) throws -> String {

        guard let source =
            CGImageSourceCreateWithURL(
                url as CFURL,
                nil
            )
        else {
            throw LivePhotoPairingIdentityVerificationError
                .stillPhotoUnreadable(url)
        }

        guard let properties =
            CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
            ) as? [String: Any]
        else {
            throw LivePhotoPairingIdentityVerificationError
                .stillPhotoUnreadable(url)
        }

        guard let identifier =
            Self.stillContentIdentifier(
                from: properties
            )
        else {
            throw LivePhotoPairingIdentityVerificationError
                .stillContentIdentifierMissing
        }

        return identifier
    }

    func videoContentIdentifier(
        from url: URL
    ) async throws -> String {

        let asset =
            AVURLAsset(url: url)
        let metadata: [AVMetadataItem]

        do {
            metadata =
                try await asset.load(.metadata)
        } catch {
            throw LivePhotoPairingIdentityVerificationError
                .pairedVideoUnreadable(url)
        }

        guard let identifier =
            try await Self.videoContentIdentifier(
                from: metadata
            )
        else {
            throw LivePhotoPairingIdentityVerificationError
                .pairedVideoContentIdentifierMissing
        }

        return identifier
    }

    static func makerAppleDictionary(
        from metadata: [String: Any]
    ) -> [AnyHashable: Any]? {

        let possibleKeys = [
            "{MakerApple}",
            kCGImagePropertyMakerAppleDictionary as String
        ]

        for key in possibleKeys {
            if let dictionary =
                metadata[key] as? [AnyHashable: Any] {
                return dictionary
            }

            if let dictionary =
                metadata[key] as? [String: Any] {
                return Dictionary(
                    uniqueKeysWithValues:
                        dictionary.map {
                            (AnyHashable($0.key), $0.value)
                        }
                )
            }

            if let dictionary =
                metadata[key] as? NSDictionary {
                var normalized:
                    [AnyHashable: Any] = [:]

                for (rawKey, value) in dictionary {
                    if let numberKey =
                        rawKey as? NSNumber {
                        normalized[
                            AnyHashable(
                                numberKey.intValue
                            )
                        ] = value
                    } else if let stringKey =
                        rawKey as? String {
                        normalized[
                            AnyHashable(stringKey)
                        ] = value
                    }
                }

                return normalized
            }
        }

        return nil
    }

    static func contentIdentifier(
        fromMakerAppleDictionary dictionary:
            [AnyHashable: Any]
    ) -> String? {

        let possibleKeys: [AnyHashable] = [
            AnyHashable(17),
            AnyHashable("17")
        ]

        for key in possibleKeys {
            if let identifier =
                dictionary[key] as? String {
                return identifier
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .nilIfEmpty
            }
        }

        return nil
    }
}

private extension String {

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
