import Foundation

struct LocationContext:
    Hashable,
    Codable {

    var coordinate: LocationCoordinate?

    var altitudeMeters: Double?

    var address: LocationAddress?

    var availability: LocationAvailability

    init(
        coordinate: LocationCoordinate? = nil,
        altitudeMeters: Double? = nil,
        address: LocationAddress? = nil,
        availability: LocationAvailability = .init()
    ) {
        self.coordinate = coordinate
        self.altitudeMeters = altitudeMeters
        self.address = address
        self.availability = availability
    }

    var hasGPS: Bool {
        availability.hasGPS
    }

    var hasAddress: Bool {
        availability.hasAddress
    }

    var hasPOI: Bool {
        availability.hasPOI
    }
}
