import Foundation
import CoreGraphics
import ImageIO
import Testing

@Suite struct GlassCardSwiftHEICRepairProbe {
    @Test func matchesControlledOutputs() throws {
        let root=URL(fileURLWithPath:"/tmp/GlassCardContainerRepairTrial")
        let manifest=try #require(JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("repaired/repair-manifest.json"))) as? [[String:Any]])
        var count=0
        for row in manifest {
            let name=try #require(row["file"] as? String)
            guard name.hasSuffix(".heic") else { continue }
            let text=try #require(row["input"] as? String)
            let before=try Data(contentsOf:root.appendingPathComponent("originals/"+name))
            if row["status"] as? String=="rejected" {
                #expect(throws:GlassCardHEICResearchRepair.Failure.insufficientCapacity) { try GlassCardHEICResearchRepair.repair(before,description:text) }
                continue
            }
            let result=try GlassCardHEICResearchRepair.repair(before,description:text)
            let reference=try Data(contentsOf:root.appendingPathComponent("repaired/"+name))
            #expect(result.data == reference)
            #expect(result.data.count==before.count)
            #expect(zip(before,result.data).enumerated().allSatisfy { i,pair in pair.0==pair.1 || result.allowedRanges.contains(where: { $0.contains(i) }) })
            let source=try #require(CGImageSourceCreateWithData(result.data as CFData,nil))
            let originalSource=try #require(CGImageSourceCreateWithData(before as CFData,nil))
            let image=try #require(CGImageSourceCreateImageAtIndex(source,0,nil))
            let original=try #require(CGImageSourceCreateImageAtIndex(originalSource,0,nil))
            let pixels=try #require(image.dataProvider?.data as Data?)
            let oldPixels=try #require(original.dataProvider?.data as Data?)
            #expect(pixels==oldPixels)
            let properties=try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
            let exif=try #require(properties[kCGImagePropertyExifDictionary] as? [CFString:Any])
            let comment=try #require(exif[kCGImagePropertyExifUserComment] as? String)
            #expect(comment.unicodeScalars.map(\.value)==text.unicodeScalars.map(\.value))
            #expect(exif[kCGImagePropertyExifExposureTime] as? Double==0.01)
            #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String=="2001:02:03 04:05:06")
            count+=1
        }
        #expect(count==11)
    }
    @Test func rejectsUnsupportedReferencesAndAliasedExtent() throws {
        let source=try Data(contentsOf:URL(fileURLWithPath:"/tmp/GlassCardContainerRepairTrial/originals/fixture-2-reserved.heic"))
        let location=try GlassCardHEICResearchRepair.locate(source)
        let tiff=Data(source[location.tiff])
        _ = try GlassCardHEICResearchRepair.locate(synthetic(tiff:tiff))
        for data in [synthetic(tiff:tiff,method:1),synthetic(tiff:tiff,reference:1),synthetic(tiff:tiff,extentCount:2)] {
            #expect(throws:GlassCardHEICResearchRepair.Failure.unsupported) { try GlassCardHEICResearchRepair.locate(data) }
        }
        #expect(throws:GlassCardHEICResearchRepair.Failure.overlappingFields) {
            try GlassCardHEICResearchRepair.locate(synthetic(tiff:tiff,alias:true))
        }
        #expect(throws:GlassCardHEICResearchRepair.Failure.malformed) {
            try GlassCardHEICResearchRepair.locate(synthetic(tiff:tiff,offsetOverride:1_000_000))
        }
        var oversized=synthetic(tiff:tiff)
        oversized.replaceSubrange(0..<4,with:[0,0,0,1])
        oversized.replaceSubrange(8..<16,with:[UInt8](repeating:255,count:8))
        #expect(throws:GlassCardHEICResearchRepair.Failure.malformed) { try GlassCardHEICResearchRepair.locate(oversized) }
    }
    private func synthetic(tiff:Data,method:Int=0,reference:Int=0,extentCount:Int=1,alias:Bool=false,offsetOverride:Int?=nil)->Data {
        func word(_ value:Int,_ size:Int)->[UInt8] { (0..<size).map { UInt8(truncatingIfNeeded:value >> ((size-1-$0)*8)) } }
        func box(_ type:String,_ data:[UInt8])->[UInt8] { word(data.count+8,4)+Array(type.utf8)+data }
        func info(_ id:Int,_ type:String)->[UInt8] { box("infe",[2,0,0,0]+word(id,2)+[0,0]+Array(type.utf8)+[0]) }
        let ftyp=box("ftyp",Array("heic".utf8)+[0,0,0,0])
        let iinf=box("iinf",[0,0,0,0]+word(alias ? 2 : 1,2)+info(1,"Exif")+(alias ? info(2,"hvc1") : []))
        func meta(_ offset:Int)->[UInt8] {
            var entries=word(1,2)+word(method,2)+word(reference,2)+word(extentCount,2)
            for _ in 0..<extentCount { entries+=word(offsetOverride ?? offset,4)+word(tiff.count+4,4) }
            if alias { entries+=word(2,2)+[0,0,0,0]+word(1,2)+word(offset,4)+word(tiff.count+4,4) }
            let iloc=box("iloc",[1,0,0,0,0x44,0]+word(alias ? 2 : 1,2)+entries)
            return box("meta",[0,0,0,0]+iinf+iloc)
        }
        let offset=ftyp.count+meta(0).count+8
        return Data(ftyp+meta(offset)+box("mdat",[0,0,0,0]+Array(tiff)))
    }
    @Test func rejectsTruncatedAndBadTIFFStart() throws {
        let url=URL(fileURLWithPath:"/tmp/GlassCardContainerRepairTrial/originals/fixture-2-reserved.heic")
        let source=try Data(contentsOf:url)
        for length in [0,7,source.count-1] {
            #expect(throws:GlassCardHEICResearchRepair.Failure.malformed) { try GlassCardHEICResearchRepair.locate(Data(source.prefix(length))) }
        }
        let location=try GlassCardHEICResearchRepair.locate(source)
        var broken=source
        // Fixture has six-byte Exif signature after its four-byte TIFF-offset field.
        let offsetField=location.tiff.lowerBound-10
        broken.replaceSubrange(offsetField..<offsetField+4,with:[255,255,255,255])
        #expect(throws:GlassCardHEICResearchRepair.Failure.malformed) { try GlassCardHEICResearchRepair.locate(broken) }
    }
}
