import Foundation
import ImageIO
import UniformTypeIdentifiers

struct PhotoProcessingInputPolicy: Hashable {

    enum RejectionReason: String, Hashable, Codable {
        case unsupportedFormat
        case livePhoto
        case missingPixelSize
        case oversizedPixelDimension
        case oversizedPixelCount
        case extremeAspectRatio
    }

    struct Verdict: Hashable {
        let isSupported: Bool
        let reason: RejectionReason?
        let title: String
        let message: String

        nonisolated static let supported = Verdict(
            isSupported: true,
            reason: nil,
            title: "可以处理",
            message: ""
        )
    }

    nonisolated static let standard = PhotoProcessingInputPolicy()

    let maximumPixelDimension: Int
    let maximumPixelCount: Int
    let maximumAspectRatio: Double
    let allowsLivePhoto:
        Bool

    init(
        maximumPixelDimension: Int = 8064,
        maximumPixelCount: Int = 8064 * 6048,
        maximumAspectRatio: Double = 3,
        allowsLivePhoto:
            Bool = false
    ) {
        self.maximumPixelDimension =
            max(maximumPixelDimension, 1)
        self.maximumPixelCount =
            max(maximumPixelCount, 1)
        self.maximumAspectRatio =
            max(maximumAspectRatio, 1)
        self.allowsLivePhoto =
            allowsLivePhoto
    }

    nonisolated func isSupportedContentType(
        _ contentType: UTType?
    ) -> Bool {

        guard let contentType else {
            return false
        }

        if Self.isLivePhotoContentType(contentType) {
            return allowsLivePhoto
        }

        return Self.supportedImageTypes.contains {
            contentType.conforms(to: $0)
        }
    }

    nonisolated func verdict(
        contentType: UTType?,
        pixelWidth: Int?,
        pixelHeight: Int?
    ) -> Verdict {

        guard let contentType else {
            return unsupportedFormatVerdict()
        }

        if Self.isLivePhotoContentType(contentType) {
            guard allowsLivePhoto else {
                return Verdict(
                    isSupported: false,
                    reason: .livePhoto,
                    title: "暂不支持 Live Photo",
                    message: "请先在系统相册中选择静态照片，或将 Live Photo 另存为普通照片后再处理。"
                )
            }

            return Verdict(
                isSupported: true,
                reason: nil,
                title: "可以处理 Live Photo",
                message: ""
            )
        }

        guard isSupportedContentType(contentType) else {
            return unsupportedFormatVerdict()
        }

        guard
            let pixelWidth,
            let pixelHeight,
            pixelWidth > 0,
            pixelHeight > 0
        else {
            return Verdict(
                isSupported: false,
                reason: .missingPixelSize,
                title: "无法读取照片尺寸",
                message: "这张照片的像素尺寸暂时无法识别，请换一张原始照片再试。"
            )
        }

        guard
            pixelWidth <= maximumPixelDimension,
            pixelHeight <= maximumPixelDimension
        else {
            return Verdict(
                isSupported: false,
                reason: .oversizedPixelDimension,
                title: "照片尺寸过大",
                message: "当前版本优先支持 iPhone 标准照片尺寸，单边像素不超过 \(maximumPixelDimension)。"
            )
        }

        guard pixelWidth * pixelHeight <= maximumPixelCount else {
            return Verdict(
                isSupported: false,
                reason: .oversizedPixelCount,
                title: "照片像素过高",
                message: "当前版本优先支持约 48MP 以内的照片，超高像素图片请先导出为标准尺寸。"
            )
        }

        let longSide =
            Double(max(pixelWidth, pixelHeight))
        let shortSide =
            Double(min(pixelWidth, pixelHeight))

        guard shortSide > 0,
              longSide / shortSide <= maximumAspectRatio else {
            return Verdict(
                isSupported: false,
                reason: .extremeAspectRatio,
                title: "暂不支持超长比例图片",
                message: "当前版本适合标准照片比例，暂不处理全景图、长截图或特别细长的图片。"
            )
        }

        return .supported
    }

