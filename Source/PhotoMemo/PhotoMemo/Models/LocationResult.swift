//
//  LocationResult.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

struct LocationResult {

    var country: String?

    var province: String?

    var city: String?

    var district: String?

    var locationName: String?

    init(
        country: String? = nil,
        province: String? = nil,
        city: String? = nil,
        district: String? = nil,
        locationName: String? = nil
    ) {

        self.country = country
        self.province = province
        self.city = city
        self.district = district
        self.locationName = locationName
    }
}