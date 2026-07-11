import AVFoundation
import CoreGraphics
import Foundation
import QuartzCore
import UniformTypeIdentifiers

protocol LivePhotoVideoComposing {

    func composeVideo(
        sourceVideoURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL
    ) async throws -> URL
}

protocol LivePhotoVideoPairingComposing {

    func composeVideo(
        sourceVideoURL: URL,
        geometry: CanonicalGeometry,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        pairingIdentityPlan:
            LivePhotoPairingIdentityPlan?
    ) async throws -> URL
}

enum LivePhotoVideoCompositionError:
    LocalizedError,
    Equatable {
    case sourceVideoUnreadable
    case videoTrackMissing
    case invalidOverlayGeometry
    case compositionTrackCreateFailed
    case exportSessionUnavailable
    case destinationPrepareFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .sourceVideoUnreadable:
            return "The source Live Photo video could not be read."
        case .videoTrackMissing:
            return "The source video does not contain a readable video track."
        case .invalidOverlayGeometry:
            return "The requested footer geometry is invalid for the target canvas."
        case .compositionTrackCreateFailed:
            return "Unable to prepare a mutable track for video composition."
        case .exportSessionUnavailable:
            return "Unable to create an export session for the composed video."
        case .destinationPrepareFailed:
            return "Unable to prepare the output video destination."
        case .exportFailed:
            return "Unable to export the composed video."
        }
    }
}

final class LivePhotoVideoCompositionService:
    LivePhotoVideoComposing,
    LivePhotoVideoPairingComposing {

    private let inputPreparer:
        any LivePhotoVideoCompositionInputPreparing

    init(
        inputPreparer:
            any LivePhotoVideoCompositionInputPreparing =
                AVFoundationLivePhotoVideoCompositionInputPreparer()
    ) {
        self.inputPreparer =
            inputPreparer
    }

    func composeVideo(
        sourceVideoURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL
    ) async throws -> URL {
        try await composeVideo(
            sourceVideoURL:
                sourceVideoURL,
            overlay:
                overlay,
            outputURL:
                outputURL,
            pairingIdentityPlan:
                nil
        )
    }

    func composeVideo(
        sourceVideoURL: URL,
        geometry: CanonicalGeometry,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        pairingIdentityPlan:
            LivePhotoPairingIdentityPlan?
    ) async throws -> URL {
        let geometryOverlay =
            try FixedFooterOverlayDescriptor(
                canvasSize:
                    geometry
                    .canvas
                    .canvasSize,
                photoFrame:
                    geometry
                    .canvas
                    .photoFrame,
                footerFrame:
                    geometry
                    .canvas
                    .footerFrame,
                footerImage:
                    overlay
                    .footerImage
            )

        return try await composeVideo(
            sourceVideoURL:
                sourceVideoURL,
            overlay:
                geometryOverlay,
            outputURL:
                outputURL,
            pairingIdentityPlan:
                pairingIdentityPlan
        )
    }

    func composeVideo(
        sourceVideoURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        pairingIdentityPlan:
            LivePhotoPairingIdentityPlan?
    ) async throws -> URL {
        let preparedOverlay =
            try overlay.normalizedForEncoder()

        let preparedInput =
            try await inputPreparer
            .preparedVideoCompositionInput(
                sourceVideoURL:
                    sourceVideoURL,
                preparedOverlay:
                    preparedOverlay
            )
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: preparedOverlay.canvasSize)

        let backgroundLayer = CALayer()
        backgroundLayer.frame = parentLayer.frame
        backgroundLayer.backgroundColor = CGColor(
            red: 1,
            green: 1,
            blue: 1,
            alpha: 1
        )

        let videoLayer = CALayer()
        videoLayer.frame = parentLayer.frame

        let footerLayer = CALayer()
        footerLayer.frame = preparedOverlay.footerFrame
        footerLayer.contents = preparedOverlay.footerImage
        footerLayer.contentsGravity = .resize
        footerLayer.masksToBounds = true

        parentLayer.addSublayer(backgroundLayer)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(footerLayer)

        let videoComposition =
            makeVideoComposition(
                videoTrack:
                    preparedInput
                    .videoTrack,
                duration:
                    preparedInput
                    .duration,
                frameDuration:
                    preparedInput
                    .frameDuration,
                resolvedVideoTransform:
                    preparedInput
                    .resolvedVideoTransform,
                preparedOverlay:
                    preparedOverlay,
                videoLayer:
                    videoLayer,
                parentLayer:
                    parentLayer
            )

        let outputFolder = outputURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(
                at: outputFolder,
                withIntermediateDirectories: true
            )
        } catch {
            throw LivePhotoVideoCompositionError.destinationPrepareFailed
        }

        try? FileManager.default.removeItem(at: outputURL)

        let presetName =
            await preferredExportPresetName(
                for:
                    preparedInput
                    .composition
            )

        guard let exportSession = AVAssetExportSession(
            asset:
                preparedInput
                .composition,
            presetName: presetName
        ) else {
            throw LivePhotoVideoCompositionError.exportSessionUnavailable
        }

        exportSession.videoComposition = videoComposition
        exportSession.metadata =
            try await metadataForExport(
                sourceMetadata:
                    preparedInput
                    .sourceMetadata,
                sourceVideoURL: sourceVideoURL,
                outputURL: outputURL,
                preparedOverlay: preparedOverlay,
                pairingIdentityPlan:
                    pairingIdentityPlan
            )
        exportSession.shouldOptimizeForNetworkUse = false

        try await export(
            exportSession,
            to: outputURL,
            as: .mov
        )

        return outputURL
    }
}

