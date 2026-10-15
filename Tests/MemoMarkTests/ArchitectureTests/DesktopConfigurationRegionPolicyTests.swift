#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics
import Testing
@testable import MemoMark

@Suite("Desktop Configuration region capacity")
struct DesktopConfigurationRegionPolicyTests {
    @Test("Readable form capacity controls desktop split without phone orientation heuristics")
    func capacity() {
        #expect(DesktopConfigurationRegionPolicy.arrangement(viewport: CGSize(width: 866, height: 600)) == .sideBySide)
        #expect(DesktopConfigurationRegionPolicy.arrangement(viewport: CGSize(width: 865, height: 600)) == .stacked)
        #expect(DesktopConfigurationRegionPolicy.arrangement(viewport: CGSize(width: 1200, height: 300)) == .stacked)
        #expect(DesktopConfigurationRegionPolicy.arrangement(viewport: CGSize(width: 1032, height: 1376)) == .sideBySide)
        #expect(DesktopConfigurationRegionPolicy.arrangement(viewport: CGSize(width: 1200, height: 800),
            minimumPreviewWidth: 525, minimumEditorWidth: 750) == .stacked)
        for bad in [CGFloat.nan, .infinity, -1, 0] {
            #expect(DesktopConfigurationRegionPolicy.arrangement(viewport: CGSize(width: bad, height: 800)) == .stacked)
        }
    }

    @Test("Peer allocation preserves form width and exactly fills the viewport")
    func allocation() {
        for width: CGFloat in [866, 1024, 1180, 1500] {
            let preview = DesktopConfigurationRegionPolicy.previewWidth(viewportWidth: width)
            #expect(preview >= 350)
            #expect(width - preview - DesktopConfigurationRegionPolicy.spacing >= 500)
        }
        #expect(DesktopConfigurationRegionPolicy.previewWidth(viewportWidth: 866) == 350)
        #expect(DesktopConfigurationRegionPolicy.previewWidth(viewportWidth: .nan) == 0)
    }
}
#endif
