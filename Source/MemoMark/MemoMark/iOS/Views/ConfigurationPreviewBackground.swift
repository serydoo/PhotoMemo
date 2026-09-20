#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics

/// Selects an authorized, downsampled sample photograph for Configuration
/// Center previews. This is presentation-only calibration state: it never
/// enters the FilmMark configuration, resolved presentation, or export path.
enum ConfigurationPreviewBackground: Equatable {
    case minimal
    case filmMark

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
        case (.minimal, .compact):
            "MinimalPreviewBackgroundPortrait"
        case (.minimal, .wide):
            "MinimalPreviewBackgroundLandscape"
        case (.filmMark, _):
            "FilmMarkPreviewBackground"
        }
    }
}
#endif
