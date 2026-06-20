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
            TemplateVariable.allToken(
                for: MetadataContext.Key.cameraSummary
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.model
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.lens
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.locationDisplay
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.captureDateDisplay
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.captureDateShort
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.captureTimeShort
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.focalLength35mm
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.aperture
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.shutter
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.iso
            ),
            TemplateVariable.allToken(
                for: MetadataContext.Key.location
            )
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
