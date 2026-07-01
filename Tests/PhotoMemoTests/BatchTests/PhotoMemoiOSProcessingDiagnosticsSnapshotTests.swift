import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemoiOSProcessingDiagnosticsSnapshot")
struct PhotoMemoiOSProcessingDiagnosticsSnapshotTests {

    @Test("Distinguishes empty shared state from corrupted persisted payloads")
    func distinguishesEmptyStateFromCorruptedPayloads() throws {

        let suiteName =
            "PhotoMemo.iOSProcessingDiagnostics.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let emptySnapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot.load(
                defaults: defaults
            )

        #expect(
            emptySnapshot
            .shareDiagnosticsAvailability
            == .empty
        )
        #expect(
            emptySnapshot
            .sharedQueueAvailability
            == .empty
        )
        #expect(
            emptySnapshot.recoveryMessage
            == nil
        )

        defaults.set(
            Data("bad-diagnostics".utf8),
            forKey:
                "photomemo.shareDiagnostics.events"
        )
        defaults.set(
            Data("bad-queue".utf8),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        let corruptedSnapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot.load(
                defaults: defaults
            )

        #expect(
            corruptedSnapshot
            .shareDiagnosticsAvailability
            == .corrupted
        )
        #expect(
            corruptedSnapshot
            .sharedQueueAvailability
            == .corrupted
        )
        #expect(
            corruptedSnapshot.hasCorruptedPersistence
        )
        #expect(
            corruptedSnapshot.recoveryMessage?
            .contains("共享进度记录")
            == true
        )
        #expect(
            corruptedSnapshot.recoveryMessage?
            .contains("共享队列快照")
            == true
        )
    }

    @Test("Preserves readable diagnostics events while surfacing queue corruption")
    func preservesReadableEventsWhileSurfacingQueueCorruption() throws {

        let suiteName =
            "PhotoMemo.iOSProcessingDiagnostics.Partial.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let events = [
            PhotoMemoShareDiagnosticEvent(
                stage: .extensionRequestPersisted,
                message: "persisted"
            )
        ]

        defaults.set(
            try JSONEncoder().encode(events),
            forKey:
                "photomemo.shareDiagnostics.events"
        )
        defaults.set(
            Data("bad-queue".utf8),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        let snapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot.load(
                defaults: defaults
            )

        #expect(
            snapshot
            .shareDiagnosticsAvailability
            == .available
        )
        #expect(
            snapshot
            .sharedQueueAvailability
            == .corrupted
        )
        #expect(
            snapshot.events == events
        )
        #expect(
            snapshot.recoveryMessage?
            .contains("共享队列快照")
            == true
        )
    }

    @Test("Surfaces corrupted persisted external intake requests")
    func surfacesCorruptedPersistedExternalIntakeRequests() throws {

        let suiteName =
            "PhotoMemo.iOSProcessingDiagnostics.Intake.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        defaults.set(
            Data("bad-intake".utf8),
            forKey:
                "photomemo.externalIntake.requests"
        )

        let snapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot.load(
                defaults: defaults
            )

        #expect(
            snapshot
            .externalIntakeAvailability
            == .corrupted
        )
        #expect(
            snapshot.hasCorruptedPersistence
        )
        #expect(
            snapshot.recoveryMessage?
            .contains("共享接单记录")
            == true
        )
    }
}
