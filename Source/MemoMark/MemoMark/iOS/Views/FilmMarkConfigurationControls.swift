#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Style-owned controls for FM. The controls edit only FilmMark's
/// presentation payload; the existing Classic White and Minimal controls do
/// not enter this view.
struct FilmMarkConfigurationControls: View {
    @Binding var configuration: FilmMarkConfiguration

    var includesPosition: Bool = true
    var includesSubstrate: Bool = true
    var includesFont: Bool = true
    var includesFontSize: Bool = true
    var includesColor: Bool = true
    var includesCustomColor: Bool = true
    var horizontalInset: CGFloat = CompactInformationRowMetrics.horizontalPadding
    let onChange: () -> Void

    private var includesAppearance: Bool {
        includesSubstrate || includesFont || includesFontSize || includesColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if includesPosition {
                FilmMarkPositionDetailsContent(configuration: $configuration, onChange: onChange)
            }

            if includesPosition && includesAppearance {
                HorizontalDivider(horizontalInset: horizontalInset)
            }

            if includesAppearance {
                FilmMarkAppearanceControls(
                    configuration: $configuration,
                    includesSubstrate: includesSubstrate,
                    includesFont: includesFont,
                    includesFontSize: includesFontSize,
                    includesColor: includesColor,
                    includesCustomColor: includesCustomColor,
                    horizontalInset: horizontalInset,
                    onChange: onChange
                )
            }
        }
    }
}
#endif
