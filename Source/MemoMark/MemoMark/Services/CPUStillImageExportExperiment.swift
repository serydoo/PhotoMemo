#if DEBUG
import CoreGraphics
import CoreImage
import Foundation
import UniformTypeIdentifiers
#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import os
#endif

/// Signed-device experiment consuming the existing renderer artifact.
/// CPU memoryLimit constrains Core Image render tasks, not total process RSS.
@MainActor
enum CPUStillImageExportExperiment {
    static func export(photo: SelectedPhoto, artifact: PresentationArtifact,
                       to url: URL, writer: MetadataPreservingImageWriter,
                       exportDescription: String) throws -> URL {
        guard UTType(filenameExtension: url.pathExtension)?.conforms(to: .jpeg) == true else {
            throw RecordCardExportError.renderFailed
        }
        let canvas = try recipe(sourceURL: photo.sourceURL, artifact: artifact, writer: writer)
        record("extension.cpuExport.beforeFileWrite")
        let output = try writer.writeCPUJPEG(image: canvas, to: url,
            sourceProperties: photo.sourceProperties, exportDescription: exportDescription,
            captureDate: photo.metadata.captureDate)
        record("extension.cpuExport.fileWritten")
        return output
    }

    static func recipe(sourceURL: URL, artifact: PresentationArtifact,
                       writer: MetadataPreservingImageWriter) throws -> CIImage {
        guard let source = CIImage(contentsOf: sourceURL,
            options: [.applyOrientationProperty: true, .cacheImmediately: false]) else {
            throw RecordCardExportError.renderFailed
        }
        let bounds = CGRect(origin: .zero, size: artifact.canvasSize)
        let frame = artifact.photoFrame
        guard source.extent.width > 0, source.extent.height > 0,
              frame.width > 0, frame.height > 0 else {
            throw RecordCardExportError.renderFailed
        }
        let scale = max(frame.width / source.extent.width, frame.height / source.extent.height)
        let scaled = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let positioned = scaled.transformed(by: CGAffineTransform(
            translationX: frame.midX - scaled.extent.midX,
            y: frame.midY - scaled.extent.midY)).cropped(to: frame)
        let background = CIImage(color: artifact.canvasBackground == .opaqueWhite ? .white : .clear)
            .cropped(to: bounds)
        var canvas = positioned.composited(over: background).cropped(to: bounds)
        if let material = artifact.backdropMaterial {
            // Retain surrounding photo pixels for the native material sampling
            // without creating a full-canvas SwiftUI raster.
            let padding = max(material.cornerRadius * 2, 64)
            let region = material.renderFrame.insetBy(dx: -padding, dy: -padding)
                .intersection(bounds).integral.intersection(bounds)
            record("extension.cpuExport.beforeRegion")
            guard let regionImage = writer.renderCPURegion(image: canvas, bounds: region) else {
                throw RecordCardExportError.renderFailed
            }
            record("extension.cpuExport.regionRendered")
            guard let patch = NativeBackdropMaterialRenderer.renderRegion(
                    sourceRegion: regionImage, regionFrame: region, material: material) else {
                throw RecordCardExportError.renderFailed
            }
            record("extension.cpuExport.materialReady")
            canvas = positionedLayer(patch, frame: material.renderFrame, opacity: 1)
                .composited(over: canvas)
        }
        for layer in artifact.layers.sorted(by: { $0.zIndex < $1.zIndex }) where layer.opacity > 0 {
            canvas = positionedLayer(layer.image, frame: layer.frame, opacity: layer.opacity)
                .composited(over: canvas)
        }
        return canvas.cropped(to: bounds)
    }

    private static func positionedLayer(_ image: CGImage, frame: CGRect, opacity: CGFloat) -> CIImage {
        CIImage(cgImage: image)
            .applyingFilter("CIColorMatrix", parameters: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: opacity)])
            .transformed(by: CGAffineTransform(scaleX: frame.width / CGFloat(image.width),
                y: frame.height / CGFloat(image.height)))
            .transformed(by: CGAffineTransform(translationX: frame.minX, y: frame.minY))
    }

    private static func record(_ event: String) {
#if os(iOS) && MEMOMARK_SHARE_EXTENSION
        MemoMarkBackgroundProbe.record(event, detail: "availableMemory=\(os_proc_available_memory())")
#endif
    }
}
#endif
