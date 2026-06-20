import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct SyntheticFixtureSpec {

    let fileName: String

    let type: UTType

    let width: Int

    let height: Int

    let backgroundColor: NSColor

    let accentColor: NSColor

    let topLevelOrientation: Int?

    let properties: [CFString: Any]
}

enum FixtureWriterError: LocalizedError {

    case destinationCreateFailed(URL)

    case finalizeFailed(URL)

    var errorDescription: String? {

        switch self {

        case let .destinationCreateFailed(url):
            return "Unable to create image destination for \(url.path)."

        case let .finalizeFailed(url):
            return "Unable to finalize image write for \(url.path)."
        }
    }
}

let scriptURL =
    URL(fileURLWithPath: CommandLine
        .arguments[0]
    )
let fixturesDirectoryURL =
    scriptURL
    .deletingLastPathComponent()
    .appendingPathComponent(
        "Synthetic",
        isDirectory: true
    )

try FileManager.default.createDirectory(
    at: fixturesDirectoryURL,
    withIntermediateDirectories: true
)

for fixture in fixtures() {
    try writeFixture(fixture)
    print("wrote \(fixture.fileName)")
}

private func fixtures() -> [SyntheticFixtureSpec] {

    [
        SyntheticFixtureSpec(
            fileName: "01_iPhone_JPEG.jpg",
            type: .jpeg,
            width: 1600,
            height: 1200,
            backgroundColor:
                .systemTeal,
            accentColor:
                .systemPink,
            topLevelOrientation: nil,
            properties:
                standardCameraProperties(
                    captureDate:
                        "2026-06-20T10:30:00+0800",
                    make: "Apple",
                    model: "iPhone 17 Pro",
                    lens:
                        "iPhone 17 Pro back triple camera 24mm f/1.78",
                    iso: 80,
                    aperture: 1.8,
                    exposureTime: 0.004,
                    focalLength: 24,
                    focalLength35mm: 24
                )
        ),
        SyntheticFixtureSpec(
            fileName: "02_iPhone_HEIC.heic",
            type: .heic,
            width: 1600,
            height: 1200,
            backgroundColor:
                .systemBlue,
            accentColor:
                .systemOrange,
            topLevelOrientation: 6,
            properties:
                standardCameraProperties(
                    captureDate:
                        "2026-06-18T07:45:00+0800",
                    make: "Apple",
                    model: "iPhone 17 Pro Max",
                    lens:
                        "iPhone 17 Pro Max back triple camera 120mm f/2.8",
                    iso: 100,
                    aperture: 2.8,
                    exposureTime: 0.002,
                    focalLength: 12,
                    focalLength35mm: 120
                )
        ),
        SyntheticFixtureSpec(
            fileName: "05_GPS.jpg",
            type: .jpeg,
            width: 1500,
            height: 1000,
            backgroundColor:
                .systemGreen,
            accentColor:
                .systemYellow,
            topLevelOrientation: nil,
            properties:
                standardCameraProperties(
                    captureDate:
                        "2026-06-15T18:20:00-0300",
                    make: "Apple",
                    model: "iPhone 17 Pro",
                    lens:
                        "iPhone 17 Pro back triple camera 48mm f/1.8",
                    iso: 125,
                    aperture: 1.8,
                    exposureTime: 0.008,
                    focalLength: 6,
                    focalLength35mm: 48,
                    gps: [
                        kCGImagePropertyGPSLatitude: 34.6037,
                        kCGImagePropertyGPSLatitudeRef:
                            "S",
                        kCGImagePropertyGPSLongitude:
                            58.3816,
                        kCGImagePropertyGPSLongitudeRef:
                            "W",
                        kCGImagePropertyGPSAltitude:
                            25.0,
                        kCGImagePropertyGPSAltitudeRef:
                            0
                    ]
                )
        ),
        SyntheticFixtureSpec(
            fileName: "06_NoGPS.jpg",
            type: .jpeg,
            width: 1400,
            height: 900,
            backgroundColor:
                .systemIndigo,
            accentColor:
                .systemMint,
            topLevelOrientation: nil,
            properties:
                standardCameraProperties(
                    captureDate:
                        "2026-06-14T12:05:00+0100",
                    make: "Apple",
                    model: "iPhone 16 Pro",
                    lens:
                        "iPhone 16 Pro back dual wide camera 26mm f/1.9",
                    iso: 64,
                    aperture: 1.9,
                    exposureTime: 0.001,
                    focalLength: 5.7,
                    focalLength35mm: 26
                )
        ),
        SyntheticFixtureSpec(
            fileName: "07_Portrait.jpg",
            type: .jpeg,
            width: 900,
            height: 1400,
            backgroundColor:
                .systemPurple,
            accentColor:
                .systemRed,
            topLevelOrientation: 6,
            properties:
                standardCameraProperties(
                    captureDate:
                        "2026-06-13T08:10:00+0800",
                    make: "Apple",
                    model: "iPhone 15 Pro",
                    lens:
                        "iPhone 15 Pro back camera 24mm f/1.78",
                    iso: 50,
                    aperture: 1.8,
                    exposureTime: 0.0005,
                    focalLength: 8,
                    focalLength35mm: 24
                )
        ),
        SyntheticFixtureSpec(
            fileName: "08_Landscape.jpg",
            type: .jpeg,
            width: 1400,
            height: 900,
            backgroundColor:
                .systemBrown,
            accentColor:
                .systemCyan,
            topLevelOrientation: 1,
            properties:
                standardCameraProperties(
                    captureDate:
                        "2026-06-12T16:00:00+0800",
                    make: "Apple",
                    model: "iPhone 15 Pro Max",
                    lens:
                        "iPhone 15 Pro Max back camera 35mm f/2.0",
                    iso: 160,
                    aperture: 2.0,
                    exposureTime: 0.016,
                    focalLength: 7,
                    focalLength35mm: 35
                )
        ),
        SyntheticFixtureSpec(
            fileName: "10_LowMetadata.jpg",
            type: .jpeg,
            width: 1024,
            height: 768,
            backgroundColor:
                .systemGray,
            accentColor:
                .white,
            topLevelOrientation: nil,
            properties: [:]
        )
    ]
}

