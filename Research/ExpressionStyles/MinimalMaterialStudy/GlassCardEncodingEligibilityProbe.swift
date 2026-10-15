import Foundation
import CoreGraphics
import ImageIO
import Testing
@testable import MemoMark

@Suite(.serialized) struct GlassCardEncodingEligibilityProbe {
    nonisolated static func image(width: Int = 64, height: Int = 48) throws -> CGImage {
        let context = try #require(CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        for y in stride(from:0,to:height,by:16) {
            context.setFillColor(CGColor(red:CGFloat(y%251)/250,green:0.4,blue:0.6,alpha:1))
            context.fill(CGRect(x:0,y:y,width:width,height:16))
        }
        return try #require(context.makeImage())
    }
    @Test func nativeMetadataControls() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        let image = try Self.image()
        let description = "相伴 Café 👨‍👩‍👧"
        let base: [CFString:Any] = [
            kCGImagePropertyExifDictionary:[kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",
                kCGImagePropertyExifOffsetTimeOriginal:"+08:00",kCGImagePropertyExifExposureTime:0.01,
                kCGImagePropertyExifFNumber:2.8,kCGImagePropertyExifLensModel:"Synthetic lens",
                kCGImagePropertyExifUserComment:"Original capture comment"],
            kCGImagePropertyGPSDictionary:[kCGImagePropertyGPSLatitude:22.5,kCGImagePropertyGPSLatitudeRef:"N",
                kCGImagePropertyGPSLongitude:113.9,kCGImagePropertyGPSLongitudeRef:"E",kCGImagePropertyGPSAltitude:12.5],
            kCGImagePropertyTIFFDictionary:[kCGImagePropertyTIFFMake:"Synthetic camera",kCGImagePropertyTIFFModel:"Fixture",kCGImagePropertyTIFFArtist:"Synthetic author"],
            kCGImagePropertyIPTCDictionary:[kCGImagePropertyIPTCKeywords:["fixture","memory"]],
            kCGImagePropertyMakerAppleDictionary:["17":"inherited-pair"],
            "QuickTime" as CFString:["Identifier":"inherited-pair"]]
        var rows: [[String:Any]] = []
        for format in [GlassCardSDRResearchVerifiedEncoder.Format.png,.heic] {
            let snapshot = try GlassCardSDRResearchMetadataSnapshot(base)
            let result = try await GlassCardSDRResearchVerifiedEncoder.encode(.init(image:image,metadata:snapshot,format:format,description:description),scratchRoot:root)
            let source = try #require(CGImageSourceCreateWithData(result.data as CFData,nil))
            let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
            let exif = try #require(properties[kCGImagePropertyExifDictionary] as? [CFString:Any])
            let gps = try #require(properties[kCGImagePropertyGPSDictionary] as? [CFString:Any])
            #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String == "2001:02:03 04:05:06")
            #expect(gps[kCGImagePropertyGPSLatitude] as? Double == 22.5)
            #expect(gps[kCGImagePropertyGPSLongitude] as? Double == 113.9)
            #expect(properties["QuickTime" as CFString] == nil)
            let maker = properties[kCGImagePropertyMakerAppleDictionary] as? [String:Any]
            #expect(maker?["17"] == nil)
            // Compare native control using the same reserved projection, not an assumed schema.
            var control = base
            var controlExif = base[kCGImagePropertyExifDictionary] as! [CFString:Any]
            controlExif[kCGImagePropertyExifColorSpace] = 1
            controlExif[kCGImagePropertyExifUserComment] = String(repeating:"\u{FFFD}",count:description.utf16.count)
            control[kCGImagePropertyExifDictionary] = controlExif
            var tiff = base[kCGImagePropertyTIFFDictionary] as! [CFString:Any]
            tiff[kCGImagePropertyTIFFImageDescription] = description; control[kCGImagePropertyTIFFDictionary] = tiff
            control[kCGImagePropertyIPTCDictionary] = [kCGImagePropertyIPTCKeywords:["fixture","memory"],kCGImagePropertyIPTCCaptionAbstract:description]
            if format == .png { control[kCGImagePropertyPNGDictionary] = [kCGImagePropertyPNGDescription:description] }
            let url = root.appendingPathComponent("control."+format.rawValue)
            _ = try MetadataPreservingImageWriter().write(cgImage:image,to:url,sourceProperties:control,exportDescription:"",captureDate:nil)
            let nativeSource = try #require(CGImageSourceCreateWithURL(url as CFURL,nil))
            let native = try #require(CGImageSourceCopyPropertiesAtIndex(nativeSource,0,nil) as? [CFString:Any])
            for key in [kCGImagePropertyGPSDictionary,kCGImagePropertyTIFFDictionary,kCGImagePropertyIPTCDictionary,kCGImagePropertyPNGDictionary] {
                #expect(NSDictionary(dictionary:properties[key] as? [CFString:Any] ?? [:]).isEqual(to:native[key] as? [CFString:Any] ?? [:]))
            }
            var nativeExif = try #require(native[kCGImagePropertyExifDictionary] as? [CFString:Any])
            var repairedExif = exif
            nativeExif.removeValue(forKey:kCGImagePropertyExifUserComment); repairedExif.removeValue(forKey:kCGImagePropertyExifUserComment)
            #expect(NSDictionary(dictionary:repairedExif).isEqual(to:nativeExif))
            try FileManager.default.removeItem(at:url)
            #expect(try FileManager.default.contentsOfDirectory(atPath:root.path).isEmpty)
            rows.append(["format":format.rawValue,"exif":exif as NSDictionary,"gps":gps as NSDictionary,
                "tiff":properties[kCGImagePropertyTIFFDictionary] ?? [:],"iptc":properties[kCGImagePropertyIPTCDictionary] ?? [:]])
            // Retained private data must be observed rather than presumed absent.
            var privateSource = base
            privateSource[kCGImagePropertyMakerAppleDictionary] = ["1":1,"17":"inherited-pair"]
            let privateSnapshot = try GlassCardSDRResearchMetadataSnapshot(privateSource)
            do {
                let output = try await GlassCardSDRResearchVerifiedEncoder.encode(.init(image:image,metadata:privateSnapshot,format:format,description:description),scratchRoot:root)
                let item = try #require(CGImageSourceCreateWithData(output.data as CFData,nil))
                let read = try #require(CGImageSourceCopyPropertiesAtIndex(item,0,nil) as? [CFString:Any])
                rows.append(["format":format.rawValue,"privateOutcome":"accepted","makerReadback":read[kCGImagePropertyMakerAppleDictionary] ?? [:]])
            } catch GlassCardContainerResearchFailure.unsupported {
                rows.append(["format":format.rawValue,"privateOutcome":"rejected unsupported"])
            }
            #expect(try FileManager.default.contentsOfDirectory(atPath:root.path).isEmpty)
        }
        Attachment.record(try PropertyListSerialization.data(fromPropertyList:rows,format:.xml,options:0),named:"metadata-eligibility.plist")
    }
    @Test func privateMetadataRejectedBeforeScratchCreation() async throws {
        let image = try Self.image()
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let metadata = try GlassCardSDRResearchMetadataSnapshot([kCGImagePropertyMakerAppleDictionary:["1":1,"17":"old-pair"]])
        await #expect(throws:GlassCardContainerResearchFailure.unsupported) {
            _ = try await GlassCardSDRResearchVerifiedEncoder.encode(.init(image:image,metadata:metadata,format:.png,description:"相伴365天"),scratchRoot:root)
        }
        #expect(!FileManager.default.fileExists(atPath:root.path))
    }

}
