import Foundation

nonisolated enum MediaPipelineRuntimeMode:
    Hashable,
    Codable,
    Sendable {
    case disabled
    case shadow
    case validationCandidate
    case internalTesting
}

nonisolated struct MediaPipelineRuntimeGate:
    Hashable,
    Codable,
    Sendable {

    let mode: MediaPipelineRuntimeMode
    let allowedRoutes: Set<MediaProcessingRoute>
    let permitsUserVisibleOutputControls: Bool
    let permitsPhotoLibraryWrites: Bool

    var requiresDiscardedOutputs: Bool {
        mode == .shadow
    }

    nonisolated static let defaultOff =
        MediaPipelineRuntimeGate(
            mode: .disabled,
            allowedRoutes: [],
            permitsUserVisibleOutputControls: false,
            permitsPhotoLibraryWrites: false
        )

    nonisolated static let v1Production =
        MediaPipelineRuntimeGate(
            mode: .disabled,
            allowedRoutes: [
                .stillImage,
                .rawStillImage
            ],
            permitsUserVisibleOutputControls: false,
            permitsPhotoLibraryWrites: false
        )

    nonisolated static let shadow =
        MediaPipelineRuntimeGate(
            mode: .shadow,
            allowedRoutes: [
                .stillImage,
                .rawStillImage,
                .livePhoto
            ],
            permitsUserVisibleOutputControls: false,
            permitsPhotoLibraryWrites: false
        )

    nonisolated static func validationCandidate(
        allowedRoutes: Set<MediaProcessingRoute>,
        exposesUserVisibleOutputControls: Bool = false,
        permitsPhotoLibraryWrites: Bool = false
    ) -> MediaPipelineRuntimeGate {
        MediaPipelineRuntimeGate(
            mode: .validationCandidate,
            allowedRoutes: allowedRoutes,
            permitsUserVisibleOutputControls:
                exposesUserVisibleOutputControls,
            permitsPhotoLibraryWrites:
                permitsPhotoLibraryWrites
        )
    }

    nonisolated static func internalTesting(
        allowedRoutes: Set<MediaProcessingRoute>,
        exposesUserVisibleOutputControls: Bool = false,
        permitsPhotoLibraryWrites: Bool = false
    ) -> MediaPipelineRuntimeGate {
        MediaPipelineRuntimeGate(
            mode: .internalTesting,
            allowedRoutes: allowedRoutes,
            permitsUserVisibleOutputControls:
                exposesUserVisibleOutputControls,
            permitsPhotoLibraryWrites:
                permitsPhotoLibraryWrites
        )
    }

    nonisolated func permitsPlanning(
        for route: MediaProcessingRoute
    ) -> Bool {
        allowedRoutes.contains(route)
    }
}
