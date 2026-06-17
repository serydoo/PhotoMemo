//
//  BadgeLibrary.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

struct BadgeLibrary {

    static let wedding = Badge(
        name: "Wedding",
        type: .systemSymbol,
        systemSymbol: "heart.circle.fill",
        isSystemDefault: true
    )

    static let birthday = Badge(
        name: "Birthday",
        type: .systemSymbol,
        systemSymbol: "birthday.cake.fill",
        isSystemDefault: true
    )

    static let baby = Badge(
        name: "Baby",
        type: .systemSymbol,
        systemSymbol: "figure.and.child.holdinghands",
        isSystemDefault: true
    )

    static let pet = Badge(
        name: "Pet",
        type: .systemSymbol,
        systemSymbol: "pawprint.fill",
        isSystemDefault: true
    )

    static var defaults: [Badge] {

        [
            .none,
            .family,
            .travel,
            .memory,
            wedding,
            birthday,
            baby,
            pet
        ]
    }

    static func badge(
        named name: String
    ) -> Badge? {

        defaults.first {
            $0.name == name
        }
    }

    static func systemBadges() -> [Badge] {

        defaults.filter {
            $0.type == .systemSymbol
        }
    }
}
