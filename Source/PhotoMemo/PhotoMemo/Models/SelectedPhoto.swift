import Foundation
import AppKit

struct SelectedPhoto: Identifiable {

    let id: UUID

    var image: NSImage

    var metadata: PhotoMetadata

    init(
        id: UUID = UUID(),
        image: NSImage,
        metadata: PhotoMetadata
    ) {
        self.id = id
        self.image = image
        self.metadata = metadata
    }
}
