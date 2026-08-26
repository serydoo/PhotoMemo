#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("iOS runtime surface contract")
struct IOSRuntimeSurfaceContractTests {

    @Test("main iOS runtime root no longer routes through the temporary entry switcher")
    func mainIOSRuntimeRootNoLongerRoutesThroughTheTemporaryEntrySwitcher() throws {
        let rootSceneSource =
            try String(
                contentsOfFile:
                    MemoMarkTestPaths.path(
                        "Source/MemoMark/MemoMark/App/MemoMarkRootSceneView.swift"
                    ),
                encoding: .utf8
            )

        #expect(
            rootSceneSource.contains("MemoMarkiOSV1View("),
            "Expected the iOS runtime root to render the accepted V1 root view."
        )
        #expect(
            !rootSceneSource.contains("MemoMarkiOSTemporaryEntryView("),
            "Temporary entry switching should no longer be part of the main iOS runtime path."
        )
        #expect(
            !rootSceneSource.contains("MemoMarkiOSTemporaryEntryConfiguration"),
            "Main iOS runtime should not carry temporary-entry configuration state anymore."
        )
    }
}
#endif
