#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("PhotoImporter file representation")
struct PhotoImporterFileRepresentationTests {

    @Test("copies picked RAW file representations before import")
    func copiesPickedRAWFileRepresentationsBeforeImport() throws {
        let sourceDirectory =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoImporterFileRepresentationTests-\(UUID().uuidString)",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: sourceDirectory
            )
        }

        let sourceURL =
            sourceDirectory
            .appendingPathComponent("IMG_9001")
            .appendingPathExtension("DNG")
        let data =
            Data([0x10, 0x20, 0x30, 0x40])

        try data.write(
            to: sourceURL
        )

        let copiedURL =
            try PhotoImporterFileRepresentationResolver
            .copyTemporaryFileRepresentation(
                from: sourceURL,
                contentType:
                    UTType(filenameExtension: "dng")
            )

        defer {
            try? FileManager.default.removeItem(
                at: copiedURL
            )
        }

        #expect(
            copiedURL.standardizedFileURL
            != sourceURL.standardizedFileURL
        )
        #expect(
            copiedURL.pathExtension.lowercased()
            == "dng"
        )
        #expect(
            try Data(contentsOf: copiedURL)
            == data
        )
    }
}
#endif
