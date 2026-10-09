import Foundation

enum MediaOutputMode:
    String,
    CaseIterable,
    Identifiable,
    Codable,
    Hashable {

    case originalFormat
    case staticImage

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .originalFormat:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.result.mode.original",
                fallback: "Original Format"
            )
        case .staticImage:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.result.mode.static",
                fallback: "Still Image"
            )
        }
    }

    var note: String {
        switch self {
        case .originalFormat:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.result.mode.original.note",
                fallback: "Still photos keep their format; Live Photos keep their motion."
            )
        case .staticImage:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.result.mode.static.note",
                fallback: "Live Photos become still images; still photos keep the current card style."
            )
        }
    }

    var mediaProcessingIntent: MediaProcessingIntent {
        switch self {
        case .originalFormat:
            return MediaProcessingIntent(
                motionMode: .automatic,
                outputPreference: .sourceCompatible
            )
        case .staticImage:
            return MediaProcessingIntent(
                motionMode: .stillImageOnly,
                outputPreference: .sourceCompatible
            )
        }
    }
}

/// Shared output policy; raw values preserve existing configuration transport.
enum LivePhotoOutputPolicy: String, Codable, Hashable {
    case preserveMotion
    case staticImageOnly
}
