//
//  CardTextBlockEngine.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation

final class CardTextBlockEngine {

    private let variableEngine = TemplateVariableEngine()

    func build(
        from card: RecordCard
    ) -> [CardTextBlock] {

        let context = CardVariableProvider
            .build(from: card)

        var blocks: [CardTextBlock] = []

        blocks.append(
            contentsOf: buildBlocks(
                area: "Left",
                items: card.template.leftArea.items,
                context: context
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: "Center",
                items: card.template.centerArea.items,
                context: context
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: "Right",
                items: card.template.rightArea.items,
                context: context
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: "Badge",
                items: card.template.badgeArea.items,
                context: context
            )
        )

        return blocks
    }

    private func buildBlocks(
        area: String,
        items: [TemplateItem],
        context: MetadataContext
    ) -> [CardTextBlock] {

        items
            .filter(\.isEnabled)
            .map { item in

                CardTextBlock(
                    title: item.name,
                    value: variableEngine.render(
                        item.value,
                        context: context
                    ),
                    area: area
                )
            }
    }
}