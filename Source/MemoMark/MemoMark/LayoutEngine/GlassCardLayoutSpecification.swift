import CoreGraphics
import Foundation

/// Geometry for the fourth presentation study: one structured information
/// panel placed inside the original photo canvas.
///
/// This type deliberately has no FilmMark placement state. The panel's bottom
/// rail composition is part of the presentation itself, not a user-positionable
/// annotation. Ratios are normalized from the measured glass-watermark corpus
/// and remain provisional until the visual review freezes the MemoMark form.
enum GlassCardLayoutSpecification {

    struct Layout: Equatable {
        let horizontalInsetToShortEdge: CGFloat
        let bottomInsetToShortEdge: CGFloat
        let panelHeightToShortEdge: CGFloat
        let cornerRadiusToPanelHeight: CGFloat
        let logoZoneWidthToPanelHeight: CGFloat
        let logoSizeToPanelHeight: CGFloat
        let dividerHeightToPanelHeight: CGFloat
        let dividerSpacingToPanelHeight: CGFloat
        let leftPaddingToPanelHeight: CGFloat
        let rightPaddingToPanelHeight: CGFloat
        let columnSpacingToPanelHeight: CGFloat
        let leftRowSpacingToPanelHeight: CGFloat
        let rightRowSpacingToPanelHeight: CGFloat
        let primaryFontToPanelHeight: CGFloat
        let secondaryFontToPanelHeight: CGFloat
        let minimumLeftColumnWidthToPanelWidth: CGFloat
        let leftPrimaryCenterYToPanelHeight: CGFloat
        let leftSecondaryCenterYToPanelHeight: CGFloat
        let rightPrimaryCenterYToPanelHeight: CGFloat
        let rightSecondaryCenterYToPanelHeight: CGFloat
        let primaryRowHeightToPanelHeight: CGFloat
        let secondaryRowHeightToPanelHeight: CGFloat
    }

    /// Frames inside the panel. The right group shares a trailing anchor;
    /// its width comes from the preferred-font measurement in the resolved plan.
    struct ResolvedGeometry: Equatable {
        let panelFrame: CGRect
        let leftTopFrame: CGRect
        let leftBottomFrame: CGRect
        let badgeFrame: CGRect
        let dividerFrame: CGRect
        let rightTopFrame: CGRect
        let rightBottomFrame: CGRect
    }

    /// The benchmark family clusters around a ~140 px rail on a 1080 px short
    /// edge, with ~16-20 px edge clearance. MemoMark keeps those proportions as
    /// a starting point while its typography and semantic hierarchy remain its
    /// own. These are prototype ratios, not a frozen export recipe.
    static let layout = Layout(
        horizontalInsetToShortEdge: 0.018,
        bottomInsetToShortEdge: 0.016,
        panelHeightToShortEdge: 0.130,
        cornerRadiusToPanelHeight: 0.50,
        logoZoneWidthToPanelHeight: 0.54,
        // Visible mark height is 56 px on the measured 140–142 px reference rails.
        logoSizeToPanelHeight: 0.40,
        dividerHeightToPanelHeight: 0.58,
        dividerSpacingToPanelHeight: 0.12,
        leftPaddingToPanelHeight: 0.50,
        rightPaddingToPanelHeight: 0.51,
        columnSpacingToPanelHeight: 0.38,
        leftRowSpacingToPanelHeight: 0.16,
        rightRowSpacingToPanelHeight: 0.10,
        primaryFontToPanelHeight: 0.165,
        secondaryFontToPanelHeight: 0.135,
        minimumLeftColumnWidthToPanelWidth: 0.30,
        leftPrimaryCenterYToPanelHeight: 0.364,
        leftSecondaryCenterYToPanelHeight: 0.713,
        rightPrimaryCenterYToPanelHeight: 0.386,
        rightSecondaryCenterYToPanelHeight: 0.669,
        primaryRowHeightToPanelHeight: 0.27,
        secondaryRowHeightToPanelHeight: 0.22
    )

