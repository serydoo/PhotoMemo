import Foundation
import UniformTypeIdentifiers

nonisolated enum MediaProcessingRoute: String, Hashable, Codable {
    case stillImage
    case rawStillImage
    case livePhoto
    case unsupported
}

nonisolated struct MediaProcessingInputDescriptor: Hashable {

    let contentType: UTType?
    let fileURL: URL?
    let pixelWidth: Int?
    let pixelHeight: Int?
    let isLivePhotoAsset: Bool

    nonisolated init(
        contentType: UTType? = nil,
        fileURL: URL? = nil,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        isLivePhotoAsset: Bool = false
    ) {
        self.contentType = contentType
        self.fileURL = fileURL
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.isLivePhotoAsset = isLivePhotoAsset
    }

    var resolvedContentType: UTType? {
        contentType
            ?? fileURL.flatMap {
                UTType(
                    filenameExtension:
                        $0.pathExtension
                        .lowercased()
                )
            }
    }
}

nonisolated struct MediaProcessingDecision: Hashable {

    let route: MediaProcessingRoute
    let rejectionReason:
        PhotoProcessingInputPolicy
        .RejectionReason?

    static func route(
        _ route: MediaProcessingRoute
    ) -> MediaProcessingDecision {
        MediaProcessingDecision(
            route: route,
            rejectionReason: nil
        )
    }

    static func unsupported(
        _ reason:
            PhotoProcessingInputPolicy
            .RejectionReason
    ) -> MediaProcessingDecision {
        MediaProcessingDecision(
            route: .unsupported,
            rejectionReason: reason
        )
    }
}

protocol MediaProcessingRouting {

    func decision(
        for descriptor: MediaProcessingInputDescriptor
    ) -> MediaProcessingDecision
}
