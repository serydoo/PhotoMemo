import Foundation
import UniformTypeIdentifiers

nonisolated enum MediaOutputPreference:
    Hashable,
    Codable,
    Sendable {
    case automatic
    case sourceCompatible
    case jpeg
    case png
    case heic
}

nonisolated enum MediaOutputPlan:
    Hashable,
    Sendable {
    case stillImage(
        imageType: UTType
    )
    case livePhotoPair(
        stillImageType: UTType,
        pairedVideoType: UTType
    )

    var preservesLivePhotoMotion: Bool {
        switch self {
        case .stillImage:
            return false
        case .livePhotoPair:
            return true
        }
    }
}

nonisolated enum MediaOutputPlanningError:
    LocalizedError,
    Equatable,
    Sendable {
    case unsupportedRoute(
        MediaProcessingRoute
    )
    case livePhotoMotionRequiresPairedHEICOutput(
        requested:
            MediaOutputPreference
    )

    var errorDescription: String? {
        switch self {
        case .unsupportedRoute:
            return "The media route does not support output generation."
        case .livePhotoMotionRequiresPairedHEICOutput:
            return "Live Photo motion preservation requires a paired HEIC and MOV output."
        }
    }
}

nonisolated struct MediaOutputPolicy:
    Hashable,
    Sendable {

    nonisolated static let standard =
        MediaOutputPolicy()

    func plan(
        for route: MediaProcessingRoute,
        sourceContentType: UTType?,
        preference: MediaOutputPreference
    ) throws -> MediaOutputPlan {
        try plan(
            for: route,
            sourceContentType:
                sourceContentType,
            intent:
                MediaProcessingIntent(
                    outputPreference:
                        preference
                )
        )
    }

    func plan(
        for route: MediaProcessingRoute,
        sourceContentType: UTType?,
        intent: MediaProcessingIntent
    ) throws -> MediaOutputPlan {

        switch route {
        case .stillImage:
            return .stillImage(
                imageType:
                    stillImageOutputType(
                        sourceContentType:
                            sourceContentType,
                        preference:
                            intent
                            .outputPreference
                    )
            )

        case .rawStillImage:
            return .stillImage(
                imageType:
                    rawStillImageOutputType(
                        preference:
                            intent
                            .outputPreference
                    )
            )

        case .livePhoto:
            return try livePhotoOutputPlan(
                sourceContentType:
                    sourceContentType,
                intent:
                    intent
            )

        case .unsupported:
            throw MediaOutputPlanningError
                .unsupportedRoute(route)
        }
    }
}

private extension MediaOutputPolicy {

    nonisolated func stillImageOutputType(
        sourceContentType: UTType?,
        preference:
            MediaOutputPreference
    ) -> UTType {

        switch preference {
        case .automatic,
             .sourceCompatible:
            return sourceCompatibleOutputType(
                sourceContentType
            )

        case .jpeg:
            return .jpeg

        case .png:
            return .png

        case .heic:
            return .heic
        }
    }

    nonisolated func rawStillImageOutputType(
        preference:
            MediaOutputPreference
    ) -> UTType {

        switch preference {
        case .jpeg:
            return .jpeg

        case .png:
            return .png

        case .automatic,
             .sourceCompatible,
             .heic:
            return .heic
        }
    }

    nonisolated func livePhotoOutputPlan(
        sourceContentType: UTType?,
        intent:
            MediaProcessingIntent
    ) throws -> MediaOutputPlan {

        switch intent.motionMode {
        case .stillImageOnly:
            return .stillImage(
                imageType:
                    stillImageOutputType(
                        sourceContentType:
                            sourceContentType,
                        preference:
                            intent
                            .outputPreference
                    )
            )

        case .automatic,
             .preserveLivePhotoMotion:
            return try livePhotoMotionPreservingOutputPlan(
                preference:
                    intent
                    .outputPreference
            )
        }
    }

    nonisolated func livePhotoMotionPreservingOutputPlan(
        preference:
            MediaOutputPreference
    ) throws -> MediaOutputPlan {

        switch preference {
        case .automatic,
             .sourceCompatible,
             .heic:
            return .livePhotoPair(
                stillImageType: .heic,
                pairedVideoType:
                    Self.quickTimeMovieType
            )

        case .jpeg,
             .png:
            throw MediaOutputPlanningError
                .livePhotoMotionRequiresPairedHEICOutput(
                    requested:
                        preference
                )
        }
    }

    nonisolated func sourceCompatibleOutputType(
        _ sourceContentType: UTType?
    ) -> UTType {

        guard let sourceContentType else {
            return .heic
        }

        if sourceContentType.conforms(to: .jpeg) {
            return .jpeg
        }

        if sourceContentType.conforms(to: .png) {
            return .png
        }

        if sourceContentType.conforms(to: .heic)
            || sourceContentType.conforms(to: .heif) {
            return .heic
        }

        return .heic
    }

    nonisolated static var quickTimeMovieType: UTType {
        UTType(
            "com.apple.quicktime-movie"
        )
        ?? .movie
    }
}