struct LivePhotoComposedPair:
    Hashable,
    Sendable {

    let stillPhotoURL: URL
    let pairedVideoURL: URL
    let pairingIdentityPlan:
        LivePhotoPairingIdentityPlan
}

protocol LivePhotoPairComposing {

    func composePair(
        sourceStillURL: URL,
        sourceVideoURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputStillURL: URL,
        outputVideoURL: URL,
        outputStillType: UTType,
        outputDescription: String?
    ) async throws -> LivePhotoComposedPair
}

final class LivePhotoPairCompositionService:
    LivePhotoPairComposing {

    private let pairingIdentityPlanner:
        LivePhotoPairingIdentityPlanner
    private let geometryResolver:
        any LivePhotoGeometryResolving
    private let stillComposer:
        any LivePhotoStillImagePairingComposing
    private let videoComposer:
        any LivePhotoVideoPairingComposing

    init(
        pairingIdentityPlanner:
            LivePhotoPairingIdentityPlanner =
                LivePhotoPairingIdentityPlanner(),
        geometryResolver:
            any LivePhotoGeometryResolving =
                LivePhotoGeometryResolver(),
        stillComposer:
            any LivePhotoStillImagePairingComposing =
                LivePhotoStillImageCompositionService(),
        videoComposer:
            any LivePhotoVideoPairingComposing =
                LivePhotoVideoCompositionService()
    ) {
        self.pairingIdentityPlanner =
            pairingIdentityPlanner
        self.geometryResolver =
            geometryResolver
        self.stillComposer =
            stillComposer
        self.videoComposer =
            videoComposer
    }

    func composePair(
        sourceStillURL: URL,
        sourceVideoURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputStillURL: URL,
        outputVideoURL: URL,
        outputStillType: UTType,
        outputDescription: String? = nil
    ) async throws -> LivePhotoComposedPair {

        let pairingIdentityPlan =
            try pairingIdentityPlanner.plan()
        let geometry =
            try geometryResolver
            .resolveGeometry(
                sourceStillURL:
                    sourceStillURL,
                overlay:
                    overlay,
                outputStillType:
                    outputStillType
            )

        let stillPhotoURL =
            try stillComposer.composeStillImage(
                sourceStillURL:
                    sourceStillURL,
                geometry:
                    geometry,
                overlay:
                    overlay,
                outputURL:
                    outputStillURL,
                outputType:
                    outputStillType,
                pairingIdentifier:
                    pairingIdentityPlan
                    .pairingIdentifier,
                outputDescription:
                    outputDescription
            )
        let pairedVideoURL =
            try await videoComposer.composeVideo(
                sourceVideoURL:
                    sourceVideoURL,
                geometry:
                    geometry,
                overlay:
                    overlay,
                outputURL:
                    outputVideoURL,
                pairingIdentityPlan:
                    pairingIdentityPlan
            )

        return LivePhotoComposedPair(
            stillPhotoURL:
                stillPhotoURL,
            pairedVideoURL:
                pairedVideoURL,
            pairingIdentityPlan:
                pairingIdentityPlan
        )
    }
}

