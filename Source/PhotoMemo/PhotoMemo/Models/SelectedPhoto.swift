import Foundation
import UniformTypeIdentifiers

struct SelectedPhoto: Identifiable {

    let id: UUID

    var sourceURL: URL

    var sourceInfo: PhotoSourceInfo

    var sourceProperties: [CFString: Any]

    var image: PlatformImage

    var metadata: PhotoMetadata

    var mediaAsset: MediaAsset

    var previewRepresentation: MediaRepresentation?

    var importReport: MediaImportReport {
        MediaImportReport(
            asset: mediaAsset,
            representation:
                previewRepresentation
        )
    }

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        sourceProperties: [CFString: Any] = [:],
        image: PlatformImage,
        metadata: PhotoMetadata,
        sourceInfo: PhotoSourceInfo? = nil,
        mediaAsset: MediaAsset? = nil,
        previewRepresentation: MediaRepresentation? = nil
    ) {
        self.id = id
        self.sourceURL = sourceURL
        let resolvedSourceInfo =
            sourceInfo
            ?? PhotoSourceInfo(
                originalFileName:
                    sourceURL.lastPathComponent,
                contentTypeIdentifier:
                    UTType(
                        filenameExtension:
                            sourceURL.pathExtension
                            .lowercased()
                    )?.identifier
            )
        self.sourceInfo = resolvedSourceInfo
        self.sourceProperties = sourceProperties
        self.image = image
        self.metadata = metadata
        self.mediaAsset =
            mediaAsset
            ?? MediaAsset(
                fileURL: sourceURL,
                sourceInfo: resolvedSourceInfo,
                sourceProperties: sourceProperties,
                contentType:
                    resolvedSourceInfo
                    .contentTypeIdentifier
                    .flatMap(UTType.init)
                    ?? UTType(
                        filenameExtension:
                            sourceURL.pathExtension
                            .lowercased()
                    )
            )
        self.previewRepresentation =
            previewRepresentation
    }
}