    static func panelFrame(canvasSize: CGSize) -> CGRect {
        let width = max(canvasSize.width, 1)
        let height = max(canvasSize.height, 1)
        let shortEdge = min(width, height)
        let horizontalInset = shortEdge * layout.horizontalInsetToShortEdge
        let bottomInset = shortEdge * layout.bottomInsetToShortEdge
        let panelHeight = min(
            shortEdge * layout.panelHeightToShortEdge,
            max(height - bottomInset, 1)
        )
        let panelWidth = max(width - horizontalInset * 2, 1)

        return CGRect(
            x: horizontalInset,
            y: max(height - bottomInset - panelHeight, 0),
            width: panelWidth,
            height: panelHeight
        )
    }

    static func resolvedGeometry(canvasSize: CGSize, preferredRightColumnWidth: CGFloat = 0) -> ResolvedGeometry {
        let panel = panelFrame(canvasSize: canvasSize)
        let height = max(panel.height, 0.001)
        let width = max(panel.width, 0.001)
        let leftMinX = height * layout.leftPaddingToPanelHeight
        let badgeSize = height * layout.logoSizeToPanelHeight
        let dividerWidth = height * 0.006
        let neighboringGap = height * layout.dividerSpacingToPanelHeight
        let columnGap = height * layout.columnSpacingToPanelHeight
        let rightMaxX = width - height * layout.rightPaddingToPanelHeight
        let minimumLeftWidth = width * layout.minimumLeftColumnWidthToPanelWidth
        let groupAccessoriesWidth = badgeSize + dividerWidth + neighboringGap * 2
        let capacity = max(rightMaxX - leftMinX - minimumLeftWidth - columnGap - groupAccessoriesWidth, 0)
        let requestedWidth = preferredRightColumnWidth.isFinite ? max(preferredRightColumnWidth, 0) : capacity
        let rightWidth = min(requestedWidth, capacity)
        let rightMinX = rightMaxX - rightWidth
        let dividerMinX = rightMinX - neighboringGap - dividerWidth
        let dividerCenter = dividerMinX + dividerWidth / 2
        let badgeMinX = dividerMinX - neighboringGap - badgeSize
        let badgeCenter = badgeMinX + badgeSize / 2
        let leftMaxX = badgeMinX - columnGap
        let dividerHeight = height * layout.dividerHeightToPanelHeight

        func rowFrame(centerY: CGFloat, height ratio: CGFloat, minX: CGFloat, maxX: CGFloat) -> CGRect {
            CGRect(
                x: minX,
                y: centerY * height - height * ratio / 2,
                width: max(maxX - minX, 0),
                height: height * ratio
            )
        }

        return ResolvedGeometry(
            panelFrame: panel,
            leftTopFrame: rowFrame(
                centerY: layout.leftPrimaryCenterYToPanelHeight,
                height: layout.primaryRowHeightToPanelHeight,
                minX: leftMinX,
                maxX: leftMaxX
            ),
            leftBottomFrame: rowFrame(
                centerY: layout.leftSecondaryCenterYToPanelHeight,
                height: layout.secondaryRowHeightToPanelHeight,
                minX: leftMinX,
                maxX: leftMaxX
            ),
            badgeFrame: CGRect(
                x: badgeCenter - badgeSize / 2,
                y: (height - badgeSize) / 2,
                width: badgeSize,
                height: badgeSize
            ),
            dividerFrame: CGRect(
                x: dividerCenter - dividerWidth / 2,
                y: (height - dividerHeight) / 2,
                width: dividerWidth,
                height: dividerHeight
            ),
            rightTopFrame: rowFrame(
                centerY: layout.rightPrimaryCenterYToPanelHeight,
                height: layout.primaryRowHeightToPanelHeight,
                minX: rightMinX,
                maxX: rightMaxX
            ),
            rightBottomFrame: rowFrame(
                centerY: layout.rightSecondaryCenterYToPanelHeight,
                height: layout.secondaryRowHeightToPanelHeight,
                minX: rightMinX,
                maxX: rightMaxX
            )
        )
    }
}
