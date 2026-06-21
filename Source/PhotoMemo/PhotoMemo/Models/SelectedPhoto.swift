import Foundation
import SwiftUI
import UniformTypeIdentifiers
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

    var sourceInfo: PhotoSourceInfo

    var sourceProperties: [CFString: Any]

    var image: PlatformImage

    var metadata: PhotoMetadata

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        sourceProperties: [CFString: Any] = [:],
        image: PlatformImage,
        metadata: PhotoMetadata,
        sourceInfo: PhotoSourceInfo? = nil
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceInfo =
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
        self.sourceProperties = sourceProperties
        self.image = image
        self.metadata = metadata
    }
}

struct PhotoSourceInfo:
    Hashable,
    Codable {

    var originalFileName: String

    var assetLocalIdentifier: String?

    var contentTypeIdentifier: String?

    init(
        originalFileName: String,
        assetLocalIdentifier: String? = nil,
        contentTypeIdentifier: String? = nil
    ) {
        self.originalFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                originalFileName
            )
            ?? "PhotoMemo Import.jpg"
        self.assetLocalIdentifier =
            assetLocalIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        self.contentTypeIdentifier =
            contentTypeIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    var originalBaseName: String {

        let baseName =
            URL(
                fileURLWithPath:
                    originalFileName
            )
            .deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return baseName.isEmpty
            ? "PhotoMemo Import"
            : baseName
    }
}
