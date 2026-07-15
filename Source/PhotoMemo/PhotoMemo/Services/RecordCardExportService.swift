import Foundation
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

enum RecordCardExportError: LocalizedError {

    case saveCancelled

    case renderFailed

    case destinationCreateFailed

    case writeFailed

    case temporaryFileCreateFailed

    var errorDescription: String? {

        switch self {

        case .saveCancelled:
            return "Export was cancelled."

        case .renderFailed:
            return "Unable to render the final image."

        case .destinationCreateFailed:
            return "Unable to create the export file."

        case .writeFailed:
            return "Unable to save the exported image."

        case .temporaryFileCreateFailed:
            return "Unable to prepare the temporary export file."
        }
    }
}

@MainActor
final class RecordCardExportService {

    private let namingResolver: OutputFileNamingResolver

    private let pipeline: RecordCardExportPipeline

    init() {
        let namingResolver =
            OutputFileNamingResolver()
        self.namingResolver = namingResolver
        self.pipeline =
            RecordCardExportPipeline(
                namingResolver: namingResolver
            )
    }

    func export(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> URL {

#if os(macOS)
        let saveURL = try chooseSaveURL(
            for: photo
        )

        return try pipeline.export(
            photo: photo,
            card: card,
            to: saveURL
        )
#else
        return try exportToTemporaryFile(
            photo: photo,
            card: card
        )
#endif
    }

    func exportToTemporaryFile(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> URL {

        let folderURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkExports",
                isDirectory: true
            )

        do {

            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )

        } catch {

            throw RecordCardExportError
                .temporaryFileCreateFailed
        }

        let fileURL =
            namingResolver.uniqueTemporaryURL(
                in: folderURL,
                for: photo
            )

        return try pipeline.export(
            photo: photo,
            card: card,
            to: fileURL
        )
    }
}

private extension RecordCardExportService {

#if os(macOS)
    func chooseSaveURL(
        for photo: SelectedPhoto
    ) throws -> URL {

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.allowedContentTypes = [
            .jpeg,
            .png,
            .heic
        ]
        panel.nameFieldStringValue =
            namingResolver.defaultFileName(
                for: photo
            )

        let response = panel.runModal()

        guard response == .OK,
              let url = panel.url else {
            throw RecordCardExportError.saveCancelled
        }

        return url
    }
#endif
}
