import Foundation
import AppKit
import UniformTypeIdentifiers

enum PhotoImportError: LocalizedError {

    case imageLoadFailed

    var errorDescription: String? {

        switch self {

        case .imageLoadFailed:
            return "Unable to load this image."
        }
    }
}

final class PhotoImportService {

    private let metadataReader = PhotoMetadataReader()

    func importPhoto(from url: URL) async throws -> SelectedPhoto {

        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let metadata = metadataReader.read(from: url)

        // ✅ 关键修复：用 Data 读取（稳定）
        guard let data = try? Data(contentsOf: url),
              let image = NSImage(data: data) else {

            throw PhotoImportError.imageLoadFailed
        }

        return SelectedPhoto(
            sourceURL: url,
            image: image,
            metadata: metadata
        )
    }

    func supportedTypes() -> [UTType] {
        [.jpeg, .png, .heic, .heif, .tiff]
    }

    func isSupported(_ url: URL) -> Bool {

        guard let type = UTType(filenameExtension: url.pathExtension.lowercased())
        else { return false }

        return supportedTypes().contains(type)
    }
}
