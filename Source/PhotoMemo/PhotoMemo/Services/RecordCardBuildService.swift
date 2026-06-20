import Foundation

final class RecordCardBuildService {

    private let anchorEngine =
        AnchorEngine()

    private let templateVariableEngine =
        TemplateVariableEngine()

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

        let anchorResult =
            configuration.anchor.map {
                anchorEngine.build(
                    from: $0,
                    photoDate:
                        selectedPhoto.metadata.captureDate
                        ?? Date()
                )
            }

        return RecordCard(
            template: configuration.template,
            metadata: selectedPhoto.metadata,
            context: MetadataContext.build(
                from: selectedPhoto.metadata
            ),
            anchor: configuration.anchor,
            anchorResult: anchorResult,
            badge: configuration.badge,
            title: resolvedTitle(
                from: configuration
            ),
            story: resolvedStory(
                from: configuration
            ),
            exportDescriptionOverride: nil
        )
    }

    func resolvedTitle(
        from configuration: BatchConfigurationSnapshot
    ) -> String {

        return configuration.anchor?.title ?? ""
    }

    func resolvedStory(
        from configuration: BatchConfigurationSnapshot
    ) -> String {

        ""
    }

    func resolvedPhotoDescription(
        from card: RecordCard,
        configuration: BatchConfigurationSnapshot
    ) -> String {

        guard configuration.shouldWritePhotoDescription
        else {
            return ""
        }

        let override =
            configuration.photoDescriptionOverride
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !override.isEmpty {
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
}
