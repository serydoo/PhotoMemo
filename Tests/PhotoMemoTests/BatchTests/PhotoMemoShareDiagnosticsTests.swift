import Foundation
import Testing
import UniformTypeIdentifiers
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
                rawValue: "app.enqueue.taskRoute"
            ) == .appEnqueueTaskRoute
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "app.picker.itemObserved"
            ) == .appPickerItemObserved
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "batch.task.route"
            ) == .batchTaskRoute
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "batch.task.duration"
            ) == .batchTaskDuration
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "extension.provider.observed"
            ) == .extensionProviderObserved
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "extension.livePhotoRepresentation.probe"
            ) == .extensionLivePhotoRepresentationProbe
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
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "livePhoto.videoComposition.geometry"
            ) == .livePhotoVideoCompositionGeometry
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "livePhoto.assetResources.observed"
            ) == .livePhotoAssetResourcesObserved
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "livePhoto.assetResource.exportFailed"
            ) == .livePhotoAssetResourceExportFailed
        )
    }

    @Test("Live Photo provider type selection prefers Live Photo before image")
    func livePhotoProviderTypeSelectionPrefersLivePhotoBeforeImage() {
        let selectedType =
            PhotoMemoShareProviderTypeSelection
            .preferredImportTypeIdentifier(
                from: [
                    UTType.jpeg.identifier,
                    "com.apple.live-photo",
                    UTType.heic.identifier
                ]
            )

        #expect(selectedType == "com.apple.live-photo")
        #expect(
            PhotoMemoShareProviderTypeSelection
                .supportsLivePhoto(
                    [
                        UTType.jpeg.identifier,
                        "com.apple.live-photo",
                        UTType.heic.identifier
                    ]
            )
        )
    }

    @Test("Live Photo representation probe messages include operation")
    func livePhotoRepresentationProbeMessagesIncludeOperation() {
        let message =
            PhotoMemoShareLivePhotoRepresentationProbe
            .message(
                operation: "loadItem",
                providerIndex: 0,
                typeIdentifier: "com.apple.live-photo",
                resultDescription: "itemClass=PHLivePhoto",
                url: nil,
                error: nil
            )

        #expect(message.contains("operation=loadItem"))
        #expect(message.contains("type=com.apple.live-photo"))
        #expect(message.contains("itemClass=PHLivePhoto"))
    }

    @Test("Static image provider type selection falls back to first supported image")
    func staticImageProviderTypeSelectionFallsBackToFirstSupportedImage() {
        let selectedType =
            PhotoMemoShareProviderTypeSelection
            .preferredImportTypeIdentifier(
                from: [
                    UTType.jpeg.identifier,
                    UTType.heic.identifier
                ]
            )

        #expect(selectedType == UTType.jpeg.identifier)
        #expect(
            !PhotoMemoShareProviderTypeSelection
                .supportsLivePhoto(
                    [
                        UTType.jpeg.identifier,
                        UTType.heic.identifier
                    ]
                )
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
