import Foundation
import CoreGraphics
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@Suite("PhotoImportService")
struct PhotoImportServiceTests {

    @Test("Rejects unsupported declared media types with input policy reason")
    func rejectsUnsupportedDeclaredMediaTypesWithPolicyReason() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)

        do {
            _ =
                try await PhotoImportService()
                .importPhoto(
                    from: sourceData,
                    suggestedFileName:
                        "animated.gif",
                    contentType: .gif
                )

            Issue.record(
                "Expected PhotoImportService to reject unsupported media before decode."
            )

        } catch let error as PhotoImportError {
            guard case let .unsupportedInput(verdict) = error else {
                Issue.record(
                    "Expected unsupported input policy error, got \(error)."
                )
                return
            }

            #expect(verdict.reason == .unsupportedFormat)
            #expect(
                error.inputPolicyReason
                == .unsupportedFormat
            )
            #expect(
                error.errorDescription
                == verdict.title
            )
            #expect(
                error.failureReason
                == verdict.message
            )

        } catch {
            Issue.record(
                "Expected PhotoImportError, got \(error)."
            )
        }
    }

    @Test("Allows Live Photo still frames only when internal policy is supplied")
    func allowsLivePhotoStillFramesWithInternalPolicy() async throws {
        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)
        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )

        do {
            _ =
                try await PhotoImportService()
                .importPhoto(
                    from: sourceData,
                    suggestedFileName:
                        "IMG_6093.HEIC",
                    contentType:
                        livePhotoType,
                    assetLocalIdentifier:
                        "live-photo-local-identifier"
                )

            Issue.record(
                "Expected the standard importer to reject Live Photo input."
            )
        } catch let error as PhotoImportError {
            #expect(
                error.inputPolicyReason
                == .livePhoto
            )
        }

        let importedPhoto =
            try await PhotoImportService(
                inputPolicy:
                    PhotoProcessingInputPolicy(
                        allowsLivePhoto: true
                    )
            )
            .importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_6093.HEIC",
                contentType:
                    livePhotoType,
                assetLocalIdentifier:
                    "live-photo-local-identifier"
            )

        #expect(
            importedPhoto.mediaAsset.isLivePhoto
        )
        #expect(
            importedPhoto.mediaAsset.sourceIdentifier
            == "live-photo-local-identifier"
        )
        #expect(
            importedPhoto.sourceInfo
                .contentTypeIdentifier
            == livePhotoType.identifier
        )
    }

    @Test("Rejects oversized media dimensions with input policy reason")
    func rejectsOversizedMediaDimensionsWithPolicyReason() async throws {

        let temporaryDirectory =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoImportServicePolicyTests-\(UUID().uuidString)",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let oversizedURL =
            temporaryDirectory
            .appendingPathComponent("OversizedDimension")
            .appendingPathExtension("jpg")

        try writeSolidJPEG(
            width:
                PhotoProcessingInputPolicy
                .standard
                .maximumPixelDimension
                + 1,
            height: 8,
            to: oversizedURL
        )

        do {
            _ =
                try await PhotoImportService()
                .importPhoto(from: oversizedURL)

            Issue.record(
                "Expected PhotoImportService to reject oversized media before decode."
            )

        } catch let error as PhotoImportError {
            guard case let .unsupportedInput(verdict) = error else {
                Issue.record(
                    "Expected unsupported input policy error, got \(error)."
                )
                return
            }

            #expect(verdict.reason == .oversizedPixelDimension)
            #expect(
                error.inputPolicyReason
                == .oversizedPixelDimension
            )
            #expect(
                error.failureReason
                == verdict.message
            )

        } catch {
            Issue.record(
                "Expected PhotoImportError, got \(error)."
            )
        }
    }

    @Test("Preserves explicit suggested file names for data imports")
    func preservesExplicitSuggestedFileNames() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_9558.HEIC",
                contentType: .heic
            )

        defer {
            try? FileManager.default.removeItem(
                at: importedPhoto.sourceURL
            )
        }

        #expect(
            importedPhoto.sourceURL
            .lastPathComponent
            == "IMG_9558.HEIC"
        )
        #expect(
            importedPhoto.sourceInfo
            .originalFileName
            == "IMG_9558.HEIC"
        )
        #expect(
            importedPhoto.sourceInfo
            .contentTypeIdentifier
            == UTType.heic.identifier
        )
    }

    @Test("Applies location metadata enrichment during import")
    func appliesLocationMetadataEnrichmentDuringImport() async throws {
        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let service =
            PhotoImportService(
                locationMetadataEnricher:
                    StubLocationMetadataEnricher { metadata in
                        var enrichedMetadata = metadata
                        enrichedMetadata.city = "商丘"
                        enrichedMetadata.district = "永城"
                        enrichedMetadata.province = "河南"
                        enrichedMetadata.country = "中国"
                        return enrichedMetadata
                    }
            )

        let importedPhoto =
            try await service.importPhoto(
                from: sourceURL
            )

        #expect(importedPhoto.metadata.city == "商丘")
        #expect(importedPhoto.metadata.district == "永城")
        #expect(importedPhoto.metadata.province == "河南")
        #expect(importedPhoto.metadata.country == "中国")
    }

    @Test("Falls back away from the Photo Library placeholder for data imports")
    func fallsBackAwayFromPhotoLibraryPlaceholder() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .portraitJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(
                from: sourceData,
                suggestedFileName:
                    "Photo Library",
                contentType: .jpeg
            )

        defer {
            try? FileManager.default.removeItem(
                at: importedPhoto.sourceURL
            )
        }

        #expect(
            importedPhoto.sourceURL
            .lastPathComponent
            != "Photo Library.jpg"
        )
        #expect(
            importedPhoto.sourceURL
            .lastPathComponent
            .hasPrefix(
                "MemoMark Import"
            )
        )
        #expect(
            importedPhoto.sourceURL
            .pathExtension
            .lowercased()
            == "jpg"
        )
    }

    @Test("Repeated data imports keep the original source file name")
    func repeatedDataImportsKeepOriginalSourceFileName() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .landscapeJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)
        let service = PhotoImportService()

        let firstImport =
            try await service.importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_7065.JPEG",
                contentType: .jpeg
            )

        let secondImport =
            try await service.importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_7065.JPEG",
                contentType: .jpeg
            )

        defer {
            try? FileManager.default.removeItem(
                at: firstImport.sourceURL
            )
            try? FileManager.default.removeItem(
                at: secondImport.sourceURL
            )
            try? FileManager.default.removeItem(
                at: firstImport.sourceURL
                    .deletingLastPathComponent()
            )
            try? FileManager.default.removeItem(
                at: secondImport.sourceURL
                    .deletingLastPathComponent()
            )
        }

        #expect(
            firstImport.sourceURL
            .lastPathComponent
            == "IMG_7065.JPEG"
        )
        #expect(
            secondImport.sourceURL
            .lastPathComponent
            == "IMG_7065.JPEG"
        )
        #expect(
            firstImport.sourceInfo
            .originalFileName
            == "IMG_7065.JPEG"
        )
        #expect(
            secondImport.sourceInfo
            .originalFileName
            == "IMG_7065.JPEG"
        )
        #expect(
            firstImport.sourceURL
            .deletingLastPathComponent()
            != secondImport.sourceURL
            .deletingLastPathComponent()
        )
    }

    @Test("Carries source asset identifier and type into imported photos")
    func carriesSourceAssetIdentifierAndTypeIntoImportedPhotos() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_6001.HEIC",
                contentType: .heic,
                assetLocalIdentifier:
                    "asset-local-123"
            )

        defer {
            try? FileManager.default.removeItem(
                at: importedPhoto.sourceURL
            )
        }

        #expect(
            importedPhoto.sourceInfo
            .originalFileName
            == "IMG_6001.HEIC"
        )
        #expect(
            importedPhoto.sourceInfo
            .assetLocalIdentifier
            == "asset-local-123"
        )
        #expect(
            importedPhoto.sourceInfo
            .contentTypeIdentifier
            == UTType.heic.identifier
        )
    }

    @Test("Data imports preserve metadata and image size from the source photo")
    func dataImportsPreserveMetadataAndImageSizeFromSourcePhoto() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)
        let service =
            PhotoImportService()

        let fileImport =
            try await service.importPhoto(
                from: sourceURL
            )
        let dataImport =
            try await service.importPhoto(
                from: sourceData,
                suggestedFileName:
                    sourceURL.lastPathComponent,
                contentType: .jpeg
            )

        defer {
            try? FileManager.default.removeItem(
                at: dataImport.sourceURL
            )
        }

        #expect(
            dataImport.metadata.captureDate
            == fileImport.metadata.captureDate
        )
        #expect(
            dataImport.metadata.deviceBrand
            == fileImport.metadata.deviceBrand
        )
        #expect(
            dataImport.metadata.deviceModel
            == fileImport.metadata.deviceModel
        )
        #expect(
            dataImport.image.photoMemoSize
            == fileImport.image.photoMemoSize
        )
        #expect(
            dataImport.sourceProperties[kCGImagePropertyPixelWidth] as? Int
            == fileImport.sourceProperties[kCGImagePropertyPixelWidth] as? Int
        )
        #expect(
            dataImport.sourceProperties[kCGImagePropertyPixelHeight] as? Int
            == fileImport.sourceProperties[kCGImagePropertyPixelHeight] as? Int
        )
    }

    @Test("Builds canonical media asset and preview representation for RAW-like files")
    func buildsCanonicalMediaAssetAndPreviewRepresentationForRAWLikeFiles() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let temporaryDirectory =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoImportServiceMediaAssetTests-\(UUID().uuidString)",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let rawLikeURL =
            temporaryDirectory
            .appendingPathComponent("IMG_9001")
            .appendingPathExtension("DNG")

        try FileManager.default.copyItem(
            at: sourceURL,
            to: rawLikeURL
        )

        let dngType =
            try #require(
                UTType(filenameExtension: "dng")
            )
        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(
                from: rawLikeURL,
                sourceInfo:
                    PhotoSourceInfo(
                        originalFileName:
                            rawLikeURL.lastPathComponent,
                        assetLocalIdentifier:
                            "asset-raw-9001",
                        contentTypeIdentifier:
                            dngType.identifier
                    )
            )

        #expect(
            importedPhoto.mediaAsset.fileURL
            == rawLikeURL
        )
        #expect(
            importedPhoto.mediaAsset.contentType?.identifier
            == dngType.identifier
        )
        #expect(
            importedPhoto.mediaAsset.isRAW
        )
        #expect(
            !importedPhoto.mediaAsset.isLivePhoto
        )
        #expect(
            importedPhoto.mediaAsset.sourceIdentifier
            == "asset-raw-9001"
        )
        #expect(
            importedPhoto.mediaAsset.pixelSize?.width
            == importedPhoto.sourceProperties[
                kCGImagePropertyPixelWidth
            ] as? Int
        )
        #expect(
            importedPhoto.mediaAsset.pixelSize?.height
            == importedPhoto.sourceProperties[
                kCGImagePropertyPixelHeight
            ] as? Int
        )

        let previewRepresentation =
            try #require(
                importedPhoto.previewRepresentation
            )

        #expect(
            previewRepresentation.kind
            == .preview
        )
        #expect(
            previewRepresentation.decodePurpose
            == .preview
        )
        #expect(
            previewRepresentation.asset.fileURL
            == rawLikeURL
        )
        #expect(
            previewRepresentation.maxPixelDimension
            == PhotoProcessingInputPolicy.standard.maximumPixelDimension
        )
        #expect(
            (previewRepresentation.pixelSize?.longSide ?? 0)
            <= PhotoProcessingInputPolicy.standard.maximumPixelDimension
        )

        let report =
            importedPhoto.importReport

        #expect(report.fileName == "IMG_9001.DNG")
        #expect(report.contentTypeIdentifier == dngType.identifier)
        #expect(report.pixelSize == importedPhoto.mediaAsset.pixelSize)
        #expect(report.isRAW)
        #expect(!report.isLivePhoto)
        #expect(report.memoryTier == .normal)
        #expect(report.requiresExtendedPreviewPreparation)
        #expect(report.representationKind == .preview)
        #expect(report.decodePurpose == .preview)
        #expect(
            report.representationPixelSize
            == previewRepresentation.pixelSize
        )
        #expect(
            report.representationMaxPixelDimension
            == PhotoProcessingInputPolicy.standard.maximumPixelDimension
        )
        #expect(!report.isRepresentationDownsampled)

        let encodedReport =
            try JSONEncoder().encode(report)
        let decodedReport =
            try JSONDecoder().decode(
                MediaImportReport.self,
                from: encodedReport
            )

        #expect(decodedReport == report)
    }

    @Test("Removes narrow black left edge artifact while preserving size")
    func removesNarrowBlackLeftEdgeArtifact() throws {

        let sourceImage =
            PlatformImage.photoMemoImage(
                cgImage:
                    try makeSyntheticEdgeArtifactImage(
                        width: 400,
                        height: 640,
                        blackWidth: 6
                    )
            )

        let correctedImage =
            sourceImage
            .removingPhotoMemoLeftEdgeArtifact()

        #expect(
            correctedImage.photoMemoSize
            == sourceImage.photoMemoSize
        )

        let correctedCGImage =
            try #require(
                cgImage(
                    from: correctedImage
                )
            )
        let leftPixel =
            try pixel(
                in: correctedCGImage,
                x: 0,
                y: 0
            )

        #expect(
            max(
                leftPixel.red,
                leftPixel.green,
                leftPixel.blue
            ) > 45
        )
    }

    @Test("Removes wider portrait black left edge artifact while preserving size")
    func removesWiderPortraitBlackLeftEdgeArtifact() throws {

        let sourceImage =
            PlatformImage.photoMemoImage(
                cgImage:
                    try makeSyntheticEdgeArtifactImage(
                        width: 4_536,
                        height: 806,
                        blackWidth: 122
                    )
            )

        let correctedImage =
            sourceImage
            .removingPhotoMemoLeftEdgeArtifact()

        #expect(
            correctedImage.photoMemoSize
            == sourceImage.photoMemoSize
        )

        let correctedCGImage =
            try #require(
                cgImage(
                    from: correctedImage
                )
            )
        let leftPixel =
            try pixel(
                in: correctedCGImage,
                x: 0,
                y: 0
            )

        #expect(
            max(
                leftPixel.red,
                leftPixel.green,
                leftPixel.blue
            ) > 45
        )
    }

    @Test("Corrects rendered photo area edge without changing information bar")
    func correctsRenderedPhotoAreaEdgeWithoutChangingInformationBar() throws {

        let renderedImage =
            try makeSyntheticRenderedImage(
                width: 400,
                photoHeight: 640,
                barHeight: 80,
                blackWidth: 6
            )

        let correctedImage =
            PhotoMemoRenderedImageArtifactGuard
            .removingLeftPhotoEdgeArtifact(
                from: renderedImage,
                photoHeight: 640
            )

        #expect(correctedImage.width == renderedImage.width)
        #expect(correctedImage.height == renderedImage.height)

        let photoLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 0
            )
        let barLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 700
            )

        #expect(
            max(
                photoLeftPixel.red,
                photoLeftPixel.green,
                photoLeftPixel.blue
            ) > 45
        )
        #expect(barLeftPixel.red > 230)
        #expect(barLeftPixel.green > 230)
        #expect(barLeftPixel.blue > 230)
    }

    @Test("Corrects wider portrait rendered photo edge artifact")
    func correctsWiderPortraitRenderedPhotoEdgeArtifact() throws {

        let renderedImage =
            try makeSyntheticRenderedImage(
                width: 4_536,
                photoHeight: 806,
                barHeight: 75,
                blackWidth: 122
            )
        let originalPhotoLeftPixel =
            try pixel(
                in: renderedImage,
                x: 0,
                y: 0
            )

        #expect(
            max(
                originalPhotoLeftPixel.red,
                originalPhotoLeftPixel.green,
                originalPhotoLeftPixel.blue
            ) <= 24
        )
        #expect(
            PhotoMemoRenderedImageArtifactGuard
                .leftPhotoEdgeArtifactWidth(
                    in: renderedImage,
                    photoHeight: 806
                ) == 122
        )

        let correctedImage =
            PhotoMemoRenderedImageArtifactGuard
            .removingLeftPhotoEdgeArtifact(
                from: renderedImage,
                photoHeight: 806
            )

        #expect(correctedImage.width == renderedImage.width)
        #expect(correctedImage.height == renderedImage.height)

        let photoLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 0
            )
        let barLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 850
            )

        #expect(
            max(
                photoLeftPixel.red,
                photoLeftPixel.green,
                photoLeftPixel.blue
            ) > 45
        )
        #expect(barLeftPixel.red > 230)
        #expect(barLeftPixel.green > 230)
        #expect(barLeftPixel.blue > 230)
    }

    @Test("Replacing rendered photo area preserves original right edge")
    func replacingRenderedPhotoAreaPreservesOriginalRightEdge() throws {

        let sourceImage =
            try makeSyntheticHorizontalGradientImage(
                width: 4_536,
                height: 806
            )
        let renderedImage =
            try makeSyntheticShiftedRenderedImage(
                sourceImage: sourceImage,
                barHeight: 75,
                blackWidth: 122
            )

        let shiftedRightPixel =
            try pixel(
                in: renderedImage,
                x: renderedImage.width - 1,
                y: 0
            )

        #expect(shiftedRightPixel.red < 252)

        let correctedImage =
            PhotoMemoRenderedImageArtifactGuard
            .replacingPhotoArea(
                in: renderedImage,
                with: sourceImage,
                photoHeight: 806
            )

        let correctedLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 0
            )
        let correctedRightPixel =
            try pixel(
                in: correctedImage,
                x: correctedImage.width - 1,
                y: 0
            )
        let barLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 850
            )

        #expect(correctedLeftPixel.green == 100)
        #expect(correctedRightPixel.red > 252)
        #expect(correctedRightPixel.green == 100)
        #expect(barLeftPixel.red > 230)
        #expect(barLeftPixel.green > 230)
        #expect(barLeftPixel.blue > 230)
    }

    private func makeSyntheticEdgeArtifactImage(
        width: Int,
        height: Int,
        blackWidth: Int
    ) throws -> CGImage {

        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel

                if x < blackWidth {
                    pixels[offset] = 0
                    pixels[offset + 1] = 0
                    pixels[offset + 2] = 0
                } else {
                    pixels[offset] = 120
                    pixels[offset + 1] = 118
                    pixels[offset + 2] = 112
                }

                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        return try #require(
            context.makeImage()
        )
    }

    private func writeSolidJPEG(
        width: Int,
        height: Int,
        to url: URL
    ) throws {

        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel

                pixels[offset] = 94
                pixels[offset + 1] = 111
                pixels[offset + 2] = 126
                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )
        let image =
            try #require(
                context.makeImage()
            )
        let data = NSMutableData()
        let destination =
            try #require(
                CGImageDestinationCreateWithData(
                    data,
                    UTType.jpeg.identifier as CFString,
                    1,
                    nil
                )
            )

        CGImageDestinationAddImage(
            destination,
            image,
            nil
        )
        #expect(
            CGImageDestinationFinalize(
                destination
            )
        )

        try (data as Data).write(
            to: url
        )
    }

    private func makeSyntheticHorizontalGradientImage(
        width: Int,
        height: Int
    ) throws -> CGImage {

        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel
                let red =
                    UInt8(
                        min(
                            255,
                            Int(
                                round(
                                    Double(x)
                                    * 255
                                    / Double(width - 1)
                                )
                            )
                        )
                    )

                pixels[offset] = red
                pixels[offset + 1] = 100
                pixels[offset + 2] = 50
                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        return try #require(
            context.makeImage()
        )
    }

    private func makeSyntheticShiftedRenderedImage(
        sourceImage: CGImage,
        barHeight: Int,
        blackWidth: Int
    ) throws -> CGImage {

        let width = sourceImage.width
        let photoHeight = sourceImage.height
        let height =
            photoHeight + barHeight
        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var sourcePixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * photoHeight
            )
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        let sourceContext =
            try #require(
                CGContext(
                    data: &sourcePixels,
                    width: width,
                    height: photoHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )
        sourceContext.draw(
            sourceImage,
            in:
                CGRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: photoHeight
                )
        )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel

                if y >= photoHeight {
                    pixels[offset] = 244
                    pixels[offset + 1] = 244
                    pixels[offset + 2] = 242
                } else if x < blackWidth {
                    pixels[offset] = 0
                    pixels[offset + 1] = 0
                    pixels[offset + 2] = 0
                } else {
                    let sourceX =
                        min(
                            x - blackWidth,
                            width - 1
                        )
                    let sourceOffset =
                        y * bytesPerRow
                        + sourceX * bytesPerPixel

                    pixels[offset] =
                        sourcePixels[sourceOffset]
                    pixels[offset + 1] =
                        sourcePixels[sourceOffset + 1]
                    pixels[offset + 2] =
                        sourcePixels[sourceOffset + 2]
                }

                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        return try #require(
            context.makeImage()
        )
    }

    private func makeSyntheticRenderedImage(
        width: Int,
        photoHeight: Int,
        barHeight: Int,
        blackWidth: Int
    ) throws -> CGImage {

        let height =
            photoHeight + barHeight
        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel

                if y >= photoHeight {
                    pixels[offset] = 244
                    pixels[offset + 1] = 244
                    pixels[offset + 2] = 242
                } else if x < blackWidth {
                    pixels[offset] = 0
                    pixels[offset + 1] = 0
                    pixels[offset + 2] = 0
                } else {
                    pixels[offset] = 120
                    pixels[offset + 1] = 118
                    pixels[offset + 2] = 112
                }

                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        return try #require(
            context.makeImage()
        )
    }

    private func cgImage(
        from image: PlatformImage
    ) -> CGImage? {

#if os(macOS)
        var proposedRect =
            CGRect(
                origin: .zero,
                size: image.size
            )

        return image.cgImage(
            forProposedRect: &proposedRect,
            context: nil,
            hints: nil
        )
#else
        return image.cgImage
#endif
    }

    private func pixel(
        in image: CGImage,
        x: Int,
        y: Int
    ) throws -> (
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) {

        let bytesPerPixel = 4
        let bytesPerRow =
            image.width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * image.height
            )

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: image.width,
                    height: image.height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        context.draw(
            image,
            in:
                CGRect(
                    x: 0,
                    y: 0,
                    width: image.width,
                    height: image.height
                )
        )

        let offset =
            y * bytesPerRow
            + x * bytesPerPixel

        return (
            pixels[offset],
            pixels[offset + 1],
            pixels[offset + 2]
        )
    }
}

private struct StubLocationMetadataEnricher:
    PhotoLocationMetadataEnriching {

    let transform:
        (PhotoMetadata) -> PhotoMetadata

    func enrichedMetadata(
        _ metadata: PhotoMetadata
    ) async -> PhotoMetadata {

        transform(metadata)
    }
}
