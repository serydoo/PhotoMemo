import CoreGraphics
import Testing
@testable import MemoMark

@Suite("FilmMark layout specification")
struct FilmMarkLayoutSpecificationTests {

    @Test("resolves lower-left and lower-right starts inside the safe area")
    func resolvesLowerCornerStartsInsideSafeArea() {
        let canvasSize = CGSize(width: 1_000, height: 800)
        let contentSize = CGSize(width: 200, height: 40)

        let lowerLeft = FilmMarkLayoutSpecification.resolve(
            canvasSize: canvasSize,
            contentSize: contentSize,
            placement: .init(anchor: .bottomLeft)
        )
        let lowerRight = FilmMarkLayoutSpecification.resolve(
            canvasSize: canvasSize,
            contentSize: contentSize,
            placement: .init(anchor: .bottomRight)
        )

        expectFrame(
            lowerLeft.frame,
            equals: CGRect(x: 40, y: 728, width: 200, height: 40)
        )
        expectFrame(
            lowerRight.frame,
            equals: CGRect(x: 760, y: 728, width: 200, height: 40)
        )
        expectFrameIsInsideSafeRect(lowerLeft)
        expectFrameIsInsideSafeRect(lowerRight)
    }

    @Test("directional nudges use a stable normalized step")
    func directionalNudgesUseStableNormalizedStep() {
        let start = FilmMarkPlacementDraft(anchor: .bottomLeft)

        let nudged = FilmMarkLayoutSpecification.nudged(
            start,
            direction: .right
        )

        #expect(nudged.normalizedOffset.x == 0.005)
        #expect(nudged.normalizedOffset.y == 0)
    }

    @Test("quantizes normalized offsets to fixed precision")
    func quantizesNormalizedOffsetsToFixedPrecision() {
        let offset = FilmMarkNormalizedOffset(x: 0.00504, y: -0.00503)

        #expect(offset.xUnits == 50)
        #expect(offset.yUnits == -50)
        #expect(offset.x == 0.005)
        #expect(offset.y == -0.005)
    }

    @Test("repeated nudges do not accumulate floating-point drift")
    func repeatedNudgesDoNotAccumulateFloatingPointDrift() {
        var placement = FilmMarkPlacementDraft(anchor: .bottomLeft)

        for _ in 0..<200 {
            placement = FilmMarkLayoutSpecification.nudged(
                placement,
                direction: .right
            )
        }

        #expect(placement.normalizedOffset.xUnits == 10_000)
        #expect(placement.normalizedOffset.x == 1)
    }

    @Test("resolved frame maps the same normalized nudge across aspect ratios")
    func resolvedFrameMapsNormalizedNudgeAcrossAspectRatios() {
        let placement = FilmMarkPlacementDraft(
            anchor: .bottomLeft,
            normalizedOffset: .init(x: 0.005, y: -0.005)
        )

        let wide = FilmMarkLayoutSpecification.resolve(
            canvasSize: CGSize(width: 1_000, height: 500),
            contentSize: CGSize(width: 100, height: 20),
            placement: placement
        )
        let tall = FilmMarkLayoutSpecification.resolve(
            canvasSize: CGSize(width: 500, height: 1_000),
            contentSize: CGSize(width: 100, height: 20),
            placement: placement
        )

        #expect(abs(wide.frame.minX - 45) < 0.0001)
        #expect(abs(wide.frame.minY - 457.5) < 0.0001)
        #expect(abs(tall.frame.minX - 22.5) < 0.0001)
        #expect(abs(tall.frame.minY - 935) < 0.0001)
    }

