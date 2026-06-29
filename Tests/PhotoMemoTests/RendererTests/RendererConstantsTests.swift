import Testing
@testable import PhotoMemo

@Suite("PM-004 renderer constants")
struct RendererConstantsTests {

    @Test("PM-004 freezes information-bar anchor coordinates")
    func pm004FreezesInformationBarAnchorCoordinates() {
        let slots = RendererConstants.Slot.self

        #expect(slots.recorder.anchor.x == 0.06)
        #expect(slots.recorder.anchor.y == 0.18)
        #expect(slots.timeline.anchor.x == 0.42)
        #expect(slots.timeline.anchor.y == 0.18)
        #expect(slots.captureSummary.anchor.x == 0.74)
        #expect(slots.captureSummary.anchor.y == 0.18)
        #expect(slots.memoryBlock.anchor.x == 0.06)
        #expect(slots.memoryBlock.anchor.y == 0.60)
        #expect(slots.badge.anchor.x > slots.captureSummary.anchor.x)
        #expect(slots.badge.anchor.y > slots.memoryBlock.anchor.y)
    }

    @Test("PM-004 keeps Memory Block as the largest slot")
    func pm004KeepsMemoryBlockAsLargestSlot() {
        let slots = RendererConstants.Slot.self

        #expect(slots.memoryBlock.weight > slots.recorder.weight)
        #expect(slots.recorder.weight > slots.timeline.weight)
        #expect(slots.timeline.weight > slots.captureSummary.weight)
        #expect(slots.memoryBlock.size.width > slots.recorder.size.width)
    }

    @Test("PM-004 limits capture summary to four facts")
    func pm004LimitsCaptureSummaryToFourFacts() {
        #expect(
            RendererConstants.CaptureSummary.allowedFactCount == 4
        )

        #expect(
            RendererConstants.CaptureSummary.allowedFacts == [
                .focalLength,
                .aperture,
                .iso,
                .shutterSpeed
            ]
        )
    }

    @Test("Compact information bar freezes measured bar height ratios")
    func compactInformationBarFreezesMeasuredBarHeightRatios() {
        let compact =
            RendererConstants.CompactInformationBar.self

        #expect(compact.portrait.barHeightToWidth == 0.1660)
        #expect(compact.landscape.barHeightToWidth == 0.1266)
        #expect(
            compact.portrait.barHeightToWidth
            > compact.landscape.barHeightToWidth
        )
        #expect(
            compact.portrait.referencePhotoHeightToWidth
            > compact.landscape.referencePhotoHeightToWidth
        )
    }

    @Test("Compact information bar locks measured slot anchors")
    func compactInformationBarLocksMeasuredSlotAnchors() {
        let portrait =
            RendererConstants.CompactInformationBar.portrait
        let landscape =
            RendererConstants.CompactInformationBar.landscape

        #expect(portrait.leftX == 0.046)
        #expect(portrait.rightX == 0.590)
        #expect(portrait.logoCenterX == 0.514)
        #expect(portrait.dividerCenterX == 0.564)

        #expect(landscape.leftX == 0.035)
        #expect(landscape.rightX == 0.696)
        #expect(landscape.logoCenterX == 0.636)
        #expect(landscape.dividerCenterX == 0.675)
    }

    @Test("Compact information bar keeps final text single-line")
    func compactInformationBarKeepsFinalTextSingleLineScale() {
        let portrait =
            RendererConstants.CompactInformationBar.portrait

        #expect(portrait.primaryFontToBarHeight == 0.190)
        #expect(portrait.secondaryFontToBarHeight == 0.142)
        #expect(
            RendererConstants.CompactInformationBar.landscape
                .primaryFontToBarHeight == 0.190
        )
        #expect(
            RendererConstants.CompactInformationBar.landscape
                .secondaryFontToBarHeight == 0.142
        )
        #expect(portrait.contentCenterY == 0.500)
        #expect(portrait.dividerTopY < portrait.contentCenterY)
        #expect(
            portrait.dividerTopY + portrait.dividerHeight
            > portrait.contentCenterY
        )
    }

    @Test("Compact information bar maps custom regions to render areas")
    func compactInformationBarMapsCustomRegionsToRenderAreas() {
        #expect(
            CardRegion.region(for: .leftPrimary)
            == .slotA
        )
        #expect(
            CardRegion.region(for: .leftSecondary)
            == .slotB
        )
        #expect(
            CardRegion.region(for: .rightPrimary)
            == .slotC
        )
        #expect(
            CardRegion.region(for: .rightSecondary)
            == .slotD
        )

        #expect(CardRegion.slotA.compactInformationBarTextArea == .leftTop)
        #expect(CardRegion.slotB.compactInformationBarTextArea == .leftBottom)
        #expect(CardRegion.slotC.compactInformationBarTextArea == .rightTop)
        #expect(CardRegion.slotD.compactInformationBarTextArea == .rightBottom)
    }
}
