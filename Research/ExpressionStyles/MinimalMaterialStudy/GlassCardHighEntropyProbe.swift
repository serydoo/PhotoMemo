import Foundation
import CoreGraphics
import ImageIO
import Darwin
import Testing
@testable import MemoMark

@Suite(.serialized) struct GlassCardHighEntropyProbe {
    nonisolated private static func image(width:Int,height:Int) throws -> CGImage {
        var bytes = Data(count:width*height*4)
        bytes.withUnsafeMutableBytes { raw in
            let pixels = raw.bindMemory(to:UInt8.self)
            var seed: UInt32 = 0x13579BDF
            for index in stride(from:0,to:pixels.count,by:4) {
                seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
                pixels[index] = UInt8(truncatingIfNeeded:seed)
                pixels[index+1] = UInt8(truncatingIfNeeded:seed >> 8)
                pixels[index+2] = UInt8(truncatingIfNeeded:seed >> 16)
                pixels[index+3] = 255
            }
        }
        let provider = try #require(CGDataProvider(data:bytes as CFData))
        return try #require(CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:width*4,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),
            provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
    }
    nonisolated private static func highWater() throws -> Int {
        var usage = rusage()
        guard getrusage(RUSAGE_SELF,&usage) == 0 else { throw CocoaError(.fileReadUnknown) }
        return Int(usage.ru_maxrss)
    }
    @Test func deterministicNoiseEncodingAndSizeRejection() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        let metadata = try GlassCardSDRResearchMetadataSnapshot([
            kCGImagePropertyExifDictionary:[kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifExposureTime:0.01]])
        var rows: [[String:Any]] = []
        let clock = ContinuousClock()
        for (width,height) in [(1024,768),(2048,1536),(4096,3072)] {
            let image = try Self.image(width:width,height:height)
            for format in [GlassCardSDRResearchVerifiedEncoder.Format.png,.heic] {
                let before = try Self.highWater()
                let start = clock.now
                var status = "verified", count = 0
                do {
                    let result = try await GlassCardSDRResearchVerifiedEncoder.encode(.init(image:image,metadata:metadata,format:format,description:"相伴365天 Café 👨‍👩‍👧"),scratchRoot:root)
                    #expect(result.ranOffMainThread)
                    count = result.data.count
                    #expect(count > 0 && count <= 16*1024*1024)
                    #expect(!(width == 4096 && format == .png))
                } catch GlassCardSDRResearchVerifiedEncoder.Failure.oversizedOutput {
                    #expect(width == 4096 && format == .png)
                    status = "rejected encoded size"
                }
                let elapsed = start.duration(to:clock.now).components
                let after = try Self.highWater()
                #expect(try FileManager.default.contentsOfDirectory(atPath:root.path).isEmpty)
                var row: [String:Any] = ["width":width,"height":height,"format":format.rawValue,"status":status,
                    "callSeconds":Double(elapsed.seconds)+Double(elapsed.attoseconds)/1e18,"returnedBytes":count,
                    "inputRasterBytes":width*height*4,"processLifetimeHighWaterBeforeCallBytes":before,
                    "processLifetimeHighWaterAfterCallBytes":after]
                if status != "verified" {
                    let url = root.appendingPathComponent("size-control.png")
                    // File-size control only; description encoding does not affect the large raster verdict.
                    _ = try MetadataPreservingImageWriter().write(cgImage:image,to:url,sourceProperties:metadata.properties(),exportDescription:"相伴365天",captureDate:nil)
                    let length = try #require(FileManager.default.attributesOfItem(atPath:url.path)[.size] as? NSNumber)
                    #expect(length.intValue > 16*1024*1024)
                    row["nativeControlBytes"] = length.intValue
                    try FileManager.default.removeItem(at:url)
                }
                rows.append(row)
            }
        }
        Attachment.record(try JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys]),named:"high-entropy-observations.json")
    }
}
