//
//  BadgeLibrary.swift
//  PhotoMemo
//
//  Created by MemoMark on 2026/6/17.
//


import Foundation

struct BadgeLibrary {

    static let love = Badge(
        name: "喜爱",
        type: .png,
        imageName: "badge-love",
        isSystemDefault: true
    )

    static let weddingBlessing = Badge(
        name: "囍",
        type: .png,
        imageName: "badge-wedding",
        isSystemDefault: true
    )

    static let birthBlessing = Badge(
        name: "新生",
        type: .png,
        imageName: "badge-birth",
        isSystemDefault: true
    )

    static let fuBlessing = Badge(
        name: "福",
        type: .png,
        imageName: "badge-fu",
        isSystemDefault: true
    )

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
            .appleClassic,
            love,
            weddingBlessing,
            birthBlessing,
            fuBlessing,
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
