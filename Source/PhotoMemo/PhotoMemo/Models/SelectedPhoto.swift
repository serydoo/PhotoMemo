import Foundation
import AppKit

struct SelectedPhoto: Identifiable {

    let id: UUID

    var sourceURL: URL

    var image: NSImage

    var metadata: PhotoMetadata

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        image: NSImage,
        metadata: PhotoMetadata
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.image = image
        self.metadata = metadata
    }
}
