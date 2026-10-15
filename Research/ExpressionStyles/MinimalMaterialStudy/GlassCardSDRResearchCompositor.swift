// Research-only explicit final color boundary; no production callers.
import CoreGraphics
import Foundation
@testable import MemoMark

nonisolated enum GlassCardSDRResearchCompositor {
    struct Snapshot: Sendable {
        struct Layer: Sendable {
            let frame: CGRect
            let image: CGImage
            let zIndex: Int
            let opacity: CGFloat
        }
        let canvasSize: CGSize
        let photoFrame: CGRect
        let layers: [Layer]
        @MainActor init(_ artifact: PresentationArtifact) {
            canvasSize=artifact.canvasSize; photoFrame=artifact.photoFrame
            layers=artifact.layers.map { Layer(frame:$0.frame,image:$0.image,zIndex:$0.zIndex,opacity:$0.opacity) }
        }
    }
    enum Failure: Error, Equatable { case mappingMismatch, invalidLayer, contextFailed }
    @MainActor
    static func compose(_ source: GlassCardSDRResearchAdmission.Accepted, artifact: PresentationArtifact) throws -> CGImage {
        try compose(source,snapshot:Snapshot(artifact))
    }
    static func compose(_ source: GlassCardSDRResearchAdmission.Accepted, snapshot artifact: Snapshot) throws -> CGImage {
        try Task.checkCancellation()
        let bounds=CGRect(origin:.zero,size:source.canvas)
        guard artifact.canvasSize==source.canvas,artifact.photoFrame==bounds else { throw Failure.mappingMismatch }
        guard artifact.layers.allSatisfy({ layer in
            let f=layer.frame
            return f.minX.isFinite && f.minY.isFinite && f.width.isFinite && f.height.isFinite && f.width>0 && f.height>0 && bounds.contains(f) && layer.opacity.isFinite
        }) else { throw Failure.invalidLayer }
        guard let context=CGContext(data:nil,width:source.image.width,height:source.image.height,bitsPerComponent:8,bytesPerRow:source.image.width*4,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue) else { throw Failure.contextFailed }
        context.setBlendMode(.normal)
        context.draw(source.image,in:bounds)
        for layer in artifact.layers.sorted(by: { $0.zIndex<$1.zIndex }) where layer.opacity>0 {
            try Task.checkCancellation()
            context.saveGState();context.setAlpha(layer.opacity);context.draw(layer.image,in:layer.frame);context.restoreGState()
        }
        guard let output=context.makeImage() else { throw Failure.contextFailed }
        try Task.checkCancellation()
        return output
    }
}
