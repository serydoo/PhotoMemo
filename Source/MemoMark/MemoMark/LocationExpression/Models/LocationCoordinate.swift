import Foundation

struct LocationCoordinate:
    Hashable,
    Codable {

    let latitude: Double

    let longitude: Double

    init(
        latitude: Double,
        longitude: Double
    ) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
