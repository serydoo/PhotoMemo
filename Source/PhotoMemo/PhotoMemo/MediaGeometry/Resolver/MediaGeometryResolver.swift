import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum MediaGeometryResolverError:
    LocalizedError,
    Equatable {

    case imageSourceUnavailable
    case pixelSizeUnavailable

    var errorDescription: String? {
        switch self {
        case .imageSourceUnavailable:
            return "Unable to create an image source for geometry resolution."
        case .pixelSizeUnavailable:
            return "Unable to read source image pixel dimensions."
        }
    }
}

struct MediaGeometryResolver:
    Sendable {

    static let standard =
        MediaGeometryResolver()

    private let footerHeightRatio:
        CGFloat

    init(
        footerHeightRatio: CGFloat = 0.0863
    ) {
        self.footerHeightRatio =
            footerHeightRatio
    }

    func resolve(
        fileURL: URL,
        contentType: UTType? = nil
    ) throws -> CanonicalGeometry {
        guard
            let source =
                CGImageSourceCreateWithURL(
                    fileURL as CFURL,
                    nil
                )
        else {
            throw MediaGeometryResolverError
                .imageSourceUnavailable
        }

        let properties =
            CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
            ) as? [CFString: Any] ?? [:]

        guard
            let rawPixelSize =
                Self.rawPixelSize(
                    from: properties
                )
        else {
            throw MediaGeometryResolverError
                .pixelSizeUnavailable
        }

        let orientation =
            MediaGeometryOrientation(
                rawImageIOValue:
                    Self.orientationRawValue(
                        from: properties
                    )
            )
        let displaySize =
            Self.displaySize(
                rawPixelSize:
                    rawPixelSize,
                orientation:
                    orientation
            )
        let footerHeight =
            Self.footerHeight(
                for:
                    displaySize,
                ratio:
                    footerHeightRatio
            )
        let facts =
            MediaGeometryFacts(
                rawPixelSize:
                    rawPixelSize,
                displaySize:
                    displaySize,
                orientation:
                    orientation
            )
        let canvas =
            CanvasGeometry(
                canvasSize:
                    CGSize(
                        width:
                            displaySize
                            .width,
                        height:
                            displaySize
                            .height
                            + footerHeight
                    ),
                photoFrame:
                    CGRect(
                        x: 0,
                        y: 0,
                        width:
                            displaySize
                            .width,
                        height:
                            displaySize
                            .height
                    ),
                footerFrame:
                    CGRect(
                        x: 0,
                        y:
                            displaySize
                            .height,
                        width:
                            displaySize
                            .width,
                        height:
                            footerHeight
                    )
            )

        return CanonicalGeometry(
            facts: facts,
            canvas: canvas
        )
    }
}

private extension MediaGeometryResolver {

    static func rawPixelSize(
        from properties: [CFString: Any]
    ) -> CGSize? {
        guard
            let width =
                integerValue(
                    properties[
                        kCGImagePropertyPixelWidth
                    ]
                ),
            let height =
                integerValue(
                    properties[
                        kCGImagePropertyPixelHeight
                    ]
                ),
            width > 0,
            height > 0
        else {
            return nil
        }

        return CGSize(
            width: width,
            height: height
        )
    }

    static func orientationRawValue(
        from properties: [CFString: Any]
    ) -> Int {
        integerValue(
            properties[
                kCGImagePropertyOrientation
            ]
        )
        ?? 1
    }

    static func integerValue(
        _ value: Any?
    ) -> Int? {
        switch value {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        default:
            return nil
        }
    }

    static func displaySize(
        rawPixelSize: CGSize,
        orientation: MediaGeometryOrientation
    ) -> CGSize {
        if orientation.swapsDisplayAxes {
            return CGSize(
                width:
                    rawPixelSize
                    .height,
                height:
                    rawPixelSize
                    .width
            )
        }

        return rawPixelSize
    }

    static func footerHeight(
        for displaySize: CGSize,
        ratio: CGFloat
    ) -> CGFloat {
        max(
            1,
            ceil(
                displaySize
                .height
                * ratio
            )
        )
    }
}
