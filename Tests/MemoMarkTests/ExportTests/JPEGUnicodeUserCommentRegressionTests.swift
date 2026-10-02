import Foundation
import CoreGraphics
import ImageIO
import Testing
@testable import MemoMark

@MainActor
@Suite struct JPEGUnicodeUserCommentRegressionTests {
    @Test(arguments: ["Cafe\u{301} 365", "Café 365", "相伴365天", "回忆📷365天", "Memory 365", String(repeating:"相伴365天",count:20)])
    func preservesDescriptionMetadataAndPixels(_ text: String) throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:directory) }
        let context=try #require(CGContext(data:nil,width:64,height:48,bitsPerComponent:8,bytesPerRow:256,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red:0.2,green:0.4,blue:0.6,alpha:1));context.fill(CGRect(x:0,y:0,width:64,height:48))
        let image=try #require(context.makeImage())
        let metadata:[CFString:Any]=[
            kCGImagePropertyExifDictionary:[kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifExposureTime:0.01],
            kCGImagePropertyGPSDictionary:[kCGImagePropertyGPSLatitude:22.5,kCGImagePropertyGPSLatitudeRef:"N",kCGImagePropertyGPSLongitude:113.9,kCGImagePropertyGPSLongitudeRef:"E"]]
        func writeAndRead(_ description:String,_ name:String) throws -> (CGImage,[CFString:Any]) {
            let url=directory.appendingPathComponent(name+".jpg")
            _ = try MetadataPreservingImageWriter().write(cgImage:image,to:url,sourceProperties:metadata,exportDescription:description,captureDate:nil)
            let source=try #require(CGImageSourceCreateWithURL(url as CFURL,nil))
            return (try #require(CGImageSourceCreateImageAtIndex(source,0,nil)),try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any]))
        }
        let (decoded,properties)=try writeAndRead(text,"unicode")
        let (control,_)=try writeAndRead("Memory 365","control")
        let actualPixels=try #require(decoded.dataProvider?.data as Data?)
        let controlPixels=try #require(control.dataProvider?.data as Data?)
        #expect(actualPixels==controlPixels)
        let exif=try #require(properties[kCGImagePropertyExifDictionary] as? [CFString:Any])
        let comment=try #require(exif[kCGImagePropertyExifUserComment] as? String)
        #expect(comment.unicodeScalars.map(\.value)==text.unicodeScalars.map(\.value))
        #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String=="2001:02:03 04:05:06")
        #expect(exif[kCGImagePropertyExifExposureTime] as? Double==0.01)
        let gps=try #require(properties[kCGImagePropertyGPSDictionary] as? [CFString:Any])
        #expect(gps[kCGImagePropertyGPSLatitude] as? Double==22.5)
        #expect(gps[kCGImagePropertyGPSLongitude] as? Double==113.9)
    }
}