private func writeFixture(
    _ spec: SyntheticFixtureSpec
) throws {

    let outputURL =
        fixturesDirectoryURL
        .appendingPathComponent(
            spec.fileName
        )

    try? FileManager.default.removeItem(
        at: outputURL
    )

    guard let destination =
        CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            spec.type.identifier as CFString,
            1,
            nil
        )
    else {
        throw FixtureWriterError
            .destinationCreateFailed(
                outputURL
            )
    }

    let cgImage =
        makeImage(
            width: spec.width,
            height: spec.height,
            backgroundColor:
                spec.backgroundColor,
            accentColor:
                spec.accentColor
        )

    var properties = spec.properties

    if let orientation =
        spec.topLevelOrientation {
        properties[
            kCGImagePropertyOrientation
        ] = orientation
    }

    CGImageDestinationAddImage(
        destination,
        cgImage,
        properties as CFDictionary
    )

    guard CGImageDestinationFinalize(
        destination
    ) else {
        throw FixtureWriterError
            .finalizeFailed(outputURL)
    }
}

private func makeImage(
    width: Int,
    height: Int,
    backgroundColor: NSColor,
    accentColor: NSColor
) -> CGImage {

    let colorSpace =
        CGColorSpaceCreateDeviceRGB()
    let bitmapInfo =
        CGImageAlphaInfo
        .premultipliedLast
        .rawValue

    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )!

    context.setFillColor(
        backgroundColor.cgColor
    )
    context.fill(
        CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height
        )
    )

    context.setFillColor(
        accentColor.cgColor
    )
    context.fill(
        CGRect(
            x: width / 6,
            y: height / 6,
            width: width * 2 / 3,
            height: height * 2 / 3
        )
    )

    context.setStrokeColor(
        NSColor.white.withAlphaComponent(
            0.8
        ).cgColor
    )
    context.setLineWidth(
        max(CGFloat(width), CGFloat(height))
        / 48
    )
    context.stroke(
        CGRect(
            x: width / 10,
            y: height / 10,
            width: width * 4 / 5,
            height: height * 4 / 5
        )
    )

    return context.makeImage()!
}

private func standardCameraProperties(
    captureDate: String,
    make: String,
    model: String,
    lens: String,
    iso: Int,
    aperture: Double,
    exposureTime: Double,
    focalLength: Double,
    focalLength35mm: Int,
    gps: [CFString: Any]? = nil
) -> [CFString: Any] {

    var properties: [CFString: Any] = [
        kCGImagePropertyTIFFDictionary: [
            kCGImagePropertyTIFFMake: make,
            kCGImagePropertyTIFFModel: model
        ],
        kCGImagePropertyExifDictionary: [
            kCGImagePropertyExifDateTimeOriginal:
                captureDate,
            kCGImagePropertyExifLensModel:
                lens,
            kCGImagePropertyExifISOSpeedRatings:
                [iso],
            kCGImagePropertyExifFNumber:
                aperture,
            kCGImagePropertyExifExposureTime:
                exposureTime,
            kCGImagePropertyExifFocalLength:
                focalLength,
            kCGImagePropertyExifFocalLenIn35mmFilm:
                focalLength35mm
        ]
    ]

    if let gps {
        properties[
            kCGImagePropertyGPSDictionary
        ] = gps
    }

    return properties
}
