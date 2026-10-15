import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite struct GlassCardNativeMetadataProbe {
    @Test func nativeRoutes() throws {
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
            for ext in ["png","jpg","heic"] {
                for route in ["matched-property","explicit-string","explicit-alternative"] {
                    let metadata=CGImageMetadataCreateMutable()
                    #expect(CGImageMetadataSetValueMatchingImageProperty(metadata,kCGImagePropertyExifDictionary,kCGImagePropertyExifDateTimeOriginal,"2001:02:03 04:05:06" as CFString))
                    #expect(CGImageMetadataSetValueMatchingImageProperty(metadata,kCGImagePropertyExifDictionary,kCGImagePropertyExifExposureTime,"1/100" as CFString))
                    let gpsSet=CGImageMetadataSetValueMatchingImageProperty(metadata,kCGImagePropertyGPSDictionary,kCGImagePropertyGPSLatitude,"22,30N" as CFString)
                    let commentSet:Bool
                    if route=="matched-property" {
                        commentSet=CGImageMetadataSetValueMatchingImageProperty(metadata,kCGImagePropertyExifDictionary,kCGImagePropertyExifUserComment,text as CFString)
                    } else {
                        let tag=try #require(CGImageMetadataTagCreate("http://ns.adobe.com/exif/1.0/" as CFString,"exif" as CFString,"UserComment" as CFString,
                            route=="explicit-string" ? .string : .alternateText,text as CFString))
                        commentSet=CGImageMetadataSetTagWithPath(metadata,nil,"exif:UserComment" as CFString,tag)
                    }
                    let url=directory.appendingPathComponent("\(index)-\(route).\(ext)")
                    let type=try #require(UTType(filenameExtension:ext))
                    let destination=try #require(CGImageDestinationCreateWithURL(url as CFURL,type.identifier as CFString,1,nil))
                    CGImageDestinationAddImageAndMetadata(destination,image,metadata,nil)
                    #expect(CGImageDestinationFinalize(destination))
                    let source=try #require(CGImageSourceCreateWithURL(url as CFURL,nil))
                    let properties=try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
                    let exif=properties[kCGImagePropertyExifDictionary] as? [CFString:Any]
                    let embedded=CGImageSourceCopyMetadataAtIndex(source,0,nil)
                    let metadataComment=embedded.flatMap { CGImageMetadataCopyStringValueWithPath($0,nil,"exif:UserComment" as CFString) as String? }
                    rows.append(["sample":index,"input":text,"format":ext,"route":route,"commentSet":commentSet,
                        "propertyComment":exif?[kCGImagePropertyExifUserComment] as Any? ?? NSNull(),
                        "metadataComment":metadataComment as Any? ?? NSNull(),
                        "capture":exif?[kCGImagePropertyExifDateTimeOriginal] as Any? ?? NSNull(),
                        "exposure":exif?[kCGImagePropertyExifExposureTime] as Any? ?? NSNull(),
                        "gpsSet":gpsSet,"latitude":(properties[kCGImagePropertyGPSDictionary] as? [CFString:Any])?[kCGImagePropertyGPSLatitude] as Any? ?? NSNull()])
                }
            }
        }
        #expect(rows.count==54)
        Attachment.record(try JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys]),named:"native-metadata-matrix.json")
    }
}
