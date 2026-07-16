//
//  BadgeType.swift
//  PhotoMemo
//
//  Created by MemoMark on 2026/6/17.
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
            return "自动"

        case .png:
            return "PNG"

        case .systemSymbol:
            return "系统标识"

        case .customUpload:
            return "自定义图片"

        case .svg:
            return "SVG"
        }
    }
}
