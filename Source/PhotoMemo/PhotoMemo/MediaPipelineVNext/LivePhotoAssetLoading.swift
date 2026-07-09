import Foundation
#if canImport(Photos)
import Photos
#endif

protocol LivePhotoAssetLoading {

    func bundle(
        for assetLocalIdentifier: String
    ) async throws -> LivePhotoAssetBundle

    func exportResources(
        for bundle: LivePhotoAssetBundle,
        to folderURL: URL
    ) async throws -> LivePhotoPreparedAssetBundle
}

protocol LivePhotoAssetResourceProviding {

    func resources(
        for assetLocalIdentifier: String
    ) async throws -> [LivePhotoAssetResourceDescriptor]
}

protocol LivePhotoAssetResourceExporting {

    func exportResource(
        assetLocalIdentifier: String,
        resource: LivePhotoAssetResourceDescriptor,
        toFile targetURL: URL
    ) async throws
}

@MainActor
final class PhotoKitLivePhotoAssetLoader:
    LivePhotoAssetLoading {

    private let resourceProvider:
        any LivePhotoAssetResourceProviding
    private let resourceExporter:
        any LivePhotoAssetResourceExporting
    private let fileManager: FileManager

    init(
        resourceProvider:
            (any LivePhotoAssetResourceProviding)? = nil,
        resourceExporter:
            (any LivePhotoAssetResourceExporting)? = nil,
        fileManager: FileManager = .default
    ) {
        self.resourceProvider =
            resourceProvider
            ?? PhotoKitLivePhotoAssetResourceProvider()
        self.resourceExporter =
            resourceExporter
            ?? PhotoKitLivePhotoAssetResourceExporter()
        self.fileManager = fileManager
    }

    func bundle(
        for assetLocalIdentifier: String
    ) async throws -> LivePhotoAssetBundle {

        let resources =
            try await resourceProvider
            .resources(
                for: assetLocalIdentifier
            )

        guard !resources.isEmpty else {
            throw LivePhotoAssetLoadingError
                .assetNotFound
        }

        guard let stillPhotoResource =
            preferredStillPhotoResource(
                in: resources
            ) else {
            throw LivePhotoAssetLoadingError
                .stillPhotoResourceMissing
        }

        let pairedVideoResourceCandidates =
            preferredPairedVideoResources(
                in: resources
            )

        guard let pairedVideoResource =
            pairedVideoResourceCandidates.first
        else {
            throw LivePhotoAssetLoadingError
                .pairedVideoResourceMissing
        }

        return LivePhotoAssetBundle(
            assetLocalIdentifier:
                assetLocalIdentifier,
            stillPhotoResource:
                stillPhotoResource,
            pairedVideoResource:
                pairedVideoResource,
            pairedVideoResourceCandidates:
                pairedVideoResourceCandidates
        )
    }

    func exportResources(
        for bundle: LivePhotoAssetBundle,
        to folderURL: URL
    ) async throws -> LivePhotoPreparedAssetBundle {

        do {
            try fileManager.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw LivePhotoAssetLoadingError
                .temporaryDirectoryCreateFailed
        }

        let stillPhotoFileURL =
            uniqueResourceURL(
                in: folderURL,
                for:
                    bundle
                    .stillPhotoResource,
                fallbackBaseName:
                    "\(bundle.assetLocalIdentifier)-still",
                fallbackExtension: "heic"
            )
        try await resourceExporter
            .exportResource(
                assetLocalIdentifier:
                    bundle.assetLocalIdentifier,
                resource:
                    bundle.stillPhotoResource,
                toFile:
                    stillPhotoFileURL
            )

        let pairedVideoExport =
            try await exportFirstAvailablePairedVideoResource(
                for: bundle,
                to: folderURL
            )

        return LivePhotoPreparedAssetBundle(
            assetLocalIdentifier:
                bundle.assetLocalIdentifier,
            stillPhotoResource:
                bundle.stillPhotoResource,
            pairedVideoResource:
                pairedVideoExport.resource,
            stillPhotoFileURL:
                stillPhotoFileURL,
            pairedVideoFileURL:
                pairedVideoExport.fileURL
        )
    }
}

