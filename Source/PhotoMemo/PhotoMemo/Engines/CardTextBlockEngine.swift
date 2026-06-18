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
                area: .leftTop,
                items: card.template.leftTopArea.items,
                context: context
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: .leftBottom,
                items: card.template.leftBottomArea.items,
                context: context
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: .rightTop,
                items: card.template.rightTopArea.items,
                context: context
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: .rightBottom,
                items: card.template.rightBottomArea.items,
                context: context
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: .badge,
                items: card.template.badgeArea.items,
                context: context
            )
        )

        return blocks
    }

    private func buildBlocks(
        area: CardTextArea,
        items: [TemplateItem],
        context: MetadataContext
    ) -> [CardTextBlock] {

        resolvedItems(
            for: area,
            items: items
        )
            .filter(\.isEnabled)
            .compactMap { item in

                let renderedValue =
                    variableEngine.render(
                        item.value,
                        context: context
                    )
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                guard !renderedValue.isEmpty else {
                    return nil
                }

                return CardTextBlock(
                    title: item.name,
                    value: renderedValue,
                    area: area
                    )
            }
    }

    private func resolvedItems(
        for area: CardTextArea,
        items: [TemplateItem]
    ) -> [TemplateItem] {

        switch area {

        case .badge:
            return items

        case .leftTop,
             .leftBottom,
             .rightTop,
             .rightBottom:
            return items.first.map { [$0] } ?? []
        }
    }
}
