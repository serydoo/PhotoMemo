#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics
import Testing
@testable import MemoMark

@Suite("System reserved presentation regions")
struct ReservedPresentationRegionPolicyTests {
    @Test("Actual Duo viewport uses unequal regions after the system toolbar")
    func observedBookGeometry() {
        let region = ReservedPresentationDivision(frame: CGRect(x: 455.5, y: -82, width: 40, height: 669),
            leadingMargin: 20, trailingMargin: 20, topMargin: 0, bottomMargin: 0, isActive: true)
        let result = ReservedPresentationRegionPolicy.allocation(viewport: CGSize(width: 867, height: 553), divisions: [region])
        #expect(result?.arrangement == .sideBySide)
        #expect(result?.primary == CGRect(x: 0, y: 0, width: 435.5, height: 553))
        #expect(result?.secondary == CGRect(x: 515.5, y: 0, width: 351.5, height: 553))
        #expect(ReservedPresentationRegionPolicy.allocation(viewport: CGSize(width: 867, height: 553),
            divisions: [region], minimumRegionWidth: 420) == nil)
    }
    @Test("Tabletop rows consume system top and bottom margins")
    func horizontalDivision() {
        let region = ReservedPresentationDivision(frame: CGRect(x: -20, y: 400, width: 740, height: 20),
            leadingMargin: 0, trailingMargin: 0, topMargin: 20, bottomMargin: 20, isActive: true)
        let result = ReservedPresentationRegionPolicy.allocation(viewport: CGSize(width: 700, height: 900), divisions: [region])
        #expect(result?.arrangement == .stacked)
        #expect(result?.primary.height == 380)
        #expect(result?.secondary.minY == 440)
        #expect(result?.secondary.height == 460)
    }
    @Test("Native wide admission follows system divisions, never the device name")
    func nativeAdmission() {
        let flat = ReservedPresentationDivision(frame: CGRect(x: 455.5, y: -82, width: 40, height: 669),
            leadingMargin: 20, trailingMargin: 20, topMargin: 0, bottomMargin: 0, isActive: false)
        #expect(ReservedPresentationRegionPolicy.supportsNativeWidePresentation(
            viewport: CGSize(width: 867, height: 553), divisions: [flat]))
        #expect(!ReservedPresentationRegionPolicy.supportsNativeWidePresentation(
            viewport: CGSize(width: 1032, height: 1376), divisions: []))
        #expect(!ReservedPresentationRegionPolicy.supportsNativeWidePresentation(
            viewport: CGSize(width: 382, height: 562), divisions: [flat]))
        let tabletop = ReservedPresentationDivision(frame: CGRect(x: 0, y: 321.5, width: 669, height: 40),
            leadingMargin: 0, trailingMargin: 0, topMargin: 20, bottomMargin: 20, isActive: true)
        #expect(ReservedPresentationRegionPolicy.supportsNativeWidePresentation(
            viewport: CGSize(width: 669, height: 783), divisions: [tabletop]))
        let flatPortrait = ReservedPresentationDivision(frame: tabletop.frame,
            leadingMargin: 0, trailingMargin: 0, topMargin: 20, bottomMargin: 20, isActive: false)
        #expect(ReservedPresentationRegionPolicy.supportsNativeWidePresentation(
            viewport: CGSize(width: 669, height: 783), divisions: [flatPortrait]))
        #expect(ReservedPresentationRegionPolicy.allocation(
            viewport: CGSize(width: 669, height: 783), divisions: [flatPortrait]) == nil)
    }
    @Test("Keyboard-reduced regions still preserve the reserved gap")
    func keyboardCapacity() {
        let book = ReservedPresentationDivision(frame: CGRect(x: 455.5, y: -82, width: 40, height: 669),
            leadingMargin: 20, trailingMargin: 20, topMargin: 0, bottomMargin: 0, isActive: true)
        let allocation = ReservedPresentationRegionPolicy.allocation(viewport: CGSize(width: 867, height: 220),
            divisions: [book], minimumRegionWidth: 1, minimumRegionHeight: 1)
        #expect(allocation?.primary.height == 220)
        #expect(allocation?.secondary.minX == 515.5)
    }
    @Test("Flat, compact, invalid or ambiguous regions never invent a split")
    func fallback() {
        let frame = CGRect(x: 400, y: 0, width: 20, height: 900)
        let inactive = ReservedPresentationDivision(frame: frame, leadingMargin: 0, trailingMargin: 0,
            topMargin: 0, bottomMargin: 0, isActive: false)
        #expect(ReservedPresentationRegionPolicy.allocation(viewport: CGSize(width: 820, height: 900), divisions: [inactive]) == nil)
        #expect(ReservedPresentationRegionPolicy.allocation(viewport: CGSize(width: 440, height: 956), divisions: []) == nil)
        #expect(ReservedPresentationRegionPolicy.allocation(viewport: CGSize(width: CGFloat.nan, height: 900), divisions: [inactive]) == nil)
    }
}
#endif
