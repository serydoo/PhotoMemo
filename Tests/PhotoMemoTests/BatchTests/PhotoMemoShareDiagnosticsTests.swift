import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemo share diagnostics")
struct PhotoMemoShareDiagnosticsTests {

    @Test("Reset result surfaces encoding failures")
    func resetResultSurfacesEncodingFailures() throws {

        let suiteName =
            "PhotoMemo.ShareDiagnostics.Reset.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        enum ExpectedFailure: Error {
            case encodeFailed
        }

        let result =
            PhotoMemoShareDiagnostics
            .resetResult(
                reason: "reset",
                defaults: defaults,
                encode: { _ in
                    throw ExpectedFailure.encodeFailed
                }
            )

        switch result {
        case .encodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.shareDiagnostics.events"
            )
            #expect(
                failure.underlyingDescription
                .contains("encodeFailed")
            )
        case .success:
            Issue.record(
                "Expected .encodingFailed when reset encoding throws."
            )
        }
    }

    @Test("Distinguishes empty diagnostics storage from corrupted payloads")
    func distinguishesEmptyStorageFromCorruptedPayloads() throws {

        let suiteName =
            "PhotoMemo.ShareDiagnostics.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        switch PhotoMemoShareDiagnostics
            .loadEventsResult(defaults: defaults) {
        case .noValue:
            break
        case .success,
             .decodingFailed:
            Issue.record(
                "Expected .noValue for empty diagnostics storage."
            )
        }

        defaults.set(
            Data("bad-diagnostics".utf8),
            forKey:
                "photomemo.shareDiagnostics.events"
        )

        switch PhotoMemoShareDiagnostics
            .loadEventsResult(defaults: defaults) {
        case .decodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.shareDiagnostics.events"
            )
            #expect(
                failure.payloadByteCount
                == Data("bad-diagnostics".utf8).count
            )
            #expect(
                !failure.underlyingDescription.isEmpty
            )
        case .noValue,
             .success:
            Issue.record(
                "Expected .decodingFailed for corrupted diagnostics payload."
            )
        }
    }

    @Test("Known share-diagnostics stage raw values resolve to typed constants")
    func resolvesKnownStageRawValues() {

        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "app.enqueue.created"
            ) == .appEnqueueCreated
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "extension.source.ready"
            ) == .extensionSourceReady
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "liveActivity.request.created"
            ) == .liveActivityRequestCreated
        )
    }

    @Test("Unknown share-diagnostics stage raw values remain round-trippable")
    func preservesUnknownStageRawValues() {

        let stage =
            PhotoMemoShareDiagnosticStage(
                rawValue: "legacy.custom.stage"
            )

        #expect(stage.rawValue == "legacy.custom.stage")
    }

    @Test("Diagnostic event decoding keeps compatibility with stored stage strings")
    func decodesStoredStageStrings() throws {

        let data =
            try JSONEncoder().encode([
                [
                    "id": UUID().uuidString,
                    "timestamp": "2026-06-30T06:00:00Z",
                    "stage": "extension.request.persisted",
                    "message": "persisted"
                ],
                [
                    "id": UUID().uuidString,
                    "timestamp": "2026-06-30T06:00:01Z",
                    "stage": "legacy.custom.stage",
                    "message": "legacy"
                ]
            ])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let events =
            try decoder.decode(
                [PhotoMemoShareDiagnosticEvent].self,
                from: data
            )

        #expect(events.count == 2)
        #expect(events[0].stage == .extensionRequestPersisted)
        #expect(events[1].stage.rawValue == "legacy.custom.stage")
    }

    @Test("Persist result surfaces encoding failures without changing stored format expectations")
    func persistResultSurfacesEncodingFailures() throws {

        let suiteName =
            "PhotoMemo.ShareDiagnostics.Persist.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        enum ExpectedFailure: Error {
            case encodeFailed
        }

        let result =
            PhotoMemoShareDiagnostics
            .persistResult(
                [
                    PhotoMemoShareDiagnosticEvent(
                        stage: .extensionRequestCreated,
                        message: "test"
                    )
                ],
                defaults: defaults,
                encode: { _ in
                    throw ExpectedFailure.encodeFailed
                }
            )

        switch result {
        case .encodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.shareDiagnostics.events"
            )
            #expect(
                failure.underlyingDescription
                .contains("encodeFailed")
            )
        case .success:
            Issue.record(
                "Expected .encodingFailed when the encoder throws."
            )
        }
    }
}
