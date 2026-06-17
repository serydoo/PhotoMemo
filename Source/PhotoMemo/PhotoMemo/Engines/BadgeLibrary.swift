//
//  BadgeLibrary.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

struct BadgeLibrary {

    static var defaults: [Badge] {

        [
            .none,
            .family,
            .travel,
            .memory,

            Badge(
                name: "Wedding",
                type: .systemSymbol,
                systemSymbol: "heart.circle.fill",
                isSystemDefault: true
            ),

            Badge(
                name: "Birthday",
                type: .systemSymbol,
                systemSymbol: "birthday.cake.fill",
                isSystemDefault: true
            ),

            Badge(
                name: "Baby",
                type: .systemSymbol,
                systemSymbol: "figure.and.child.holdinghands",
                isSystemDefault: true
            ),

            Badge(
                name: "Pet",
                type: .systemSymbol,
                systemSymbol: "pawprint.fill",
                isSystemDefault: true
            )
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