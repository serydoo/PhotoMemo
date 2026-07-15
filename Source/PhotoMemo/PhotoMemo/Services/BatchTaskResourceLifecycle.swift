#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class BatchTaskResourceLifecycle {

    private let coordinator: BatchProcessingCoordinator
    private let externalIntakeStore: ExternalPhotoIntakeStore
    private let managedIntakeRootURL: URL
    private let notificationAttachmentsDirectoryURL: URL

    init(
        coordinator: BatchProcessingCoordinator,
        externalIntakeStore: ExternalPhotoIntakeStore,
        managedIntakeRootURL: URL =
            PhotoMemoSharedContainer.externalIntakeDirectoryURL,
        notificationAttachmentsDirectoryURL: URL =
            PhotoMemoSharedContainer.baseDirectoryURL.appendingPathComponent(
                "NotificationAttachments",
                isDirectory: true
            )
    ) {
        self.coordinator = coordinator
        self.externalIntakeStore = externalIntakeStore
        self.managedIntakeRootURL = managedIntakeRootURL
        self.notificationAttachmentsDirectoryURL =
            notificationAttachmentsDirectoryURL
    }

    func cleanupTemporaryFile(
        at url: URL?
    ) {
        coordinator.cleanupTemporaryFile(at: url)
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

        guard normalizedURL.path.hasPrefix(
            managedIntakeRootURL.standardizedFileURL.path
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
        do {
            try PhotoMemoSharedContainer.ensureDirectory(
                at: notificationAttachmentsDirectoryURL
            )
        } catch {
            return nil
        }

        let destinationURL = notificationAttachmentsDirectoryURL
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
}
#endif
