import Foundation
import AppKit

struct SelectedPhoto: Identifiable {

    let id: UUID

    var sourceURL: URL

    var sourceProperties: [CFString: Any]

    var image: NSImage

    var metadata: PhotoMetadata

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        sourceProperties: [CFString: Any] = [:],
        image: NSImage,
        metadata: PhotoMetadata
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceProperties = sourceProperties
        self.image = image
        self.metadata = metadata
    }
}
