import Foundation
import CoreGraphics
import ImageIO
import Testing
@testable import MemoMark

@Suite struct GlassCardVerifiedEncodingProbe {
    @Test func verifiedOutputsAndScratchOwnership() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        let context = try #require(CGContext(data:nil,width:64,height:48,bitsPerComponent:8,bytesPerRow:256,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red:0.2,green:0.4,blue:0.6,alpha:1))
        context.fill(CGRect(x:0,y:0,width:64,height:48))
        let image = try #require(context.makeImage())
        let metadata = try GlassCardSDRResearchMetadataSnapshot([
            kCGImagePropertyExifDictionary:[kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifExposureTime:0.01]])
        for format in [GlassCardSDRResearchVerifiedEncoder.Format.png,.heic] {
            for description in ["Cafe\u{301} 365","Café 365","相伴365天","回忆👨‍👩‍👧","Memory 365",String(repeating:"相伴",count:20)] {
                let result = try await GlassCardSDRResearchVerifiedEncoder.encode(.init(image:image,metadata:metadata,format:format,description:description),scratchRoot:root)
                #expect(result.ranOffMainThread)
                let source = try #require(CGImageSourceCreateWithData(result.data as CFData,nil))
                let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
                let exif = try #require(properties[kCGImagePropertyExifDictionary] as? [CFString:Any])
                #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String == "2001:02:03 04:05:06")
                #expect(exif[kCGImagePropertyExifExposureTime] as? Double == 0.01)
                #expect(try FileManager.default.contentsOfDirectory(atPath:root.path).isEmpty)
            }
            let control = GlassCardSDRResearchVerifiedEncoder.Request(image:image,metadata:metadata,format:format,description:"Cafe\u{301} 365",capacity:.inheritedControl)
            await #expect(throws:GlassCardContainerResearchFailure.insufficientCapacity) {
                _ = try await GlassCardSDRResearchVerifiedEncoder.encode(control,scratchRoot:root)
            }
            #expect(try FileManager.default.contentsOfDirectory(atPath:root.path).isEmpty)
        }
        let request = GlassCardSDRResearchVerifiedEncoder.Request(image:image,metadata:metadata,format:.png,description:"回忆")
        let task = Task { @MainActor in try await GlassCardSDRResearchVerifiedEncoder.encode(request,scratchRoot:root) }
        task.cancel()
        await #expect(throws:CancellationError.self) { _ = try await task.value }
        #expect(try FileManager.default.contentsOfDirectory(atPath:root.path).isEmpty)
    }
    @Test func rejectsOversizedCanvasBeforeEncoding() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:false)
        defer { try? FileManager.default.removeItem(at:root) }
        let context = try #require(CGContext(data:nil,width:4097,height:1,bitsPerComponent:8,bytesPerRow:4097*4,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        let image = try #require(context.makeImage())
        let metadata = try GlassCardSDRResearchMetadataSnapshot([:])
        await #expect(throws:GlassCardSDRResearchVerifiedEncoder.Failure.unsupportedInput) {
            _ = try await GlassCardSDRResearchVerifiedEncoder.encode(.init(image:image,metadata:metadata,format:.png,description:"Memory"),scratchRoot:root)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath:root.path).isEmpty)
    }

}
