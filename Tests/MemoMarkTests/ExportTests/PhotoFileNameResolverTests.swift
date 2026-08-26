import Foundation
import Testing
@testable import MemoMark

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

    @Test("Builds MemoMark output copy names with Apple-style spacing")
    func buildsMemoMarkOutputCopyNamesWithAppleStyleSpacing() {

        #expect(
            PhotoFileNameResolver
            .outputCopyBaseName(
                from: "IMG_1234",
                index: 1
            ) == "IMG_1234 (1)"
        )

        #expect(
            PhotoFileNameResolver
            .outputCopyBaseName(
                from: " IMG_1234 ",
                index: 2
            ) == "IMG_1234 (2)"
        )

        #expect(
            PhotoFileNameResolver
            .outputCopyBaseName(
                from: "",
                index: 0
            ) == "MemoMark (1)"
        )
    }

    @Test("Finds next MemoMark output copy name")
    func findsNextMemoMarkOutputCopyName() {

        let existingNames: Set<String> = [
            "IMG_1234 (1)",
            "IMG_1234 (2)"
        ]

        #expect(
            PhotoFileNameResolver
            .nextOutputCopyBaseName(
                from: "IMG_1234",
                exists: existingNames.contains
            ) == "IMG_1234 (3)"
        )
    }

    @Test("Continues MemoMark output copy names without nesting suffixes")
    func continuesMemoMarkOutputCopyNamesWithoutNestingSuffixes() {

        let existingNames: Set<String> = [
            "IMG_1234 (1)"
        ]

        #expect(
            PhotoFileNameResolver
            .nextOutputCopyBaseName(
                from: "IMG_1234(1)",
                exists: existingNames.contains
            ) == "IMG_1234 (2)"
        )
    }

    @MainActor
    @Test("Allocates durable Live Photo copy names from the source base")
    func allocatesDurableLivePhotoCopyNamesFromSourceBase() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.PhotoFileNameResolverTests.\(UUID().uuidString)",
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
            try await firstStore.nextOutputBaseName(
                preferredOriginalFileName: "IMG_1164.jpg",
                assetOriginalFileName: "FullSizeRender.jpeg"
            ) == "IMG_1164 (1)"
        )
        #expect(
            try await firstStore.nextOutputBaseName(
                preferredOriginalFileName: "IMG_1164.jpg",
                assetOriginalFileName: "FullSizeRender.jpeg"
            ) == "IMG_1164 (2)"
        )

        let restartedStore =
            LivePhotoOutputFilenameSequenceStore(
                storageURL: storageURL
            )

        #expect(
            try await restartedStore.nextOutputBaseName(
                preferredOriginalFileName: "IMG_1164.jpg",
                assetOriginalFileName: "FullSizeRender.jpeg"
            ) == "IMG_1164 (3)"
        )
    }

    @MainActor
    @Test("Rejects a corrupt Live Photo filename sequence without reusing names")
    func rejectsCorruptLivePhotoFilenameSequence() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.PhotoFileNameResolverCorruptTests.\(UUID().uuidString)",
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

        await #expect(throws: LivePhotoOutputFilenameSequenceError.self) {
            _ = try await store.nextOutputBaseName(
                preferredOriginalFileName: "IMG_1164.jpg"
            )
        }
    }

    @Test("Retains only the most recently used durable filename sequences")
    func reclaimsLeastRecentlyUsedFilenameSequences() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.FilenameSequenceCapacityTests.\(UUID().uuidString)",
                isDirectory: true
            )
        let storageURL = rootURL.appendingPathComponent(
            "LivePhotoOutputFilenameSequence.json"
        )
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let store = LivePhotoOutputFilenameSequenceStore(
            storageURL: storageURL,
            maximumEntryCount: 2
        )

        #expect(
            try await store.nextOutputBaseName(
                from: "IMG_A"
            ) == "IMG_A (1)"
        )
        #expect(
            try await store.nextOutputBaseName(
                from: "IMG_B"
            ) == "IMG_B (1)"
        )
        #expect(
            try await store.nextOutputBaseName(
                from: "IMG_A"
            ) == "IMG_A (2)"
        )
        #expect(
            try await store.nextOutputBaseName(
                from: "IMG_C"
            ) == "IMG_C (1)"
        )

        let reloadedStore = LivePhotoOutputFilenameSequenceStore(
            storageURL: storageURL,
            maximumEntryCount: 2
        )

        #expect(
            try await reloadedStore.nextOutputBaseName(
                from: "IMG_A"
            ) == "IMG_A (3)"
        )
        #expect(
            try await reloadedStore.nextOutputBaseName(
                from: "IMG_B"
            ) == "IMG_B (1)"
        )
    }

    @Test("Migrates legacy filename sequence dictionaries without resetting names")
    func migratesLegacyFilenameSequenceDictionary() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.FilenameSequenceMigrationTests.\(UUID().uuidString)",
                isDirectory: true
            )
        let storageURL = rootURL.appendingPathComponent(
            "LivePhotoOutputFilenameSequence.json"
        )
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(
            ["img_1164": 4]
        ).write(to: storageURL)
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let store = LivePhotoOutputFilenameSequenceStore(
            storageURL: storageURL
        )

        #expect(
            try await store.nextOutputBaseName(
                from: "IMG_1164"
            ) == "IMG_1164 (5)"
        )

        let persistedObject = try #require(
            JSONSerialization.jsonObject(
                with: Data(contentsOf: storageURL)
            ) as? [String: Any]
        )
        #expect(persistedObject["version"] as? Int == 2)
    }

    @Test("Serializes concurrent filename allocations without reusing a suffix")
    func serializesConcurrentFilenameAllocations() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.FilenameSequenceConcurrencyTests.\(UUID().uuidString)",
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let store = LivePhotoOutputFilenameSequenceStore(
            storageURL: rootURL.appendingPathComponent(
                "LivePhotoOutputFilenameSequence.json"
            )
        )
        let allocatedNames = try await withThrowingTaskGroup(
            of: String.self,
            returning: [String].self
        ) { group in
            for _ in 0..<32 {
                group.addTask {
                    try await store.nextOutputBaseName(
                        from: "IMG_Concurrent"
                    )
                }
            }

            var names: [String] = []
            for try await name in group {
                names.append(name)
            }
            return names
        }

        #expect(Set(allocatedNames).count == 32)
        #expect(
            Set(allocatedNames)
            == Set(
                (1...32).map {
                    "IMG_Concurrent (\($0))"
                }
            )
        )
    }

    @MainActor
    @Test("Continues after a copy suffix already present in the source name")
    func continuesAfterExistingSourceCopySuffix() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.ExistingCopySuffixTests.\(UUID().uuidString)",
                isDirectory: true
            )
        let storageURL = rootURL.appendingPathComponent(
            "OutputFilenameSequence.json"
        )
        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let store = LivePhotoOutputFilenameSequenceStore(
            storageURL: storageURL
        )

        #expect(
            try await store.nextOutputBaseName(
                preferredOriginalFileName:
                    "IMG_1164 (4).jpg"
            ) == "IMG_1164 (5)"
        )
    }
}
