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
                "PhotoMemo Import.JPG"
            ) == nil
        )

        #expect(
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                "PhotoMemo Import (1).JPG"
            ) == nil
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
                    "PhotoMemo Import.JPG",
                captureDate: captureDate,
                timeZone: calendar.timeZone
            ) == "IMG_20260620_090819"
        )
    }
}
