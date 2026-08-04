import Foundation

final class RecordCardBuildService {

    private let anchorEngine =
        AnchorEngine()

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
                    memoryPayload.subject,
                timeDisplayConfiguration:
                    configuration.timeDisplayConfiguration,
                language: configuration.language
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
                configuration: configuration,
                timeDisplayConfiguration:
                    configuration.timeDisplayConfiguration,
                language: configuration.language
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
            language: configuration.language,
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

        let smartMemoryText = values.first {
            $0.token == MemoryProvider.memoryToken
        }?.resolvedText
        if let composedMemoryText = MemoryWriteTextComposer.compose(
            smartText: smartMemoryText,
            usesCustomText:
                configuration.usesCustomMemoryWriteText,
            customText:
                configuration.customMemoryWriteText
        ) {
            values.removeAll {
                $0.token == MemoryProvider.memoryToken
            }
            values.append(
                ExpressionValue(
                    token: MemoryProvider.memoryToken,
                    resolvedText: composedMemoryText
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
        guard let composedText = MemoryWriteTextComposer.compose(
            smartText: module?.renderedText,
            usesCustomText:
                configuration.usesCustomMemoryWriteText,
            customText:
                configuration.customMemoryWriteText
        ) else {
            return module
        }

        if var module {
            module.renderedText = composedText
            return module
        }

        return MemoryModule(
            title: "Memory",
            blocks: [.text(composedText)],
            renderedText: composedText,
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

        return CardTextBlockEngine()
            .build(from: card)
            .first(where: { $0.area == .rightBottom })?
            .value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""
    }

#if !PHOTOMEMO_SHARE_EXTENSION
    func buildContext(
        from metadata: PhotoMetadata,
        memorySubject: MemorySubject,
        timeDisplayConfiguration:
            ExpressionModuleConfiguration?,
        language: MemoMarkLanguage
    ) -> MetadataContext {

        var context =
            MetadataContext.build(
                from: metadata
            )
        context.replace(
            metadata.orientationText(for: language),
            for: MetadataContext.Key.orientation
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

        applyTimeDisplayConfiguration(
            timeDisplayConfiguration,
            to: &context,
            metadata: metadata,
            language: language
        )

        return context
    }
#else
    func buildContext(
        from metadata: PhotoMetadata,
        configuration: BatchConfigurationSnapshot,
        timeDisplayConfiguration:
            ExpressionModuleConfiguration?,
        language: MemoMarkLanguage
    ) -> MetadataContext {

        var context = MetadataContext.build(
            from: metadata
        )
        context.replace(
            metadata.orientationText(for: language),
            for: MetadataContext.Key.orientation
        )

        applyTimeDisplayConfiguration(
            timeDisplayConfiguration,
            to: &context,
            metadata: metadata,
            language: language
        )

        return context
    }
#endif

    func applyTimeDisplayConfiguration(
        _ configuration: ExpressionModuleConfiguration?,
        to context: inout MetadataContext,
        metadata: PhotoMetadata,
        language: MemoMarkLanguage
    ) {
        guard
            let date = metadata.captureDate
        else {
            return
        }

        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.locale = language.locale
        dateTimeFormatter.timeZone = metadata.captureTimeZone
        dateTimeFormatter.dateStyle = .medium
        dateTimeFormatter.timeStyle = .short
        context.set(
            dateTimeFormatter.string(from: date),
            for: MetadataContext.Key.captureDateDisplay
        )
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = language.locale
        weekdayFormatter.timeZone = metadata.captureTimeZone
        weekdayFormatter.dateFormat = "EEEE"
        context.set(
            weekdayFormatter.string(from: date),
            for: MetadataContext.Key.weekdayName
        )

        guard let configuration else {
            return
        }

        let timeConfiguration = TimeDisplayConfiguration(
            baseStyle: TimeDisplayConfiguration.BaseStyle(
                rawValue: configuration.options["baseStyle"] ?? "daily"
            ) ?? .daily,
            supplement: TimeDisplayConfiguration.Supplement(
                rawValue: configuration.options["supplement"] ?? "none"
            ) ?? .none
        )
        let timeZone = metadata.captureTimeZone
        context.set(
            TimeExpressionProvider.dateText(
                for: date,
                configuration: timeConfiguration,
                timeZone: timeZone,
                language: language
            ),
            for: MetadataContext.Key.captureDateShort
        )
        context.set(
            TimeExpressionProvider.timeText(
                for: date,
                configuration: timeConfiguration,
                timeZone: timeZone,
                language: language
            ),
            for: MetadataContext.Key.captureTimeShort
        )
    }

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
