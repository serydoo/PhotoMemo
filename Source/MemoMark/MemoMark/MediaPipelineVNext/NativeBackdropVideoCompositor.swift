import AVFoundation
import CoreImage
import Foundation
import os

/// Immutable Layout output and source transform for a source-dependent frame.
nonisolated final class NativeBackdropVideoInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    let timeRange: CMTimeRange
    let enablePostProcessing = false
    let containsTweening = true
    let passthroughTrackID = kCMPersistentTrackID_Invalid
    var requiredSourceTrackIDs: [NSValue]? { [NSNumber(value: sourceTrackID)] }
    let sourceTrackID: CMPersistentTrackID
    let videoTransform: CGAffineTransform
    let artifact: PresentationArtifact
    private let foregroundLayers: [CIImage]

    init(trackID: CMPersistentTrackID, duration: CMTime,
         videoTransform: CGAffineTransform, artifact: PresentationArtifact) {
        sourceTrackID = trackID
        timeRange = CMTimeRange(start: .zero, duration: duration)
        self.videoTransform = videoTransform
        self.artifact = artifact
        // Prepare immutable foreground once; the photo and glass remain frame-dependent.
        foregroundLayers = artifact.layers.sorted(by: { $0.zIndex < $1.zIndex }).map { layer in
            CIImage(cgImage: layer.image)
                .applyingFilter("CIColorMatrix", parameters: ["inputAVector": CIVector(x: 0, y: 0, z: 0, w: layer.opacity)])
                .transformed(by: CGAffineTransform(scaleX: layer.frame.width / CGFloat(layer.image.width),
                    y: layer.frame.height / CGFloat(layer.image.height)))
                .transformed(by: CGAffineTransform(translationX: layer.frame.minX, y: layer.frame.minY))
        }
    }

    func compositingForeground(over canvas: CIImage) -> CIImage {
        foregroundLayers.reduce(canvas) { $1.composited(over: $0) }
    }
}

/// Reuses AVAssetExportSession. Only native SwiftUI raster work hops to MainActor.
@available(iOS 26.0, macOS 26.0, *)
nonisolated final class NativeBackdropVideoCompositor: NSObject, AVVideoCompositing {

    private let pending = OSAllocatedUnfairLock(initialState: [UUID: AVAsynchronousVideoCompositionRequest]())
    // AVFoundation conforms SDR source frames; Core Image preserves their attached color space.
    private let context = CIContext(options: [.cacheIntermediates: false])
    var sourcePixelBufferAttributes: [String: any Sendable]? {
        [kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, kCVPixelFormatType_32BGRA]]
    }
    var requiredPixelBufferAttributesForRenderContext: [String: any Sendable] {
        [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
         kCVPixelBufferIOSurfacePropertiesKey as String: [String: Int]()]
    }
    var supportsWideColorSourceFrames: Bool { false }
    var supportsHDRSourceFrames: Bool { false }
    var canConformColorOfSourceFrames: Bool { false }

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // Each immutable request supplies its own context; no mutable context cache.
    }

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        let id = UUID()
        pending.withLock { $0[id] = request }
        Task {
            do {
                guard isPending(id),
                      let instruction = request.videoCompositionInstruction as? NativeBackdropVideoInstruction,
                      let source = request.sourceReadOnlyPixelBuffer(byTrackID: instruction.sourceTrackID),
                      let material = instruction.artifact.backdropMaterial else {
                    throw LivePhotoVideoCompositionError.exportFailed
                }
                let output = try request.renderContext.makeMutablePixelBuffer()
                let bounds = CGRect(origin: .zero, size: instruction.artifact.canvasSize)
                let sourceFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0,
                    ty: source.withUnsafeBuffer { CGFloat(CVPixelBufferGetHeight($0)) })
                let canvasFlip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: bounds.height)
                let transform = sourceFlip.concatenating(instruction.videoTransform).concatenating(canvasFlip)
                var canvas = source.withUnsafeBuffer { CIImage(cvPixelBuffer: $0) }
                    .transformed(by: transform).cropped(to: bounds)
                if instruction.artifact.canvasBackground == .opaqueWhite {
                    canvas = canvas.composited(over: CIImage(color: .white).cropped(to: bounds))
                }
                let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
                guard let image = context.createCGImage(canvas, from: bounds, format: .RGBA8, colorSpace: colorSpace) else {
                    throw LivePhotoVideoCompositionError.exportFailed
                }

                let patch = await MainActor.run {
                    guard self.isPending(id) else { return nil as CGImage? }
                    return NativeBackdropMaterialRenderer.render(sourceCanvas: image,
                        canvasSize: instruction.artifact.canvasSize, material: material)
                }
                guard isPending(id), let patch else { throw CancellationError() }
                let frame = material.renderFrame
                let materialImage = CIImage(cgImage: patch).transformed(by: CGAffineTransform(
                    scaleX: frame.width / CGFloat(patch.width), y: frame.height / CGFloat(patch.height)))
                    .transformed(by: CGAffineTransform(translationX: frame.minX, y: frame.minY))
                canvas = materialImage.composited(over: canvas)
                canvas = instruction.compositingForeground(over: canvas)
                // Match the native material raster space; Rec.709 here raised dark material values on readback.
                output.withUnsafeBuffer {
                    context.render(canvas.transformed(by: request.renderContext.renderTransform), to: $0,
                        bounds: CGRect(origin: .zero, size: request.renderContext.size),
                        colorSpace: CGColorSpace(name: CGColorSpace.sRGB))

                }
                let finishedBuffer = CVReadOnlyPixelBuffer(output)
                finish(id) { $0.finish(withComposedPixelBuffer: finishedBuffer) }
            } catch {
                finish(id) { $0.finish(with: error) }
            }
        }
    }

    func cancelAllPendingVideoCompositionRequests() {
        pending.withLock { requests in
            for request in requests.values { request.finishCancelledRequest() }
            requests.removeAll()
        }
    }

    private func isPending(_ id: UUID) -> Bool { pending.withLock { $0[id] != nil } }

    private func finish(_ id: UUID, action: (AVAsynchronousVideoCompositionRequest) -> Void) {
        pending.withLock { requests in
            // Completion and cancellation have one owner; AVFoundation receives exactly one callback.
            guard let request = requests.removeValue(forKey: id) else { return }
            action(request)
        }
    }
}
