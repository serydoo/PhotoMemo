import Foundation
import AppKit
import UniformTypeIdentifiers

final class PhotoImportService {

    private let metadataReader = PhotoMetadataReader()
    private let locationResolver = LocationResolver()

    func importPhoto(from url: URL) async -> SelectedPhoto {

        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var metadata = metadataReader.read(from: url)

        if let latitude = metadata.latitude,
           let longitude = metadata.longitude {

            let location = await locationResolver.resolve(
                latitude: latitude,
                longitude: longitude
            )

            metadata.country = location.country
            metadata.province = location.province
            metadata.city = location.city
            metadata.district = location.district
            metadata.locationName = location.locationName
        }

        // ✅ 关键修复：用 Data 读取（稳定）
        guard let data = try? Data(contentsOf: url),
              let image = NSImage(data: data) else {

            fatalError("IMAGE LOAD FAILED (Data method failed)")
        }

        return SelectedPhoto(
            image: image,
            metadata: metadata
        )
    }

    func supportedTypes() -> [UTType] {
        [.jpeg, .png, .heic, .heif, .tiff]
    }

    func isSupported(_ url: URL) -> Bool {

        guard let type = UTType(filenameExtension: url.pathExtension.lowercased())
        else { return false }

        return supportedTypes().contains(type)
    }
}