extension LivePhotoVideoCompositionService {

    private func makeVideoComposition(
        videoTrack: AVMutableCompositionTrack,
        duration: CMTime,
        frameDuration: CMTime,
        resolvedVideoTransform: CGAffineTransform,
        preparedOverlay: FixedFooterOverlayDescriptor,
        videoLayer: CALayer,
        parentLayer: CALayer
    ) -> AVVideoComposition {
        #if os(macOS)
        makeConfiguredVideoComposition(
            videoTrack: videoTrack,
            duration: duration,
            frameDuration: frameDuration,
            resolvedVideoTransform: resolvedVideoTransform,
            preparedOverlay: preparedOverlay,
            videoLayer: videoLayer,
            parentLayer: parentLayer
        )
        #else
        makeMutableVideoComposition(
            videoTrack: videoTrack,
            duration: duration,
            frameDuration: frameDuration,
            resolvedVideoTransform: resolvedVideoTransform,
            preparedOverlay: preparedOverlay,
            videoLayer: videoLayer,
            parentLayer: parentLayer
        )
        #endif
    }

    #if os(macOS)
    private func makeConfiguredVideoComposition(
        videoTrack: AVMutableCompositionTrack,
        duration: CMTime,
        frameDuration: CMTime,
        resolvedVideoTransform: CGAffineTransform,
        preparedOverlay: FixedFooterOverlayDescriptor,
        videoLayer: CALayer,
        parentLayer: CALayer
    ) -> AVVideoComposition {
        var layerConfiguration =
            AVVideoCompositionLayerInstruction
            .Configuration(
                trackID:
                    videoTrack.trackID
        )
        layerConfiguration.setTransform(
            resolvedVideoTransform,
            at: .zero
        )

        let layerInstruction =
            AVVideoCompositionLayerInstruction(
                configuration:
                    layerConfiguration
            )
        let instruction =
            AVVideoCompositionInstruction(
                configuration:
                    AVVideoCompositionInstruction
                    .Configuration(
                        layerInstructions:
                            [layerInstruction],
                        timeRange:
                            CMTimeRange(
                                start: .zero,
                                duration: duration
                            )
                    )
            )
        let animationTool =
            AVVideoCompositionCoreAnimationTool(
                configuration:
                    AVVideoCompositionCoreAnimationTool
                    .Configuration(
                        postProcessingAsVideoLayer:
                            videoLayer,
                        containingLayer:
                            parentLayer
                    )
            )

        return AVVideoComposition(
            configuration:
                AVVideoComposition
                .Configuration(
                    animationTool:
                        animationTool,
                    frameDuration:
                        frameDuration,
                    instructions:
                        [instruction],
                    renderSize:
                        preparedOverlay
                        .canvasSize
                )
        )
    }
    #else
    private func makeMutableVideoComposition(
        videoTrack: AVMutableCompositionTrack,
        duration: CMTime,
        frameDuration: CMTime,
        resolvedVideoTransform: CGAffineTransform,
        preparedOverlay: FixedFooterOverlayDescriptor,
        videoLayer: CALayer,
        parentLayer: CALayer
    ) -> AVVideoComposition {
        let layerInstruction =
            AVMutableVideoCompositionLayerInstruction(
                assetTrack:
                    videoTrack
        )
        layerInstruction.setTransform(
            resolvedVideoTransform,
            at: .zero
        )

        let instruction =
            AVMutableVideoCompositionInstruction()
        instruction.timeRange =
            CMTimeRange(
                start: .zero,
                duration: duration
            )
        instruction.layerInstructions =
            [layerInstruction]

        let videoComposition =
            AVMutableVideoComposition()
        videoComposition.animationTool =
            AVVideoCompositionCoreAnimationTool(
                postProcessingAsVideoLayer:
                    videoLayer,
                in:
                    parentLayer
            )
        videoComposition.frameDuration =
            frameDuration
        videoComposition.instructions =
            [instruction]
        videoComposition.renderSize =
            preparedOverlay
            .canvasSize

        return videoComposition
    }
    #endif

