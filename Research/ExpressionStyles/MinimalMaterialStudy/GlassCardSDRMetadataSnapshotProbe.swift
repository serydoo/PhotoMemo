import Foundation
import ImageIO
import Testing

@Suite struct GlassCardSDRMetadataSnapshotProbe {
    @Test func preservesMetadataAndFreezesMutableInput() async throws {
        let exif=NSMutableDictionary(dictionary:["DateTimeOriginal":"2001:02:03 04:05:06","ExposureTime":0.01])
        let bytes=NSMutableData(data:Data([1,2,3]))
        let date=Date(timeIntervalSince1970:123456)
        let source:[CFString:Any]=[kCGImagePropertyExifDictionary:exif,
            kCGImagePropertyGPSDictionary:["Latitude":22.5,"Longitude":113.9],
            "Captured" as CFString:date,"Payload" as CFString:bytes,
            "Values" as CFString:[true,42,"时光记"]]
        let snapshot=try GlassCardSDRResearchMetadataSnapshot(source)
        exif["DateTimeOriginal"]="changed"
        bytes.append(Data([4]))
        let result=try await consume(snapshot)
        #expect(result.offMain)
        #expect(result.date==date)
        #expect(result.payload==Data([1,2,3]))
        #expect(result.capture=="2001:02:03 04:05:06")
        let decoded=try snapshot.properties()
        let gps=try #require(decoded[kCGImagePropertyGPSDictionary] as? [String:Any])
        #expect(gps["Latitude"] as? Double==22.5)
        #expect(gps["Longitude"] as? Double==113.9)
        let values=try #require(decoded["Values" as CFString] as? [Any])
        #expect(values[0] as? Bool==true)
        #expect(values[1] as? Int==42)
        #expect(values[2] as? String=="时光记")
    }
    @Test func rejectsUnsupportedNestedValues() throws {
        #expect(throws:GlassCardSDRResearchMetadataSnapshot.Failure.unsupportedProperties) {
            _ = try GlassCardSDRResearchMetadataSnapshot([kCGImagePropertyExifDictionary:["Unsupported":URL(fileURLWithPath:"/tmp/fixture")]])
        }
    }
    @Test func emptyPropertiesRoundTrip() throws {
        #expect(try GlassCardSDRResearchMetadataSnapshot([:]).properties().isEmpty)
    }
    nonisolated struct Consumed:Sendable {
        let offMain:Bool
        let date:Date?
        let payload:Data?
        let capture:String?
    }
    @concurrent private func consume(_ snapshot:GlassCardSDRResearchMetadataSnapshot) async throws -> Consumed {
        let properties=try snapshot.properties()
        let exif=properties[kCGImagePropertyExifDictionary] as? [String:Any]
        return Consumed(offMain:!Thread.isMainThread,date:properties["Captured" as CFString] as? Date,
            payload:properties["Payload" as CFString] as? Data,capture:exif?["DateTimeOriginal"] as? String)
    }
}
