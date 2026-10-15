import Foundation
import CoreGraphics
import ImageIO
import Testing
@testable import MemoMark

@Suite(.serialized) struct GlassCardHEICGridProbe {
    @Test @concurrent nonisolated func nativeGridOutputsRetainPixelsAndMetadata() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        for (width,height) in [(1024,768),(2048,1536),(4096,3072)] {
            let image = try GlassCardEncodingEligibilityProbe.image(width:width,height:height)
            let text = "相伴365天 Café 👨‍👩‍👧"
            let url = root.appendingPathComponent("reserved.heic")
            _ = try MetadataPreservingImageWriter().write(cgImage:image,to:url,sourceProperties:[
                kCGImagePropertyExifDictionary:[kCGImagePropertyExifUserComment:String(repeating:"\u{FFFD}",count:text.utf16.count),
                    kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifExposureTime:0.01]],exportDescription:"",captureDate:nil)
            let original = try Data(contentsOf:url)
            let result = try GlassCardHEICResearchRepair.repair(original,description:text)
            #expect(result.data.count == original.count)
            #expect(zip(original,result.data).enumerated().allSatisfy { index,values in
                values.0 == values.1 || result.allowedRanges.contains(where: { $0.contains(index) }) })
            let source = try #require(CGImageSourceCreateWithData(result.data as CFData,nil))
            let oldSource = try #require(CGImageSourceCreateWithData(original as CFData,nil))
            let decoded = try #require(CGImageSourceCreateImageAtIndex(source,0,nil))
            let oldDecoded = try #require(CGImageSourceCreateImageAtIndex(oldSource,0,nil))
            let pixels = try #require(decoded.dataProvider?.data as Data?)
            let oldPixels = try #require(oldDecoded.dataProvider?.data as Data?)
            #expect(pixels == oldPixels)
            let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
            let exif = try #require(properties[kCGImagePropertyExifDictionary] as? [CFString:Any])
            let comment = try #require(exif[kCGImagePropertyExifUserComment] as? String)
            #expect(Array(comment.unicodeScalars) == Array(text.unicodeScalars))
            #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String == "2001:02:03 04:05:06")
            #expect(exif[kCGImagePropertyExifExposureTime] as? Double == 0.01)
        }
    }
    @Test func localExtentBoundsAndAliases() throws {
        let original = try Data(contentsOf:URL(fileURLWithPath:"/tmp/GlassCardContainerRepairTrial/originals/fixture-2-reserved.heic"))
        let location = try GlassCardHEICResearchRepair.locate(original)
        let tiff = Data(original[location.tiff])
        _ = try GlassCardHEICResearchRepair.locate(synthetic(tiff:tiff))
        for input in [synthetic(tiff:tiff,method:2),synthetic(tiff:tiff,method:17),synthetic(tiff:tiff,kind:"mime"),synthetic(tiff:tiff,reference:1),synthetic(tiff:tiff,protected:true)] {
            #expect(throws:GlassCardContainerResearchFailure.unsupported) { _ = try GlassCardHEICResearchRepair.locate(input) }
        }
        for input in [synthetic(tiff:tiff,offset:8),synthetic(tiff:tiff,base:1),synthetic(tiff:tiff,idatCount:0),synthetic(tiff:tiff,idatCount:2)] {
            #expect(throws:GlassCardContainerResearchFailure.malformed) { _ = try GlassCardHEICResearchRepair.locate(input) }
        }
        #expect(throws:GlassCardContainerResearchFailure.overlappingFields) {
            _ = try GlassCardHEICResearchRepair.locate(synthetic(tiff:tiff,alias:true))
        }
    }
    private func synthetic(tiff:Data,method:Int=1,kind:String="grid",reference:Int=0,protected:Bool=false,
                           offset:Int=0,base:Int=0,idatCount:Int=1,alias:Bool=false)->Data {
        func word(_ value:Int,_ size:Int)->[UInt8] { (0..<size).map { UInt8(truncatingIfNeeded:value >> ((size-1-$0)*8)) } }
        func box(_ kind:String,_ payload:[UInt8])->[UInt8] { word(payload.count+8,4)+Array(kind.utf8)+payload }
        func info(_ id:Int,_ kind:String,_ protection:Int=0)->[UInt8] { box("infe",[2,0,0,0]+word(id,2)+word(protection,2)+Array(kind.utf8)+[0]) }
        let ftyp = box("ftyp",Array("heic".utf8)+[0,0,0,0])
        let infos = info(1,"Exif")+info(2,kind,protected ? 1 : 0)+(alias ? info(3,"grid") : [])
        let iinf = box("iinf",[0,0,0,0]+word(alias ? 3 : 2,2)+infos)
        func meta(_ fileOffset:Int)->[UInt8] {
            func entry(_ id:Int,_ method:Int,_ ref:Int,_ base:Int,_ offset:Int,_ length:Int)->[UInt8] {
                word(id,2)+word(method,2)+word(ref,2)+word(base,4)+word(1,2)+word(offset,4)+word(length,4)
            }
            var entries = entry(1,0,0,0,fileOffset,tiff.count+4)+entry(2,method,reference,base,offset,8)
            if alias { entries += entry(3,1,0,0,0,8) }
            let iloc = box("iloc",[1,0,0,0,0x44,0x40]+word(alias ? 3 : 2,2)+entries)
            let idat = (0..<idatCount).flatMap { _ in box("idat",[UInt8](repeating:0,count:8)) }
            return box("meta",[0,0,0,0]+iinf+iloc+idat)
        }
        let fileOffset = ftyp.count+meta(0).count+8
        return Data(ftyp+meta(fileOffset)+box("mdat",[0,0,0,0]+Array(tiff)))
    }
}