    func export(
        _ exportSession: AVAssetExportSession,
        to outputURL: URL,
        as fileType: AVFileType
    ) async throws {

        do {
            try await exportSession.export(
                to: outputURL,
                as: fileType
            )
        } catch {
            throw error
        }
    }

    func preferredExportPresetName(
        for composition: AVComposition
    ) async -> String {
        if await AVAssetExportSession.compatibility(
            ofExportPreset: AVAssetExportPresetHEVCHighestQuality,
            with: composition,
            outputFileType: .mov
        ) {
            return AVAssetExportPresetHEVCHighestQuality
        }

        return AVAssetExportPresetHighestQuality
    }

    func metadataForExport(
        sourceMetadata: [AVMetadataItem],
        sourceVideoURL: URL,
        outputURL: URL,
        preparedOverlay: FixedFooterOverlayDescriptor,
        pairingIdentityPlan:
            LivePhotoPairingIdentityPlan? = nil
    ) async throws -> [AVMetadataItem] {
        let sourcePairingIdentifier =
            try await LivePhotoPairingIdentityVerifier
                .videoContentIdentifier(
                    from: sourceMetadata
                )
        let pairingIdentifier =
            pairingIdentityPlan?.pairingIdentifier
            ?? sourcePairingIdentifier

        guard let pairingIdentifier else {
            return sourceMetadata
        }

        let policy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .livePhoto,
                        sourceContentType: .heic,
                        outputPlan:
                            .livePhotoPair(
                                stillImageType: .heic,
                                pairedVideoType:
                                    Self.quickTimeMovieType
                            ),
                        preservesLivePhotoMotion: true,
                        requiresLivePhotoPairedResources: true
                    )
            )
        let plan =
            try LivePhotoVideoMetadataWritePlanner
                .standard
                .plan(
                    LivePhotoVideoMetadataWriteRequest(
                        sourceVideoURL: sourceVideoURL,
                        renderedVideoURL: outputURL,
                        destinationVideoURL: outputURL,
                        pairingIdentifier:
                            pairingIdentifier,
                        outputPixelWidth:
                            Int(
                                preparedOverlay
                                    .canvasSize
                                    .width
                            ),
                        outputPixelHeight:
                            Int(
                                preparedOverlay
                                    .canvasSize
                                    .height
                            ),
                        policyPlan: policy
                    )
                )

        return AVFoundationLivePhotoVideoMetadataReviser()
            .revisedMetadata(
                from: sourceMetadata,
                plan: plan
            )
    }

    static func normalizedOverlay(
        _ overlay: FixedFooterOverlayDescriptor
    ) throws -> FixedFooterOverlayDescriptor {
        try overlay.normalizedForEncoder()
    }

    static func normalizedEncoderDimension(
        _ value: CGFloat
    ) -> CGFloat {
        FixedFooterOverlayDescriptor
            .normalizedEncoderDimension(value)
    }

    private static let quickTimeMovieType =
        UTType("com.apple.quicktime-movie")
        ?? .movie
}
