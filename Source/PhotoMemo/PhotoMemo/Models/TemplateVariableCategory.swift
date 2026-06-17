//
//  TemplateVariableCategory.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

enum TemplateVariableCategory: String, Codable, CaseIterable {

    case recognized

    case intelligent

    case user
}

extension TemplateVariableCategory {

    var title: String {

        switch self {

        case .recognized:
            return "识别数据"

        case .intelligent:
            return "智能数据"

        case .user:
            return "用户数据"
        }
    }
}