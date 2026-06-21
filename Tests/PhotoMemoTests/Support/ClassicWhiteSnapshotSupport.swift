import AppKit
import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import Testing
@testable import PhotoMemo

@MainActor
enum ClassicWhiteSnapshotSupport {

    struct Scenario: Hashable {

        struct Palette: Hashable {

            let background: CGColor

            let horizon: CGColor

            let accent: CGColor

            let detail: CGColor
        }

        let name: String

        let photoSize: CGSize

        let leftTop: String

        let leftBottom: String

        let rightTop: String

        let rightBottom: String

        let badge: Badge

        let palette: Palette
    }

    enum SnapshotKind: String {

        case fullCard = "full-card"
    }

    struct ComparisonResult {

        let differingPixelCount: Int

        let totalPixelCount: Int

        let maxChannelDelta: UInt8

        var isMatch: Bool {

            if differingPixelCount == 0 {
                return true
            }

            guard maxChannelDelta <= 1 else {
                return false
            }

            return differenceRatio <= 0.0005
        }

        var differenceRatio: Double {

            guard totalPixelCount > 0 else {
                return 0
            }

            return Double(
                differingPixelCount
            ) / Double(
                totalPixelCount
            )
        }
    }

    static let scenarios: [Scenario] = [
        .init(
            name: "landscape_standard",
            photoSize: CGSize(
                width: 960,
                height: 540
            ),
            leftTop:
                "爸爸手持 iPhone 17 Pro 记录",
            leftBottom:
                "拍摄于 2026.06.21 18:25",
            rightTop:
                "52mm f/1.8 1/125 ISO64",
            rightBottom:
                "兔兔今天 1岁2个月18天",
            badge: .appleClassic,
            palette: .init(
                background: color(
                    red: 0x6E,
                    green: 0x95,
                    blue: 0xB5
                ),
                horizon: color(
                    red: 0xE6,
                    green: 0xC9,
                    blue: 0x9E
                ),
                accent: color(
                    red: 0xBF,
                    green: 0x6B,
                    blue: 0x4C
                ),
                detail: color(
                    red: 0x2D,
                    green: 0x3F,
                    blue: 0x50
                )
            )
        ),
        .init(
            name: "landscape_long_exif",
            photoSize: CGSize(
                width: 960,
                height: 540
            ),
            leftTop:
                "妈妈手持 FUJIFILM X100VI 记录",
            leftBottom:
                "拍摄于 2026.10.03 07:42",
            rightTop:
                "35mm f/2.0 1/1600 ISO125 DR400",
            rightBottom:
                "小满今天 3岁4个月12天",
            badge: .family,
            palette: .init(
                background: color(
                    red: 0x85,
                    green: 0xA7,
                    blue: 0x7A
                ),
                horizon: color(
                    red: 0xF2,
                    green: 0xDE,
                    blue: 0xA8
                ),
                accent: color(
                    red: 0x6D,
                    green: 0x4E,
                    blue: 0x43
                ),
                detail: color(
                    red: 0xF9,
                    green: 0xF6,
                    blue: 0xF1
                )
            )
        ),
        .init(
            name: "portrait_standard",
            photoSize: CGSize(
                width: 720,
                height: 1280
            ),
            leftTop:
                "爸爸手持 Leica Q3 记录",
            leftBottom:
                "拍摄于 2026.02.14 09:18",
            rightTop:
                "28mm f/1.7 1/500 ISO100",
            rightBottom:
                "可乐今天 289天",
            badge: .memory,
            palette: .init(
                background: color(
                    red: 0x8B,
                    green: 0x7E,
                    blue: 0xB4
                ),
                horizon: color(
                    red: 0xE9,
                    green: 0xD5,
                    blue: 0xC8
                ),
                accent: color(
                    red: 0xC9,
                    green: 0x8E,
                    blue: 0x7B
                ),
                detail: color(
                    red: 0x2E,
                    green: 0x28,
                    blue: 0x3B
                )
            )
        ),
        .init(
            name: "portrait_long_memory",
            photoSize: CGSize(
                width: 720,
                height: 1280
            ),
            leftTop:
                "家人手持 Nikon Zf 记录",
            leftBottom:
                "拍摄于 2026.12.01 16:08",
            rightTop:
                "40mm f/2.0 1/320 ISO800",
            rightBottom:
                "糖糖今天已经学会主动挥手和认真看向镜头啦",
            badge: .none,
            palette: .init(
                background: color(
                    red: 0x6D,
                    green: 0x8E,
                    blue: 0x8B
                ),
                horizon: color(
                    red: 0xE8,
                    green: 0xE1,
                    blue: 0xCC
                ),
                accent: color(
                    red: 0x8C,
                    green: 0x5A,
                    blue: 0x52
                ),
                detail: color(
                    red: 0xF7,
                    green: 0xF3,
                    blue: 0xEA
                )
            )
        )
    ]

