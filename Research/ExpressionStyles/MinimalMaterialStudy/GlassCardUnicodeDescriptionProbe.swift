import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite struct GlassCardUnicodeDescriptionProbe {
    @Test func readbackMatrix() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:directory) }
        let context=try #require(CGContext(data:nil,width:64,height:48,bitsPerComponent:8,bytesPerRow:256,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray:0.5,alpha:1));context.fill(CGRect(x:0,y:0,width:64,height:48))
        let image=try #require(context.makeImage())
        let samples=["Memory 365", "相伴时光", "相伴365天", "回忆📷365天", "Café 365", String(repeating:"相伴365天",count:20)]
        var rows:[[String:Any]]=[]
        for (index,text) in samples.enumerated() {
            for ext in ["png","jpg","heic"] {
                for route in ["writer","direct-string","direct-data"] {
                    let url=directory.appendingPathComponent("\(index)-\(route).\(ext)")
                    let type=try #require(UTType(filenameExtension:ext))
                    var exif:[CFString:Any]=[kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifUserComment:text]
                    if route=="direct-data" {
                        var value=Data("UNICODE\0".utf8)
                        value.append(try #require(text.data(using:.utf16BigEndian)))
                        exif[kCGImagePropertyExifUserComment]=value
                    }
                    let properties:[CFString:Any]=[kCGImagePropertyExifDictionary:exif,
                        kCGImagePropertyTIFFDictionary:[kCGImagePropertyTIFFImageDescription:text],
                        kCGImagePropertyIPTCDictionary:[kCGImagePropertyIPTCCaptionAbstract:text],
                        kCGImagePropertyPNGDictionary:[kCGImagePropertyPNGDescription:text]]
                    if route=="writer" {
                        _ = try MetadataPreservingImageWriter().write(cgImage:image,to:url,sourceProperties:[:],exportDescription:text,captureDate:nil)
                    } else {
                        let destination=try #require(CGImageDestinationCreateWithURL(url as CFURL,type.identifier as CFString,1,nil))
                        CGImageDestinationAddImage(destination,image,properties as CFDictionary)
                        #expect(CGImageDestinationFinalize(destination))
                    }
                    let source=try #require(CGImageSourceCreateWithURL(url as CFURL,nil))
                    let output=try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
                    func field(_ group:CFString,_ key:CFString)->String? {
                        (output[group] as? [CFString:Any])?[key] as? String
                    }
                    let comment=field(kCGImagePropertyExifDictionary,kCGImagePropertyExifUserComment)
                    if route=="writer",ext=="jpg" { #expect(comment?.unicodeScalars.map(\.value)==text.unicodeScalars.map(\.value)) }
                    rows.append(["sample":index,"input":text,"format":ext,"route":route,
                        "comment":comment as Any? ?? NSNull(),"commentMatches":comment==text,
                        "tiff":field(kCGImagePropertyTIFFDictionary,kCGImagePropertyTIFFImageDescription) as Any? ?? NSNull(),
                        "iptc":field(kCGImagePropertyIPTCDictionary,kCGImagePropertyIPTCCaptionAbstract) as Any? ?? NSNull(),
                        "png":field(kCGImagePropertyPNGDictionary,kCGImagePropertyPNGDescription) as Any? ?? NSNull()])
                }
            }
        }
        #expect(rows.count==54)
        Attachment.record(try JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys]),named:"unicode-description-matrix.json")
    }
}
