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

        let allRecognized =
            variables(
                in: .recognized
            )

        let prioritizedTokens = [
            "{{camera_summary}}",
            "{{model}}",
            "{{lens}}",
            "{{capture_date_display}}",
            "{{focal_len_in_35mm_film}}",
            "{{aperture}}",
            "{{shutter}}",
            "{{iso}}",
            "{{location}}"
        ]

        let prioritizedVariables =
            prioritizedTokens.compactMap { token in
                allRecognized.first {
                    $0.token == token
                }
            }

        let remainingVariables =
            allRecognized.filter { variable in
                !prioritizedTokens.contains(
                    variable.token
                )
            }

        return prioritizedVariables
            + remainingVariables
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