    static func assertMatchesReference(
        scenario: Scenario,
        kind: SnapshotKind = .fullCard,
        filePath: StaticString = #filePath
    ) throws {

        let renderedImage = try renderImage(
            for: scenario,
            kind: kind
        )

        let snapshotDirectory =
            snapshotDirectoryURL(
                filePath: filePath
            )
        let referenceURL =
            snapshotDirectory
            .appendingPathComponent(
                kind.rawValue,
                isDirectory: true
            )
            .appendingPathComponent(
                scenario.name
            )
            .appendingPathExtension("png")

        if snapshotRecordModeEnabled(
            snapshotDirectory: snapshotDirectory
        ) {
            let stagingURL =
                recordingStagingURL(
                    for: scenario,
                    kind: kind
                )

            try writePNG(
                renderedImage,
                to: stagingURL
            )

            Attachment.record(
                renderedImage,
                named:
                    "\(kind.rawValue)-\(scenario.name)",
                as: .png
            )

            try writePNG(
                renderedImage,
                to: referenceURL,
                allowBestEffortFailure: true
            )
            return
        }

        guard FileManager.default.fileExists(
            atPath: referenceURL.path
        ) else {
            throw SnapshotFailure
                .missingReference(
                    referenceURL
                )
        }

        let referenceImage =
            try loadReferenceImage(
                from: referenceURL
            )

        let comparison =
            try compare(
                reference: referenceImage,
                actual: renderedImage
            )

        guard comparison.isMatch else {
            let artifactDirectory =
                diffArtifactsDirectory(
                    for: scenario,
                    kind: kind
                )

            try writePNG(
                referenceImage,
                to: artifactDirectory
                    .appendingPathComponent(
                        "reference.png"
                    )
            )
            try writePNG(
                renderedImage,
                to: artifactDirectory
                    .appendingPathComponent(
                        "actual.png"
                    )
            )
            try writePNG(
                diffImage(
                    reference: referenceImage,
                    actual: renderedImage
                ),
                to: artifactDirectory
                    .appendingPathComponent(
                        "diff.png"
                    )
            )

            throw SnapshotFailure
                .mismatch(
                    referenceURL: referenceURL,
                    artifactDirectory: artifactDirectory,
                    differingPixelCount:
                        comparison
                        .differingPixelCount,
                    totalPixelCount:
                        comparison
                        .totalPixelCount,
                    maxChannelDelta:
                        comparison
                        .maxChannelDelta
                )
        }
    }

    static func snapshotReferenceURL(
        for scenario: Scenario,
        kind: SnapshotKind,
        filePath: StaticString = #filePath
    ) -> URL {

        snapshotDirectoryURL(
            filePath: filePath
        )
        .appendingPathComponent(
            kind.rawValue,
            isDirectory: true
        )
        .appendingPathComponent(
            scenario.name
        )
        .appendingPathExtension("png")
    }

    private static func snapshotRecordModeEnabled(
        snapshotDirectory: URL
    ) -> Bool {

        let value =
            ProcessInfo.processInfo
            .environment[
                "PHOTOMEMO_RECORD_SNAPSHOTS"
            ] ?? ""

        if value == "1" {
            return true
        }

        return FileManager.default.fileExists(
            atPath: snapshotDirectory
                .appendingPathComponent(
                    ".record-mode"
                )
                .path
        )
    }

