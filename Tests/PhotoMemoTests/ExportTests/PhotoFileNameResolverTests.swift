import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoFileNameResolver")
struct PhotoFileNameResolverTests {

    @Test("Rejects system photo-library placeholder variants")
    func rejectsSystemPhotoLibraryPlaceholderVariants() {

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "Photo Library"
            ) == nil
        )

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "Photo Library.JPG"
            ) == nil
        )

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "Photo Library 2.jpeg"
            ) == nil
        )

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "MemoMark Import.JPG"
            ) == nil
        )

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "MemoMark Import (1).JPG"
            ) == nil
        )

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "FullSizeRender.jpeg"
            ) == "FullSizeRender.jpeg"
        )

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "FullSizeRender.mov"
            ) == "FullSizeRender.mov"
        )

        #expect(
            PhotoFileNameResolver
            .isPhotoKitInternalResourceFileName(
                "FullSizeRender.jpeg"
            )
        )

        #expect(
            !PhotoFileNameResolver
            .isPhotoKitInternalResourceFileName(
                "IMG_1164.JPG"
            )
        )
    }

    @Test("Preserves real camera file names")
    func preservesRealCameraFileNames() {

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "IMG_9558.HEIC"
            ) == "IMG_9558.HEIC"
        )

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "IMG_7065.JPEG"
            ) == "IMG_7065.JPEG"
        )
    }

    @Test("Builds a stable timestamp fallback base name when only placeholder names exist")
    func buildsStableTimestampFallbackBaseNameWhenOnlyPlaceholderNamesExist() throws {

        var calendar =
            Calendar(identifier: .gregorian)
        calendar.timeZone =
            try #require(
                TimeZone(
                    secondsFromGMT:
                        8 * 60 * 60
                )
            )

        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 20,
                        hour: 9,
                        minute: 8,
                        second: 19
                    )
                )
            )

        #expect(
            PhotoFileNameResolver
            .outputBaseName(
                preferredOriginalFileName:
                    "MemoMark Import.JPG",
                captureDate: captureDate,
                timeZone: calendar.timeZone
            ) == "IMG_20260620_090819"
        )
    }

    @Test("Builds MemoMark output copy names without spaces")
    func buildsMemoMarkOutputCopyNamesWithoutSpaces() {

        #expect(
            PhotoFileNameResolver
            .outputCopyBaseName(
                from: "IMG_1234",
                index: 1
            ) == "IMG_1234(1)"
        )

        #expect(
            PhotoFileNameResolver
            .outputCopyBaseName(
                from: " IMG_1234 ",
                index: 2
            ) == "IMG_1234(2)"
        )

        #expect(
            PhotoFileNameResolver
            .outputCopyBaseName(
                from: "",
                index: 0
            ) == "MemoMark(1)"
        )
    }

    @Test("Finds next MemoMark output copy name")
    func findsNextMemoMarkOutputCopyName() {

        let existingNames: Set<String> = [
            "IMG_1234(1)",
            "IMG_1234(2)"
        ]

        #expect(
            PhotoFileNameResolver
            .nextOutputCopyBaseName(
                from: "IMG_1234",
                exists: existingNames.contains
            ) == "IMG_1234(3)"
        )
    }

    @Test("Continues MemoMark output copy names without nesting suffixes")
    func continuesMemoMarkOutputCopyNamesWithoutNestingSuffixes() {

        let existingNames: Set<String> = [
            "IMG_1234(1)"
        ]

        #expect(
            PhotoFileNameResolver
            .nextOutputCopyBaseName(
                from: "IMG_1234(1)",
                exists: existingNames.contains
            ) == "IMG_1234(2)"
        )
    }

    @MainActor
    @Test("Allocates durable Live Photo copy names from the source base")
    func allocatesDurableLivePhotoCopyNamesFromSourceBase() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo.PhotoFileNameResolverTests.\(UUID().uuidString)",
                isDirectory: true
            )
        let storageURL = rootURL.appendingPathComponent(
            "LivePhotoOutputFilenameSequence.json"
        )
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let firstStore =
            LivePhotoOutputFilenameSequenceStore(
                storageURL: storageURL
            )

        #expect(
            try firstStore.nextOutputBaseName(
                preferredOriginalFileName: "IMG_1164.jpg",
                assetOriginalFileName: "FullSizeRender.jpeg"
            ) == "IMG_1164(1)"
        )
        #expect(
            try firstStore.nextOutputBaseName(
                preferredOriginalFileName: "IMG_1164.jpg",
                assetOriginalFileName: "FullSizeRender.jpeg"
            ) == "IMG_1164(2)"
        )

        let restartedStore =
            LivePhotoOutputFilenameSequenceStore(
                storageURL: storageURL
            )

        #expect(
            try restartedStore.nextOutputBaseName(
                preferredOriginalFileName: "IMG_1164.jpg",
                assetOriginalFileName: "FullSizeRender.jpeg"
            ) == "IMG_1164(3)"
        )
    }

    @MainActor
    @Test("Rejects a corrupt Live Photo filename sequence without reusing names")
    func rejectsCorruptLivePhotoFilenameSequence() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo.PhotoFileNameResolverCorruptTests.\(UUID().uuidString)",
                isDirectory: true
            )
        let storageURL = rootURL.appendingPathComponent(
            "LivePhotoOutputFilenameSequence.json"
        )
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(to: storageURL)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let store = LivePhotoOutputFilenameSequenceStore(
            storageURL: storageURL
        )

        #expect(throws: LivePhotoOutputFilenameSequenceError.self) {
            _ = try store.nextOutputBaseName(
                preferredOriginalFileName: "IMG_1164.jpg"
            )
        }
    }
}
