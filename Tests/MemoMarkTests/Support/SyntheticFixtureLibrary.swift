import Foundation
import ImageIO

enum SyntheticFixture: String, CaseIterable {

    case iphoneJPEG = "01_iPhone_JPEG.jpg"
    case iphoneHEIC = "02_iPhone_HEIC.heic"
    case gpsJPEG = "05_GPS.jpg"
    case noGPSJPEG = "06_NoGPS.jpg"
    case portraitJPEG = "07_Portrait.jpg"
    case landscapeJPEG = "08_Landscape.jpg"
    case lowMetadataJPEG = "10_LowMetadata.jpg"
}

enum SyntheticFixtureLibraryError: LocalizedError {

    case missingFixture(URL)

    case unreadableProperties(URL)

    var errorDescription: String? {

        switch self {

        case let .missingFixture(url):
            return "Missing synthetic fixture at \(url.path). Run Tests/Fixtures/GenerateSyntheticFixtures.swift first."

        case let .unreadableProperties(url):
            return "Unable to read image properties for fixture at \(url.path)."
        }
    }
}

enum SyntheticFixtureLibrary {

    static func fixtureURL(
        _ fixture: SyntheticFixture,
        filePath: StaticString = #filePath
    ) throws -> URL {

        let url = fixturesDirectoryURL(
            filePath: filePath
        )
        .appendingPathComponent(
            fixture.rawValue
        )

        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            throw SyntheticFixtureLibraryError
                .missingFixture(url)
        }

        return url
    }

    static func properties(
        at url: URL
    ) throws -> [CFString: Any] {

        guard
            let source = CGImageSourceCreateWithURL(
                url as CFURL,
                nil
            ),
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
            throw SyntheticFixtureLibraryError
                .unreadableProperties(url)
        }

        return properties
    }

    static func fixturesDirectoryURL(
        filePath: StaticString = #filePath
    ) -> URL {

        repositoryRootURL(
            filePath: filePath
        )
        .appendingPathComponent(
            "Tests/Fixtures/Synthetic",
            isDirectory: true
        )
    }

    static func repositoryRootURL(
        filePath: StaticString = #filePath
    ) -> URL {

        URL(fileURLWithPath: "\(filePath)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
