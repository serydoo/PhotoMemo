#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics

/// Selects an authorized, downsampled sample photograph for Configuration
/// Center previews. This is presentation-only calibration state: it never
/// enters the FilmMark configuration, resolved presentation, or export path.
enum ConfigurationPreviewBackground: Equatable {
    case classicWhite
    case minimal
    case filmMark

    enum Orientation: String, CaseIterable, Equatable {
        case landscape
        case portrait
    }

    static let landscapeAspectRatio: CGFloat = 16.0 / 9.0
    static let portraitAspectRatio: CGFloat = 9.0 / 16.0

    enum Surface: Equatable {
        case compact
        case wide
    }

    /// Minimal has purpose-made crop variants. FilmMark preserves one real
    /// narrative photograph through rotation, changing only the crop inside
    /// the unchanged preview frame.
    static func surface(forPreviewWidth width: CGFloat) -> Surface {
        width >= 560 ? .wide : .compact
    }

    func assetName(for surface: Surface) -> String {
        switch (self, surface) {
        case (.classicWhite, _):
            "MidAutumnPreviewBackgroundLandscape"
        case (.minimal, .compact):
            "MinimalPreviewBackgroundPortrait"
        case (.minimal, .wide):
            "MinimalPreviewBackgroundLandscape"
        case (.filmMark, _):
            "FilmMarkPreviewBackground"
        }
    }

    /// Shared owner-provided photographs used by all three production styles.
    /// This remains local preview state and never enters the output pipeline.
    func assetName(forOrientation orientation: Orientation) -> String {
        switch orientation {
        case .landscape:
            "MidAutumnPreviewBackgroundLandscape"
        case .portrait:
            "MidAutumnPreviewBackgroundPortrait"
        }
    }

    static func aspectRatio(for orientation: Orientation) -> CGFloat {
        switch orientation {
        case .landscape:
            landscapeAspectRatio
        case .portrait:
            portraitAspectRatio
        }
    }
}

enum ConfigurationPreviewPreferenceKey {
    static let orientation = "memomark.configuration.preview.orientation"
}

enum ConfigurationPreviewViewportSpec {
    static let landscapeFitScale: CGFloat = 0.88
    static let portraitFitScale: CGFloat = 0.88
    static let portraitFitVisibleFraction: CGFloat = 0.5
    static let alternateCardPeekScale: CGFloat = 0.94
    static let alternateCardPeekOpacity: CGFloat = 0.82
    static let alternateCardPeekOffset: CGFloat = 48

    static func canvasAspectRatio(
        for presentationStyle: RecordCardPresentationStyle,
        orientation: ConfigurationPreviewBackground.Orientation
    ) -> CGFloat {
        let photoAspectRatio = ConfigurationPreviewBackground.aspectRatio(
            for: orientation
        )
        guard presentationStyle == .classicWhite else {
            return photoAspectRatio
        }

        let barOrientation: CompactInformationBarOrientation =
            orientation == .landscape ? .landscape : .portrait
        let informationBarHeightToWidth =
            RendererConstants.CompactInformationBar.spec(for: barOrientation)
                .barHeightToWidth
        return classicCanvasAspectRatio(
            photoAspectRatio: photoAspectRatio,
            informationBarHeightToWidth: informationBarHeightToWidth
        )
    }

    static func classicCanvasAspectRatio(
        photoAspectRatio: CGFloat,
        informationBarHeightToWidth: CGFloat
    ) -> CGFloat {
        1 / (1 / photoAspectRatio + informationBarHeightToWidth)
    }

    static func canvasWidth(
        availableWidth: CGFloat,
        for orientation: ConfigurationPreviewBackground.Orientation,
        isExpanded: Bool
    ) -> CGFloat {
        guard !isExpanded else {
            return availableWidth
        }
        switch orientation {
        case .landscape:
            return availableWidth * landscapeFitScale
        case .portrait:
            return availableWidth * portraitFitScale
        }
    }

    static func viewportAspectRatio(
        for orientation: ConfigurationPreviewBackground.Orientation,
        isExpanded: Bool
    ) -> CGFloat {
        viewportAspectRatio(
            canvasAspectRatio: ConfigurationPreviewBackground.aspectRatio(for: orientation),
            for: orientation,
            isExpanded: isExpanded
        )
    }

    static func viewportAspectRatio(
        canvasAspectRatio: CGFloat,
        for orientation: ConfigurationPreviewBackground.Orientation,
        isExpanded: Bool
    ) -> CGFloat {
        let canvasRatio = canvasAspectRatio
        guard !isExpanded else { return canvasRatio }
        switch orientation {
        case .landscape:
            return canvasRatio / landscapeFitScale
        case .portrait:
            // The compact viewport reveals a fixed fraction of the actual
            // orientation-matched canvas. The canvas itself is scaled by
            // portraitFitScale, so the viewport ratio must divide by that
            // scale to keep the visible fraction honest.
            return canvasRatio
                / (portraitFitScale * portraitFitVisibleFraction)
        }
    }
}
#endif
