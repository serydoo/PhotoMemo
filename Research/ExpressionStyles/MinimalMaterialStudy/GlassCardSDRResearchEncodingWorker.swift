import Foundation
import CoreGraphics
@testable import MemoMark

nonisolated enum GlassCardSDRResearchEncodingWorker {
    struct Request: Sendable {
        let image: CGImage
        let metadata: GlassCardSDRResearchMetadataSnapshot
        let destination: URL
        let description: String
        let captureDate: Date?
    }
    struct Result: Sendable {
        let url: URL
        let ranOffMainThread: Bool
    }
    private static func isOffMainThread() -> Bool { !Thread.isMainThread }
    @concurrent static func write(_ request: Request) async throws -> Result {
        try Task.checkCancellation()
        let offMain = isOffMainThread()
        let properties=try request.metadata.properties()
        try Task.checkCancellation()
        let url=try MetadataPreservingImageWriter().write(cgImage:request.image,to:request.destination,
            sourceProperties:properties,exportDescription:request.description,captureDate:request.captureDate)
        // The caller owns the file even if cancellation arrives after the synchronous write.
        try Task.checkCancellation()
        return Result(url:url,ranOffMainThread:offMain)
    }
}
