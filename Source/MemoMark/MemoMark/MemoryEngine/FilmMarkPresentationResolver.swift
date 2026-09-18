import CoreGraphics
import Foundation

/// Compiles the FM-owned authored content into resolved presentation input.
///
/// This is deliberately outside the Renderer. Memory/Card Content owns what
/// the user means; Layout owns geometry; this resolver is the single bridge
/// that makes those decisions explicit before a Renderer draws anything.
enum FilmMarkPresentationResolver {

    static func resolvedContentBlocks(
        for card: RecordCard
    ) -> [CardTextBlock] {
        guard card.presentationStyle == .filmMark else {
            return CardTextBlockEngine().build(from: card)
        }

        let projection = contentProjection(for: card)
        guard !projection.primaryOutput.isEmpty else {
            return []
        }

        let title = card.filmMarkContent?.primaryOutputItems.first?.name
            ?? "FilmMark"
        return [
            CardTextBlock(
                title: title,
                value: projection.primaryOutput,
                area: .leftTop
            )
        ]
    }

    static func contentProjection(
        for card: RecordCard
    ) -> FilmMarkContentProjection {
        guard let authoredContent = card.filmMarkContent else {
            return FilmMarkContentProjection(primaryOutput: "")
        }

        // CardTextBlockEngine is retained as the established token resolver,
        // but only behind this FM content adapter. The authored payload is
        // layout-independent; the temporary Template is runtime-only.
        var contentCard = card
        contentCard.template = authoredContent.compositionTemplate(
            basedOn: card.template
        )
        let blocks = CardTextBlockEngine().build(from: contentCard)
        let text = blocks
            .first(where: { $0.area == .leftTop })?
            .value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
        return FilmMarkContentProjection(primaryOutput: text)
    }

    static func resolvedPresentation(
        for card: RecordCard,
        canvasSize: CGSize
    ) -> FilmMarkResolvedPresentation {
        resolve(
            content: contentProjection(for: card),
            configuration: card.filmMarkConfiguration,
            canvasSize: canvasSize
        )
    }

    static func resolve(
        content: FilmMarkContentProjection,
        configuration: FilmMarkConfiguration,
        canvasSize: CGSize
    ) -> FilmMarkResolvedPresentation {
        let measurement = FilmMarkLayoutSpecification.measure(
            text: content.primaryOutput,
            canvasSize: canvasSize,
            appearance: configuration.appearance
        )
        return FilmMarkResolvedPresentation(
            canvasSize: canvasSize,
            content: content,
            appearance: configuration.appearance,
            measuredContentSize: measurement.size,
            placement: configuration.placement,
            safeAreaInsets: configuration.safeAreaInsets,
            didFitEntireString: measurement.didFitEntireString
        )
    }
}
