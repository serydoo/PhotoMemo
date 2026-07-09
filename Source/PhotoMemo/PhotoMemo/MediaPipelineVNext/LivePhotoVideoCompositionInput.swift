import AVFoundation
import CoreGraphics
import Foundation

struct LivePhotoPreparedVideoCompositionInput {

    let composition: AVComposition
    let videoTrack: AVMutableCompositionTrack
    let duration: CMTime
    let frameDuration: CMTime
    let resolvedVideoTransform: CGAffineTransform
    let sourceMetadata: [AVMetadataItem]
}

protocol LivePhotoVideoCompositionInputPreparing {

    func preparedVideoCompositionInput(
        sourceVideoURL: URL,
        preparedOverlay: FixedFooterOverlayDescriptor
    ) async throws -> LivePhotoPreparedVideoCompositionInput
}

struct AVFoundationLivePhotoVideoCompositionInputPreparer:
    LivePhotoVideoCompositionInputPreparing {

    func preparedVideoCompositionInput(
        sourceVideoURL: URL,
        preparedOverlay: FixedFooterOverlayDescriptor
    ) async throws -> LivePhotoPreparedVideoCompositionInput {
        guard FileManager.default.fileExists(atPath: sourceVideoURL.path) else {
            throw LivePhotoVideoCompositionError.sourceVideoUnreadable
        }

        let asset = AVURLAsset(url: sourceVideoURL)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)

        guard let sourceVideoTrack = videoTracks.first else {
            throw LivePhotoVideoCompositionError.videoTrackMissing
        }

        let composition = AVMutableComposition()

        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw LivePhotoVideoCompositionError.compositionTrackCreateFailed
        }

        let duration = try await asset.load(.duration)

        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: sourceVideoTrack,
            at: .zero
        )

        if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: sourceAudioTrack,
                at: .zero
            )
        }

        let naturalSize = try await sourceVideoTrack.load(.naturalSize)
        let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        let nominalFrameRate = try await sourceVideoTrack.load(.nominalFrameRate)
        let frameRate = nominalFrameRate > 0 ? nominalFrameRate : 30
        let frameDuration =
            CMTime(
                value: 1,
                timescale:
                    Int32(
                        max(1, Int(round(frameRate)))
                    )
            )
        let videoRenderFrame =
            videoRenderFrame(
                for:
                    preparedOverlay
                    .photoFrame,
                canvasSize:
                    preparedOverlay
                    .canvasSize
            )
        let resolvedTransform =
            resolvedVideoTransform(
                preferredTransform: preferredTransform,
                naturalSize: naturalSize,
                targetFrame:
                    videoRenderFrame
            )
        let sourceMetadata =
            try await asset.load(.metadata)

        PhotoMemoShareDiagnostics.record(
            stage: .livePhotoVideoCompositionGeometry,
            message:
                geometryDiagnosticMessage(
                    naturalSize:
                        naturalSize,
                    preferredTransform:
                        preferredTransform,
                    canvasSize:
                        preparedOverlay
                        .canvasSize,
                    photoFrame:
                        preparedOverlay
                        .photoFrame,
                    footerFrame:
                        preparedOverlay
                        .footerFrame,
                    videoRenderFrame:
                        videoRenderFrame,
                    resolvedTransform:
                        resolvedTransform
                )
        )

        return LivePhotoPreparedVideoCompositionInput(
            composition: composition,
            videoTrack: compositionVideoTrack,
            duration: duration,
            frameDuration: frameDuration,
            resolvedVideoTransform: resolvedTransform,
            sourceMetadata: sourceMetadata
        )
    }

    func videoRenderFrame(
        for photoFrame: CGRect,
        canvasSize: CGSize
    ) -> CGRect {
        CGRect(
            x: photoFrame.minX,
            y: canvasSize.height - photoFrame.maxY,
            width: photoFrame.width,
            height: photoFrame.height
        )
    }

    func geometryDiagnosticMessage(
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform,
        canvasSize: CGSize,
        photoFrame: CGRect,
        footerFrame: CGRect,
        videoRenderFrame: CGRect,
        resolvedTransform: CGAffineTransform
    ) -> String {
        [
            "naturalSize=\(format(naturalSize))",
            "preferredTransform=\(format(preferredTransform))",
            "canvasSize=\(format(canvasSize))",
            "photoFrame=\(format(photoFrame))",
            "footerFrame=\(format(footerFrame))",
            "videoRenderFrame=\(format(videoRenderFrame))",
            "resolvedTransform=\(format(resolvedTransform))"
        ].joined(separator: ", ")
    }

    func resolvedVideoTransform(
        preferredTransform: CGAffineTransform,
        naturalSize: CGSize,
        targetFrame: CGRect
    ) -> CGAffineTransform {
        let presentationRect = CGRect(origin: .zero, size: naturalSize)
            .applying(preferredTransform)
        let presentationSize = CGSize(
            width: abs(presentationRect.width),
            height: abs(presentationRect.height)
        )

        let scale =
            max(
                targetFrame.width
                / max(presentationSize.width, 1),
                targetFrame.height
                / max(presentationSize.height, 1)
            )

        var transform = preferredTransform.concatenating(
            CGAffineTransform(
                scaleX: scale,
                y: scale
            )
        )

        let scaledRect = CGRect(origin: .zero, size: naturalSize)
            .applying(transform)

        transform = transform.concatenating(
            CGAffineTransform(
                translationX:
                    targetFrame.midX
                    - scaledRect.midX,
                y:
                    targetFrame.midY
                    - scaledRect.midY
            )
        )

        return transform
    }

    private func format(
        _ size: CGSize
    ) -> String {
        "\(format(size.width))x\(format(size.height))"
    }

    private func format(
        _ rect: CGRect
    ) -> String {
        "x:\(format(rect.minX)) y:\(format(rect.minY)) w:\(format(rect.width)) h:\(format(rect.height))"
    }

    private func format(
        _ transform: CGAffineTransform
    ) -> String {
        "a:\(format(transform.a)) b:\(format(transform.b)) c:\(format(transform.c)) d:\(format(transform.d)) tx:\(format(transform.tx)) ty:\(format(transform.ty))"
    }

    private func format(
        _ value: CGFloat
    ) -> String {
        String(
            format:
                "%.3f",
            Double(value)
        )
    }
}
