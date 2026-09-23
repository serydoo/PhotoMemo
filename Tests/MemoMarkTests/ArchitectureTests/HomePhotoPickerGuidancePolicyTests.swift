#if !MEMOMARK_SHARE_EXTENSION
import Foundation
@testable import MemoMark
import Testing

@Suite("Home photo picker guidance policy")
struct HomePhotoPickerGuidancePolicyTests {

    @Test("beginner photo picker guidance ends at the configured use threshold")
    func beginnerGuidanceEndsAtThreshold() {
        #expect(
            HomePhotoPickerGuidancePolicy.shouldShowBeginnerGuidance(
                useCount: 0
            )
        )
        #expect(
            HomePhotoPickerGuidancePolicy.shouldShowBeginnerGuidance(
                useCount:
                    HomePhotoPickerGuidancePolicy.useThreshold - 1
            )
        )
        #expect(
            !HomePhotoPickerGuidancePolicy.shouldShowBeginnerGuidance(
                useCount: HomePhotoPickerGuidancePolicy.useThreshold
            )
        )
    }
}
#endif
