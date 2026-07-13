import Foundation
import Testing
@testable import PhotoMemo
#if canImport(Photos)
import Photos
#endif

@MainActor
@Suite("Live Photo asset loader contract")
struct LivePhotoAssetLoaderContractTests {

    @Test("Resolves one still-photo resource and one paired-video resource from a mixed asset resource list")
    func resolvesStillAndPairedVideoResources() async throws {
        let provider = StubLivePhotoAssetResourceProvider(
            resources: [
                .init(
                    id: "alternate",
                    kind: .alternatePhoto,
                    originalFilename: "ALT.HEIC",
                    uniformTypeIdentifier: "public.heic"
                ),
                .init(
                    id: "paired",
                    kind: .pairedVideo,
                    originalFilename: "PAIR.MOV",
                    uniformTypeIdentifier: "com.apple.quicktime-movie"
                ),
                .init(
                    id: "fullsize",
                    kind: .fullSizePhoto,
                    originalFilename: "FULL.HEIC",
                    uniformTypeIdentifier: "public.heic"
                )
            ]
        )
        let exporter = StubLivePhotoAssetResourceExporter()
        let loader = PhotoKitLivePhotoAssetLoader(
            resourceProvider: provider,
            resourceExporter: exporter
        )

        let bundle =
            try await loader.bundle(
                for: "asset-live-1"
            )

        #expect(bundle.assetLocalIdentifier == "asset-live-1")
        #expect(bundle.stillPhotoResource.id == "fullsize")
        #expect(bundle.pairedVideoResource.id == "paired")
    }

