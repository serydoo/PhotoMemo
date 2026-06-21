import Testing
@testable import PhotoMemo

@MainActor
@Suite("Classic White snapshot")
struct ClassicWhiteSnapshotTests {

    @Test("Landscape standard snapshot stays stable")
    func landscapeStandardSnapshotStaysStable() throws {

        try ClassicWhiteSnapshotSupport
            .assertMatchesReference(
                scenario:
                    ClassicWhiteSnapshotSupport
                    .scenarios[0]
            )
    }

    @Test("Landscape long EXIF snapshot stays stable")
    func landscapeLongEXIFSnapshotStaysStable() throws {

        try ClassicWhiteSnapshotSupport
            .assertMatchesReference(
                scenario:
                    ClassicWhiteSnapshotSupport
                    .scenarios[1]
            )
    }

    @Test("Portrait standard snapshot stays stable")
    func portraitStandardSnapshotStaysStable() throws {

        try ClassicWhiteSnapshotSupport
            .assertMatchesReference(
                scenario:
                    ClassicWhiteSnapshotSupport
                    .scenarios[2]
            )
    }

    @Test("Portrait long memory snapshot stays stable")
    func portraitLongMemorySnapshotStaysStable() throws {

        try ClassicWhiteSnapshotSupport
            .assertMatchesReference(
                scenario:
                    ClassicWhiteSnapshotSupport
                    .scenarios[3]
            )
    }
}
