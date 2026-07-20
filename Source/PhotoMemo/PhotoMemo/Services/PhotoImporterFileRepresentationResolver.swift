#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

enum PhotoImporterFileRepresentationResolver {

    nonisolated static func copyTemporaryFileRepresentation(
        from sourceURL: URL,
        contentType: UTType? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let temporaryURL = try makeTemporaryURL(
            sourceURL: sourceURL,
            contentType: contentType,
            fileManager: fileManager
        )

        if fileManager.fileExists(atPath: temporaryURL.path) {
            try fileManager.removeItem(at: temporaryURL)
        }

        try fileManager.copyItem(
            at: sourceURL,
            to: temporaryURL
        )

        return temporaryURL.standardizedFileURL
    }

    private nonisolated static func makeTemporaryURL(
        sourceURL: URL,
        contentType: UTType?,
        fileManager: FileManager
    ) throws -> URL {
        let baseDirectory = fileManager.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkPickerFileRepresentations",
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )

        let sanitizedFileName = PhotoFileNameResolver
            .sanitizedOriginalFileName(
                sourceURL.lastPathComponent
            )
        let baseName = sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .deletingPathExtension()
                    .lastPathComponent
            }
            .flatMap { value in
                let trimmed = value.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                return trimmed.isEmpty ? nil : trimmed
            }
            ?? "MemoMark Picked Photo"
        let fileExtension = sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .pathExtension
            }
            .flatMap { value in
                let trimmed = value.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                return trimmed.isEmpty
                    ? nil
                    : trimmed.lowercased()
            }
            ?? contentType?.preferredFilenameExtension
            ?? "jpg"

        return baseDirectory
            .appendingPathComponent(
                "\(baseName)-\(UUID().uuidString)"
            )
            .appendingPathExtension(fileExtension)
    }
}
#endif
