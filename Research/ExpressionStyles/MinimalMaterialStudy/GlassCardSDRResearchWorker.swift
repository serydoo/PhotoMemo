import Foundation
import CoreGraphics
@testable import MemoMark

nonisolated enum GlassCardSDRResearchWorker {
    struct PixelRequest: Sendable {
        let source: GlassCardSDRResearchAdmission.Accepted
        let panel: CGRect
        let cornerRadius: CGFloat
        let blurRadius: CGFloat
        let luminanceCap: Double
    }
    struct PreparedResult: Sendable {
        let prepared: GlassCardSDRResearchPreparation.Prepared
        let ranOffMainThread: Bool
    }
    struct PixelResult: Sendable {
        let source: GlassCardSDRResearchAdmission.Accepted
        let bareHaloBytes: Int
        let ranOffMainThread: Bool
    }
    struct CompositionResult: Sendable {
        let image: CGImage
        let ranOffMainThread: Bool
    }
    @concurrent
    static func compose(_ source:GlassCardSDRResearchAdmission.Accepted,snapshot:GlassCardSDRResearchCompositor.Snapshot) async throws -> CompositionResult {
        try Task.checkCancellation()
        let offMain = !Thread.isMainThread
        let image=try GlassCardSDRResearchCompositor.compose(source,snapshot:snapshot)
        try Task.checkCancellation()
        return CompositionResult(image:image,ranOffMainThread:offMain)
    }
    enum Failure: Error { case invalidRequest, boundaryChanged }
    @concurrent
    static func prepare(_ data:Data,canvas:CGSize,mapping:GlassCardSDRResearchPreparation.Mapping) async throws -> PreparedResult {
        try Task.checkCancellation()
        let offMain = !Thread.isMainThread
        let prepared=try GlassCardSDRResearchPreparation.prepareControlledFixture(data,canvas:canvas,mapping:mapping)
        try Task.checkCancellation()
        return PreparedResult(prepared:prepared,ranOffMainThread:offMain)
    }
    @concurrent
    static func process(_ request:PixelRequest) async throws -> PixelResult {
        try Task.checkCancellation()
        let offMain = !Thread.isMainThread
        let p=request.panel
        guard p.minX.isFinite,p.minY.isFinite,p.width.isFinite,p.height.isFinite,p.width>0,p.height>0,
              CGRect(origin:.zero,size:request.source.canvas).contains(p),request.cornerRadius.isFinite,
              request.cornerRadius>=0,request.cornerRadius<=min(p.width,p.height)/2,
              request.blurRadius.isFinite,request.blurRadius>=0,request.blurRadius<=p.height*0.1,
              request.luminanceCap.isFinite,request.luminanceCap>0,request.luminanceCap<=1 else { throw Failure.invalidRequest }
        let material=GlassCardSDRResearchMaterial()
        let blurred=try material.blurredSource(request.source.image,panel:p,radius:request.blurRadius,cornerRadius:request.cornerRadius)
        try Task.checkCancellation()
        guard blurred.outsideDifference==0,blurred.haloDifference<=1 else { throw Failure.boundaryChanged }
        let photo=try material.compressed(blurred.image,panel:p,cap:request.luminanceCap,cornerRadius:request.cornerRadius)
        try Task.checkCancellation()
        let admitted=try GlassCardSDRResearchAdmission.admit(photo,orientation:.up,canvas:request.source.canvas)
        try Task.checkCancellation()
        return PixelResult(source:admitted,bareHaloBytes:blurred.haloBytes,ranOffMainThread:offMain)
    }
}
