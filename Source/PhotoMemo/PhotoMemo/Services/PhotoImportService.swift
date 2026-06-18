import Foundation
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

        try importPhotoSync(from: url)
    }

    func importPhotoOffMainThread(
        from url: URL
    ) async throws -> SelectedPhoto {

        try await withCheckedThrowingContinuation {
            continuation in

            DispatchQueue.global(
                qos: .userInitiated
            ).async {

                do {

                    let photo =
                        try self.importPhotoSync(
                            from: url
                        )

                    continuation.resume(
                        returning: photo
                    )

                } catch {

                    continuation.resume(
                        throwing: error
                    )
                }
            }
        }
    }

    private func importPhotoSync(
        from url: URL
    ) throws -> SelectedPhoto {

        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let sourceProperties =
            metadataReader.properties(from: url)
            ?? [:]

        let metadata =
            metadataReader.read(
                from: sourceProperties
            )

        // ✅ 关键修复：用 Data 读取（稳定）
        guard let data = try? Data(contentsOf: url),
              let image = PlatformImage.loadPhotoMemoImage(from: data) else {

            throw PhotoImportError.imageLoadFailed
        }

        return SelectedPhoto(
            sourceURL: url,
            sourceProperties: sourceProperties,
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
