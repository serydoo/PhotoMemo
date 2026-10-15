// Research-only shared source preparation. No production registration.
import CoreGraphics
import ImageIO
import Foundation
@testable import MemoMark

nonisolated enum GlassCardSDRResearchAdmission {
    enum Rejection: Error, Equatable {
        case orientationNotNormalized
        case canvasMismatch
        case colorSpaceNotSRGB
        case unsupportedPixelFormat
        case containsTransparency
        case pixelReadFailed
    }
    struct Accepted: Sendable {
        let image: CGImage
        let canvas: CGSize
        fileprivate init(image: CGImage, canvas: CGSize) { self.image=image;self.canvas=canvas }
    }
    static func admit(_ image: CGImage, orientation: MediaGeometryOrientation, canvas: CGSize) throws -> Accepted {
        guard orientation == .up else { throw Rejection.orientationNotNormalized }
        guard canvas.width.isFinite, canvas.height.isFinite,
              canvas.width == CGFloat(image.width), canvas.height == CGFloat(image.height) else { throw Rejection.canvasMismatch }
        guard image.colorSpace?.name == CGColorSpace.sRGB else { throw Rejection.colorSpaceNotSRGB }
        guard image.bitsPerComponent == 8, image.bitsPerPixel == 32,
              !image.bitmapInfo.contains(.floatComponents), image.alphaInfo == .premultipliedLast else { throw Rejection.unsupportedPixelFormat }
        // Read through a declared sRGB context to check actual alpha; no whitening or implicit opaque assumption.
        var bytes=[UInt8](repeating:0,count:image.width*image.height*4)
        let readSucceeded = bytes.withUnsafeMutableBytes { storage -> Bool in
            guard let context=CGContext(data:storage.baseAddress,width:image.width,height:image.height,bitsPerComponent:8,
                bytesPerRow:image.width*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,
                bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height));return true
        }
        guard readSucceeded else { throw Rejection.pixelReadFailed }
        guard stride(from:3,to:bytes.count,by:4).allSatisfy({ bytes[$0] == 255 }) else { throw Rejection.containsTransparency }
        return Accepted(image:image,canvas:canvas)
    }
}

nonisolated enum GlassCardSDRResearchPreparation {
    enum Mapping: Sendable { case exact, centeredAspectFill }
    enum Failure: Error, Equatable {
        case invalidSource, invalidOrientation, colorNotSRGB, decodeFailed, canvasInvalid, exactSizeMismatch
    }
    struct Report: Sendable {
        let orientationRaw: Int
        let encodedSize: CGSize
        let normalizedSize: CGSize
        let canvas: CGSize
        let drawRect: CGRect
        let provenance: String = "controlled SDR fixture; not production HDR classification"
    }
    struct Prepared: Sendable { let source: GlassCardSDRResearchAdmission.Accepted; let report: Report }
    // Deliberately research-only: Data must be from a known opaque SDR fixture.
    static func prepareControlledFixture(_ data: Data, canvas: CGSize, mapping: Mapping) throws -> Prepared {
        guard canvas.width.isFinite, canvas.height.isFinite, canvas.width>0, canvas.height>0,
              canvas.width.rounded()==canvas.width,canvas.height.rounded()==canvas.height,
              canvas.width<=4096,canvas.height<=4096 else { throw Failure.canvasInvalid }
        guard let source=CGImageSourceCreateWithData(data as CFData,nil),
              let properties=CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any],
              let width=properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height=properties[kCGImagePropertyPixelHeight] as? NSNumber else { throw Failure.invalidSource }
        guard let orientation=properties[kCGImagePropertyOrientation] as? NSNumber,
              (1...8).contains(orientation.intValue) else { throw Failure.invalidOrientation }
        guard let raw=CGImageSourceCreateImageAtIndex(source,0,nil) else { throw Failure.decodeFailed }
        guard raw.colorSpace?.name == CGColorSpace.sRGB else { throw Failure.colorNotSRGB }
        guard raw.bitsPerComponent == 8, !raw.bitmapInfo.contains(.floatComponents) else { throw GlassCardSDRResearchAdmission.Rejection.unsupportedPixelFormat }
        let options:[CFString:Any]=[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceCreateThumbnailWithTransform:true,
            kCGImageSourceThumbnailMaxPixelSize:max(width.intValue,height.intValue),kCGImageSourceShouldCacheImmediately:true]
        guard let oriented=CGImageSourceCreateThumbnailAtIndex(source,0,options as CFDictionary) else { throw Failure.decodeFailed }
        let normalizedSize=CGSize(width:oriented.width,height:oriented.height)
        // ImageIO can omit an alpha channel for opaque TIFFs. Explicitly standardize
        // storage without flattening transparency; admission inspects actual alpha next.
        guard let storage=CGContext(data:nil,width:oriented.width,height:oriented.height,bitsPerComponent:8,bytesPerRow:oriented.width*4,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue) else { throw Failure.decodeFailed }
        storage.draw(oriented,in:CGRect(origin:.zero,size:normalizedSize))
        guard let normalized=storage.makeImage() else { throw Failure.decodeFailed }
        // Check real opacity before preparing a canvas; avoids clearing transparency into black.
        _ = try GlassCardSDRResearchAdmission.admit(normalized,orientation:.up,canvas:normalizedSize)
        let drawRect:CGRect
        switch mapping {
        case .exact:
            guard normalizedSize==canvas else { throw Failure.exactSizeMismatch }
            drawRect=CGRect(origin:.zero,size:canvas)
        case .centeredAspectFill:
            let scale=max(canvas.width/normalizedSize.width,canvas.height/normalizedSize.height)
            let size=CGSize(width:normalizedSize.width*scale,height:normalizedSize.height*scale)
            drawRect=CGRect(x:(canvas.width-size.width)/2,y:(canvas.height-size.height)/2,width:size.width,height:size.height)
        }
        guard let context=CGContext(data:nil,width:Int(canvas.width),height:Int(canvas.height),bitsPerComponent:8,bytesPerRow:Int(canvas.width)*4,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue) else { throw Failure.decodeFailed }
        context.interpolationQuality = .high
        context.draw(normalized,in:drawRect)
        guard let image=context.makeImage() else { throw Failure.decodeFailed }
        let admitted=try GlassCardSDRResearchAdmission.admit(image,orientation:.up,canvas:canvas)
        return Prepared(source:admitted,report:Report(orientationRaw:orientation.intValue,
            encodedSize:CGSize(width:width.intValue,height:height.intValue),normalizedSize:normalizedSize,canvas:canvas,drawRect:drawRect))
    }
}
