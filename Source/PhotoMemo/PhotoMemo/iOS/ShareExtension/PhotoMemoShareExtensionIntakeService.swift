#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation
import CryptoKit
import UniformTypeIdentifiers
import UIKit

enum PhotoMemoShareExtensionError:
    LocalizedError {

    case noSupportedImages

    case allImportsFailed

    case persistFailed

    var errorDescription: String? {

        switch self {

        case .noSupportedImages:
            return "没有找到可交给 PhotoMemo 的图片。"

        case .allImportsFailed:
            return "这次分享里的图片未能成功写入 PhotoMemo 收件箱。"

        case .persistFailed:
            return "无法把这次分享写入 PhotoMemo 收件箱。"
        }
    }
}

@MainActor
final class PhotoMemoShareExtensionIntakeService {

    private let intakeStore:
        ExternalPhotoIntakeStore

    private let snapshotService:
        SharedBatchConfigurationSnapshotService

    init(
        intakeStore: ExternalPhotoIntakeStore,
        snapshotService:
            SharedBatchConfigurationSnapshotService
    ) {
        self.intakeStore = intakeStore
        self.snapshotService =
            snapshotService
    }

    convenience init() {
        self.init(
            intakeStore: .shared,
            snapshotService:
                SharedBatchConfigurationSnapshotService()
        )
    }

    func persistSharedItems(
        _ items: [NSExtensionItem]
    ) async throws -> PhotoMemoShareExtensionImportResult {

        let providers =
            items.flatMap { item in
                item.attachments ?? []
            }
            .filter {
                $0.hasItemConformingToTypeIdentifier(
                    UTType.image.identifier
                )
            }

        guard !providers.isEmpty else {
            throw PhotoMemoShareExtensionError
                .noSupportedImages
        }

        let requestID = UUID()
        var managedURLs: [URL] = []
        var seenSourceKeys = Set<String>()
        var skippedCount = 0
        var failedCount = 0

        for (
            index,
            provider
        ) in providers.enumerated() {

            let outcome =
                await loadManagedURL(
                    from: provider,
                    requestID: requestID,
                    index: index,
                    seenSourceKeys:
                        &seenSourceKeys
                )

            switch outcome {

            case .imported(let managedURL):
                managedURLs.append(
                    managedURL
                )

            case .skippedDuplicate:
                skippedCount += 1

            case .unsupported:
                failedCount += 1
            }
        }

        guard !managedURLs.isEmpty else {
            if failedCount > 0 {
                throw PhotoMemoShareExtensionError
                    .allImportsFailed
            }

            throw PhotoMemoShareExtensionError
                .noSupportedImages
        }

        let request =
            {
                let importSummary =
                    ExternalPhotoImportSummary(
                        importedCount:
                            managedURLs.count,
                        skippedCount:
                            skippedCount,
                        failedCount:
                            failedCount
                    )

                return intakeStore.persistManagedRequest(
                    id: requestID,
                    urls: managedURLs,
                    source: .shareExtension,
                    importSummary:
                        importSummary,
                    configurationSnapshot:
                        snapshotService
                        .loadSnapshot()
                )
            }()

        guard request != nil else {
            managedURLs.forEach {
                intakeStore
                    .cleanupManagedSourceIfNeeded(
                        at: $0
                    )
            }
            throw PhotoMemoShareExtensionError
                .persistFailed
        }

        return PhotoMemoShareExtensionImportResult(
            summary:
                ExternalPhotoImportSummary(
                    importedCount:
                        managedURLs.count,
                    skippedCount:
                        skippedCount,
                    failedCount:
                        failedCount
                )
        )
    }
}

private extension PhotoMemoShareExtensionIntakeService {

    enum ManagedImportOutcome {

        case imported(URL)

        case skippedDuplicate

        case unsupported
    }

    struct FallbackImportResult {

        let managedURL: URL

        let dedupeKey: String
    }