private extension PhotoKitLivePhotoAssetLoader {

    func preferredStillPhotoResource(
        in resources: [LivePhotoAssetResourceDescriptor]
    ) -> LivePhotoAssetResourceDescriptor? {

        let preferredKinds:
            [LivePhotoAssetResourceKind] = [
                .fullSizePhoto,
                .photo,
                .alternatePhoto
            ]

        for kind in preferredKinds {
            if let match =
                resources.first(
                    where: {
                        $0.kind == kind
                    }
                ) {
                return match
            }
        }

        return nil
    }

    func preferredPairedVideoResources(
        in resources: [LivePhotoAssetResourceDescriptor]
    ) -> [LivePhotoAssetResourceDescriptor] {

        let preferredKinds:
            [LivePhotoAssetResourceKind] = [
                .fullSizePairedVideo,
                .pairedVideo
            ]

        return preferredKinds.flatMap { kind in
            resources.filter {
                $0.kind == kind
            }
        }
    }

    func exportFirstAvailablePairedVideoResource(
        for bundle: LivePhotoAssetBundle,
        to folderURL: URL
    ) async throws -> (
        resource: LivePhotoAssetResourceDescriptor,
        fileURL: URL
    ) {

        var lastError: Error?

        for resource in bundle.pairedVideoResourceCandidates {
            let fileURL =
                uniqueResourceURL(
                    in: folderURL,
                    for: resource,
                    fallbackBaseName:
                        "\(bundle.assetLocalIdentifier)-paired",
                    fallbackExtension: "mov"
                )

            do {
                try await resourceExporter
                    .exportResource(
                        assetLocalIdentifier:
                            bundle.assetLocalIdentifier,
                        resource:
                            resource,
                        toFile:
                            fileURL
                    )
                return (
                    resource,
                    fileURL
                )
            } catch {
                lastError = error
                try? fileManager.removeItem(
                    at: fileURL
                )
            }
        }

        if let lastError {
            throw lastError
        }

        throw LivePhotoAssetLoadingError
            .pairedVideoResourceMissing
    }

    func uniqueResourceURL(
        in folderURL: URL,
        for resource:
            LivePhotoAssetResourceDescriptor,
        fallbackBaseName: String,
        fallbackExtension: String
    ) -> URL {

        let sanitizedFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                resource.originalFilename
            )

        let baseName =
            sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .deletingPathExtension()
                    .lastPathComponent
            }
            .flatMap { value in
                let trimmed =
                    value.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                return trimmed.isEmpty ? nil : trimmed
            }
            ?? fallbackBaseName

        let fileExtension =
            sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .pathExtension
            }
            .flatMap { value in
                let trimmed =
                    value.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                return trimmed.isEmpty ? nil : trimmed
            }
            ?? fallbackExtension

        var candidateURL =
            folderURL
            .appendingPathComponent(
                baseName
            )
            .appendingPathExtension(
                fileExtension
            )
        var suffix = 1

        while fileManager.fileExists(
            atPath: candidateURL.path
        ) {
            candidateURL =
                folderURL
                .appendingPathComponent(
                    "\(baseName) (\(suffix))"
                )
                .appendingPathExtension(
                    fileExtension
                )
            suffix += 1
        }

        return candidateURL
    }
}

#if canImport(Photos)
struct PhotoKitLivePhotoAssetResourceProvider:
    LivePhotoAssetResourceProviding {

    func resources(
        for assetLocalIdentifier: String
    ) async throws -> [LivePhotoAssetResourceDescriptor] {

        let assets =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    assetLocalIdentifier
                ],
                options: nil
            )

        guard let asset = assets.firstObject else {
            return []
        }

        let resources =
            PHAssetResource.assetResources(
                for: asset
            )

        return resources.enumerated().map {
            index,
            resource in
            LivePhotoAssetResourceDescriptor(
                id: "\(index)",
                kind:
                    livePhotoAssetResourceKind(
                        for:
                            resource.type
                    ),
                originalFilename:
                    resource.originalFilename,
                uniformTypeIdentifier:
                    resource.uniformTypeIdentifier
            )
        }
        .recordedAsObservedResources(
            for:
                assetLocalIdentifier
        )
    }

    private func livePhotoAssetResourceKind(
        for type: PHAssetResourceType
    ) -> LivePhotoAssetResourceKind {

        switch type {
        case .photo:
            return .photo

        case .fullSizePhoto:
            return .fullSizePhoto

        case .alternatePhoto:
            return .alternatePhoto

        case .pairedVideo:
            return .pairedVideo

        case .fullSizePairedVideo:
            return .fullSizePairedVideo

        default:
            return .other(
                String(
                    describing: type.rawValue
                )
            )
        }
    }
}

