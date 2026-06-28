import SwiftUI
import ImageIO
import UniformTypeIdentifiers
#if canImport(Photos)
import Photos
#endif
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

    func export(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> URL {

#if os(macOS)
        let saveURL = try chooseSaveURL(
            for: photo
        )

        return try export(
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
                "PhotoMemoExports",
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
            uniqueTemporaryURL(
                in: folderURL,
                for: photo
            )

        return try export(
            photo: photo,
            card: card,
            to: fileURL
        )
    }
}

private extension RecordCardExportService {

    func export(
        photo: SelectedPhoto,
        card: RecordCard,
        to saveURL: URL
    ) throws -> URL {

        let resolvedSaveURL =
            uniqueOutputURL(for: saveURL)

        let renderSize =
            outputPixelSize(
                for: photo,
                template: card.template
            )

        let content = RecordCardRenderer(
            image: photo.image.swiftUIImage,
            card: card
        )
        .frame(
            width: renderSize.width,
            height: renderSize.height
        )

        let renderer =
            ImageRenderer(content: content)

        renderer.scale = 1
        renderer.proposedSize = .init(renderSize)
        renderer.isOpaque = true

        guard let cgImage = renderer.cgImage else {
            throw RecordCardExportError.renderFailed
        }

        let actualRenderSize = CGSize(
            width: cgImage.width,
            height: cgImage.height
        )
        let exportDescription =
            CardVariableProvider
            .exportDescription(
                from: card
            )

        let type =
            outputType(for: resolvedSaveURL)

        guard let destination =
            CGImageDestinationCreateWithURL(
                resolvedSaveURL as CFURL,
                type.identifier as CFString,
                1,
                nil
            )
        else {
            throw RecordCardExportError.destinationCreateFailed
        }

        let properties =
            sanitizedMetadata(
                from: photo.sourceProperties,
                renderSize: actualRenderSize,
                outputType: type,
                exportDescription:
                    exportDescription
            )

        CGImageDestinationAddImage(
            destination,
            cgImage,
            properties as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw RecordCardExportError.writeFailed
        }

        patchUnicodeUserCommentIfNeeded(
            at: resolvedSaveURL,
            outputType: type,
            exportDescription:
                exportDescription
        )

        applyFileDates(
            to: resolvedSaveURL,
            captureDate: photo.metadata.captureDate
        )

        return resolvedSaveURL
    }

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
            defaultFileName(for: photo)

        let response = panel.runModal()

        guard response == .OK,
              let url = panel.url else {
            throw RecordCardExportError.saveCancelled
        }

        return url
    }
#endif

    func defaultFileName(
        for photo: SelectedPhoto
    ) -> String {

        let baseName =
            PhotoFileNameResolver
            .outputCopyBaseName(
                from: resolvedOutputBaseName(
                    for: photo
                ),
                index: 1
            )

        return baseName + ".jpg"
    }

    func uniqueTemporaryURL(
        in folderURL: URL,
        for photo: SelectedPhoto
    ) -> URL {

        let originalBaseName =
            resolvedOutputBaseName(
                for: photo
            )

        let baseName =
            PhotoFileNameResolver
            .nextOutputCopyBaseName(
                from: originalBaseName
            ) { candidate in
                FileManager.default.fileExists(
                    atPath:
                        folderURL
                        .appendingPathComponent(candidate)
                        .appendingPathExtension("jpg")
                        .path
                )
            }

        return folderURL
            .appendingPathComponent(
                baseName
            )
            .appendingPathExtension("jpg")
    }

    func resolvedOutputBaseName(
        for photo: SelectedPhoto
    ) -> String {

        PhotoFileNameResolver
            .outputBaseName(
                preferredOriginalFileName:
                    photo.sourceInfo
                    .originalFileName,
                assetOriginalFileName:
                    originalPhotoLibraryFileName(
                        for:
                            photo
                            .sourceInfo
                            .assetLocalIdentifier
                    ),
                captureDate:
                    photo.metadata.captureDate,
                timeZone:
                    photo.metadata
                    .captureTimeZone,
                fallbackBaseName:
                    sourceURLFallbackBaseName(
                        for: photo
                    )
            )
    }

    func sourceURLFallbackBaseName(
        for photo: SelectedPhoto
    ) -> String {

        let fileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                photo.sourceURL
                .lastPathComponent
            )

        let baseName =
            fileName.map {
                URL(fileURLWithPath: $0)
                    .deletingPathExtension()
                    .lastPathComponent
            }?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return baseName?.isEmpty == false
            ? baseName ?? "PhotoMemo"
            : "PhotoMemo"
    }

    func originalPhotoLibraryFileName(
        for assetLocalIdentifier: String?
    ) -> String? {

#if canImport(Photos)
        guard
            let assetLocalIdentifier,
            !assetLocalIdentifier
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        else {
            return nil
        }

        let assets =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    assetLocalIdentifier
                ],
                options: nil
            )

        guard let asset = assets.firstObject else {
            return nil
        }

        let resources =
            PHAssetResource.assetResources(
                for: asset
            )

        let preferredFileName =
            resources.first {
                switch $0.type {
                case .photo,
                     .fullSizePhoto,
                     .alternatePhoto:
                    return true

                default:
                    return false
                }
            }?.originalFilename
            ?? resources.first?.originalFilename

        return PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferredFileName
            )
