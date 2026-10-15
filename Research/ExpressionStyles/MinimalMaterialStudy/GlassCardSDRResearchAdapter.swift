import Foundation
import CoreGraphics
import ImageIO
import SwiftUI
@testable import MemoMark

/// Research-only assembly; all geometry comes from the supplied resolved plan.
enum GlassCardSDRResearchAdapter {
    nonisolated struct Parameters: Sendable {
        let blurFraction: CGFloat
        let luminanceCap: Double
        let secondaryOpacity: Double
        static let candidate = Self(blurFraction:0.025,luminanceCap:0.12,secondaryOpacity:0.96)
    }
    enum Failure: Error, Equatable { case invalidParameters, mismatchedPlan, overflowingContent, renderingFailed, boundaryChanged, colorMismatch }
    struct Output {
        let image: CGImage
        let artifact: PresentationArtifact
        let processedSource: CGImage
        let sourceReport: GlassCardSDRResearchPreparation.Report
        let parameters: Parameters
        let bareHaloBytes: Int
    }
    @MainActor
    private static func pixelRequest(_ prepared:GlassCardSDRResearchPreparation.Prepared,plan:GlassCardResolvedPresentation,
                                     parameters:Parameters) throws -> GlassCardSDRResearchWorker.PixelRequest {
        guard parameters.blurFraction.isFinite,parameters.blurFraction>=0,parameters.blurFraction<=0.1,
              parameters.luminanceCap.isFinite,parameters.luminanceCap>0,parameters.luminanceCap<=1,
              parameters.secondaryOpacity.isFinite,parameters.secondaryOpacity>=0,parameters.secondaryOpacity<=1 else { throw Failure.invalidParameters }
        let panel=plan.geometry.panelFrame
        guard plan.canvasSize==prepared.source.canvas,CGRect(origin:.zero,size:prepared.source.canvas).contains(panel),panel.width>0,panel.height>0 else { throw Failure.mismatchedPlan }
        guard !plan.isContentOverflowing else { throw Failure.overflowingContent }
        return .init(source:prepared.source,panel:panel,cornerRadius:panel.height*GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight,
                     blurRadius:panel.height*parameters.blurFraction,luminanceCap:parameters.luminanceCap)
    }
    @MainActor
    static func render(_ prepared:GlassCardSDRResearchPreparation.Prepared,plan:GlassCardResolvedPresentation,
                       badge:Badge?=nil,parameters:Parameters = .candidate) throws -> Output {
        let request=try pixelRequest(prepared,plan:plan,parameters:parameters)
        let material=GlassCardSDRResearchMaterial()
        let blurred=try material.blurredSource(prepared.source.image,panel:request.panel,radius:request.blurRadius,cornerRadius:request.cornerRadius)
        guard blurred.outsideDifference==0,blurred.haloDifference<=1 else { throw Failure.boundaryChanged }
        let photo=try material.compressed(blurred.image,panel:request.panel,cap:request.luminanceCap,cornerRadius:request.cornerRadius)
        let admitted=try GlassCardSDRResearchAdmission.admit(photo,orientation:.up,canvas:prepared.source.canvas)
        return try draw(prepared,plan:plan,badge:badge,parameters:parameters,processed:admitted,haloBytes:blurred.haloBytes)
    }
    @MainActor
    static func renderAsync(_ prepared:GlassCardSDRResearchPreparation.Prepared,plan:GlassCardResolvedPresentation,
                            badge:Badge?=nil,parameters:Parameters = .candidate) async throws -> Output {
        try Task.checkCancellation()
        let request=try pixelRequest(prepared,plan:plan,parameters:parameters)
        let processed=try await GlassCardSDRResearchWorker.process(request)
        try Task.checkCancellation()
        let artifact=try drawArtifact(prepared,plan:plan,badge:badge,parameters:parameters)
        let composed=try await GlassCardSDRResearchWorker.compose(processed.source,snapshot:.init(artifact))
        try Task.checkCancellation()
        return Output(image:composed.image,artifact:artifact,processedSource:processed.source.image,sourceReport:prepared.report,parameters:parameters,bareHaloBytes:processed.bareHaloBytes)
    }
    @MainActor
    private static func draw(_ prepared:GlassCardSDRResearchPreparation.Prepared,plan:GlassCardResolvedPresentation,
                             badge:Badge?,parameters:Parameters,processed:GlassCardSDRResearchAdmission.Accepted,haloBytes:Int) throws -> Output {
        let artifact=try drawArtifact(prepared,plan:plan,badge:badge,parameters:parameters)
        let image=try GlassCardSDRResearchCompositor.compose(processed,artifact:artifact)
        try Task.checkCancellation()
        return Output(image:image,artifact:artifact,processedSource:processed.image,sourceReport:prepared.report,parameters:parameters,bareHaloBytes:haloBytes)
    }
    @MainActor
    private static func drawArtifact(_ prepared:GlassCardSDRResearchPreparation.Prepared,plan:GlassCardResolvedPresentation,
                                     badge:Badge?,parameters:Parameters) throws -> PresentationArtifact {
        try Task.checkCancellation()
        let base=GlassCardProductionRenderer.recipe
        let recipe=GlassCardMaterialRecipe(researchID:"shared-sdr-candidate",surface:.init(red:0,green:0,blue:0,alpha:0),
            keyline:base.keyline,shadow:base.shadow,keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,
            shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
        let frame=plan.overlayFrame
        let renderer=ImageRenderer(content:GlassCardOverlayLayer(presentation:plan,badge:badge,recipe:recipe,secondaryTextOpacity:parameters.secondaryOpacity)
            .offset(y:-frame.minY).frame(width:frame.width,height:frame.height,alignment:.topLeading).clipped())
        renderer.scale=1;renderer.proposedSize = .init(frame.size)
        guard let overlay=renderer.cgImage else { throw Failure.renderingFailed }
        try Task.checkCancellation()
        let artifact=try PresentationArtifact(canvasSize:prepared.source.canvas,photoFrame:CGRect(origin:.zero,size:prepared.source.canvas),
            layers:[.init(frame:plan.artifactOverlayFrame,image:overlay,zIndex:100)],canvasBackground:.transparent)
        return artifact
    }
    static func outputProperties(for image:CGImage,source:[CFString:Any]) throws -> [CFString:Any] {
        guard image.colorSpace?.name==CGColorSpace.sRGB else { throw Failure.colorMismatch }
        var properties=source
        properties.removeValue(forKey:kCGImagePropertyProfileName)
        var exif=properties[kCGImagePropertyExifDictionary] as? [CFString:Any] ?? [:]
        exif[kCGImagePropertyExifColorSpace]=1
        properties[kCGImagePropertyExifDictionary]=exif
        return properties
    }
}
