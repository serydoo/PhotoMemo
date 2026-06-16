import CoreLocation
import Foundation
import ImageIO

struct PhotoMetadata {

    let fileName: String
    let captureDate: String?
    let cameraModel: String?

    let latitude: Double?
    let longitude: Double?
    var locationName: String?

    static func load(from url: URL) -> PhotoMetadata {

        guard let source = CGImageSourceCreateWithURL(
            url as CFURL,
            nil
        ),
        let properties = CGImageSourceCopyPropertiesAtIndex(
            source,
            0,
            nil
        ) as? [CFString: Any]
        else {
            return PhotoMetadata(
                fileName: url.lastPathComponent,
                captureDate: nil,
                cameraModel: nil,
                latitude: nil,
                longitude: nil,
                locationName: nil
            )
        }

        let exif =
            properties[kCGImagePropertyExifDictionary]
            as? [CFString: Any]

        let tiff =
            properties[kCGImagePropertyTIFFDictionary]
            as? [CFString: Any]
        let gps =
            properties[kCGImagePropertyGPSDictionary]
            as? [CFString: Any]
        let latitude =
            gps?[kCGImagePropertyGPSLatitude]
            as? Double

        let longitude =
            gps?[kCGImagePropertyGPSLongitude]
            as? Double

        let captureDate =
            exif?[kCGImagePropertyExifDateTimeOriginal]
            as? String

        let cameraModel =
            tiff?[kCGImagePropertyTIFFModel]
            as? String

        return PhotoMetadata(
            fileName: url.lastPathComponent,
            captureDate: captureDate,
            cameraModel: cameraModel,
            latitude: latitude,
            longitude: longitude,
            locationName: nil
        )
    }
}