#else
        return nil
#endif
    }

    func uniqueOutputURL(
        for url: URL
    ) -> URL {

        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return url
        }

        let folderURL =
            url.deletingLastPathComponent()
        let baseName =
            url.deletingPathExtension()
            .lastPathComponent
        let pathExtension =
            url.pathExtension

        let candidateBaseName =
            PhotoFileNameResolver
            .nextOutputCopyBaseName(
                from: baseName
            ) { candidate in
                FileManager.default.fileExists(
                    atPath:
                        folderURL
                        .appendingPathComponent(candidate)
                        .appendingPathExtension(pathExtension)
                        .path
                )
            }

        return folderURL
            .appendingPathComponent(
                candidateBaseName
            )
            .appendingPathExtension(
                pathExtension
            )
    }

    func outputType(
        for url: URL
    ) -> UTType {

        UTType(
            filenameExtension:
                url.pathExtension.lowercased()
        ) ?? .jpeg
    }

    func outputPixelSize(
        for photo: SelectedPhoto,
        template: Template
    ) -> CGSize {

        if template.preset.renderLayout == .immersWhite {

            return ImmersWhiteRenderer
                .outputPixelSize(
                    for: photo.metadata,
                    fallbackSize:
                        photo.image.photoMemoSize
                )
        }

        return ClassicWhiteRenderer
            .outputPixelSize(
                for: photo.metadata,
                fallbackSize:
                    photo.image.photoMemoSize
            )
    }

    func sanitizedMetadata(
        from sourceProperties: [CFString: Any],
        renderSize: CGSize,
        outputType: UTType,
        exportDescription: String
    ) -> [CFString: Any] {

        var properties = sourceProperties

        let pixelWidth = Int(renderSize.width)
        let pixelHeight = Int(renderSize.height)

        properties[kCGImagePropertyPixelWidth] =
            pixelWidth
        properties[kCGImagePropertyPixelHeight] =
            pixelHeight

        properties[kCGImagePropertyOrientation] = 1

        var exif =
            properties[
                kCGImagePropertyExifDictionary
            ] as? [CFString: Any] ?? [:]

        exif[
            kCGImagePropertyExifPixelXDimension
        ] = pixelWidth

        exif[
            kCGImagePropertyExifPixelYDimension
        ] = pixelHeight

        if !exportDescription.isEmpty {
            exif[
                "UserComment" as CFString
            ] = exportDescription
        }

        properties[
            kCGImagePropertyExifDictionary
        ] = exif

        var tiff =
            properties[
                kCGImagePropertyTIFFDictionary
            ] as? [CFString: Any] ?? [:]

        tiff[
            kCGImagePropertyTIFFSoftware
        ] = "PhotoMemo"

        if !exportDescription.isEmpty {
            tiff[
                kCGImagePropertyTIFFImageDescription
            ] = exportDescription
        }

        properties[
            kCGImagePropertyTIFFDictionary
        ] = tiff

        if !exportDescription.isEmpty {

            var iptc =
                properties[
                    kCGImagePropertyIPTCDictionary
                ] as? [CFString: Any] ?? [:]

            iptc[
                kCGImagePropertyIPTCCaptionAbstract
            ] = exportDescription

            properties[
                kCGImagePropertyIPTCDictionary
            ] = iptc
        }

        if outputType.conforms(
            to: .png
        ),
           !exportDescription.isEmpty {

            var png =
                properties[
                    kCGImagePropertyPNGDictionary
                ] as? [CFString: Any] ?? [:]

            png[
                kCGImagePropertyPNGDescription
            ] = exportDescription

            properties[
                kCGImagePropertyPNGDictionary
            ] = png
        }

        return properties
    }

    func patchUnicodeUserCommentIfNeeded(
        at url: URL,
        outputType: UTType,
        exportDescription: String
    ) {

        guard
            outputType.conforms(to: .jpeg),
            !exportDescription.isEmpty,
            !exportDescription.canBeConverted(to: .ascii),
            var fileData =
                try? Data(contentsOf: url),
            let location =
                jpegUserCommentLocation(
                    in: fileData
                )
        else {
            return
        }

        let encodedComment =
            exifUnicodeUserCommentData(
                exportDescription
            )

        guard
            encodedComment.count
            <= location.dataRange.count
        else {
            return
        }

        var replacement =
            encodedComment

        if encodedComment.count < location.dataRange.count {
            replacement.append(
                Data(
                    repeating: 0,
                    count:
                        location.dataRange.count
                        - encodedComment.count
                )
            )
        }

        fileData.replaceSubrange(
            location.dataRange,
            with: replacement
        )
        fileData.replaceSubrange(
            location.countRange,
            with:
                encodedUInt32(
                    UInt32(
                        encodedComment.count
                    ),
                    endianness:
                        location.endianness
                )
        )

        try? fileData.write(
            to: url,
            options: .atomic
        )
    }

    func exifUnicodeUserCommentData(
        _ text: String
    ) -> Data {

        var data =
            Data("UNICODE\0".utf8)
        data.append(
            text.data(
                using: .utf16BigEndian
            ) ?? Data()
        )
        return data
    }

    func jpegUserCommentLocation(
        in data: Data
    ) -> JPEGExifUserCommentLocation? {

        guard data.count >= 4 else {
            return nil
        }

        var offset = 2

        while offset + 4 <= data.count {

            guard data[offset] == 0xFF else {
                return nil
            }

            let marker = data[offset + 1]

            if marker == 0xDA || marker == 0xD9 {
                return nil
            }

            let segmentLength =
                Int(
                    readUInt16(
                        in: data,
                        at: offset + 2,
                        endianness: .big
                    )
                )

            guard segmentLength >= 2 else {
                return nil
            }

            let segmentStart = offset + 4
            let segmentEnd =
                offset + 2 + segmentLength

            guard segmentEnd <= data.count else {
                return nil
            }

            if marker == 0xE1,
               segmentEnd - segmentStart >= 6,
               data[
                    segmentStart..<segmentStart + 6
               ] == Data("Exif\0\0".utf8),
               let location =
                exifUserCommentLocation(
                    in: data,
                    exifHeaderStart:
                        segmentStart
                ) {
                return location
            }

            offset = segmentEnd
        }

        return nil
    }

    func exifUserCommentLocation(
        in data: Data,
        exifHeaderStart: Int
    ) -> JPEGExifUserCommentLocation? {

        let tiffStart =
            exifHeaderStart + 6

        guard tiffStart + 8 <= data.count else {
            return nil
        }

        let endianness:
            TIFFEndianness

        switch (
            data[tiffStart],
            data[tiffStart + 1]
        ) {

        case (0x4D, 0x4D):
            endianness = .big

        case (0x49, 0x49):
            endianness = .little

        default:
            return nil
        }

        let ifd0Offset =
            Int(
                readUInt32(
                    in: data,
                    at: tiffStart + 4,
                    endianness: endianness
                )
            )
        let ifd0Start =
            tiffStart + ifd0Offset

        guard
            let exifIFDOffset =
                ifdValueOffset(
                    forTag: 0x8769,
                    in: data,
                    at: ifd0Start,
                    endianness: endianness
                )
        else {
            return nil
        }

        let exifIFDStart =
            tiffStart + exifIFDOffset

        guard
            let entry =
                ifdEntry(
                    forTag: 0x9286,
                    in: data,
                    at: exifIFDStart,
                    endianness: endianness
                )
        else {
            return nil
        }

        let dataStart =
            tiffStart + entry.valueOffset
        let dataEnd =
            dataStart + Int(entry.count)

        guard
            dataStart >= 0,
            dataEnd <= data.count
        else {
            return nil
        }

        return JPEGExifUserCommentLocation(
            dataRange:
                dataStart..<dataEnd,
            countRange:
                entry.countOffset
                ..<
                (entry.countOffset + 4),
            endianness: endianness
        )
    }

    func ifdValueOffset(
        forTag tag: UInt16,
        in data: Data,
        at ifdStart: Int,
        endianness: TIFFEndianness
    ) -> Int? {

        ifdEntry(
            forTag: tag,
            in: data,
            at: ifdStart,
            endianness: endianness
        )?.valueOffset
    }

    func ifdEntry(
        forTag tag: UInt16,
        in data: Data,
        at ifdStart: Int,
        endianness: TIFFEndianness
    ) -> TIFFIFDEntry? {

        guard ifdStart + 2 <= data.count else {
            return nil
        }

        let entryCount =
            Int(
                readUInt16(
                    in: data,
                    at: ifdStart,
                    endianness: endianness
                )
            )

        for index in 0..<entryCount {

            let entryStart =
                ifdStart + 2 + (index * 12)

            guard entryStart + 12 <= data.count else {
                return nil
            }

            let entryTag =
                readUInt16(
                    in: data,
                    at: entryStart,
                    endianness: endianness
                )

            guard entryTag == tag else {
                continue
            }

            return TIFFIFDEntry(
                count:
                    readUInt32(
                        in: data,
                        at: entryStart + 4,
                        endianness: endianness
                    ),
                countOffset:
                    entryStart + 4,
                valueOffset:
                    Int(
                        readUInt32(
                            in: data,
                            at: entryStart + 8,
                            endianness: endianness
                        )
                    )
            )
        }

        return nil
    }

    func readUInt16(
        in data: Data,
        at offset: Int,
        endianness: TIFFEndianness
    ) -> UInt16 {

        let bytes = data[offset..<offset + 2]

        switch endianness {

        case .big:
            return bytes.reduce(0) {
                ($0 << 8) | UInt16($1)
            }

        case .little:
            return bytes
                .reversed()
                .reduce(0) {
                    ($0 << 8) | UInt16($1)
                }
        }
    }

    func readUInt32(
        in data: Data,
        at offset: Int,
        endianness: TIFFEndianness
    ) -> UInt32 {

        let bytes = data[offset..<offset + 4]

        switch endianness {

        case .big:
            return bytes.reduce(0) {
                ($0 << 8) | UInt32($1)
            }

        case .little:
            return bytes
                .reversed()
                .reduce(0) {
                    ($0 << 8) | UInt32($1)
                }
        }
    }

    func encodedUInt32(
        _ value: UInt32,
        endianness: TIFFEndianness
    ) -> Data {

        let bytes = [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ]

        switch endianness {

        case .big:
            return Data(bytes)

        case .little:
            return Data(bytes.reversed())
        }
    }

    func applyFileDates(
        to url: URL,
        captureDate: Date?
    ) {

        guard let captureDate else {
            return
        }

        try? FileManager.default.setAttributes(
            [
                .creationDate: captureDate,
                .modificationDate: captureDate
            ],
            ofItemAtPath: url.path
        )
    }
}

private extension RecordCardExportService {

    enum TIFFEndianness {

        case big

        case little
    }

    struct TIFFIFDEntry {

        let count: UInt32

        let countOffset: Int

        let valueOffset: Int
    }

    struct JPEGExifUserCommentLocation {

        let dataRange: Range<Int>

        let countRange: Range<Int>

        let endianness: TIFFEndianness
    }
}