    private static func renderImage(
        for scenario: Scenario,
        kind: SnapshotKind
    ) throws -> CGImage {

        let card = makeCard(
            for: scenario
        )

        let photoImage = try syntheticPhotoImage(
            size: scenario.photoSize,
            palette: scenario.palette
        )

        let outputSize =
            ClassicWhiteRenderer
            .outputPixelSize(
                for: card.metadata,
                fallbackSize:
                    scenario.photoSize
            )

        let content =
            RecordCardRenderer(
                image: photoImage.swiftUIImage,
                card: card
            )
            .frame(
                width: outputSize.width,
                height: outputSize.height
            )

        let renderer =
            ImageRenderer(
                content: content
            )

        renderer.scale = 1
        renderer.proposedSize = .init(
            outputSize
        )
        renderer.isOpaque = true

        guard let image = renderer.cgImage else {
            throw SnapshotFailure
                .renderFailed(
                    scenario.name
                )
        }

        switch kind {

        case .fullCard:
            return image
        }
    }

    private static func makeCard(
        for scenario: Scenario
    ) -> RecordCard {

        let metadata = PhotoMetadata(
            imageWidth: Int(
                scenario.photoSize.width
            ),
            imageHeight: Int(
                scenario.photoSize.height
            )
        )

        return RecordCard(
            template: Template(
                preset: .template2,
                name: "Classic White Snapshot",
                leftTopArea: area(
                    name: "Left Top",
                    value: scenario.leftTop
                ),
                leftBottomArea: area(
                    name: "Left Bottom",
                    value: scenario.leftBottom
                ),
                rightTopArea: area(
                    name: "Right Top",
                    value: scenario.rightTop
                ),
                rightBottomArea: area(
                    name: "Right Bottom",
                    value: scenario.rightBottom
                ),
                badgeArea: .badge
            ),
            metadata: metadata,
            context: MetadataContext(),
            badge: scenario.badge
        )
    }

    private static func area(
        name: String,
        value: String
    ) -> TemplateArea {

        TemplateArea(
            name: name,
            items: [
                TemplateItem(
                    type: .text,
                    name: name,
                    value: value
                )
            ]
        )
    }

    private static func syntheticPhotoImage(
        size: CGSize,
        palette: Scenario.Palette
    ) throws -> PlatformImage {

        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerRow = width * 4
        let colorSpace =
            CGColorSpaceCreateDeviceRGB()
        let bitmapInfo =
            CGImageAlphaInfo
            .premultipliedLast
            .rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw SnapshotFailure
                .renderFailed(
                    "synthetic-photo-\(width)x\(height)"
                )
        }

