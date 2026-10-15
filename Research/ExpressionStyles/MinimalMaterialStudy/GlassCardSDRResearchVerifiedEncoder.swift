import Foundation
import CoreGraphics
import ImageIO
@testable import MemoMark

/// Research orchestration only. Owns scratch files; publishes verified bytes, never a scratch URL.
nonisolated enum GlassCardSDRResearchVerifiedEncoder {
    enum Format: String, Sendable { case png, heic }
    enum Capacity: Sendable { case reserved, inheritedControl }
    enum Failure: Error { case unsupportedInput, oversizedOutput, readbackMismatch }
    struct Request: Sendable {
        let image: CGImage
        let metadata: GlassCardSDRResearchMetadataSnapshot
        let format: Format
        let description: String
        var capacity: Capacity = .reserved
    }
    struct Result: Sendable {
        let data: Data
        let ranOffMainThread: Bool
    }
    private static func offMain() -> Bool { !Thread.isMainThread }

    @concurrent static func encode(_ request: Request, scratchRoot: URL) async throws -> Result {
        try Task.checkCancellation()
        guard request.image.colorSpace?.name == CGColorSpace.sRGB,
              request.image.bitsPerComponent == 8, request.image.bitsPerPixel == 32,
              request.image.width <= 4096, request.image.height <= 4096,
              !request.description.isEmpty, request.description.utf16.count <= 4096 else {
            throw Failure.unsupportedInput
        }
        let ranOffMainThread = offMain()
        var properties = try request.metadata.properties()
        if let maker = properties[kCGImagePropertyMakerAppleDictionary],
           !(maker is [AnyHashable:Any]) {
            throw GlassCardContainerResearchFailure.unsupported
        }
        ImageIOStillImageMetadataCleanup.removeInheritedLivePhotoMetadata(from:&properties)
        // Retained private MakerApple data emits MakerNote, outside this parser's contract.
        guard properties[kCGImagePropertyMakerAppleDictionary] == nil else {
            throw GlassCardContainerResearchFailure.unsupported
        }
        try Task.checkCancellation()
        let directory = scratchRoot.appendingPathComponent(UUID().uuidString, isDirectory:true)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:false)
        // Only this invocation's unique child is ever removed.
        var ownsDirectory = true
        defer { if ownsDirectory { try? FileManager.default.removeItem(at:directory) } }
        do {
            properties.removeValue(forKey:kCGImagePropertyProfileName)
            var exif = properties[kCGImagePropertyExifDictionary] as? [CFString:Any] ?? [:]
            exif[kCGImagePropertyExifColorSpace] = 1
            if request.capacity == .reserved {
                exif[kCGImagePropertyExifUserComment] = String(repeating:"\u{FFFD}",count:request.description.utf16.count)
            }
            properties[kCGImagePropertyExifDictionary] = exif
            var tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString:Any] ?? [:]
            tiff[kCGImagePropertyTIFFImageDescription] = request.description
            properties[kCGImagePropertyTIFFDictionary] = tiff
            var iptc = properties[kCGImagePropertyIPTCDictionary] as? [CFString:Any] ?? [:]
            iptc[kCGImagePropertyIPTCCaptionAbstract] = request.description
            properties[kCGImagePropertyIPTCDictionary] = iptc
            if request.format == .png {
                var png = properties[kCGImagePropertyPNGDictionary] as? [CFString:Any] ?? [:]
                png[kCGImagePropertyPNGDescription] = request.description
                properties[kCGImagePropertyPNGDictionary] = png
            }
            try Task.checkCancellation()
            let url = directory.appendingPathComponent("encoded."+request.format.rawValue)
            _ = try MetadataPreservingImageWriter().write(cgImage:request.image,to:url,
                sourceProperties:properties,
                exportDescription:request.capacity == .reserved ? "" : request.description,captureDate:nil)
            try Task.checkCancellation()
            let size = try FileManager.default.attributesOfItem(atPath:url.path)[.size] as? NSNumber
            guard let size, size.intValue <= 16*1024*1024 else { throw Failure.oversizedOutput }
            let encoded = try Data(contentsOf:url)
            let repaired: Data
            switch request.format {
            case .png: repaired = try GlassCardPNGResearchRepair.repair(encoded,description:request.description).data
            case .heic: repaired = try GlassCardHEICResearchRepair.repair(encoded,description:request.description).data
            }
            try Task.checkCancellation()
            guard let source = CGImageSourceCreateWithData(repaired as CFData,nil),
                  let decoded = CGImageSourceCreateImageAtIndex(source,0,nil),
                  decoded.width == request.image.width, decoded.height == request.image.height,
                  decoded.colorSpace?.name == CGColorSpace.sRGB,
                  let readback = CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any],
                  let readExif = readback[kCGImagePropertyExifDictionary] as? [CFString:Any],
                  let comment = readExif[kCGImagePropertyExifUserComment] as? String,
                  Array(comment.unicodeScalars) == Array(request.description.unicodeScalars) else {
                throw Failure.readbackMismatch
            }
            try Task.checkCancellation()
            try FileManager.default.removeItem(at:directory)
            ownsDirectory = false
            try Task.checkCancellation()
            return Result(data:repaired,ranOffMainThread:ranOffMainThread)
        } catch {
            if ownsDirectory {
                try FileManager.default.removeItem(at:directory)
                ownsDirectory = false
            }
            throw error
        }
    }
}
