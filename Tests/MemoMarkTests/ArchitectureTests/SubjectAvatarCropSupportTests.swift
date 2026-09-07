#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Subject avatar crop support")
struct SubjectAvatarCropSupportTests {

    @Test("default configuration resolves to the base aspect-fill rect")
    func defaultConfigurationUsesBaseRect() {
        let sourceSize =
            CGSize(width: 1200, height: 800)
        let canvasSize =
            CGSize(width: 320, height: 320)

        let baseRect =
            SubjectAvatarCropSupport
            .aspectFillRect(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04
            )
        let drawRect =
            SubjectAvatarCropSupport
            .resolvedDrawRect(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04,
                configuration: .init()
            )

        #expect(drawRect == baseRect)
    }

    @Test("translation roundtrip stays stable across normalization")
    func translationRoundtripStaysStable() {
        let sourceSize =
            CGSize(width: 800, height: 1200)
        let canvasSize =
            CGSize(width: 320, height: 320)
        let translation =
            CGSize(width: 0, height: 60)

        let normalizedOffset =
            SubjectAvatarCropSupport
            .normalizedOffset(
                for: translation,
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04,
                zoomScale: 1.8
            )
        let restoredTranslation =
            SubjectAvatarCropSupport
            .translation(
                for: .init(
                    zoomScale: 1.8,
                    normalizedOffset: normalizedOffset
                ),
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04
            )

        #expect(abs(restoredTranslation.width - translation.width) < 0.001)
        #expect(abs(restoredTranslation.height - translation.height) < 0.001)
    }

    @Test("translation is clamped when it exceeds the zoom-adjusted bounds")
    func translationIsClampedToBounds() {
        let sourceSize =
            CGSize(width: 800, height: 1200)
        let canvasSize =
            CGSize(width: 320, height: 320)
        let maxTranslation =
            SubjectAvatarCropSupport
            .maximumTranslation(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04,
                zoomScale: 2
            )

        let clamped =
            SubjectAvatarCropSupport
            .clampedTranslation(
                CGSize(width: 999, height: -999),
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04,
                zoomScale: 2
            )

        #expect(clamped.width == maxTranslation.width)
        #expect(clamped.height == -maxTranslation.height)
    }

    @Test("pan bounds use the inset circular crop target instead of the full canvas")
    func panBoundsUseInsetCircularCropTarget() {
        let sourceSize = CGSize(width: 1600, height: 900)
        let canvasSize = CGSize(width: 320, height: 320)

        let translation =
            SubjectAvatarCropSupport.maximumTranslation(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.08,
                zoomScale: 1
            )

        // A landscape image fills the crop circle vertically and must retain
        // the complete surplus width as horizontal positioning space.
        #expect(translation.width > 100)
        #expect(translation.height == 0)
    }

    @Test("zoom expands the draw rect and applies normalized translation")
    func zoomExpandsDrawRectAndAppliesTranslation() {
        let sourceSize =
            CGSize(width: 1200, height: 800)
        let canvasSize =
            CGSize(width: 320, height: 320)

        let baseRect =
            SubjectAvatarCropSupport
            .resolvedDrawRect(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04,
                configuration: .init()
            )
        let zoomedRect =
            SubjectAvatarCropSupport
            .resolvedDrawRect(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04,
                configuration: .init(
                    zoomScale: 2,
                    normalizedOffset: .init(
                        width: 1,
                        height: 0
                    )
                )
            )

        #expect(zoomedRect.width > baseRect.width)
        #expect(zoomedRect.height > baseRect.height)
        #expect(zoomedRect.midX > baseRect.midX)
    }

    @Test("changing zoom preserves the source point under the crop center")
    func changingZoomPreservesCropCenterSourcePoint() {
        let sourceSize = CGSize(width: 1600, height: 900)
        let canvasSize = CGSize(width: 320, height: 320)
        let current = SubjectAvatarCropConfiguration(
            zoomScale: 1.8,
            normalizedOffset: CGSize(width: 0.42, height: -0.18)
        )

        let updated = SubjectAvatarCropSupport
            .configurationPreservingCropCenter(
                current,
                newZoomScale: 3,
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: 0.04
            )

        let currentRect = SubjectAvatarCropSupport.resolvedDrawRect(
            sourceSize: sourceSize,
            canvasSize: canvasSize,
            safeInsetRatio: 0.04,
            configuration: current
        )
        let updatedRect = SubjectAvatarCropSupport.resolvedDrawRect(
            sourceSize: sourceSize,
            canvasSize: canvasSize,
            safeInsetRatio: 0.04,
            configuration: updated
        )
        let currentBaseRect = SubjectAvatarCropSupport.aspectFillRect(
            sourceSize: sourceSize,
            canvasSize: canvasSize,
            safeInsetRatio: 0.04
        )
        let updatedBaseRect = currentBaseRect

        let currentSourcePoint = CGPoint(
            x: (canvasSize.width / 2 - currentRect.minX)
                / (currentBaseRect.width * current.zoomScale),
            y: (canvasSize.height / 2 - currentRect.minY)
                / (currentBaseRect.height * current.zoomScale)
        )
        let updatedSourcePoint = CGPoint(
            x: (canvasSize.width / 2 - updatedRect.minX)
                / (updatedBaseRect.width * updated.zoomScale),
            y: (canvasSize.height / 2 - updatedRect.minY)
                / (updatedBaseRect.height * updated.zoomScale)
        )

        #expect(updated.zoomScale == 3)
        #expect(abs(updatedSourcePoint.x - currentSourcePoint.x) < 0.001)
        #expect(abs(updatedSourcePoint.y - currentSourcePoint.y) < 0.001)
    }
}
#endif
