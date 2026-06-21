import CoreGraphics
import Testing
@testable import PhotoMemo

@Suite("Classic White renderer theme")
struct ClassicWhiteRendererThemeTests {

    @Test("Classic White locks the new fixed bottom-bar design system")
    func classicWhiteLocksFixedBottomBarDesignSystem() {

        let theme = ClassicWhiteRenderer.theme

        #expect(theme.bottomBar.height == 260)
        #expect(theme.colors.background.hexString == "#F4F3F3")
        #expect(theme.grid.leftRatio == 0.40)
        #expect(theme.grid.centerRatio == 0.20)
        #expect(theme.grid.rightRatio == 0.40)
        #expect(theme.typography.primaryTextSize == 28)
        #expect(theme.typography.secondaryTextSize == 18)
        #expect(theme.spacing.horizontalPadding == 80)
        #expect(theme.spacing.topPadding == 54)
        #expect(theme.spacing.bottomPadding == 42)
        #expect(theme.divider.width == 2)
        #expect(theme.divider.height == 110)
        #expect(theme.divider.color.hexString == "#D8D8D8")
    }

    @Test("Classic White export sizing adds a fixed bottom bar")
    func classicWhiteExportSizingAddsFixedBottomBar() {

        let outputSize = ClassicWhiteRenderer
            .outputPixelSize(
                for: PhotoMetadata(
                    imageWidth: 2048,
                    imageHeight: 1152
                ),
                fallbackSize: CGSize(
                    width: 1600,
                    height: 900
                )
            )

        #expect(outputSize.width == 2048)
        #expect(outputSize.height == 1412)
    }

    @Test("Classic White export sizing falls back to the image size when metadata dimensions are missing")
    func classicWhiteExportSizingFallsBackWhenMetadataDimensionsAreMissing() {

        let outputSize = ClassicWhiteRenderer
            .outputPixelSize(
                for: PhotoMetadata(),
                fallbackSize: CGSize(
                    width: 1200,
                    height: 800
                )
            )

        #expect(outputSize.width == 1200)
        #expect(outputSize.height == 1060)
    }
}