    @Test("clamps a nudged output without allowing it to leave the safe area")
    func clampsOutputToSafeArea() {
        let placement = FilmMarkPlacementDraft(
            anchor: .bottomRight,
            normalizedOffset: .init(x: 1, y: 1)
        )

        let resolved = FilmMarkLayoutSpecification.resolve(
            canvasSize: CGSize(width: 1_000, height: 800),
            contentSize: CGSize(width: 200, height: 40),
            placement: placement
        )

        expectFrame(
            resolved.frame,
            equals: CGRect(x: 760, y: 728, width: 200, height: 40)
        )
        expectFrameIsInsideSafeRect(resolved)
        #expect(abs(resolved.normalizedOffset.x) < 0.0001)
        #expect(abs(resolved.normalizedOffset.y) < 0.0001)
    }

    @Test("reports content overflow instead of silently shrinking it")
    func reportsContentOverflow() {
        let resolved = FilmMarkLayoutSpecification.resolve(
            canvasSize: CGSize(width: 100, height: 100),
            contentSize: CGSize(width: 200, height: 20),
            placement: .init(anchor: .bottomLeft)
        )

        #expect(resolved.isContentOverflowingSafeArea)
        #expect(resolved.frame.width == 200)
    }

    @Test("accounts for soft-shadow outset without marking the default anchor as overflow")
    func accountsForSoftShadowOutset() {
        let resolved = FilmMarkLayoutSpecification.resolve(
            canvasSize: CGSize(width: 1_000, height: 800),
            contentSize: CGSize(width: 200, height: 40),
            placement: .init(anchor: .bottomRight),
            appearance: .init(substrate: .softShadow)
        )

        #expect(!resolved.isContentOverflowingSafeArea)
        #expect(resolved.safeRect.contains(resolved.effectBounds))
        #expect(resolved.effectBounds.contains(resolved.substrateFrame))
    }

    @Test("bridges the top-left preview frame to the artifact coordinate system once")
    func bridgesPreviewFrameToArtifactCoordinates() {
        let resolved = FilmMarkLayoutSpecification.resolve(
            canvasSize: CGSize(width: 1_000, height: 800),
            contentSize: CGSize(width: 200, height: 40),
            placement: .init(anchor: .bottomRight)
        )

        let artifactFrame = FilmMarkCoordinateBridge.artifactFrame(
            for: resolved
        )

        expectFrame(
            artifactFrame,
            equals: CGRect(x: 760, y: 32, width: 200, height: 40)
        )
    }

    @Test("bridges arbitrary layout frames through the same artifact coordinate owner")
    func bridgesArbitraryFrameToArtifactCoordinates() {
        let frame = CGRect(x: 120, y: 260, width: 280, height: 64)

        let artifactFrame = FilmMarkCoordinateBridge.artifactFrame(
            for: frame,
            canvasSize: CGSize(width: 1_000, height: 800)
        )

        expectFrame(
            artifactFrame,
            equals: CGRect(x: 120, y: 476, width: 280, height: 64)
        )
    }

    @Test("normalizes FilmMark colors to the sRGB unit range")
    func normalizesColorsToSRGBUnitRange() {
        let color = FilmMarkRGBAColor(
            red: -0.2,
            green: 0.4,
            blue: 1.4,
            alpha: 2
        )

        #expect(color == FilmMarkRGBAColor(red: 0, green: 0.4, blue: 1, alpha: 1))
    }

    private func expectFrame(_ actual: CGRect, equals expected: CGRect) {
        #expect(abs(actual.minX - expected.minX) < 0.0001)
        #expect(abs(actual.minY - expected.minY) < 0.0001)
        #expect(abs(actual.width - expected.width) < 0.0001)
        #expect(abs(actual.height - expected.height) < 0.0001)
    }

    private func expectFrameIsInsideSafeRect(_ resolved: FilmMarkResolvedLayout) {
        let frame = resolved.frame
        let safeRect = resolved.safeRect
        #expect(frame.minX >= safeRect.minX - 0.0001)
        #expect(frame.minY >= safeRect.minY - 0.0001)
        #expect(frame.maxX <= safeRect.maxX + 0.0001)
        #expect(frame.maxY <= safeRect.maxY + 0.0001)
    }
}
