import Foundation

struct LocationContextBuilder {

    func build() -> LocationContext {
        LocationContext()
    }

    func build(
        from metadata: PhotoMetadata
    ) -> LocationContext {

        let metadata =
            metadata.normalized()

        let coordinate =
            makeCoordinate(
                latitude: metadata.normalizedLatitude,
                longitude: metadata.normalizedLongitude
            )

        let address =
            makeAddress(
                country: metadata.normalizedCountry,
                province: metadata.normalizedProvince,
                city: metadata.normalizedCity,
                district: metadata.normalizedDistrict,
                name: metadata.normalizedLocationName
            )

        return LocationContext(
            coordinate: coordinate,
            altitudeMeters: metadata.normalizedAltitude,
            address: address,
            availability: LocationAvailability(
                hasGPS: coordinate != nil,
                hasAddress: address != nil,
                hasPOI: metadata.normalizedLocationName != nil
            )
        )
    }
}

private extension LocationContextBuilder {

    func makeCoordinate(
        latitude: Double?,
        longitude: Double?
    ) -> LocationCoordinate? {

        guard
            let latitude,
            let longitude
        else {
            return nil
        }

        return LocationCoordinate(
            latitude: latitude,
            longitude: longitude
        )
    }

    func makeAddress(
        country: String?,
        province: String?,
        city: String?,
        district: String?,
        name: String?
    ) -> LocationAddress? {

        guard
            country != nil
                || province != nil
                || city != nil
                || district != nil
                || name != nil
        else {
            return nil
        }

        return LocationAddress(
            country: country,
            province: province,
            city: city,
            district: district,
            name: name
        )
    }
}
