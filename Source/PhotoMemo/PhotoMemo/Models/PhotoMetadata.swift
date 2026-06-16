import Foundation
import CoreLocation

struct PhotoMetadata: Hashable, Codable {

    var captureDate: Date?

    var deviceModel: String

    var lensModel: String

    var iso: String

    var aperture: String

    var shutterSpeed: String

    var focalLength: String

    var latitude: Double?

    var longitude: Double?

    var locationName: String?

    init(
        captureDate: Date? = nil,
        deviceModel: String = "",
        lensModel: String = "",
        iso: String = "",
        aperture: String = "",
        shutterSpeed: String = "",
        focalLength: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil
    ) {
        self.captureDate = captureDate
        self.deviceModel = deviceModel
        self.lensModel = lensModel
        self.iso = iso
        self.aperture = aperture
        self.shutterSpeed = shutterSpeed
        self.focalLength = focalLength
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
    }
}
