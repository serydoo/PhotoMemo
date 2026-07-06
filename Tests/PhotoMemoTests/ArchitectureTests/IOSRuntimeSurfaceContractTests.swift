#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("iOS runtime surface contract")
struct IOSRuntimeSurfaceContractTests {

    @Test("main iOS runtime root no longer routes through the temporary entry switcher")
    func mainIOSRuntimeRootNoLongerRoutesThroughTheTemporaryEntrySwitcher() throws {
        let rootSceneSource =
            try String(
                contentsOfFile:
                    "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift",
                encoding: .utf8
            )

        #expect(
            rootSceneSource.contains("ConfigurationCenteriOSView("),
            "Expected the iOS runtime root to render Configuration Center directly."
        )
        #expect(
            !rootSceneSource.contains("PhotoMemoiOSTemporaryEntryView("),
            "Temporary entry switching should no longer be part of the main iOS runtime path."
        )
        #expect(
            !rootSceneSource.contains("PhotoMemoiOSTemporaryEntryConfiguration"),
            "Main iOS runtime should not carry temporary-entry configuration state anymore."
        )
    }
}
#endif