    nonisolated func verdict(
        fileURL: URL,
        declaredContentTypeIdentifier: String?
    ) -> Verdict {

        let contentType =
            resolvedContentType(
                fileURL: fileURL,
                declaredContentTypeIdentifier:
                    declaredContentTypeIdentifier
            )
        let pixelSize =
            imagePixelSize(from: fileURL)

        return verdict(
            contentType: contentType,
            pixelWidth: pixelSize?.width,
            pixelHeight: pixelSize?.height
        )
    }
}

extension PhotoProcessingInputPolicy {

    nonisolated static let supportedImageTypes: [UTType] = [
        .jpeg,
        .heic,
        .heif,
        .png,
        .tiff
    ] + rawImageTypes

    nonisolated static let rawImageTypes: [UTType] = [
        UTType("public.camera-raw-image"),
        UTType("com.adobe.raw-image"),
        UTType("com.adobe.digital-negative"),
        UTType("com.apple.proraw")
    ]
    .compactMap { $0 }

    nonisolated static func isRawContentType(
        _ contentType: UTType?
    ) -> Bool {

        guard let contentType else {
            return false
        }

        return rawImageTypes.contains {
            contentType.conforms(to: $0)
            || contentType.identifier == $0.identifier
        }
        || rawFileExtensions.contains(
            contentType.preferredFilenameExtension?
                .lowercased() ?? ""
        )
    }

    nonisolated static func isRawFileURL(
        _ fileURL: URL
    ) -> Bool {

        rawFileExtensions.contains(
            fileURL.pathExtension
                .lowercased()
        )
    }

    nonisolated static func isLivePhotoContentType(
        _ contentType: UTType?
    ) -> Bool {

        guard
            let contentType,
            let livePhotoType =
                UTType("com.apple.live-photo")
        else {
            return false
        }

        return contentType.conforms(to: livePhotoType)
            || contentType.identifier
                == livePhotoType.identifier
    }

    nonisolated static let rawFileExtensions: Set<String> = [
        "dng",
        "raw",
        "arw",
        "cr2",
        "cr3",
        "nef",
        "nrw",
        "orf",
        "raf",
        "rw2",
        "rwl",
        "srw",
        "pef"
    ]

    nonisolated static let supportedFormatDescription =
        "JPEG/JPG、HEIC/HEIF、PNG、TIFF、RAW/DNG"
}

private extension PhotoProcessingInputPolicy {

    nonisolated func unsupportedFormatVerdict() -> Verdict {

        Verdict(
            isSupported: false,
            reason: .unsupportedFormat,
            title: "暂不支持这种格式",
            message: "当前版本支持 \(Self.supportedFormatDescription)。GIF、WebP、视频和 Live Photo 暂不处理。"
        )
    }

    nonisolated func resolvedContentType(
        fileURL: URL,
        declaredContentTypeIdentifier: String?
    ) -> UTType? {

        let declaredType =
            declaredContentTypeIdentifier
            .flatMap(UTType.init)

        if let declaredType,
           Self.isLivePhotoContentType(declaredType) {
            return declaredType
        }

        if let declaredType,
           Self.isRawContentType(declaredType) {
            return declaredType
        }

        if let declaredType,
           Self.supportedImageTypes.contains(where: {
               declaredType.conforms(to: $0)
           }) {
            return declaredType
        }

        let extensionType = UTType(
            filenameExtension:
                fileURL.pathExtension
                .lowercased()
        )

        if let extensionType,
           Self.isRawContentType(extensionType) {
            return extensionType
        }

        return extensionType ?? declaredType
    }

    nonisolated func imagePixelSize(
        from fileURL: URL
    ) -> (width: Int, height: Int)? {

        guard
            let source =
                CGImageSourceCreateWithURL(
                    fileURL as CFURL,
                    nil
                ),
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
            return nil
        }

        guard
            let width =
                properties[
                    kCGImagePropertyPixelWidth
                ] as? Int,
            let height =
                properties[
                    kCGImagePropertyPixelHeight
                ] as? Int
        else {
            return nil
        }

        return (width, height)
    }
}
