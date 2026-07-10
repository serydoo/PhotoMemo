import Foundation

#if canImport(CoreLocation)
import CoreLocation
#endif

protocol PhotoLocationMetadataEnriching {

    func enrichedMetadata(
        _ metadata: PhotoMetadata
    ) async -> PhotoMetadata
}

struct PhotoLocationMetadataEnricher:
    PhotoLocationMetadataEnriching {

    private let reverseGeocoder:
        any ReverseGeocoder

    init(
        reverseGeocoder:
            any ReverseGeocoder =
                CoreLocationReverseGeocoder()
    ) {

        self.reverseGeocoder =
            reverseGeocoder
    }

    func enrichedMetadata(
        _ metadata: PhotoMetadata
    ) async -> PhotoMetadata {

        let normalizedMetadata =
            metadata.normalized()

        guard
            normalizedMetadata.normalizedCity == nil
                || normalizedMetadata.normalizedDistrict == nil,
            let coordinate =
                LocationContextBuilder()
                .build(
                    from: normalizedMetadata
                )
                .coordinate
        else {
            return normalizedMetadata
        }

        guard
            let context =
                try? await reverseGeocoder
                .reverseGeocode(
                    coordinate: coordinate
                ),
            let address =
                context.address
        else {
            return normalizedMetadata
        }

        return metadata
            .mergingLocationAddress(address)
            .normalized()
    }
}

private extension PhotoMetadata {

    func mergingLocationAddress(
        _ address: LocationAddress
    ) -> PhotoMetadata {

        var metadata = self

        metadata.country =
            normalizedCountry
            ?? address.country
        metadata.province =
            normalizedProvince
            ?? address.province
        metadata.city =
            normalizedCity
            ?? address.city
        metadata.district =
            normalizedDistrict
            ?? address.district
        metadata.locationName =
            normalizedLocationName
            ?? address.name

        return metadata
    }
}

struct CoreLocationReverseGeocoder:
    ReverseGeocoder {

    func reverseGeocode(
        coordinate: LocationCoordinate
    ) async throws -> LocationContext {

#if canImport(CoreLocation)
        let location =
            CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        let placemarks =
            try await CLGeocoder()
            .reverseGeocodeLocation(location)

        guard let placemark =
            placemarks.first
        else {
            return LocationContext(
                coordinate: coordinate,
                availability:
                    LocationAvailability(
                        hasGPS: true
                    )
            )
        }

        return LocationContext(
            coordinate: coordinate,
            address:
                LocationAddress(
                    country:
                        cleanedAdministrativeName(
                            placemark.country
                        ),
                    province:
                        cleanedAdministrativeName(
                            placemark.administrativeArea
                        ),
                    city:
                        resolvedCity(
                            from: placemark
                        ),
                    district:
                        resolvedDistrict(
                            from: placemark
                        ),
                    name:
                        cleanedAdministrativeName(
                            placemark.name
                        )
                ),
            availability:
                LocationAvailability(
                    hasGPS: true,
                    hasAddress: true,
                    hasPOI:
                        placemark.name != nil
                )
        )
#else
        return LocationContext(
            coordinate: coordinate,
            availability:
                LocationAvailability(
                    hasGPS: true
                )
        )
#endif
    }
}

#if canImport(CoreLocation)
private extension CoreLocationReverseGeocoder {

    func resolvedCity(
        from placemark: CLPlacemark
    ) -> String? {

        if
            isMainlandChina(placemark),
            let subAdministrativeArea =
                placemark.subAdministrativeArea,
            let locality =
                placemark.locality,
            subAdministrativeArea != locality {

            return cleanedAdministrativeName(
                subAdministrativeArea
            )
        }

        return cleanedAdministrativeName(
            placemark.locality
                ?? placemark.subAdministrativeArea
        )
    }

    func resolvedDistrict(
        from placemark: CLPlacemark
    ) -> String? {

        if let subLocality =
            placemark.subLocality {

            return cleanedAdministrativeName(
                subLocality
            )
        }

        if
            isMainlandChina(placemark),
            let subAdministrativeArea =
                placemark.subAdministrativeArea,
            let locality =
                placemark.locality,
            subAdministrativeArea != locality {

            return cleanedAdministrativeName(
                locality
            )
        }

        return nil
    }

    func isMainlandChina(
        _ placemark: CLPlacemark
    ) -> Bool {

        placemark.isoCountryCode?
            .uppercased() == "CN"
    }
}
#endif

private func cleanedAdministrativeName(
    _ value: String?
) -> String? {

    guard let value else {
        return nil
    }

    let cleanedValue =
        value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

    return cleanedValue.isEmpty
        ? nil
        : cleanedValue
}
