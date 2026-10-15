#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics
import Testing
@testable import MemoMark

@Suite("Native compact navigation capability")
struct NativeCompactNavigationPolicyTests {
    @Test("Compact portrait rail requires a native vertical-toolbar capability")
    func nativeCapabilityAdmission() {
        let outer = CGSize(width: 382, height: 562)
        #expect(NativeCompactNavigationPolicy.usesFixedRail(hasVerticalToolbar: true,
            isPhone: true, viewport: outer, usesWidePresentation: false))
        #expect(!NativeCompactNavigationPolicy.usesFixedRail(hasVerticalToolbar: false,
            isPhone: true, viewport: outer, usesWidePresentation: false))
        #expect(!NativeCompactNavigationPolicy.usesFixedRail(hasVerticalToolbar: true,
            isPhone: false, viewport: outer, usesWidePresentation: false))
        #expect(!NativeCompactNavigationPolicy.usesFixedRail(hasVerticalToolbar: true,
            isPhone: true, viewport: outer, usesWidePresentation: true))
    }
    @Test("Wide, landscape and invalid windows retain their established presentation")
    func conservativeFallback() {
        for size in [CGSize(width: 867, height: 635), CGSize(width: 1032, height: 1376),
                     CGSize(width: CGFloat.nan, height: 562), .zero] {
            #expect(!NativeCompactNavigationPolicy.usesFixedRail(hasVerticalToolbar: true,
                isPhone: true, viewport: size, usesWidePresentation: false))
        }
    }
}
#endif
