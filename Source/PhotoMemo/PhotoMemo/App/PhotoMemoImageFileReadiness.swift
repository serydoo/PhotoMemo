import Foundation
import ImageIO

enum PhotoMemoImageFileReadiness {

    struct ProbeResult:
        Hashable {

        let isFileURL: Bool

        let isReadableImage: Bool

        let isUbiquitousItem: Bool

        let ubiquitousDownloadStatus: String?

        nonisolated var shouldDisplayPreparationState: Bool {
            guard isFileURL else {
                return false
            }

            if !isReadableImage {
                return true
            }

            guard isUbiquitousItem,
                  let ubiquitousDownloadStatus else {
                return false
            }

            return ubiquitousDownloadStatus
                != URLUbiquitousItemDownloadingStatus
                .current
                .rawValue
        }

        nonisolated var diagnosticMessage: String {
            [
                "readable=\(isReadableImage)",
                "ubiquitous=\(isUbiquitousItem)",
                "downloadStatus=\(ubiquitousDownloadStatus ?? "none")"
            ]
            .joined(separator: ", ")
        }
    }

    nonisolated static func probe(
        at url: URL
    ) -> ProbeResult {

        let values =
            try? url.resourceValues(
                forKeys: [
                    .isUbiquitousItemKey,
                    .ubiquitousItemDownloadingStatusKey
                ]
            )

        return ProbeResult(
            isFileURL: url.isFileURL,
            isReadableImage:
                isExistingReadableImageFile(
                    at: url
                ),
            isUbiquitousItem:
                values?.isUbiquitousItem == true,
            ubiquitousDownloadStatus:
                values?
                .ubiquitousItemDownloadingStatus?
                .rawValue
        )
    }

    nonisolated static func isExistingReadableImageFile(
        at url: URL
    ) -> Bool {

        guard url.isFileURL,
              stablePositiveFileSize(
                at: url
              ) != nil else {
            return false
        }

        return imageSourceIsReadable(
            at: url
        )
    }

    nonisolated static func waitForReadableImageFile(
        at url: URL,
        timeout: TimeInterval = 4,
        pollInterval: TimeInterval = 0.15
    ) -> Bool {

        guard url.isFileURL else {
            return false
        }

        requestUbiquitousDownloadIfNeeded(
            at: url
        )

        let deadline =
            Date().addingTimeInterval(
                timeout
            )
        var previousSize: Int64?

        repeat {
            let currentSize =
                stablePositiveFileSize(
                    at: url
                )

            if let currentSize,
               currentSize == previousSize,
               imageSourceIsReadable(
                   at: url
               ) {
                return true
            }

            previousSize = currentSize

            if Date() >= deadline {
                break
            }

            Thread.sleep(
                forTimeInterval:
                    max(
                        pollInterval,
                        0.02
                    )
            )
        } while true

        return isExistingReadableImageFile(
            at: url
        )
    }
}

private extension PhotoMemoImageFileReadiness {

    nonisolated static func stablePositiveFileSize(
        at url: URL
    ) -> Int64? {

        guard
            let size =
                try? FileManager.default
                .attributesOfItem(
                    atPath:
                        url.standardizedFileURL
                        .path
                )[.size] as? NSNumber
        else {
            return nil
        }

        let byteCount =
            size.int64Value

        return byteCount > 0
            ? byteCount
            : nil
    }

    nonisolated static func imageSourceIsReadable(
        at url: URL
    ) -> Bool {

        guard
            let source =
                CGImageSourceCreateWithURL(
                    url as CFURL,
                    [
                        kCGImageSourceShouldCache:
                            false
                    ] as CFDictionary
                ),
            CGImageSourceGetCount(
                source
            ) > 0,
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
            return false
        }

        let width =
            properties[
                kCGImagePropertyPixelWidth
            ] as? Int
        let height =
            properties[
                kCGImagePropertyPixelHeight
            ] as? Int

        return (width ?? 0) > 0
            && (height ?? 0) > 0
    }

    nonisolated static func requestUbiquitousDownloadIfNeeded(
        at url: URL
    ) {

        guard
            let values =
                try? url.resourceValues(
                    forKeys: [
                        .isUbiquitousItemKey,
                        .ubiquitousItemDownloadingStatusKey
                    ]
                ),
            values.isUbiquitousItem == true
        else {
            return
        }

        _ = try? FileManager.default
            .startDownloadingUbiquitousItem(
                at: url
            )
    }
}
