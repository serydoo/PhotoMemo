//
//  LocationResolver.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation
import CoreLocation

final class LocationResolver {

    private let geocoder = CLGeocoder()

    func resolve(
        latitude: Double,
        longitude: Double
    ) async -> LocationResult {

        let location = CLLocation(
            latitude: latitude,
            longitude: longitude
        )

        do {

            let placemarks =
                try await geocoder.reverseGeocodeLocation(
                    location
                )

            guard let placemark = placemarks.first else {

                return LocationResult()
            }

            return LocationResult(
                country: placemark.country,
                province: placemark.administrativeArea,
                city: placemark.locality,
                district: placemark.subLocality,
                locationName: placemark.name
            )

        } catch {

            print(
                "LocationResolver Error:",
                error.localizedDescription
            )

            return LocationResult()
        }
    }
}