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
            rootSceneSource.contains("MemoMarkConfigurationCenterView("),
            "Expected the iOS runtime root to render the accepted Configuration Center root view."
        )
        #expect(
            !rootSceneSource.contains("MemoMarkiOSTemporaryEntryView("),
            "Temporary entry switching should no longer be part of the main iOS runtime path."
        )
        #expect(
            !rootSceneSource.contains("MemoMarkiOSTemporaryEntryConfiguration"),
            "Main iOS runtime should not carry temporary-entry configuration state anymore."
        )

        let configurationSource =
            try String(
                contentsOfFile:
                    MemoMarkTestPaths.path(
                        "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
                    ),
                encoding: .utf8
            )
        #expect(
            configurationSource.contains(
                ".accessibilityIdentifier(\"configuration-center-root\")"
            ),
            "The Configuration Center must expose one stable semantic root for UI automation."
        )
        #expect(
            configurationSource.contains("runtimeEnvironment: runtimeEnvironment"),
            "Presentation capabilities must flow from the root into the Home surface."
        )

        let homeSource =
            try String(
                contentsOfFile:
                    MemoMarkTestPaths.path(
                        "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
                    ),
                encoding: .utf8
            )
        #expect(
            homeSource.contains(
                ".accessibilityIdentifier(\"home-photo-picker\")"
            ),
            "The photo-picker action must remain discoverable independent of interface language."
        )

        let intakeSource =
            try String(
                contentsOfFile:
                    MemoMarkTestPaths.path(
                        "Source/MemoMark/MemoMark/iOS/Views/UIKitPhotoPicker.swift"
                    ),
                encoding: .utf8
            )
        #expect(
            intakeSource.contains(".livePhotos"),
            "The production picker must explicitly include complete Live Photos."
        )
    }
}
#endif
