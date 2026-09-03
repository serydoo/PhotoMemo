#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class BatchTaskResourceLifecycle {

    private let externalIntakeStore: ExternalPhotoIntakeStore
    private let managedIntakeRootURL: URL
    private let notificationAttachmentsDirectoryURL: URL
    private let historyCoversDirectoryURL: URL

    init(
        externalIntakeStore: ExternalPhotoIntakeStore,
        managedIntakeRootURL: URL =
            MemoMarkSharedContainer.externalIntakeDirectoryURL,
        notificationAttachmentsDirectoryURL: URL =
            MemoMarkSharedContainer.baseDirectoryURL.appendingPathComponent(
                "NotificationAttachments",
                isDirectory: true
            ),
        historyCoversDirectoryURL: URL =
            MemoMarkSharedContainer.baseDirectoryURL.appendingPathComponent(
                "TaskHistoryCovers",
                isDirectory: true
            )
    ) {
        self.externalIntakeStore = externalIntakeStore
        self.managedIntakeRootURL = managedIntakeRootURL
        self.notificationAttachmentsDirectoryURL =
            notificationAttachmentsDirectoryURL
        self.historyCoversDirectoryURL = historyCoversDirectoryURL
    }

    func cleanupTemporaryFile(
        at url: URL?
    ) {
        guard let url else {
            return
        }

        try? FileManager.default.removeItem(at: url)
    }

    func cleanupTemporaryFiles(
        _ urls: [URL]
    ) {
        for url in urls {
            cleanupTemporaryFile(at: url)
        }
    }

    func cleanupManagedSourceIfNeeded(
        at url: URL?
    ) {
        guard let url else {
            return
        }

        externalIntakeStore.cleanupManagedSourceIfNeeded(at: url)
    }

    func canPreserveManagedSourceForRetry(
        at url: URL
    ) -> Bool {
        let normalizedURL = url.standardizedFileURL

        guard MemoMarkPathContainment.contains(
            normalizedURL,
            root: managedIntakeRootURL
        ) else {
            return true
        }

        return FileManager.default.fileExists(
            atPath: normalizedURL.path
        )
    }

    func makeNotificationAttachmentIfNeeded(
        from exportedFileURL: URL,
        taskID: UUID
    ) -> URL? {
        Self.generateNotificationAttachment(
            from: exportedFileURL,
            taskID: taskID,
            directoryURL: notificationAttachmentsDirectoryURL
        )
    }

    /// Generates the notification thumbnail away from the UI actor. The
    /// synchronous method above remains as a compatibility seam for existing
    /// callers and tests, while production queue execution uses this method so
    /// ImageIO decoding/encoding cannot block the main actor.
    func makeNotificationAttachmentOffMainThreadIfNeeded(
        from exportedFileURL: URL,
        taskID: UUID
    ) async -> URL? {
        let directoryURL = notificationAttachmentsDirectoryURL
        return await Task.detached(priority: .utility) {
            Self.generateNotificationAttachment(
                from: exportedFileURL,
                taskID: taskID,
                directoryURL: directoryURL
            )
        }.value
    }

    nonisolated private static func generateNotificationAttachment(
        from exportedFileURL: URL,
        taskID: UUID,
        directoryURL: URL
    ) -> URL? {
        do {
            try MemoMarkSharedContainer.ensureDirectory(
                at: directoryURL
            )
        } catch {
            return nil
        }

        let destinationURL = directoryURL
            .appendingPathComponent(
                "\(taskID.uuidString).jpg",
                isDirectory: false
            )

        try? FileManager.default.removeItem(at: destinationURL)

        guard let source = CGImageSourceCreateWithURL(
            exportedFileURL as CFURL,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceThumbnailMaxPixelSize: 720
                ] as CFDictionary
              ),
              let destination = CGImageDestinationCreateWithURL(
                destinationURL as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
              ) else {
            return nil
        }

        CGImageDestinationAddImage(
            destination,
            thumbnail,
            [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary
        )

        return CGImageDestinationFinalize(destination)
            ? destinationURL
            : nil
    }

    func makeHistoryCoverIfNeeded(
        from exportedFileURL: URL,
        jobID: UUID,
        sourceTaskID: UUID
    ) async -> BatchJobHistoryCover? {
        let directoryURL = historyCoversDirectoryURL
        return await Task.detached(priority: .utility) {
            Self.generateHistoryCover(
                from: exportedFileURL,
                jobID: jobID,
                sourceTaskID: sourceTaskID,
                directoryURL: directoryURL
            )
        }.value
    }

    nonisolated private static func generateHistoryCover(
        from exportedFileURL: URL,
        jobID: UUID,
        sourceTaskID: UUID,
        directoryURL: URL
    ) -> BatchJobHistoryCover? {
        do {
            try MemoMarkSharedContainer.ensureDirectory(
                at: directoryURL
            )
        } catch {
            return nil
        }

        let fileName = "\(jobID.uuidString).jpg"
        let relativePath = "TaskHistoryCovers/\(fileName)"
        let destinationURL = directoryURL
            .appendingPathComponent(fileName)
        let temporaryURL = directoryURL
            .appendingPathComponent(".\(jobID.uuidString)-\(UUID().uuidString).tmp")

        guard let source = CGImageSourceCreateWithURL(
            exportedFileURL as CFURL,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ), let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: 360
            ] as CFDictionary
        ), let destination = CGImageDestinationCreateWithURL(
            temporaryURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            try? FileManager.default.removeItem(at: temporaryURL)
            return nil
        }

        CGImageDestinationAddImage(
            destination,
            thumbnail,
            [kCGImageDestinationLossyCompressionQuality: 0.78] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            try? FileManager.default.removeItem(at: temporaryURL)
            return nil
        }

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                _ = try FileManager.default.replaceItemAt(
                    destinationURL,
                    withItemAt: temporaryURL
                )
            } else {
                try FileManager.default.moveItem(
                    at: temporaryURL,
                    to: destinationURL
                )
            }
        } catch {
            try? FileManager.default.removeItem(at: temporaryURL)
            return nil
        }

        return BatchJobHistoryCover(
            sourceTaskID: sourceTaskID,
            relativePath: relativePath
        )
    }

    nonisolated static func historyCoverURL(
        for cover: BatchJobHistoryCover,
        baseDirectoryURL: URL = MemoMarkSharedContainer.baseDirectoryURL
    ) -> URL? {
        guard BatchJobHistoryCover.isValid(relativePath: cover.relativePath) else {
            return nil
        }
        return baseDirectoryURL.appendingPathComponent(cover.relativePath)
    }

    static func cleanupUnreferencedNotificationAttachments(
        in directoryURL: URL,
        retaining referencedURLs: Set<URL>,
        previouslyUnreferencedURLs: Set<URL>,
        fileManager: FileManager = .default
    ) -> Set<URL> {
        let normalizedDirectoryURL =
            directoryURL.standardizedFileURL
        let normalizedReferencedURLs =
            Set(
                referencedURLs.map {
                    $0.standardizedFileURL
                }
            )
        let normalizedPreviouslyUnreferencedURLs =
            Set(
                previouslyUnreferencedURLs.map {
                    $0.standardizedFileURL
                }
            )

        guard let candidateURLs = try? fileManager
            .contentsOfDirectory(
                at: normalizedDirectoryURL,
                includingPropertiesForKeys: [
                    .isRegularFileKey,
                    .isSymbolicLinkKey
                ],
                options: [
                    .skipsHiddenFiles
                ]
            ) else {
            return []
        }

        var currentUnreferencedURLs:
            Set<URL> = []

        for candidateURL in candidateURLs {
            let normalizedCandidateURL =
                candidateURL.standardizedFileURL

            guard normalizedCandidateURL
                .deletingLastPathComponent()
                == normalizedDirectoryURL,
                  !normalizedReferencedURLs
                    .contains(
                        normalizedCandidateURL
                    ),
                  let resourceValues = try? normalizedCandidateURL
                    .resourceValues(
                        forKeys: [
                            .isRegularFileKey,
                            .isSymbolicLinkKey
                        ]
                    ),
                  resourceValues.isRegularFile == true,
                  resourceValues.isSymbolicLink != true else {
                continue
            }

            currentUnreferencedURLs.insert(
                normalizedCandidateURL
            )

            if normalizedPreviouslyUnreferencedURLs
                .contains(
                    normalizedCandidateURL
                ) {
                try? fileManager.removeItem(
                    at: normalizedCandidateURL
                )
            }
        }

        return currentUnreferencedURLs
    }
}
#endif
