import Foundation
import UniformTypeIdentifiers

nonisolated struct MediaProcessingPlan:
    Hashable,
    Sendable {

    let route: MediaProcessingRoute
    let sourceContentType: UTType?
    let outputPlan: MediaOutputPlan
    let preservesLivePhotoMotion: Bool
    let requiresLivePhotoPairedResources: Bool
}

nonisolated enum MediaProcessingPlanningError:
    LocalizedError,
    Equatable,
    Sendable {

    case unsupportedInput(
        PhotoProcessingInputPolicy
            .RejectionReason
    )
    case outputPlanningFailed(
        MediaOutputPlanningError
    )
    case routeDisabledByRuntimeGate(
        MediaProcessingRoute
    )

    var errorDescription: String? {
        switch self {
        case .unsupportedInput(let reason):
            return "The media input is not supported because of \(reason.rawValue)."
        case .outputPlanningFailed(let error):
            return error.localizedDescription
        case .routeDisabledByRuntimeGate(let route):
            return "The \(route.rawValue) media route is disabled by the runtime gate."
        }
    }
}

struct MediaProcessingPlanner {

    static let standard =
        MediaProcessingPlanner()

    private let routeDecider:
        any MediaProcessingRouting
    private let outputPolicy:
        MediaOutputPolicy
    private let runtimeGate:
        MediaPipelineRuntimeGate

    init(
        routeDecider:
            any MediaProcessingRouting =
                MediaProcessingRouter(),
        outputPolicy:
            MediaOutputPolicy =
                .standard,
        runtimeGate:
            MediaPipelineRuntimeGate =
                .v1Production
    ) {
        self.routeDecider = routeDecider
        self.outputPolicy = outputPolicy
        self.runtimeGate =
            runtimeGate
    }

    func plan(
        for descriptor:
            MediaProcessingInputDescriptor,
        outputPreference:
            MediaOutputPreference
    ) throws -> MediaProcessingPlan {
        try plan(
            for: descriptor,
            intent:
                MediaProcessingIntent(
                    outputPreference:
                        outputPreference
                )
        )
    }

    func plan(
        for descriptor:
            MediaProcessingInputDescriptor,
        intent:
            MediaProcessingIntent
    ) throws -> MediaProcessingPlan {

        let decision =
            routeDecider.decision(
                for: descriptor
            )

        guard decision.route != .unsupported else {
            throw MediaProcessingPlanningError
                .unsupportedInput(
                    decision.rejectionReason
                    ?? .unsupportedFormat
                )
        }

        guard runtimeGate.permitsPlanning(
            for:
                decision.route
        ) else {
            throw MediaProcessingPlanningError
                .routeDisabledByRuntimeGate(
                    decision.route
                )
        }

        let sourceContentType =
            descriptor.resolvedContentType

        do {
            let outputPlan =
                try outputPolicy.plan(
                    for: decision.route,
                    sourceContentType:
                        sourceContentType,
                    intent:
                        intent
                )

            return MediaProcessingPlan(
                route: decision.route,
                sourceContentType:
                    sourceContentType,
                outputPlan: outputPlan,
                preservesLivePhotoMotion:
                    outputPlan
                    .preservesLivePhotoMotion,
                requiresLivePhotoPairedResources:
                    outputPlan
                    .preservesLivePhotoMotion
            )
        } catch let error as MediaOutputPlanningError {
            throw MediaProcessingPlanningError
                .outputPlanningFailed(error)
        }
    }
}