        let canvas =
            CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: size.height
            )

        context.setFillColor(
            palette.background
        )
        context.fill(canvas)

        context.setFillColor(
            palette.horizon
        )
        context.fill(
            CGRect(
                x: 0,
                y: size.height * 0.55,
                width: size.width,
                height: size.height * 0.45
            )
        )

        context.setFillColor(
            palette.accent
        )
        context.fill(
            CGRect(
                x: size.width * 0.08,
                y: size.height * 0.16,
                width: size.width * 0.84,
                height: size.height * 0.14
            )
        )

        context.setFillColor(
            palette.detail
        )
        context.fillEllipse(
            in: CGRect(
                x: size.width * 0.12,
                y: size.height * 0.34,
                width: size.width * 0.26,
                height: size.width * 0.26
            )
        )

        context.fill(
            CGRect(
                x: size.width * 0.50,
                y: size.height * 0.20,
                width: size.width * 0.26,
                height: size.height * 0.46
            )
        )

        context.setStrokeColor(
            palette.horizon
        )
        context.setLineWidth(
            max(
                6,
                size.width * 0.008
            )
        )
        context.stroke(
            CGRect(
                x: size.width * 0.58,
                y: size.height * 0.28,
                width: size.width * 0.16,
                height: size.height * 0.28
            )
        )

        guard let cgImage =
            context.makeImage()
        else {
            throw SnapshotFailure
                .renderFailed(
                    "synthetic-photo-\(width)x\(height)"
                )
        }

        return PlatformImage(
            cgImage: cgImage,
            size: size
        )
    }

    private static func loadReferenceImage(
        from url: URL
    ) throws -> CGImage {

        guard
            let source =
                CGImageSourceCreateWithURL(
                    url as CFURL,
                    nil
                ),
            let image =
                CGImageSourceCreateImageAtIndex(
                    source,
                    0,
                    nil
                )
        else {
            throw SnapshotFailure
                .missingReference(url)
        }

        return image
    }

    private static func compare(
        reference: CGImage,
        actual: CGImage
    ) throws -> ComparisonResult {

        guard reference.width == actual.width,
              reference.height == actual.height
        else {
            throw SnapshotFailure
                .sizeMismatch(
                    expected: CGSize(
                        width: reference.width,
                        height: reference.height
                    ),
                    actual: CGSize(
                        width: actual.width,
                        height: actual.height
                    )
                )
        }

        let referenceBytes =
            try rgbaBytes(
                from: reference
            )
        let actualBytes =
            try rgbaBytes(
                from: actual
            )

        var differingPixelCount = 0
        var maxChannelDelta: UInt8 = 0

        for offset in stride(
            from: 0,
            to: referenceBytes.count,
            by: 4
        ) {
            var pixelDiffers = false

            for channel in 0..<4 {
                let referenceValue =
                    referenceBytes[
                        offset + channel
                    ]
                let actualValue =
                    actualBytes[
                        offset + channel
                    ]
                let delta =
                    referenceValue > actualValue
                    ? referenceValue - actualValue
                    : actualValue - referenceValue

                if delta > 0 {
                    pixelDiffers = true
                }

                maxChannelDelta = max(
                    maxChannelDelta,
                    delta
                )
            }

            if pixelDiffers {
                differingPixelCount += 1
            }
        }

        return ComparisonResult(
            differingPixelCount:
                differingPixelCount,
            totalPixelCount:
                reference.width
                * reference.height,
            maxChannelDelta:
                maxChannelDelta
        )
    }

    private static func diffImage(
        reference: CGImage,
        actual: CGImage
    ) -> CGImage {

        let width = reference.width
        let height = reference.height
        let bytesPerRow = width * 4
        let colorSpace =
            CGColorSpaceCreateDeviceRGB()

        let referenceBytes =
            (try? rgbaBytes(
                from: reference
            )) ?? []
        let actualBytes =
            (try? rgbaBytes(
                from: actual
            )) ?? []

        var diffBytes = Data(
            count: referenceBytes.count
        )

        diffBytes.withUnsafeMutableBytes { rawBuffer in
            guard let buffer =
                rawBuffer.baseAddress?
                .assumingMemoryBound(
                    to: UInt8.self
                )
            else {
                return
            }

            for offset in stride(
                from: 0,
                to: referenceBytes.count,
                by: 4
            ) {
                let refR = referenceBytes[offset]
                let refG = referenceBytes[offset + 1]
                let refB = referenceBytes[offset + 2]
                let actR = actualBytes[offset]
                let actG = actualBytes[offset + 1]
                let actB = actualBytes[offset + 2]

                let differs =
                    refR != actR
                    || refG != actG
                    || refB != actB

                if differs {
                    buffer[offset] = 0xFF
                    buffer[offset + 1] = 0x4D
                    buffer[offset + 2] = 0x4D
                    buffer[offset + 3] = 0xFF
                } else {
                    buffer[offset] = UInt8(
                        Double(refR) * 0.25
                    )
                    buffer[offset + 1] = UInt8(
                        Double(refG) * 0.25
                    )
                    buffer[offset + 2] = UInt8(
                        Double(refB) * 0.25
                    )
                    buffer[offset + 3] = 0xFF
                }
            }
        }

        let provider =
            CGDataProvider(
                data: diffBytes as CFData
            )!

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(
                rawValue:
                    CGImageAlphaInfo
                    .premultipliedLast
                    .rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    private static func rgbaBytes(
        from image: CGImage
    ) throws -> [UInt8] {

        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        let colorSpace =
            CGColorSpaceCreateDeviceRGB()

        var bytes = [UInt8](
            repeating: 0,
            count: height * bytesPerRow
        )

        let drawn = bytes.withUnsafeMutableBytes {
            rawBuffer -> Bool in

            guard let baseAddress =
                rawBuffer.baseAddress
            else {
                return false
            }

            guard let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo:
                    CGImageAlphaInfo
                    .premultipliedLast
                    .rawValue
            ) else {
                return false
            }

            context.draw(
                image,
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: height
                )
            )

            return true
        }

        if drawn {
            return bytes
        }

        throw SnapshotFailure
            .renderFailed(
                "rgba-bytes-\(image.width)x\(image.height)"
            )
    }

    private static func writePNG(
        _ image: CGImage,
        to url: URL,
        allowBestEffortFailure: Bool = false
    ) throws {

        do {
            try FileManager.default
                .createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

            let bitmap =
                NSBitmapImageRep(
                    cgImage: image
                )

            guard let data =
                bitmap.representation(
                    using: .png,
                    properties: [:]
                )
            else {
                throw SnapshotFailure
                    .renderFailed(
                        "png-encode-\(url.lastPathComponent)"
                    )
            }

            try data.write(
                to: url,
                options: .atomic
            )

        } catch {

            if allowBestEffortFailure {
                return
            }

            throw error
        }
    }

    private static func diffArtifactsDirectory(
        for scenario: Scenario,
        kind: SnapshotKind
    ) -> URL {

        hostWritableTemporaryDirectory()
            .appendingPathComponent(
                "PhotoMemoSnapshotDiffs",
                isDirectory: true
            )
            .appendingPathComponent(
                "ClassicWhite",
                isDirectory: true
            )
            .appendingPathComponent(
                kind.rawValue,
                isDirectory: true
            )
            .appendingPathComponent(
                scenario.name,
                isDirectory: true
            )
    }

    private static func recordingStagingURL(
        for scenario: Scenario,
        kind: SnapshotKind
    ) -> URL {

        hostWritableTemporaryDirectory()
            .appendingPathComponent(
                "PhotoMemoSnapshotRecordings",
                isDirectory: true
            )
            .appendingPathComponent(
                "ClassicWhite",
                isDirectory: true
            )
            .appendingPathComponent(
                kind.rawValue,
                isDirectory: true
            )
            .appendingPathComponent(
                scenario.name
            )
            .appendingPathExtension("png")
    }

    private static func hostWritableTemporaryDirectory() -> URL {

        FileManager.default
            .temporaryDirectory
    }

    private static func snapshotDirectoryURL(
        filePath: StaticString = #filePath
    ) -> URL {

        repositoryRootURL(
            filePath: filePath
        )
        .appendingPathComponent(
            "Tests/Fixtures/RendererSnapshots/ClassicWhite",
            isDirectory: true
        )
    }

    private static func repositoryRootURL(
        filePath: StaticString = #filePath
    ) -> URL {

        URL(fileURLWithPath: "\(filePath)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func color(
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) -> CGColor {

        CGColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }
}

