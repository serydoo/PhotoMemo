#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

/// Resolves supported picker URLs and contains only MemoMark-owned temporary
/// picker files. It is intentionally separate from configuration saving,
/// intake admission, queue submission, and Photo Library output behavior.
enum PhotoIntakeURLResolver {

    nonisolated static func resolve(
        _ urls: [URL]
    ) -> [URL] {
        return urls.reduce(into: [URL]()) { result, url in
            let normalized = url.standardizedFileURL
            let contentType =
                UTType(
                    filenameExtension:
                        normalized.pathExtension
                        .lowercased()
                )

            guard PhotoProcessingInputPolicy.standard
                .isSupportedContentType(
                    contentType
                ) else {
                return
            }

            if !result.contains(normalized) {
                result.append(normalized)
            }
        }
    }

    nonisolated static func makeTemporaryURL(
        suggestedFileName: String?,
        contentType: UTType?,
        fileManager: FileManager = .default
    ) throws -> URL {
        let baseDirectory =
            fileManager.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkPicker",
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )

        let sanitizedFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                suggestedFileName
            )

        let baseName =
            sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .deletingPathExtension()
                    .lastPathComponent
            }
            .flatMap { text in
                let trimmed =
                    text.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                return trimmed.isEmpty ? nil : trimmed
            }
            ?? "MemoMark Picked Photo"

        let fileExtension =
            sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .pathExtension
            }
            .flatMap { text in
                let trimmed =
                    text.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                return trimmed.isEmpty ? nil : trimmed.lowercased()
            }
            ?? contentType?.preferredFilenameExtension
            ?? "jpg"

        return baseDirectory
            .appendingPathComponent(
                "\(baseName)-\(UUID().uuidString)"
            )
            .appendingPathExtension(fileExtension)
    }

    nonisolated static func copyTemporaryFileRepresentation(
        from sourceURL: URL,
        suggestedFileName: String? = nil,
        contentType: UTType? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let resolvedContentType =
            contentType
            ?? UTType(
                filenameExtension:
                    sourceURL.pathExtension
                    .lowercased()
            )

        let temporaryURL =
            try makeTemporaryURL(
                suggestedFileName:
                    suggestedFileName
                    ?? sourceURL.lastPathComponent,
                contentType:
                    resolvedContentType,
                fileManager:
                    fileManager
            )

        if fileManager.fileExists(
            atPath: temporaryURL.path
        ) {
            try fileManager.removeItem(
                at: temporaryURL
            )
        }

        try fileManager.copyItem(
            at: sourceURL,
            to: temporaryURL
        )

        return temporaryURL.standardizedFileURL
    }

    nonisolated static func discardTemporaryPickerFiles(
        _ urls: [URL],
        fileManager: FileManager = .default
    ) {
        let pickerDirectory =
            fileManager.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkPicker",
                isDirectory: true
            )
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let pickerDirectoryPath = pickerDirectory.path + "/"

        for url in urls {
            let normalizedURL =
                url.standardizedFileURL
                .resolvingSymlinksInPath()
            guard normalizedURL.path.hasPrefix(
                pickerDirectoryPath
            ) else {
                continue
            }
            try? fileManager.removeItem(at: normalizedURL)
        }
    }
}
#endif