struct PhotoKitLivePhotoAssetResourceExporter:
    LivePhotoAssetResourceExporting {

    static func exportRequestOptions()
        -> PHAssetResourceRequestOptions {
        let options =
            PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        return options
    }

    func exportResource(
        assetLocalIdentifier: String,
        resource: LivePhotoAssetResourceDescriptor,
        toFile targetURL: URL
    ) async throws {

        let assets =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    assetLocalIdentifier
                ],
                options: nil
            )

        guard let asset = assets.firstObject else {
            throw LivePhotoAssetLoadingError
                .assetNotFound
        }

        let resources =
            PHAssetResource.assetResources(
                for: asset
            )

        guard
            let index =
                Int(resource.id),
            resources.indices.contains(index)
        else {
            throw LivePhotoAssetLoadingError
                .assetNotFound
        }

        try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<Void, Error>
            ) in

            PHAssetResourceManager.default()
                .writeData(
                    for: resources[index],
                    toFile: targetURL,
                    options:
                        Self.exportRequestOptions()
                ) { error in

                    if let error {
                        PhotoMemoShareDiagnostics.record(
                            stage:
                                .livePhotoAssetResourceExportFailed,
                            message:
                                resourceExportFailureMessage(
                                    resource:
                                        resource,
                                    targetURL:
                                        targetURL,
                                    error:
                                        error
                                )
                        )
                        continuation.resume(
                            throwing: error
                        )
                        return
                    }

                    continuation.resume()
                }
        }
    }
}
#endif

private extension Array where Element == LivePhotoAssetResourceDescriptor {

    func recordedAsObservedResources(
        for assetLocalIdentifier: String
    ) -> [LivePhotoAssetResourceDescriptor] {
        let resourceList =
            map(resourceSummary)
            .joined(separator: "|")

        PhotoMemoShareDiagnostics.record(
            stage:
                .livePhotoAssetResourcesObserved,
            message:
                "asset=\(assetLocalIdentifier), resources=\(resourceList)"
        )

        return self
    }
}

private func resourceSummary(
    _ resource:
        LivePhotoAssetResourceDescriptor
) -> String {
    let uti =
        resource.uniformTypeIdentifier
        ?? "unknown"

    return [
        "id:\(resource.id)",
        "kind:\(resource.kind.diagnosticDescription)",
        "file:\(resource.originalFilename)",
        "uti:\(uti)"
    ]
    .joined(separator: ",")
}

private func resourceExportFailureMessage(
    resource:
        LivePhotoAssetResourceDescriptor,
    targetURL: URL,
    error: Error
) -> String {
    let uti =
        resource.uniformTypeIdentifier
        ?? "unknown"
    let nsError =
        error as NSError

    return [
        "id=\(resource.id)",
        "kind=\(resource.kind.diagnosticDescription)",
        "file=\(resource.originalFilename)",
        "uti=\(uti)",
        "target=\(targetURL.lastPathComponent)",
        "error=\(nsError.domain) \(nsError.code): \(error.localizedDescription)"
    ]
    .joined(separator: ", ")
}

private extension LivePhotoAssetResourceKind {

    var diagnosticDescription: String {
        switch self {
        case .photo:
            return "photo"
        case .fullSizePhoto:
            return "fullSizePhoto"
        case .alternatePhoto:
            return "alternatePhoto"
        case .pairedVideo:
            return "pairedVideo"
        case .fullSizePairedVideo:
            return "fullSizePairedVideo"
        case .other(let value):
            return "other(\(value))"
        }
    }
}
