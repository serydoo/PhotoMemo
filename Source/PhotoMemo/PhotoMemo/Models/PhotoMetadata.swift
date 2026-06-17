import Foundation

struct PhotoMetadata: Hashable, Codable {

    var captureDate: Date?

    var deviceBrand: String

    var deviceModel: String

    var lensModel: String

    var iso: String

    var aperture: String

    var shutterSpeed: String

    var focalLength: String

    var focalLength35mm: String

    var imageWidth: Int?

    var imageHeight: Int?

    var latitude: Double?

    var longitude: Double?

    var altitude: Double?

    var city: String?

    var district: String?

    var province: String?

    var country: String?

    var locationName: String?

    init(
        captureDate: Date? = nil,
        deviceBrand: String = "",
        deviceModel: String = "",
        lensModel: String = "",
        iso: String = "",
        aperture: String = "",
        shutterSpeed: String = "",
        focalLength: String = "",
        focalLength35mm: String = "",
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        city: String? = nil,
        district: String? = nil,
        province: String? = nil,
        country: String? = nil,
        locationName: String? = nil
    ) {
        self.captureDate = captureDate
        self.deviceBrand = deviceBrand
        self.deviceModel = deviceModel
        self.lensModel = lensModel
        self.iso = iso
        self.aperture = aperture
        self.shutterSpeed = shutterSpeed
        self.focalLength = focalLength
        self.focalLength35mm = focalLength35mm
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.city = city
        self.district = district
        self.province = province
        self.country = country
        self.locationName = locationName
    }
}
