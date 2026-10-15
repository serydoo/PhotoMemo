// Research-only admission boundary. No production call sites or source conversion.
import CoreGraphics
import Foundation
import Testing
@testable import MemoMark

@Suite("GlassCard SDR research source admission")
struct GlassCardSDRSourceAdmissionProbe {
    private func image(color: CFString=CGColorSpace.sRGB, alpha: UInt8=255,
                       alphaInfo:CGImageAlphaInfo = .premultipliedLast) throws -> CGImage {
        let bytes:[UInt8]=[64,32,16,alpha,64,32,16,alpha,64,32,16,alpha,64,32,16,alpha]
        return try #require(CGImage(width:2,height:2,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:8,
            space:CGColorSpace(name:color)!,bitmapInfo:CGBitmapInfo(rawValue:alphaInfo.rawValue|CGBitmapInfo.byteOrder32Big.rawValue),
            provider:CGDataProvider(data:Data(bytes) as CFData)!,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
    }
    @Test("Accept explicit opaque SDR and preserve source identity")
    func accepted() throws {
        let source=try image()
        let accepted=try GlassCardSDRResearchAdmission.admit(source,orientation:.up,canvas:CGSize(width:2,height:2))
        #expect(accepted.image === source)
        #expect(accepted.canvas == CGSize(width:2,height:2))
    }
    @Test("Reject ambiguous color, pixel format, direction, geometry and actual transparency")
    func rejected() throws {
        let source=try image()
        func check(_ input:CGImage, _ expected:GlassCardSDRResearchAdmission.Rejection,
                   orientation:MediaGeometryOrientation = .up,canvas:CGSize=CGSize(width:2,height:2)) {
            #expect(throws:expected) { try GlassCardSDRResearchAdmission.admit(input,orientation:orientation,canvas:canvas) }
        }
        check(try image(color:CGColorSpace.displayP3),.colorSpaceNotSRGB)
        check(try image(alpha:128),.containsTransparency)
        check(try image(alphaInfo:.noneSkipLast),.unsupportedPixelFormat)
        for orientation:MediaGeometryOrientation in [.upMirrored,.down,.downMirrored,.leftMirrored,.right,.rightMirrored,.left] {
            check(source,.orientationNotNormalized,orientation:orientation)
        }
        check(source,.canvasMismatch,canvas:CGSize(width:3,height:2))
        check(source,.canvasMismatch,canvas:CGSize(width:CGFloat.infinity,height:2))
        let gray=try #require(CGImage(width:2,height:2,bitsPerComponent:8,bitsPerPixel:8,bytesPerRow:2,
            space:CGColorSpaceCreateDeviceGray(),bitmapInfo:[],provider:CGDataProvider(data:Data([UInt8](repeating:128,count:4)) as CFData)!,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
        check(gray,.colorSpaceNotSRGB)
        let floating=try #require(CGContext(data:nil,width:2,height:2,bitsPerComponent:32,bytesPerRow:32,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.floatComponents.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)?.makeImage())
        check(floating,.unsupportedPixelFormat)
    }
}
