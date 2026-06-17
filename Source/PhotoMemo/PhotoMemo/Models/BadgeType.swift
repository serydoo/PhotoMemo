//
//  BadgeType.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

enum BadgeType: String, Codable, CaseIterable {

    case none

    case png

    case systemSymbol

    case customUpload

    case svg
}

extension BadgeType {

    var displayName: String {

        switch self {

        case .none:
            return "None"

        case .png:
            return "PNG"

        case .systemSymbol:
            return "System Symbol"

        case .customUpload:
            return "Custom Upload"

        case .svg:
            return "SVG"
        }
    }
}