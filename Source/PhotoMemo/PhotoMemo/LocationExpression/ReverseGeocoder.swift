import Foundation

protocol ReverseGeocoder {

    func reverseGeocode(
        coordinate: LocationCoordinate
    ) async throws -> LocationContext
}
