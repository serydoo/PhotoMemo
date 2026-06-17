//
//  CustomBadge.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

struct CustomBadge: Identifiable, Codable, Hashable {

    let id: UUID

    var name: String

    var fileName: String

    var filePath: String

    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        fileName: String,
        filePath: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.filePath = filePath
        self.createdAt = createdAt
    }
}

extension CustomBadge {

    static let empty = CustomBadge(
        name: "",
        fileName: "",
        filePath: ""
    )
}