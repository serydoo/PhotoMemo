import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if os(macOS)
typealias PlatformImage = NSImage
#elseif canImport(UIKit)
typealias PlatformImage = UIImage
#endif

extension PlatformImage {

    static func loadPhotoMemoImage(
        from data: Data
    ) -> PlatformImage? {

        PlatformImage(data: data)
    }

    static func loadPhotoMemoImage(
        contentsOfFile path: String
    ) -> PlatformImage? {

#if os(macOS)
        return PlatformImage(contentsOfFile: path)
#else
        return PlatformImage(contentsOfFile: path)
#endif
    }

    var photoMemoSize: CGSize {

#if os(macOS)
        return size
#else
        return size
#endif
    }

    var swiftUIImage: Image {

#if os(macOS)
        return Image(nsImage: self)
#else
        return Image(uiImage: self)
#endif
    }
}

struct SelectedPhoto: Identifiable {

    let id: UUID

    var sourceURL: URL

    var sourceProperties: [CFString: Any]

    var image: PlatformImage

    var metadata: PhotoMetadata

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        sourceProperties: [CFString: Any] = [:],
        image: PlatformImage,
        metadata: PhotoMetadata
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceProperties = sourceProperties
        self.image = image
        self.metadata = metadata
    }
}
