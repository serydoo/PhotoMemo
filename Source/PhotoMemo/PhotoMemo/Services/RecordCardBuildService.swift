import Foundation

final class RecordCardBuildService {

    private let anchorEngine =
        AnchorEngine()

    private let templateVariableEngine =
        TemplateVariableEngine()

#if !PHOTOMEMO_SHARE_EXTENSION
    private let productionMemoryResolver:
        ProductionMemoryResolver
#endif

#if PHOTOMEMO_SHARE_EXTENSION
    init() {}
#else
    init() {
#if !PHOTOMEMO_SHARE_EXTENSION
        self.productionMemoryResolver =
            ProductionMemoryResolver()
#endif
    }
#endif

    func buildCard(
        from selectedPhoto: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> RecordCard {

        var card = baseCard(
            from: selectedPhoto,
            configuration: configuration
        )

        card.exportDescriptionOverride =
            resolvedPhotoDescription(
                from: card,
                configuration: configuration
            )

        return card
    }

    func defaultPhotoDescription(
        from selectedPhoto: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> String {

        var descriptionConfiguration =
            configuration
        descriptionConfiguration.photoDescriptionOverride =
            ""

        let card = baseCard(
            from: selectedPhoto,
            configuration: descriptionConfiguration
        )

        return resolvedPhotoDescription(
            from: card,
            configuration: descriptionConfiguration
        )
    }
}

private extension RecordCardBuildService {

    func baseCard(
        from selectedPhoto: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> RecordCard {

#if !PHOTOMEMO_SHARE_EXTENSION
        let memoryPayload =
            resolvedMemoryPayload(
                from: selectedPhoto,
                configuration: configuration
            )
        let anchor =
            resolvedAnchor(
                from: memoryPayload,
                fallbackConfiguration:
                    configuration
            )
        let anchorResult =
            resolvedAnchorResult(
                from: anchor,
                photo: selectedPhoto
            )
        let context =
            buildContext(
                from: selectedPhoto.metadata,
                memorySubject:
                    memoryPayload.subject
            )
        let title =
            resolvedTitle(
                from: memoryPayload,
                fallbackConfiguration:
                    configuration
            )
        let memorySubjectText =
            resolvedMemorySubjectText(
                from: memoryPayload
            )
#else
        let context =
            buildContext(
                from: selectedPhoto.metadata,
                configuration: configuration
            )
        let anchor =
            configuration.legacyAnchor
        let anchorResult =
            resolvedAnchorResult(
                from: anchor,
                photo: selectedPhoto
            )
        let title =
            resolvedTitle(
                from: configuration
            )
        let memorySubjectText =
            configuration.legacyMemorySubjectText
#endif

        var card = RecordCard(
            template: configuration.template,
            metadata: selectedPhoto.metadata,
            context: context,
            anchor: anchor,
            anchorResult: anchorResult,
            badge: configuration.badge,
            title: title,
            story: resolvedStory(
                from: configuration
            ),
            memorySubjectText:
                memorySubjectText,
            exportDescriptionOverride: nil
        )

#if !PHOTOMEMO_SHARE_EXTENSION
        card.memoryResult =
            memoryPayload.result
        card.memoryModule =
            resolvedMemoryModule(
                from: memoryPayload.module,
                configuration: configuration
            )
        card.productionExpressionContext =
            productionExpressionContext(
                memoryContext:
                    memoryPayload
                    .productionExpressionContext,
                metadata:
                    selectedPhoto.metadata,
                locationDisplayConfiguration:
                    configuration
                    .locationDisplayConfiguration,
                configuration: configuration
            )
#endif

        return card
    }

    func resolvedTitle(
        from configuration: BatchConfigurationSnapshot
    ) -> String {

        return configuration.legacyAnchor?.title ?? ""
    }

    func resolvedAnchorResult(
        from anchor: Anchor?,
        photo selectedPhoto: SelectedPhoto
    ) -> AnchorResult? {

        guard let captureDate =
            selectedPhoto.metadata.captureDate
        else {
            return nil
        }

        return anchor.map {
            anchorEngine.build(
                from: $0,
                photoDate:
                    captureDate
            )
        }
    }

#if !PHOTOMEMO_SHARE_EXTENSION
    func resolvedMemoryPayload(
        from selectedPhoto: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> ProductionMemoryPayload {

        if
            let snapshot =
                configuration
                .canonicalProductionSnapshot,
            let payload =
                productionMemoryResolver.resolve(
                    photo: selectedPhoto,
                    frozenSnapshot: snapshot
                ) {

            return payload
        }

        return productionMemoryResolver.resolveLegacyBatchConfiguration(
            photo: selectedPhoto,
            configuration: configuration
        )
    }

    func resolvedAnchor(
        from payload: ProductionMemoryPayload,
        fallbackConfiguration configuration:
            BatchConfigurationSnapshot
    ) -> Anchor? {

        guard
            let frozenAnchor =
                payload
                .snapshot
                .primaryAnchor
        else {
            if configuration
                .canonicalProductionSnapshot != nil {
                return nil
            }

            return configuration.legacyAnchor
        }

        guard let anchorType =
            frozenAnchor.anchorType
        else {
            return nil
        }

        return Anchor(
            id: frozenAnchor.id,
            type: anchorType,
            title: frozenAnchor.title,
            date: frozenAnchor.date,
            isCountdown:
                anchorType.defaultCountdown,
            expressionStyle:
                frozenAnchor.expressionStyle
        )
    }

    func resolvedTitle(
        from payload: ProductionMemoryPayload,
        fallbackConfiguration configuration:
            BatchConfigurationSnapshot
    ) -> String {

        let frozenTitle =
            payload.snapshot.primaryAnchor?
            .title
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if
            frozenTitle.isEmpty,
            configuration
                .canonicalProductionSnapshot != nil {
            return ""
        }

        return frozenTitle.isEmpty
            ? resolvedTitle(
                from: configuration
            )
            : frozenTitle
    }

    func resolvedMemorySubjectText(
        from payload: ProductionMemoryPayload
    ) -> String {

        payload
            .subject
            .resolvedExpressionSubjectText
    }

    func productionExpressionContext(
        memoryContext: ExpressionContext?,
        metadata: PhotoMetadata,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration?,
        configuration: BatchConfigurationSnapshot
    ) -> ExpressionContext? {
        var values =
            memoryContext
            .map {
                Array(
                    $0
                    .valuesByToken
                    .values
                )
            }
            ?? []

        if let locationValue =
            productionLocationValue(
                metadata: metadata,
                configuration:
                    locationDisplayConfiguration
            ) {
            values.append(locationValue)
        }

        let customMemoryText =
            configuration.customMemoryWriteText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        if configuration.usesCustomMemoryWriteText,
            !customMemoryText.isEmpty {
            values.removeAll {
                $0.token == MemoryProvider.memoryToken
            }
            values.append(
                ExpressionValue(
                    token: MemoryProvider.memoryToken,
                    resolvedText: customMemoryText
                )
            )
        }

        guard !values.isEmpty else {
            return nil
        }

        return try? ExpressionContext(
            values: values
        )
    }

    func productionLocationValue(
        metadata: PhotoMetadata,
        configuration:
            ExpressionModuleConfiguration?
    ) -> ExpressionValue? {
        guard
            let configuration,
            let providerInput =
                LocationConfigurationAdapter()
                .providerInput(
                    from: configuration
                )
        else {
            return nil
        }

        return LocationExpressionProvider()
            .expressionValue(
                for:
                    LocationExpressionProvider
                    .locationToken,
                context:
                    LocationContextBuilder()
                    .build(
                        from: metadata
                    ),
                requestedPresentation:
                    providerInput
                    .requestedPresentation,
                configuration:
                    providerInput
                    .resolutionConfiguration
            )
            ?? ExpressionValue(
                token:
                    LocationExpressionProvider
                    .locationToken,
                resolvedText: ""
            )
    }
#endif

    func resolvedStory(
        from configuration: BatchConfigurationSnapshot
    ) -> String {

        ""
    }

#if !PHOTOMEMO_SHARE_EXTENSION
    func resolvedMemoryModule(
        from module: MemoryModule?,
        configuration: BatchConfigurationSnapshot
    ) -> MemoryModule? {
        let customText = configuration.customMemoryWriteText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        guard configuration.usesCustomMemoryWriteText,
            !customText.isEmpty
        else {
            return module
        }

        if var module {
            module.renderedText = customText
            return module
        }

        return MemoryModule(
            title: "Memory",
            blocks: [.text(customText)],
            renderedText: customText,
            sourceAnchor:
                configuration
                .canonicalProductionSnapshot?
                .primaryAnchor,
            preferredRegion:
                configuration
                .canonicalProductionSnapshot?
                .smartModuleCarrierRegion
        )
    }
#endif

    func resolvedPhotoDescription(
        from card: RecordCard,
        configuration: BatchConfigurationSnapshot
    ) -> String {
        let override =
            configuration.photoDescriptionOverride
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if configuration.shouldWritePhotoDescription,
           !override.isEmpty {
            return override
        }

        let context =
            CardVariableProvider.build(
                from: card
            )

        return templateVariableEngine
            .render(
                rightBottomTemplate(
                    from: configuration.template
                ),
                context: context
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    func rightBottomTemplate(
        from template: Template
    ) -> String {

        template.rightBottomArea.items.first?.value
        ?? ""
    }

#if !PHOTOMEMO_SHARE_EXTENSION
    func buildContext(
        from metadata: PhotoMetadata,
        memorySubject: MemorySubject
    ) -> MetadataContext {

        var context =
            MetadataContext.build(
                from: metadata
            )

        context.set(
            memorySubject
                .resolvedShortName,
            for:
                MetadataContext
                .Key
                .subjectNickname
        )

        if let relationshipLabel =
            normalizedRelationshipLabel(
                memorySubject
                    .relationship
                    .label
            ) {
            context.set(
                relationshipLabel,
                for: MetadataContext.Key.relationshipLabel
            )
        }

        return context
    }
#else
    func buildContext(
        from metadata: PhotoMetadata,
        configuration: BatchConfigurationSnapshot
    ) -> MetadataContext {

        return MetadataContext.build(
            from: metadata
        )
    }
#endif

    func normalizedRelationshipLabel(
        _ label: String?
    ) -> String? {

        let trimmed =
            label?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        return trimmed.isEmpty ? nil : trimmed
    }

}
