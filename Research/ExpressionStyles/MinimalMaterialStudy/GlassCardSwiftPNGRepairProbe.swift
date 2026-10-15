import Foundation
import CoreGraphics
import ImageIO
import Testing

@Suite struct GlassCardSwiftPNGRepairProbe {
    @Test func matchesControlledPythonOutputs() throws {
        let root=URL(fileURLWithPath:"/tmp/GlassCardContainerRepairTrial")
        let manifest=try #require(JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("repaired/repair-manifest.json"))) as? [[String:Any]])
        var count=0
        for row in manifest {
            let name=try #require(row["file"] as? String)
            guard name.hasSuffix(".png") else { continue }
            let text=try #require(row["input"] as? String)
            let before=try Data(contentsOf:root.appendingPathComponent("originals/"+name))
            if row["status"] as? String=="rejected" {
                #expect(throws:GlassCardPNGResearchRepair.Failure.insufficientCapacity) { try GlassCardPNGResearchRepair.repair(before,description:text) }
                continue
            }
            let result=try GlassCardPNGResearchRepair.repair(before,description:text)
            let reference=try Data(contentsOf:root.appendingPathComponent("repaired/"+name))
            #expect(result.data==reference)
            #expect(result.data.count==before.count)
            #expect(zip(before,result.data).enumerated().allSatisfy { i,pair in pair.0==pair.1 || result.allowedRanges.contains(where: { $0.contains(i) }) })
            let source=try #require(CGImageSourceCreateWithData(result.data as CFData,nil))
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
    @Test(arguments:[false,true]) func supportsBothByteOrders(_ little:Bool) throws {
        let result=try GlassCardPNGResearchRepair.repair(synthetic(little:little),description:"相伴365天")
        #expect(result.data.count==synthetic(little:little).count)
        #expect(Array(result.data[result.allowedRanges[1]]) == (little ? [20,0,0,0] : [0,0,0,20]))
        let expected = Array("UNICODE\0".utf8) + [0x76,0xF8,0x4F,0x34,0x00,0x33,0x00,0x36,0x00,0x35,0x59,0x29]
        #expect(Array(result.data[result.allowedRanges[0]].prefix(expected.count)) == expected)
    }
    @Test func rejectsOverlappingStorage() throws {
        #expect(throws:GlassCardPNGResearchRepair.Failure.overlappingFields) {
            try GlassCardPNGResearchRepair.repair(synthetic(commentOffset:26),description:"text")
        }
    }
    @Test func rejectsAliasedFields() throws {
        #expect(throws:GlassCardPNGResearchRepair.Failure.overlappingFields) {
            try GlassCardPNGResearchRepair.repair(synthetic(extraTag:0x9003),description:"text")
        }
    }
    @Test func rejectsPrivateOffsetConventions() throws {
        #expect(throws:GlassCardPNGResearchRepair.Failure.unsupported) {
            try GlassCardPNGResearchRepair.repair(synthetic(extraTag:0x927C),description:"text")
        }
    }
    @Test func rejectsCyclicIFD() throws {
        #expect(throws:GlassCardPNGResearchRepair.Failure.cyclicIFD) {
            try GlassCardPNGResearchRepair.repair(synthetic(next:26),description:"text")
        }
    }
    @Test func rejectsOutOfBoundsAndChecksum() throws {
        #expect(throws:GlassCardPNGResearchRepair.Failure.malformed) {
            try GlassCardPNGResearchRepair.repair(synthetic(commentOffset:1000),description:"text")
        }
        var broken=synthetic();broken[20]^=1
        #expect(throws:GlassCardPNGResearchRepair.Failure.checksum) {
            try GlassCardPNGResearchRepair.repair(broken,description:"text")
        }
    }
    private func synthetic(little:Bool=false,commentOffset:Int=44,next:Int=0,extraTag:Int?=nil) -> Data {
        func word(_ value:Int,_ size:Int,_ little:Bool=false)->[UInt8] {
            let big=(0..<size).map { UInt8(truncatingIfNeeded:value >> ((size-1-$0)*8)) };return little ? big.reversed() : big
        }
        func tag(_ id:Int,_ type:Int,_ count:Int,_ value:Int)->[UInt8] { word(id,2,little)+word(type,2,little)+word(count,4,little)+word(value,4,little) }
        var tiff:[UInt8]=little ? [73,73] : [77,77]
        tiff+=word(42,2,little)+word(8,4,little)+word(1,2,little)+tag(0x8769,4,1,26)+word(0,4,little)
        let storage=extraTag == nil ? commentOffset : 56
        tiff+=word(extraTag == nil ? 1 : 2,2,little)+tag(0x9286,7,40,storage)
        if let extraTag { tiff+=tag(extraTag,2,12,storage) }
        tiff+=word(next,4,little)
        tiff+=Array("UNICODE\0".utf8)+[UInt8](repeating:0,count:32)
        func chunk(_ type:String,_ payload:[UInt8])->[UInt8] {
            let content=Array(type.utf8)+payload
            var crc:UInt32=0xffffffff
            for b in content { crc ^= UInt32(b);for _ in 0..<8 { crc = crc&1==1 ? (crc>>1)^0xedb88320 : crc>>1 } }
            return word(payload.count,4)+content+word(Int(crc^0xffffffff),4)
        }
        return Data([137,80,78,71,13,10,26,10]+chunk("IHDR",word(64,4)+word(48,4)+[8,2,0,0,0])+chunk("eXIf",tiff)+chunk("IDAT",[])+chunk("IEND",[]))
    }
}