enum SnapshotFailure: LocalizedError {

    case missingReference(URL)

    case renderFailed(String)

    case sizeMismatch(
        expected: CGSize,
        actual: CGSize
    )

    case mismatch(
        referenceURL: URL,
        artifactDirectory: URL,
        differingPixelCount: Int,
        totalPixelCount: Int,
        maxChannelDelta: UInt8
    )

    var errorDescription: String? {

        switch self {

        case let .missingReference(url):
            return "Missing snapshot reference at \(url.path). Run the tests once with PHOTOMEMO_RECORD_SNAPSHOTS=1 to record the baseline."

        case let .renderFailed(label):
            return "Unable to render snapshot image for \(label)."

        case let .sizeMismatch(
            expected,
            actual
        ):
            return "Snapshot size mismatch. Expected \(Int(expected.width))x\(Int(expected.height)), got \(Int(actual.width))x\(Int(actual.height))."

        case let .mismatch(
            referenceURL,
            artifactDirectory,
            differingPixelCount,
            totalPixelCount,
            maxChannelDelta
        ):
            return """
            Snapshot mismatch against \(referenceURL.lastPathComponent).
            Differing pixels: \(differingPixelCount)/\(totalPixelCount)
            Max channel delta: \(maxChannelDelta)
            Diff artifacts: \(artifactDirectory.path)
            """
        }
    }
}
