//
//  TemplateVariableLibrary.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

struct TemplateVariableLibrary {

    static func variables(
        in category: TemplateVariableCategory
    ) -> [TemplateVariable] {

        TemplateVariable.all
            .filter {
                $0.category == category
            }
    }

    static var recognized: [TemplateVariable] {

        variables(
            in: .recognized
        )
    }

    static var intelligent: [TemplateVariable] {

        variables(
            in: .intelligent
        )
    }

    static var user: [TemplateVariable] {

        variables(
            in: .user
        )
    }

    static var all: [TemplateVariable] {

        TemplateVariable.all
    }
}