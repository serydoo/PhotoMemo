import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("PhotoImportService")
struct PhotoImportServiceTests {

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
                "PhotoMemo Import"
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
}
