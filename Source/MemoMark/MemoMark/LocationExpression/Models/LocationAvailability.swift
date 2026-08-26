import Foundation

struct LocationAvailability:
    Hashable,
    Codable {

    var hasGPS: Bool

    var hasAddress: Bool

    var hasPOI: Bool

    init(
        hasGPS: Bool = false,
        hasAddress: Bool = false,
        hasPOI: Bool = false
    ) {
        self.hasGPS = hasGPS
        self.hasAddress = hasAddress
        self.hasPOI = hasPOI
    }
}