    @Test("Rejects a Live Photo asset when the paired video resource is missing")
    func rejectsAssetsMissingPairedVideoResources() async throws {
        let provider = StubLivePhotoAssetResourceProvider(
            resources: [
                .init(
                    id: "still",
                    kind: .photo,
                    originalFilename: "IMG_0001.HEIC",
                    uniformTypeIdentifier: "public.heic"
                )
            ]
        )
        let loader = PhotoKitLivePhotoAssetLoader(
            resourceProvider: provider,
            resourceExporter:
                StubLivePhotoAssetResourceExporter()
        )

        do {
            _ = try await loader.bundle(
                for: "asset-live-2"
            )
            Issue.record(
                "Expected missing paired video resource to be rejected"
            )
        } catch let error as LivePhotoAssetLoadingError {
            #expect(
                error == .pairedVideoResourceMissing
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }

    @Test("Exports both selected resources into managed temporary files")
    func exportsSelectedResourcesIntoManagedTemporaryFiles() async throws {
        let provider = StubLivePhotoAssetResourceProvider(
            resources: [
                .init(
                    id: "still",
                    kind: .photo,
                    originalFilename: "IMG_0002.HEIC",
                    uniformTypeIdentifier: "public.heic"
                ),
                .init(
                    id: "video",
                    kind: .pairedVideo,
                    originalFilename: "IMG_0002.MOV",
                    uniformTypeIdentifier: "com.apple.quicktime-movie"
                )
            ]
        )
        let exporter = StubLivePhotoAssetResourceExporter()
        let loader = PhotoKitLivePhotoAssetLoader(
            resourceProvider: provider,
            resourceExporter: exporter
        )
        let bundle =
            try await loader.bundle(
                for: "asset-live-3"
            )

        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetLoaderContractTests-\(UUID().uuidString)",
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let exportedBundle =
            try await loader.exportResources(
                for: bundle,
                to: temporaryFolder
            )

        #expect(
            FileManager.default.fileExists(
                atPath:
                    exportedBundle.stillPhotoFileURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath:
                    exportedBundle.pairedVideoFileURL.path
            )
        )
        #expect(
            exportedBundle.stillPhotoFileURL
            .lastPathComponent == "IMG_0002.HEIC"
        )
        #expect(
            exportedBundle.pairedVideoFileURL
            .lastPathComponent == "IMG_0002.MOV"
        )

        let exportedTargets =
            exporter.exportedTargets

        #expect(
            exportedTargets.map(\.resource.id)
            == ["still", "video"]
        )
    }

    @Test("Falls back to original paired video when full-size paired video export fails")
    func fallsBackToOriginalPairedVideoWhenFullSizeExportFails() async throws {
        let provider = StubLivePhotoAssetResourceProvider(
            resources: [
                .init(
                    id: "still",
                    kind: .fullSizePhoto,
                    originalFilename: "FullSizeRender.heic",
                    uniformTypeIdentifier: "public.heic"
                ),
                .init(
                    id: "fullSizeVideo",
                    kind: .fullSizePairedVideo,
                    originalFilename: "FullSizeRender.mov",
                    uniformTypeIdentifier: "com.apple.quicktime-movie"
                ),
                .init(
                    id: "originalVideo",
                    kind: .pairedVideo,
                    originalFilename: "IMG_5999.MOV",
                    uniformTypeIdentifier: "com.apple.quicktime-movie"
                )
            ]
        )
        let exporter =
            StubLivePhotoAssetResourceExporter(
                failingResourceIDs: [
                    "fullSizeVideo"
                ]
            )
        let loader = PhotoKitLivePhotoAssetLoader(
            resourceProvider: provider,
            resourceExporter: exporter
        )
        let bundle =
            try await loader.bundle(
                for: "asset-live-4"
            )

        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetLoaderContractTests-\(UUID().uuidString)",
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let exportedBundle =
            try await loader.exportResources(
                for: bundle,
                to: temporaryFolder
            )

        #expect(
            exportedBundle.pairedVideoResource.id == "originalVideo"
        )
        #expect(
            exportedBundle.pairedVideoFileURL
            .lastPathComponent == "IMG_5999.MOV"
        )
        #expect(
            exporter.exportedTargets.map(\.resource.id)
            == [
                "still",
                "fullSizeVideo",
                "originalVideo"
            ]
        )
    }

    @Test("Preserves a FullSizeRender JPEG extension while exporting PhotoKit resources")
    func preservesFullSizeRenderJPEGExtensionDuringResourceExport() async throws {
        let provider = StubLivePhotoAssetResourceProvider(
            resources: [
                .init(
                    id: "still",
                    kind: .fullSizePhoto,
                    originalFilename: "FullSizeRender.jpeg",
                    uniformTypeIdentifier: "public.jpeg"
                ),
                .init(
                    id: "video",
                    kind: .fullSizePairedVideo,
                    originalFilename: "FullSizeRender.mov",
                    uniformTypeIdentifier: "com.apple.quicktime-movie"
                )
            ]
        )
        let exporter = StubLivePhotoAssetResourceExporter()
        let loader = PhotoKitLivePhotoAssetLoader(
            resourceProvider: provider,
            resourceExporter: exporter
        )
        let bundle = try await loader.bundle(
            for: "asset-full-size-render-jpeg"
        )
        let temporaryFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetLoaderFullSizeRenderTests-\(UUID().uuidString)",
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(at: temporaryFolder)
        }

        let exportedBundle = try await loader.exportResources(
            for: bundle,
            to: temporaryFolder
        )

        #expect(
            exportedBundle.stillPhotoFileURL.lastPathComponent
            == "FullSizeRender.jpeg"
        )
        #expect(
            exportedBundle.pairedVideoFileURL.lastPathComponent
            == "FullSizeRender.mov"
        )
    }

    #if canImport(Photos)
    @Test("PhotoKit resource exports allow network access for iCloud-backed Live Photo resources")
    func photoKitResourceExportsAllowNetworkAccess() {
        let options =
            PhotoKitLivePhotoAssetResourceExporter
            .exportRequestOptions()

        #expect(
            options.isNetworkAccessAllowed
        )
    }
    #endif
}

private struct StubLivePhotoAssetResourceProvider:
    LivePhotoAssetResourceProviding {

    let resources: [LivePhotoAssetResourceDescriptor]

    func resources(
        for assetLocalIdentifier: String
    ) async throws -> [LivePhotoAssetResourceDescriptor] {
        resources
    }
}

@MainActor
private final class StubLivePhotoAssetResourceExporter:
    LivePhotoAssetResourceExporting {

    struct ExportTarget:
        Sendable, Hashable {
        let assetLocalIdentifier: String
        let resource:
            LivePhotoAssetResourceDescriptor
        let targetURL: URL
    }

    private(set) var exportedTargets:
        [ExportTarget] = []
    private let failingResourceIDs: Set<String>

    init(
        failingResourceIDs: Set<String> = []
    ) {
        self.failingResourceIDs =
            failingResourceIDs
    }

    func exportResource(
        assetLocalIdentifier: String,
        resource: LivePhotoAssetResourceDescriptor,
        toFile targetURL: URL
    ) async throws {

        exportedTargets.append(
            ExportTarget(
                assetLocalIdentifier:
                    assetLocalIdentifier,
                resource: resource,
                targetURL: targetURL
            )
        )

        if failingResourceIDs.contains(resource.id) {
            throw LivePhotoAssetLoadingError
                .temporaryDirectoryCreateFailed
        }

        let fileContents =
            Data(resource.id.utf8)
        try fileContents.write(
            to: targetURL,
            options: .atomic
        )
    }
}
