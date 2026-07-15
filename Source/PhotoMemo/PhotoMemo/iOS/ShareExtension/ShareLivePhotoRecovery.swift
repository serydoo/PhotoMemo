#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ShareLivePhotoRecovery {

    private let diagnostics:
        ShareIntakeDiagnostics

    init(
        diagnostics: ShareIntakeDiagnostics
    ) {
        self.diagnostics = diagnostics
    }

    func recordStaticLivePhotoPayloadIfNeeded(
        _ importRecord:
            ShareManagedFileImporter.ManagedImportRecord,
        requestedTypeIdentifier: String,
        requestID: UUID,
        index: Int
    ) -> ShareManagedFileImporter.ManagedImportRecord {

        let readiness =
            livePhotoBundleReadiness(
                at: importRecord.managedURL
            )

        guard !readiness.canResolveBundle else {
            return importRecord
        }

        diagnostics.recordStaticLivePhotoPayload(
            index: index,
            requestedTypeIdentifier:
                requestedTypeIdentifier,
            item: importRecord.item,
            readinessDiagnosticMessage:
                readiness.diagnosticMessage,
            requestID: requestID
        )

        let resolvedStaticContentTypeIdentifier =
            staticContentTypeIdentifier(
                for:
                    importRecord.item.managedURL,
                fallback:
                    importRecord.item
                    .contentTypeIdentifier
            )
        let metadataHints =
            staticFallbackRecoveryMetadataHints(
                for:
                    importRecord.item.managedURL
            )
        let staticItem =
            ExternalPhotoIntakeItem(
                managedURL:
                    importRecord.item.managedURL,
                originalFileName:
                    importRecord.item.originalFileName,
                sourceIdentifier:
                    importRecord.item.sourceIdentifier,
                contentTypeIdentifier:
                    resolvedStaticContentTypeIdentifier,
                livePhotoRecoveryHint:
                    LivePhotoStaticFallbackRecoveryHint(
                        originalFileName:
                            importRecord.item
                            .originalFileName,
                        advertisedLivePhotoTypeIdentifier:
                            requestedTypeIdentifier,
                        staticContentTypeIdentifier:
                            resolvedStaticContentTypeIdentifier,
                        captureDate:
                            metadataHints.captureDate,
                        pixelWidth:
                            metadataHints.pixelWidth,
                        pixelHeight:
                            metadataHints.pixelHeight
                    )
            )

        return ShareManagedFileImporter
            .ManagedImportRecord(
                item: staticItem,
                dedupeKey:
                    importRecord.dedupeKey,
                livePhotoStaticFallback: true
            )
    }

    func staticContentTypeIdentifier(
        for fileURL: URL,
        fallback: String?
    ) -> String? {

        if let type =
            UTType(
                filenameExtension:
                    fileURL
                    .pathExtension
            ),
           type.conforms(
            to: .image
           ) {
            return type.identifier
        }

        return fallback
    }

    func staticFallbackRecoveryMetadataHints(
        for fileURL: URL
    ) -> (
        captureDate: Date?,
        pixelWidth: Int?,
        pixelHeight: Int?
    ) {

        guard let source =
            CGImageSourceCreateWithURL(
                fileURL as CFURL,
                nil
            ),
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
            return (
                captureDate: nil,
                pixelWidth: nil,
                pixelHeight: nil
            )
        }

        return (
            captureDate:
                captureDateHint(
                    from: properties
                ),
            pixelWidth:
                properties[
                    kCGImagePropertyPixelWidth
                ] as? Int,
            pixelHeight:
                properties[
                    kCGImagePropertyPixelHeight
                ] as? Int
        )
    }

    func captureDateHint(
        from properties: [CFString: Any]
    ) -> Date? {

        if let exif =
            properties[
                kCGImagePropertyExifDictionary
            ] as? [CFString: Any],
           let dateString =
            exif[
                kCGImagePropertyExifDateTimeOriginal
            ] as? String,
           let date =
            parseStaticFallbackDateHint(
                dateString
            ) {
            return date
        }

        if let tiff =
            properties[
                kCGImagePropertyTIFFDictionary
            ] as? [CFString: Any],
           let dateString =
            tiff[
                kCGImagePropertyTIFFDateTime
            ] as? String {
            return parseStaticFallbackDateHint(
                dateString
            )
        }

        return nil
    }

    func parseStaticFallbackDateHint(
        _ dateString: String
    ) -> Date? {

        LivePhotoStaticFallbackDateParser
            .parse(
                dateString
            )
    }

    func parseStaticFallbackDateHint(
        _ dateString: String,
        timeZone: TimeZone
    ) -> Date? {

        LivePhotoStaticFallbackDateParser
            .parse(
                dateString,
                timeZone: timeZone
            )
    }

    func livePhotoBundleReadiness(
        at sourceURL: URL
    ) -> (
        canResolveBundle: Bool,
        diagnosticMessage: String
    ) {

        let standardizedURL =
            sourceURL.standardizedFileURL
        var isDirectory:
            ObjCBool = false

        guard FileManager.default.fileExists(
            atPath: standardizedURL.path,
            isDirectory: &isDirectory
        ) else {
            return (
                false,
                "managedPayload=missing"
            )
        }

        guard isDirectory.boolValue else {
            return (
                false,
                "managedPayload=file, pathExtension=\(standardizedURL.pathExtension)"
            )
        }

        guard let enumerator =
            FileManager.default.enumerator(
                at: standardizedURL,
                includingPropertiesForKeys: [
                    .isRegularFileKey
                ],
                options: [
                    .skipsHiddenFiles,
                    .skipsPackageDescendants
                ]
            ) else {
            return (
                false,
                "managedPayload=directory, enumerable=false"
            )
        }

        var stillImageURLs: [URL] = []
        var pairedMovieURLs: [URL] = []

        for case let fileURL as URL in enumerator {
            guard (
                try? fileURL.resourceValues(
                    forKeys: [
                        .isRegularFileKey
                    ]
                )
                .isRegularFile
            ) == true else {
                continue
            }

            guard let type =
                UTType(
                    filenameExtension:
                        fileURL.pathExtension
                ) else {
                continue
            }

            if type.conforms(
                to: .image
            ),
               !type.conforms(
                   to: .movie
               ) {
                stillImageURLs.append(
                    fileURL
                )
            }

            if type.conforms(
                to: .movie
            ) {
                pairedMovieURLs.append(
                    fileURL
                )
            }
        }

        let hasStillImage =
            !stillImageURLs.isEmpty
        let hasPairedMovie =
            !pairedMovieURLs.isEmpty
        let hasUniquePair =
            stillImageURLs.count == 1
            && pairedMovieURLs.count == 1
        let basenameMatches =
            hasUniquePair
            && Self.livePhotoResourceBasename(
                stillImageURLs[0]
            )
            == Self.livePhotoResourceBasename(
                pairedMovieURLs[0]
            )

        return (
            hasUniquePair && basenameMatches,
            "managedPayload=directory, hasStillImage=\(hasStillImage), hasPairedMovie=\(hasPairedMovie), stillCandidateCount=\(stillImageURLs.count), movieCandidateCount=\(pairedMovieURLs.count), basenameMatches=\(basenameMatches)"
        )
    }

    nonisolated static func livePhotoResourceBasename(
        _ url: URL
    ) -> String {

        url
            .deletingPathExtension()
            .lastPathComponent
            .lowercased()
    }
}
#endif
