import Foundation
import CoreGraphics
import ImageIO
import Testing
@testable import MemoMark

@Suite struct GlassCardContainerFixtureProbe {
    @Test func exportControlledFixtures() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:directory) }
        let context=try #require(CGContext(data:nil,width:64,height:48,bitsPerComponent:8,bytesPerRow:256,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray:0.5,alpha:1));context.fill(CGRect(x:0,y:0,width:64,height:48))
        let image=try #require(context.makeImage())
        let samples=["Memory 365","相伴时光","相伴365天","回忆📷365天","Cafe\u{301} 365",String(repeating:"相伴365天",count:20)]
        var rows:[[String:Any]]=[]
        for (index,text) in samples.enumerated() {
            for ext in ["png","heic"] {
              for reserved in [false,true] {
                let url=directory.appendingPathComponent("fixture-\(index)\(reserved ? "-reserved" : "").\(ext)")
                var exif:[CFString:Any]=[kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifExposureTime:0.01]
                if reserved { exif[kCGImagePropertyExifUserComment]=String(repeating:"\u{FFFD}",count:text.utf16.count) }
                let properties:[CFString:Any]=[kCGImagePropertyExifDictionary:exif,
                    kCGImagePropertyTIFFDictionary:[kCGImagePropertyTIFFImageDescription:text],
                    kCGImagePropertyIPTCDictionary:[kCGImagePropertyIPTCCaptionAbstract:text],
                    kCGImagePropertyPNGDictionary:[kCGImagePropertyPNGDescription:text]]
                _ = try MetadataPreservingImageWriter().write(cgImage:image,to:url,
                    sourceProperties:properties,exportDescription:reserved ? "" : text,captureDate:nil)
                let source=try #require(CGImageSourceCreateWithURL(url as CFURL,nil))
                let readProperties=try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
                let readExif=readProperties[kCGImagePropertyExifDictionary] as? [CFString:Any]
                Attachment.record(try Data(contentsOf:url),named:"fixture-\(index)\(reserved ? "-reserved" : "").\(ext)")
                rows.append(["file":"fixture-\(index)\(reserved ? "-reserved" : "").\(ext)","input":text,"reserved":reserved,"readback":readExif?[kCGImagePropertyExifUserComment] as Any? ?? NSNull()])
              }
            }
        }
        Attachment.record(try JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys]),named:"fixture-manifest.json")
    }
}
