import Foundation

/// Removes only UUID-owned partial raster files created under MemoMark's
/// temporary export roots. Call while holding the shared execution lease.
enum TemporaryRasterScratchCleanup {
    static func cleanup(inProcessingRoot root: URL) throws {
        guard FileManager.default.fileExists(atPath: root.path) else { return }
        for folder in try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        ) {
            let values = try folder.resourceValues(
                forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
            )
            guard UUID(uuidString: folder.lastPathComponent) != nil,
                  values.isDirectory == true,
                  values.isSymbolicLink != true else { continue }
            try cleanup(in: folder)
        }
    }

    static func cleanup(in exportFolder: URL) throws {
        let folder = exportFolder.appendingPathComponent(
            ".cpu-raster-work",
            isDirectory: true
        )
        guard FileManager.default.fileExists(atPath: folder.path) else { return }
        for file in try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey]
        ) {
            let values = try file.resourceValues(
                forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
            )
            guard file.pathExtension == "rgba",
                  UUID(uuidString: file.deletingPathExtension().lastPathComponent) != nil,
                  values.isRegularFile == true,
                  values.isSymbolicLink != true else { continue }
            try FileManager.default.removeItem(at: file)
        }
    }
}
