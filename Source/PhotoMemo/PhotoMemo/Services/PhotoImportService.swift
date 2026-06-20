import Foundation
import UniformTypeIdentifiers

enum PhotoImportError: LocalizedError {

    case imageLoadFailed
    case temporaryImportPreparationFailed

    var errorDescription: String? {

        switch self {

        case .imageLoadFailed:
            return "Unable to load this image."

        case .temporaryImportPreparationFailed:
            return "Unable to prepare the selected photo."
        }
    }
}

final class PhotoImportService {

    private let metadataReader = PhotoMetadataReader()

    func importPhoto(from url: URL) async throws -> SelectedPhoto {

        try importPhotoSync(from: url)
    }

    func importPhoto(
        from data: Data,
        suggestedFileName: String?,
        contentType: UTType?
    ) async throws -> SelectedPhoto {

        let temporaryURL =
            try prepareTemporaryImportURL(
                suggestedFileName: suggestedFileName,
                contentType: contentType
            )

        do {

            try data.write(
                to: temporaryURL,
                options: .atomic
            )

            return try importPhotoSync(
                from: temporaryURL
            )

        } catch {

            try? FileManager.default.removeItem(
                at: temporaryURL
            )

            throw error
        }
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

    func isSupported(
        _ contentType: UTType?
    ) -> Bool {

        guard let contentType else {
            return false
        }

        return supportedTypes().contains {
            contentType.conforms(to: $0)
        }
    }

    private func prepareTemporaryImportURL(
        suggestedFileName: String?,
        contentType: UTType?
    ) throws -> URL {

        let folderURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemoPickerImports",
                isDirectory: true
            )

        do {

            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )

        } catch {

            throw PhotoImportError
                .temporaryImportPreparationFailed
        }

        let baseName =
            normalizedImportBaseName(
                suggestedFileName
            )

        let fileExtension =
            preferredImportExtension(
                suggestedFileName: suggestedFileName,
                contentType: contentType
            )

        return uniqueImportURL(
            in: folderURL,
            baseName: baseName,
            fileExtension: fileExtension
        )
    }

    private func normalizedImportBaseName(
        _ suggestedFileName: String?
    ) -> String {

        let fallback = "PhotoMemo Import"

        guard
            let suggestedFileName,
            !suggestedFileName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        else {
            return fallback
        }

        let baseName =
            URL(fileURLWithPath: suggestedFileName)
            .deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return baseName.isEmpty
            ? fallback
            : baseName
    }

    private func preferredImportExtension(
        suggestedFileName: String?,
        contentType: UTType?
    ) -> String {

        if let suggestedFileName {

            let extensionCandidate =
                URL(fileURLWithPath: suggestedFileName)
                .pathExtension
                .lowercased()

            if !extensionCandidate.isEmpty {
                return extensionCandidate
            }
        }

        if let contentType,
           let preferredFilenameExtension =
            contentType.preferredFilenameExtension {

            return preferredFilenameExtension
        }

        return "jpg"
    }

    private func uniqueImportURL(
        in folderURL: URL,
        baseName: String,
        fileExtension: String
    ) -> URL {

        let safeExtension =
            fileExtension.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let extensionSuffix =
            safeExtension.isEmpty
            ? ""
            : ".\(safeExtension)"

        var candidateURL =
            folderURL.appendingPathComponent(
                baseName + extensionSuffix
            )

        var index = 1

        while FileManager.default.fileExists(
            atPath: candidateURL.path
        ) {

            candidateURL =
                folderURL.appendingPathComponent(
                    "\(baseName) (\(index))"
                    + extensionSuffix
                )
            index += 1
        }

        return candidateURL
    }
}
