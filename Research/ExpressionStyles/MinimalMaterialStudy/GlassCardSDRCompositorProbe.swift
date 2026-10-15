import CoreGraphics
import Foundation
import Testing
@testable import MemoMark

@Suite("GlassCard explicit sRGB research compositor controls")
struct GlassCardSDRCompositorProbe {
    private func image(_ pixel:[UInt8]) throws -> CGImage {
        let bytes=Array(repeating:pixel,count:4).flatMap { $0 }
        return try #require(CGImage(width:2,height:2,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:8,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue),
            provider:CGDataProvider(data:Data(bytes) as CFData)!,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
    }
    private func pixel(_ image:CGImage) throws -> [UInt8] {
        var bytes=[UInt8](repeating:0,count:16)
        try bytes.withUnsafeMutableBytes { pointer in
            let c=try #require(CGContext(data:pointer.baseAddress,width:2,height:2,bitsPerComponent:8,bytesPerRow:8,
                space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue))
            c.draw(image,in:CGRect(x:0,y:0,width:2,height:2))
        }
        return Array(bytes.prefix(4))
    }
    @Test("Alpha, layer opacity, ordering and skipped layers have explicit pixel semantics")
    func blending() throws {
        let bounds=CGRect(x:0,y:0,width:2,height:2)
        let source=try GlassCardSDRResearchAdmission.admit(image([0,0,255,255]),orientation:.up,canvas:bounds.size)
        let red=try image([255,0,0,255]),green=try image([0,255,0,255]),transparentRed=try image([128,0,0,128])
        func composed(_ layers:[PresentationArtifact.Layer],background:PresentationArtifact.CanvasBackground = .transparent) throws -> [UInt8] {
            let a=try PresentationArtifact(canvasSize:bounds.size,photoFrame:bounds,layers:layers,canvasBackground:background)
            let output=try GlassCardSDRResearchCompositor.compose(source,artifact:a)
            #expect(output.colorSpace?.name==CGColorSpace.sRGB)
            return try pixel(output)
        }
        let opacity=try composed([.init(frame:bounds,image:red,opacity:0.5)])
        #expect(abs(Int(opacity[0])-128)<=1 && opacity[1]==0 && abs(Int(opacity[2])-127)<=1 && opacity[3]==255)
        let alpha=try composed([.init(frame:bounds,image:transparentRed)])
        #expect(zip(opacity,alpha).allSatisfy { abs(Int($0)-Int($1))<=1 })
        let sorted=try composed([.init(frame:bounds,image:red,zIndex:10),.init(frame:bounds,image:green,zIndex:0)])
        #expect(sorted==[255,0,0,255])
        #expect(try composed([.init(frame:bounds,image:red,opacity:0)])==[0,0,255,255])
        #expect(try composed([.init(frame:bounds,image:red,opacity:0)],background:.opaqueWhite)==[0,0,255,255])
    }
    @Test("Reject unexpected source mapping and invalid secondary layer")
    func geometry() throws {
        let bounds=CGRect(x:0,y:0,width:2,height:2),red=try image([255,0,0,255])
        let source=try GlassCardSDRResearchAdmission.admit(red,orientation:.up,canvas:bounds.size)
        let mapped=try PresentationArtifact(canvasSize:bounds.size,photoFrame:CGRect(x:0,y:0,width:1,height:2),layers:[.init(frame:bounds,image:red)],canvasBackground:.transparent)
        #expect(throws:GlassCardSDRResearchCompositor.Failure.mappingMismatch) { try GlassCardSDRResearchCompositor.compose(source,artifact:mapped) }
        let invalid=try PresentationArtifact(canvasSize:bounds.size,photoFrame:bounds,layers:[.init(frame:bounds,image:red),.init(frame:CGRect(x:2,y:0,width:2,height:2),image:red)],canvasBackground:.transparent)
        #expect(throws:GlassCardSDRResearchCompositor.Failure.invalidLayer) { try GlassCardSDRResearchCompositor.compose(source,artifact:invalid) }
    }
}
