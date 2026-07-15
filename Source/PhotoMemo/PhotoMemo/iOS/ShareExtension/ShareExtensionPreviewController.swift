#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit
import UniformTypeIdentifiers

struct ShareExtensionPreviewRequest {
    let inputItems: [NSExtensionItem]
    let limit: Int
}

@MainActor
final class ShareExtensionPreviewController {

    func supportedProviders(
        for request: ShareExtensionPreviewRequest
    ) -> [NSItemProvider] {
        Array(
            request.inputItems
                .flatMap { $0.attachments ?? [] }
                .filter(isSupportedPreviewProvider)
                .prefix(max(request.limit, 1))
        )
    }

    func loadImages(
        from providers: [NSItemProvider]
    ) async -> [UIImage?] {
        var images: [UIImage?] = []
        images.reserveCapacity(providers.count)
        for provider in providers {
            if Task.isCancelled {
                break
            }
            images.append(await loadPreviewImage(from: provider))
        }
        return images
    }

    private func loadPreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {
        if let systemPreview = await loadSystemPreviewImage(from: provider) {
            return systemPreview
        }
        if let filePreview = await loadFilePreviewImage(from: provider) {
            return filePreview
        }
        return await withCheckedContinuation {
            (continuation: CheckedContinuation<UIImage?, Never>) in
            provider.loadItem(
                forTypeIdentifier:
                    preferredPreviewTypeIdentifier(from: provider)
                    ?? UTType.image.identifier,
                options: nil
            ) { item, _ in
                if let url = item as? URL,
                   let image = self.thumbnailImage(from: url) {
                    continuation.resume(returning: image)
                    return
                }
                if let image = item as? UIImage {
                    continuation.resume(returning: image)
                    return
                }
                if let data = item as? Data,
                   let image = self.thumbnailImage(from: data) {
                    continuation.resume(returning: image)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    private func isSupportedPreviewProvider(
        _ provider: NSItemProvider
    ) -> Bool {
        if provider.hasItemConformingToTypeIdentifier(
            UTType.image.identifier
        ) {
            return true
        }
        return PhotoProcessingInputPolicy.supportedImageTypes.contains {
            provider.hasItemConformingToTypeIdentifier($0.identifier)
        }
    }

    private func preferredPreviewTypeIdentifier(
        from provider: NSItemProvider
    ) -> String? {
        provider.registeredTypeIdentifiers
            .compactMap(UTType.init)
            .first { candidate in
                PhotoProcessingInputPolicy.supportedImageTypes.contains {
                    candidate.conforms(to: $0)
                        || candidate.identifier == $0.identifier
                }
                    || candidate.conforms(to: .image)
            }?
            .identifier
    }

    private func loadSystemPreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {
        await withCheckedContinuation {
            (continuation: CheckedContinuation<UIImage?, Never>) in
            provider.loadPreviewImage(
                options: [
                    NSItemProviderPreferredImageSizeKey:
                        CGSize(width: 420, height: 420)
                ]
            ) { item, _ in
                continuation.resume(returning: item as? UIImage)
            }
        }
    }

    private func loadFilePreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {
        guard let typeIdentifier =
            preferredPreviewTypeIdentifier(from: provider)
            ?? PhotoProcessingInputPolicy.supportedImageTypes
                .first(where: {
                    provider.hasItemConformingToTypeIdentifier($0.identifier)
                })?
                .identifier
        else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(
                forTypeIdentifier: typeIdentifier
            ) { url, _ in
                guard let url,
                      let image = self.thumbnailImage(from: url) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }

    nonisolated func thumbnailImage(from url: URL) -> UIImage? {
        MediaDecodeService().thumbnailImage(
            from: url,
            maxPixelDimension: 640
        )
    }

    nonisolated func thumbnailImage(from data: Data) -> UIImage? {
        MediaDecodeService().thumbnailImage(
            from: data,
            maxPixelDimension: 640
        )
    }
}
#endif
