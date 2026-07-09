import Foundation

nonisolated enum MediaProcessingMotionMode:
    Hashable,
    Codable,
    Sendable {
    case automatic
    case preserveLivePhotoMotion
    case stillImageOnly
}

nonisolated struct MediaProcessingIntent:
    Hashable,
    Codable,
    Sendable {

    let motionMode: MediaProcessingMotionMode
    let outputPreference: MediaOutputPreference

    nonisolated init(
        motionMode: MediaProcessingMotionMode = .automatic,
        outputPreference: MediaOutputPreference = .automatic
    ) {
        self.motionMode = motionMode
        self.outputPreference = outputPreference
    }

    nonisolated static let automatic =
        MediaProcessingIntent()
}