    func loadManagedURL(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        seenSourceKeys: inout Set<String>
    ) async -> ManagedImportOutcome {

        let fileURL =
            await loadFileURL(
                from: provider
            )

        if let fileURL {
            let sourceKey =
                fileURL.standardizedFileURL.path

            guard
                seenSourceKeys.insert(sourceKey)
                    .inserted
            else {
                return .skippedDuplicate
            }

            guard let managedURL =
                intakeStore.createManagedCopy(
                    from: fileURL,
                    requestID: requestID,
                    index: index
                )
            else {
                return .unsupported
            }

            return .imported(managedURL)
        }

        if let fallbackResult =
            await loadFallbackItem(
                from: provider,
                requestID: requestID,
                index: index
            ) {
            let sourceKey =
                fallbackResult
                .dedupeKey

            guard
                seenSourceKeys.insert(sourceKey)
                    .inserted
            else {
                intakeStore
                    .cleanupManagedSourceIfNeeded(
                        at: fallbackResult
                        .managedURL
                    )
                return .skippedDuplicate
            }

            return .imported(
                fallbackResult.managedURL
            )
        }

        return .unsupported
    }

    func loadFileURL(
        from provider: NSItemProvider
    ) async -> URL? {

        await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<
                        URL?,
                        Never
                    >
            ) in

            provider.loadFileRepresentation(
                forTypeIdentifier:
                    UTType.image.identifier
            ) { url, error in

                guard
                    error == nil,
                    let url
                else {
                    continuation.resume(
                        returning: nil
                    )
                    return
                }

                continuation.resume(
                    returning: url
                )
            }
        }
    }

    func loadFallbackItem(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int
    ) async -> FallbackImportResult? {

        let suggestedName =
            provider.suggestedName

        let preferredExtension =
            preferredFileExtension(
                from:
                    provider
                    .registeredTypeIdentifiers
            )

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<
                        FallbackImportResult?,
                        Never
                    >
            ) in

            provider.loadItem(
                forTypeIdentifier:
                    UTType.image.identifier,
                options: nil
            ) { [intakeStore] item, error in

                if error != nil {
                    continuation.resume(
                        returning:
                            Optional<
                                FallbackImportResult
                            >.none
                    )
                    return
                }

                if let url = item as? URL {
                    let normalizedURL =
                        url.standardizedFileURL

                    guard let managedURL =
                        intakeStore.createManagedCopy(
                            from: normalizedURL,
                            requestID: requestID,
                            index: index
                        )
                    else {
                        continuation.resume(
                            returning: nil
                        )
                        return
                    }

                    continuation.resume(
                        returning: FallbackImportResult(
                            managedURL: managedURL,
                            dedupeKey:
                                "url:\(normalizedURL.path)"
                        )
                    )
                    return
                }

                if let data = item as? Data {
                    guard let managedURL =
                        intakeStore.createManagedCopy(
                            fromData: data,
                            requestID: requestID,
                            index: index,
                            preferredFileExtension:
                                preferredExtension,
                            preferredBaseName:
                                suggestedName
                        )
                    else {
                        continuation.resume(
                            returning: nil
                        )
                        return
                    }

                    continuation.resume(
                        returning: FallbackImportResult(
                            managedURL: managedURL,
                            dedupeKey:
                                Self.dedupeKey(
                                    for: data,
                                    suggestedName:
                                        suggestedName
                                )
                        )
                    )
                    return
                }

                continuation.resume(
                    returning: nil
                )
            }
        }
    }

    func preferredFileExtension(
        from registeredTypeIdentifiers:
            [String]
    ) -> String? {

        let supportedType =
            registeredTypeIdentifiers
            .compactMap(UTType.init)
            .first { type in
                type.conforms(to: .image)
            }

        return supportedType?
            .preferredFilenameExtension
    }

    nonisolated static
    func dedupeKey(
        for data: Data,
        suggestedName: String?
    ) -> String {

        let digest =
            SHA256.hash(data: data)
                .compactMap {
                    String(
                        format: "%02x",
                        $0
                    )
                }
                .joined()

        let normalizedName =
            suggestedName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if normalizedName.isEmpty {
            return "data:\(digest)"
        }

        return "data:\(digest):\(normalizedName)"
    }
}
#endif
