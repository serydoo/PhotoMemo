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
                rawValue: "app.sharedContainerReadiness"
            ) == .appSharedContainerReadiness
        )
        #expect(
            PhotoMemoShareDiagnosticStage(
                rawValue: "batch.task.admission"
            ) == .batchTaskAdmission
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
                rawValue: "batch.task.stageDuration"
            ) == .batchTaskStageDuration
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
                rawValue: "extension.livePhotoRepresentation.staticPayload"
            ) == .extensionLivePhotoRepresentationStaticPayload
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

    @Test("Diagnostics retain a full 20-photo mixed evidence matrix")
    func retainsFullTwentyPhotoMixedEvidenceMatrix() throws {

        let suiteName =
            "PhotoMemo.ShareDiagnostics.Retention.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let requestID =
            UUID()
        _ = PhotoMemoShareDiagnostics
            .recordResult(
                stage:
                    .appSharedContainerReadiness,
                message:
                    "appGroup=group.com.serydoo.PhotoMemo, handoffReady=true, userDefaultsSuiteAvailable=true, appGroupContainerAvailable=true, usesFallbackUserDefaults=false, usesFallbackBaseDirectory=false, baseDirectory=/app-group",
                requestID: requestID,
                defaults: defaults
            )

        for photoIndex in 0..<20 {
            for eventIndex in 0..<32 {
                let stage:
                    PhotoMemoShareDiagnosticStage
                let message:
                    String

                switch eventIndex % 8 {
                case 0:
                    stage =
                        .extensionProviderObserved
                    message =
                        "index=\(photoIndex), type=com.apple.live-photo"
                case 1:
                    stage =
                        .extensionSourceReady
                    message =
                        "index=\(photoIndex), fileName=IMG_\(photoIndex).livephoto, type=com.apple.live-photo-bundle, managedPayload=directory"
                case 2:
                    stage =
                        .extensionLivePhotoRepresentationProbe
                    message =
                        "index=\(photoIndex), operation=loadItem, type=com.apple.live-photo, result=failed"
                case 3:
                    stage =
                        .extensionLivePhotoRepresentationStaticPayload
                    message =
                        "index=\(photoIndex), requestedType=com.apple.live-photo, fileName=IMG_\(photoIndex).HEIC, contentType=public.jpeg, canResolveBundle=false, routeWillFallbackToStaticWithoutAssetIdentity=true"
                case 4:
                    stage =
                        .appLivePhotoIdentityRecovery
                    message =
                        "result=notFound, fileName=IMG_\(photoIndex).HEIC, fallback=static"
                case 5:
                    stage =
                        .batchTaskRoute
                    message =
                        "taskID=task-\(photoIndex)-\(eventIndex), fileName=IMG_\(photoIndex).HEIC, contentType=public.jpeg, hasSourceIdentifier=false, sourceURLIsLivePhotoBundle=false, route=staticImage"
                case 6:
                    stage =
                        .batchTaskStageDuration
                    message =
                        "taskID=task-\(photoIndex)-\(eventIndex), fileName=IMG_\(photoIndex).HEIC, contentType=public.jpeg, route=staticImage, stageName=export, outcome=completed, durationSeconds=0.001, attachmentCreated=true, isMainThread=false, threadName=batch-worker, peakResidentMemoryBytes=123456789"
                default:
                    stage =
                        .batchTaskDuration
                    message =
                        "taskID=task-\(photoIndex)-\(eventIndex), fileName=IMG_\(photoIndex).HEIC, contentType=public.jpeg, route=staticImage, runtimeStage=total, phase=completed, durationSeconds=0.010"
                }

            _ = PhotoMemoShareDiagnostics
                .recordResult(
                    stage: stage,
                    message: message,
                    requestID: requestID,
                    defaults: defaults
                )
            }
        }

        let events =
            PhotoMemoShareDiagnostics
            .loadEvents(
                defaults: defaults
            )

        #expect(events.count == 641)
        #expect(
            events.first?.stage
            == .appSharedContainerReadiness
        )
        #expect(
            events.contains {
                $0.stage == .batchTaskStageDuration
                && $0.message.contains("peakResidentMemoryBytes=123456789")
                && $0.message.contains("threadName=batch-worker")
            }
        )
        #expect(
            events.last?.message
            .contains("taskID=task-19-31")
            == true
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
