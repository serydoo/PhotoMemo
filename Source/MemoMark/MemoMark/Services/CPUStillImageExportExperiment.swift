#if DEBUG
import CoreGraphics
import CoreImage
import Foundation

/// Opt-in device experiment wrapper; production uses the shared exporter directly.
@MainActor
enum CPUStillImageExportExperiment {
    static let shareExportOptInKey = "memomark.debug.cpuStillImageExportExperiment.enabled"

    static func isEnabledForShareExport(defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: shareExportOptInKey)
    }

    static func export(photo: SelectedPhoto, artifact: PresentationArtifact,
                       to url: URL, writer: MetadataPreservingImageWriter,
                       exportDescription: String) throws -> URL {
        try SoftwareStillImageExporter.export(photo: photo, artifact: artifact,
            to: url, writer: writer, exportDescription: exportDescription)
    }

    static func recipe(sourceURL: URL, artifact: PresentationArtifact,
                       writer: MetadataPreservingImageWriter) throws -> CIImage {
        try SoftwareStillImageExporter.recipe(sourceURL: sourceURL, artifact: artifact, writer: writer)
    }
}
#endif
