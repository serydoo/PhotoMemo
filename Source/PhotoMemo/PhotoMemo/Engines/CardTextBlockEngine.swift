//
//  CardTextBlockEngine.swift
//  PhotoMemo
//
//  Created by MemoMark on 2026/6/17.
//


import Foundation

final class CardTextBlockEngine {

    private let variableEngine = TemplateVariableEngine()

    func build(
        from card: RecordCard
    ) -> [CardTextBlock] {

        let baseContext =
            CardVariableProvider
            .build(from: card)

        var metadataContext =
            baseContext

#if !PHOTOMEMO_SHARE_EXTENSION
        let hasProductionLocationExpression =
            card
            .productionExpressionContext?
            .value(
                for:
                    LocationExpressionProvider
                    .locationToken
            ) != nil
#else
        let hasProductionLocationExpression =
            false
#endif

        if let modelExpressionValue =
            MetadataProvider()
            .expressionValue(
                for: MetadataProvider.modelToken,
                metadata: card.metadata
            ),
           let expressionContext =
            try? ExpressionContext(
                values: [
                    modelExpressionValue
                ]
            ) {

            metadataContext =
                ExpressionContextMetadataAdapter()
                .metadataContext(
                    from: expressionContext,
                    base: baseContext
            )
        }

#if !PHOTOMEMO_SHARE_EXTENSION
        if let productionExpressionContext =
            card.productionExpressionContext {

            metadataContext =
                ExpressionContextMetadataAdapter()
                .metadataContext(
                    from: productionExpressionContext,
                    base: metadataContext
                )
        }
#endif

        if !hasProductionLocationExpression,
           let locationExpressionValue =
            LocationExpressionProvider()
            .expressionValue(
                for: LocationExpressionProvider.locationToken,
                context:
                    LocationContextBuilder()
                    .build(
                        from: card.metadata
                    ),
                requestedPresentation: .legacyDisplay
            ),
           let expressionContext =
            try? ExpressionContext(
                values: [
                    locationExpressionValue
                ]
            ) {

            metadataContext =
                ExpressionContextMetadataAdapter()
                .metadataContext(
                    from: expressionContext,
                    base: metadataContext
                )
        }

        let lookup =
            MetadataContextExpressionLookup(
                metadataContext: metadataContext
            )

        var blocks: [CardTextBlock] = []

        blocks.append(
            contentsOf: buildBlocks(
                area: .leftTop,
                items: card.template.leftTopArea.items,
                lookup: lookup
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: .leftBottom,
                items: card.template.leftBottomArea.items,
                lookup: lookup
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: .rightTop,
                items: card.template.rightTopArea.items,
                lookup: lookup
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: .rightBottom,
                items: card.template.rightBottomArea.items,
                lookup: lookup
            )
        )

        blocks.append(
            contentsOf: buildBlocks(
                area: .badge,
                items: card.template.badgeArea.items,
                lookup: lookup
            )
        )

        return blocks
    }

    private func buildBlocks(
        area: CardTextArea,
        items: [TemplateItem],
        lookup: any ExpressionLookup
    ) -> [CardTextBlock] {
        let enabledItems = resolvedItems(
            for: area,
            items: items
        )
        .filter(\.isEnabled)

        if area == .badge {
            return enabledItems.compactMap { item in
                block(
                    from: item,
                    area: area,
                    lookup: lookup
                )
            }
        }

        let renderedValue = InlineContentTextComposer.compose(
            enabledItems.map { item in
                InlineContentTextComposer.Piece(
                    kind: item.type == .variable ? .token : .text,
                    value: variableEngine.render(
                        item.value,
                        lookup: lookup
                    )
                )
            }
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !renderedValue.isEmpty,
              let firstItem = enabledItems.first else {
            return []
        }

        return [
            CardTextBlock(
                title: firstItem.name,
                value: renderedValue,
                area: area
            )
        ]
    }

    private func block(
        from item: TemplateItem,
        area: CardTextArea,
        lookup: any ExpressionLookup
    ) -> CardTextBlock? {
        let renderedValue = variableEngine.render(
            item.value,
            lookup: lookup
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !renderedValue.isEmpty else {
            return nil
        }

        return CardTextBlock(
            title: item.name,
            value: renderedValue,
            area: area
        )
    }

    private func resolvedItems(
        for area: CardTextArea,
        items: [TemplateItem]
    ) -> [TemplateItem] {

        items
    }
}
