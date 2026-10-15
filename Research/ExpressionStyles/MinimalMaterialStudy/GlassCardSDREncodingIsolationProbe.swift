import Foundation
import CoreGraphics
import ImageIO
import Testing
@testable import MemoMark

@Suite struct GlassCardSDREncodingIsolationProbe {
    @Test func actualWriterRunsOffMainAndRetainsMetadata() async throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:directory) }
        let context=try #require(CGContext(data:nil,width:64,height:48,bitsPerComponent:8,bytesPerRow:256,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red:0.2,green:0.4,blue:0.6,alpha:1))
        context.fill(CGRect(x:0,y:0,width:64,height:48))
        let image=try #require(context.makeImage())
        let metadata=try GlassCardSDRResearchMetadataSnapshot([
            kCGImagePropertyExifDictionary:[kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifExposureTime:0.01],
            kCGImagePropertyGPSDictionary:[kCGImagePropertyGPSLatitude:22.5,kCGImagePropertyGPSLatitudeRef:"N",kCGImagePropertyGPSLongitude:113.9,kCGImagePropertyGPSLongitudeRef:"E"],
            kCGImagePropertyMakerAppleDictionary:["17":"inherited-pair"],"QuickTime" as CFString:["Identifier":"inherited"]])
        let date=Date(timeIntervalSince1970:123456)
        for ext in ["png","jpg","heic"] {
            let url=directory.appendingPathComponent("output."+ext)
            let result=try await GlassCardSDRResearchEncodingWorker.write(.init(image:image,metadata:metadata,destination:url,description:"相伴365天",captureDate:date))
            #expect(result.ranOffMainThread)
            let source=try #require(CGImageSourceCreateWithURL(result.url as CFURL,nil))
            let properties=try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
            #expect(properties[kCGImagePropertyPixelWidth] as? Int==64)
            #expect(properties[kCGImagePropertyPixelHeight] as? Int==48)
            #expect(properties[kCGImagePropertyOrientation] as? Int==1)
            let decoded=try #require(CGImageSourceCreateImageAtIndex(source,0,nil))
            #expect(decoded.colorSpace?.name==CGColorSpace.sRGB)
            let exif=try #require(properties[kCGImagePropertyExifDictionary] as? [CFString:Any])
            #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String=="2001:02:03 04:05:06")
            #expect(exif[kCGImagePropertyExifExposureTime] as? Double==0.01)
            let controlURL=directory.appendingPathComponent("control."+ext)
            _ = try MetadataPreservingImageWriter().write(cgImage:image,to:controlURL,sourceProperties:metadata.properties(),exportDescription:"相伴365天",captureDate:date)
            let controlSource=try #require(CGImageSourceCreateWithURL(controlURL as CFURL,nil))
            let controlProperties=try #require(CGImageSourceCopyPropertiesAtIndex(controlSource,0,nil) as? [CFString:Any])
            let controlExif=try #require(controlProperties[kCGImagePropertyExifDictionary] as? [CFString:Any])
            #expect(exif[kCGImagePropertyExifUserComment] as? String==controlExif[kCGImagePropertyExifUserComment] as? String)
            Attachment.record(Data("format=\(ext)\nasyncComment=\(String(describing:exif[kCGImagePropertyExifUserComment]))\nsyncComment=\(String(describing:controlExif[kCGImagePropertyExifUserComment]))\n".utf8),named:"writer-isolation-\(ext).txt")
            let gps=try #require(properties[kCGImagePropertyGPSDictionary] as? [CFString:Any])
            #expect(gps[kCGImagePropertyGPSLatitude] as? Double==22.5)
            #expect(gps[kCGImagePropertyGPSLongitude] as? Double==113.9)
            #expect(properties["QuickTime" as CFString]==nil)
            let maker=properties[kCGImagePropertyMakerAppleDictionary] as? [String:Any]
            #expect(maker?["17"]==nil)
            let attributes=try FileManager.default.attributesOfItem(atPath:url.path)
            let modified=try #require(attributes[.modificationDate] as? Date)
            #expect(abs(modified.timeIntervalSince(date))<1)
        }
        let cancelledURL=directory.appendingPathComponent("cancelled.png")
        let request=GlassCardSDRResearchEncodingWorker.Request(image:image,metadata:metadata,destination:cancelledURL,description:"",captureDate:nil)
        let task=Task<Void,Error> { @MainActor in _ = try await GlassCardSDRResearchEncodingWorker.write(request) }
        task.cancel()
        await #expect(throws:CancellationError.self) { try await task.value }
        #expect(!FileManager.default.fileExists(atPath:cancelledURL.path))
    }
}
