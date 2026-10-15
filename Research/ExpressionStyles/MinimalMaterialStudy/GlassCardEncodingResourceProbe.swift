import Foundation
import CoreGraphics
import ImageIO
import Darwin
import Testing
@testable import MemoMark

@Suite(.serialized) struct GlassCardEncodingResourceProbe {
    private static func highWaterBytes() throws -> Int {
        var usage = rusage()
        guard getrusage(RUSAGE_SELF,&usage) == 0 else { throw CocoaError(.fileReadUnknown) }
        // macOS getrusage(2): ru_maxrss is process-lifetime maximum resident bytes.
        return Int(usage.ru_maxrss)
    }
    @Test func serialSyntheticEncodingObservations() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        let metadata = try GlassCardSDRResearchMetadataSnapshot([
            kCGImagePropertyExifDictionary:[kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifExposureTime:0.01]])
        let clock = ContinuousClock()
        var rows: [[String:Any]] = []
        for (width,height) in [(64,48),(1024,768),(2048,1536),(4096,3072)] {
            let beforeImage = try Self.highWaterBytes()
            let image = try GlassCardEncodingEligibilityProbe.image(width:width,height:height)
            for format in [GlassCardSDRResearchVerifiedEncoder.Format.png,.heic] {
                let beforeCall = try Self.highWaterBytes()
                let start = clock.now
                let status: String
                let byteCount: Int
                do {
                    let output = try await GlassCardSDRResearchVerifiedEncoder.encode(.init(image:image,metadata:metadata,format:format,description:"相伴365天 Café 👨‍👩‍👧"),scratchRoot:root)
                    #expect(output.ranOffMainThread)
                    #expect(!output.data.isEmpty)
                    status = "verified"
                    byteCount = output.data.count
                } catch GlassCardContainerResearchFailure.unsupported {
                    // An observation, not a performance pass for unsupported output.
                    #expect(format == .heic)
                    status = "rejected unsupported container"
                    byteCount = 0
                }
                #expect(status == "verified")
                let duration = start.duration(to:clock.now).components
                let seconds = Double(duration.seconds)+Double(duration.attoseconds)/1e18
                let afterCall = try Self.highWaterBytes()
                #expect(try FileManager.default.contentsOfDirectory(atPath:root.path).isEmpty)
                rows.append(["width":width,"height":height,"format":format.rawValue,"status":status,
                    "encodingRepairReadbackCleanupSeconds":seconds,"encodedBytes":byteCount,
                    "inputRasterBytes":width*height*4,"processLifetimeHighWaterBeforeImageBytes":beforeImage,
                    "processLifetimeHighWaterBeforeCallBytes":beforeCall,"processLifetimeHighWaterAfterCallBytes":afterCall])
                if status != "verified" {
                    let url = root.appendingPathComponent("diagnostic.heic")
                    _ = try MetadataPreservingImageWriter().write(cgImage:image,to:url,sourceProperties:metadata.properties(),exportDescription:"相伴365天 Café 👨‍👩‍👧",captureDate:nil)
                    let bytes = try Data(contentsOf:url)
                    #expect(throws:GlassCardContainerResearchFailure.unsupported) { _ = try GlassCardHEICResearchRepair.locate(bytes) }
                    Attachment.record(bytes,named:"unsupported-\(width)x\(height).heic")
                    try FileManager.default.removeItem(at:url)
                }

            }
        }
        Attachment.record(try JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys]),named:"encoding-resource-observations.json")
    }
}
