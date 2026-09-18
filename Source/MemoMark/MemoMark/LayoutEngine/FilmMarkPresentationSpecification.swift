import CoreGraphics
import Foundation

/// Carries meaning from the Memory Engine / Card Content layer to FM.
///
/// `primaryOutput` is resolved text, not a token expression. FM therefore
/// remains a presentation system and never becomes the owner of memory
/// semantics or user-authored sentence composition.
struct FilmMarkContentProjection: Codable, Hashable {

    var primaryOutput: String

    init(primaryOutput: String) {
        self.primaryOutput = primaryOutput
    }
}

/// Runtime text measurement supplied by the Layout Engine. It is not a
/// persisted setting because it depends on the resolved canvas and font
/// implementation.
struct FilmMarkResolvedTypography: Equatable {

    let fontID: FilmMarkFontID
    let pointSize: CGFloat
}

/// An immutable bridge object shared by the future large preview and export
/// adapters. It contains resolved geometry and typography, but does not own
/// rasterization, PhotoKit, or Live Photo lifecycle work.
struct FilmMarkResolvedPresentation: Equatable {

    let canvasSize: CGSize
    let content: FilmMarkContentProjection
    let appearance: FilmMarkAppearanceDraft
    let typography: FilmMarkResolvedTypography
    let layout: FilmMarkResolvedLayout

    init(
        canvasSize: CGSize,
        content: FilmMarkContentProjection,
        appearance: FilmMarkAppearanceDraft,
        measuredContentSize: CGSize,
        placement: FilmMarkPlacementDraft,
        safeAreaInsets: FilmMarkNormalizedInsets = .default,
        didFitEntireString: Bool = true
    ) {
        let resolvedCanvasSize = CGSize(
            width: max(canvasSize.width, 0),
            height: max(canvasSize.height, 0)
        )
        self.canvasSize = resolvedCanvasSize
        self.content = content
        self.appearance = appearance
        self.typography = FilmMarkResolvedTypography(
            fontID: appearance.fontID.resolvedForRendering,
            pointSize: max(min(
                resolvedCanvasSize.width,
                resolvedCanvasSize.height
            )
                * appearance.fontSize.relativeToCanvasWidth, 1)
        )
        self.layout = FilmMarkLayoutSpecification.resolve(
            canvasSize: resolvedCanvasSize,
            contentSize: measuredContentSize,
            placement: placement,
            appearance: appearance,
            safeAreaInsets: safeAreaInsets,
            didFitEntireString: didFitEntireString
        )
    }
}
