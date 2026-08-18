import Foundation
import Testing
@testable import PhotoMemo

@Suite("Production diagnostics")
struct ProductionDiagnosticsTests {

    @Test("Support identifiers are stable and operation scoped")
    func supportIdentifierIsStable() {
        let operationID = UUID(
            uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF"
        )!

        #expect(
            ProductionDiagnosticSupportID.make(
                prefix: "CFG",
                operationID: operationID
            ) == "CFG-1234567890AB"
        )
    }

    @Test("Failed diagnostic events export an explicit support identifier")
    func failedEventsIncludeSupportIdentifier() {
        let operationID = UUID(
            uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF"
        )!
        let event = ProductionDiagnosticEvent(
            operationID: operationID,
            category: .processing,
            stage: "processing.importing",
            outcome: .failed,
            errorCode: .processingDecodeFailed
        )

        #expect(
            event.supportID
            == "JOB-1234567890AB"
        )
    }

    @Test("Failure guidance follows the interface language")
    func failureGuidanceFollowsInterfaceLanguage() {
        let failure = ProductionDiagnosticFailureClassifier
            .configurationSave(
                ConfigurationLibraryPersistenceError
                    .writeFailed("write failed"),
                operationID: UUID(),
                language: .english
            )

        #expect(failure.userMessage.contains("could not be written"))
        #expect(failure.userMessage.contains("Support ID: CFG-"))
        #expect(!failure.userMessage.contains("故障编号"))
    }

    @Test("Configuration failures map to stable codes and recovery messages")
    func configurationFailuresAreClassified() {
        let operationID = UUID()
        let failure = ProductionDiagnosticFailureClassifier
            .configurationSave(
                ConfigurationLibraryPersistenceError.staleAggregate(
                    candidateRevision: 2,
                    storedRevision: 3
                ),
                operationID: operationID
            )

        #expect(failure.code == .configurationRevisionConflict)
        #expect(failure.supportID.hasPrefix("CFG-"))
        #expect(failure.userMessage.contains("其他修改"))
        #expect(failure.userMessage.contains(failure.supportID))
    }

    @Test("Wrapped file-system failures preserve actionable classification")
    func wrappedFileSystemFailuresAreClassified() {
        let underlyingError = NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileWriteOutOfSpaceError,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "private path must not enter diagnostics"
            ]
        )
        let failure = ProductionDiagnosticFailureClassifier
            .configurationSave(
                ConfigurationLibraryPersistenceError
                    .writeFailed(
                        String(describing: underlyingError)
                    ),
                operationID: UUID()
            )

        #expect(failure.code == .configurationWriteNoSpace)
        #expect(failure.userMessage.contains("存储空间不足"))
        #expect(
            failure.systemError?.domain
            == NSCocoaErrorDomain
        )
        #expect(
            failure.systemError?.code
            == NSFileWriteOutOfSpaceError
        )
    }

    @Test("Processing phases map to actionable failure codes")
    func processingPhasesAreClassified() {
        let importFailure =
            ProductionDiagnosticFailureClassifier
            .processing(
                phase: BatchTaskPhase.importing.rawValue,
                classification: "unsupportedInput",
                operationID: UUID(),
                error: CocoaError(.fileReadCorruptFile)
            )
        let exportFailure =
            ProductionDiagnosticFailureClassifier
            .processing(
                phase: BatchTaskPhase.exporting.rawValue,
                classification: "processingFailure",
                operationID: UUID(),
                error: CocoaError(.fileWriteUnknown)
            )
        let photoLibraryFailure =
            ProductionDiagnosticFailureClassifier
            .processing(
                phase:
                    BatchTaskPhase
                    .savingToPhotoLibrary
                    .rawValue,
                classification: "processingFailure",
                operationID: UUID(),
                error: CocoaError(.fileWriteUnknown)
            )

        #expect(importFailure.code == .processingImportFailed)
        #expect(exportFailure.code == .processingExportFailed)
        #expect(
            photoLibraryFailure.code
            == .photoLibrarySaveFailed
        )
        #expect(
            photoLibraryFailure.userMessage
                .contains("照片权限")
        )
    }

    @Test("Empty resolved content maps to actionable content guidance")
    func emptyResolvedContentIsClassified() {
        let failure = ProductionDiagnosticFailureClassifier
            .processing(
                phase: BatchTaskPhase.metadataReady.rawValue,
                classification: "processingFailure",
                operationID: UUID(),
                error: ProductionConfigurationContractError
                    .emptyResolvedContent
            )

        #expect(failure.code == .processingContentValidationFailed)
        #expect(
            failure.userMessage.contains(
                "照片缺少当前配置需要的拍摄信息"
            )
        )
        #expect(!failure.userMessage.contains("EXIF"))
    }

    @Test("Media input rejection reasons remain actionable after repository wrapping")
    func mediaInputRejectionReasonsRemainActionableAfterWrapping() {
        let operationID = UUID()
        let wrappedError = PhotoMemoError(
            code: .importFailed,
            message: "Unable to import the selected photo.",
            diagnosticCode:
                PhotoProcessingInputPolicy
                .RejectionReason
                .extremeAspectRatio
                .rawValue
        )

        let failure = ProductionDiagnosticFailureClassifier
            .processing(
                phase: BatchTaskPhase.importing.rawValue,
                classification: "unsupportedInput",
                operationID: operationID,
                error: wrappedError
            )

        #expect(failure.code == .processingExtremeAspectRatio)
        #expect(failure.userMessage.contains("全景图"))
        #expect(failure.userMessage.contains(failure.supportID))
    }

    @Test("Photo library reasons remain actionable after repository wrapping")
    func photoLibraryReasonsRemainActionableAfterWrapping() async throws {
        let repository = PhotoLibraryRepository(
            photoLibraryExportService:
                FailingPhotoLibraryExportService(
                    error: .albumNotFound
                )
        )
        let result = await repository.ensureAlbum(
            named: "MemoMark"
        )
        let wrappedError = try #require(
            result.error
        )
        let failure =
            ProductionDiagnosticFailureClassifier
            .processing(
                phase:
                    BatchTaskPhase
                    .savingToPhotoLibrary
                    .rawValue,
                classification:
                    "processingFailure",
                operationID: UUID(),
                error: wrappedError
            )

        #expect(
            wrappedError.diagnosticCode
            == ProductionDiagnosticErrorCode
                .photoLibraryAlbumNotFound
                .rawValue
        )
        #expect(
            failure.code
            == .photoLibraryAlbumNotFound
        )
    }

    @Test("Missing managed intake source has a specific recovery reason")
    func missingManagedIntakeSourceHasSpecificRecoveryReason() {
        let failure = ProductionDiagnosticFailureClassifier
            .processing(
                phase: BatchTaskPhase.queued.rawValue,
                classification: "interrupted",
                operationID: UUID(),
                error: CocoaError(.fileNoSuchFile)
            )

        #expect(failure.code == .processingSourceMissing)
        #expect(failure.userMessage.contains("接收的照片副本已不可用"))
        #expect(failure.supportID.hasPrefix("JOB-"))
    }

    @Test("Photos failures keep their actionable reason")
    func photoLibraryFailuresKeepTheirActionableReason() {
        let unauthorized = ProductionDiagnosticFailureClassifier
            .processing(
                phase: BatchTaskPhase.savingToPhotoLibrary.rawValue,
                classification: "photoLibrary",
                operationID: UUID(),
                error: PhotoLibraryExportError.unauthorized,
                language: .english
            )
        let missingAlbum = ProductionDiagnosticFailureClassifier
            .processing(
                phase: BatchTaskPhase.savingToPhotoLibrary.rawValue,
                classification: "photoLibrary",
                operationID: UUID(),
                error: PhotoLibraryExportError.albumNotFound,
                language: .english
            )
        let pendingReadback =
            ProductionDiagnosticFailureClassifier
            .processing(
                phase:
                    BatchTaskPhase
                    .savingToPhotoLibrary
                    .rawValue,
                classification: "photoLibrary",
                operationID: UUID(),
                error:
                    PhotoLibraryExportError
                    .savedAssetReadbackPending,
                language: .english
            )

        #expect(unauthorized.code == .photoLibraryUnauthorized)
        #expect(unauthorized.userMessage.contains("permission"))
        #expect(missingAlbum.code == .photoLibraryAlbumNotFound)
        #expect(missingAlbum.userMessage.contains("no longer exists"))
        #expect(
            pendingReadback.code
            == .photoLibraryAssetReadbackPending
        )
        #expect(
            pendingReadback.userMessage
                .contains("still confirming")
        )

        let pendingLivePhotoReadback =
            ProductionDiagnosticFailureClassifier
            .processing(
                phase:
                    BatchTaskPhase
                    .savingToPhotoLibrary
                    .rawValue,
                classification: "photoLibrary",
                operationID: UUID(),
                error:
                    LivePhotoAssetWritingError
                    .savedAssetReadbackPending,
                language: .english
            )
        #expect(
            pendingLivePhotoReadback.code
            == .photoLibraryAssetReadbackPending
        )
        #expect(
            pendingLivePhotoReadback.userMessage
                .contains("still confirming")
        )

        let livePhotoReadback =
            ProductionDiagnosticFailureClassifier
            .processing(
                phase:
                    BatchTaskPhase.exporting.rawValue,
                classification: "processing",
                operationID: UUID(),
                error:
                    LivePhotoAssetWritingError
                    .savedAssetNotLivePhoto,
                language: .simplifiedChinese
            )
        #expect(
            livePhotoReadback.code
            == .photoLibraryLivePhotoVerificationFailed
        )
        #expect(
            livePhotoReadback.userMessage
                .contains("没有把处理结果保留为实况照片")
        )
    }

    @Test("Event storage is bounded and recovers from last known good data")
    func storeIsBoundedAndRecovers() async throws {
        let directoryURL = temporaryDirectoryURL()
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        let store = ProductionDiagnosticsStore(
            directoryURL: directoryURL,
            maximumEventCount: 2
        )

        for index in 1...3 {
            try await store.record(
                ProductionDiagnosticEvent(
                    operationID: UUID(),
                    category: .configuration,
                    stage: "configuration.test.\(index)",
                    outcome: .succeeded
                )
            )
        }

        let currentEvents = try await store.loadEvents()
        #expect(currentEvents.map(\.stage) == [
            "configuration.test.2",
            "configuration.test.3"
        ])

        try Data("corrupted".utf8).write(
            to: directoryURL.appendingPathComponent("events.json"),
            options: .atomic
        )
        let recoveredStore = ProductionDiagnosticsStore(
            directoryURL: directoryURL,
            maximumEventCount: 2
        )
        let recoveredEvents = try await recoveredStore.loadEvents()

        #expect(recoveredEvents.map(\.stage) == [
            "configuration.test.1",
            "configuration.test.2"
        ])
    }

    @Test("Event storage self-heals when both copies are corrupted")
    func storeSelfHealsAfterCompleteCorruption() async throws {
        let directoryURL = temporaryDirectoryURL()
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        for fileName in [
            "events.json",
            "events-last-known-good.json"
        ] {
            try Data("corrupted".utf8).write(
                to: directoryURL.appendingPathComponent(fileName),
                options: .atomic
            )
        }
        let store = ProductionDiagnosticsStore(
            directoryURL: directoryURL
        )
        let operationID = UUID()

        try await store.record(
            ProductionDiagnosticEvent(
                operationID: operationID,
                category: .diagnostics,
                stage: "diagnostics.export",
                outcome: .started
            )
        )
        let events = try await store.loadEvents()

        #expect(events.count == 2)
        #expect(
            events.first?.stage
            == "diagnostics.storageRecovery"
        )
        #expect(
            events.first?.errorCode
            == .diagnosticsReadFailed
        )
        #expect(events.last?.stage == "diagnostics.export")
    }

    @Test("Export excludes raw errors and user content")
    func exportIsSanitized() async throws {
        let directoryURL = temporaryDirectoryURL()
        let exportDirectoryURL = temporaryDirectoryURL()
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
            try? FileManager.default.removeItem(at: exportDirectoryURL)
        }
        let secret = "PRIVATE SUBJECT /private/photo-name.heic"
        let unsafeError = NSError(
            domain: NSCocoaErrorDomain,
            code: NSFileWriteNoPermissionError,
            userInfo: [NSLocalizedDescriptionKey: secret]
        )
        let failure = ProductionDiagnosticFailureClassifier
            .configurationSave(
                unsafeError,
                operationID: UUID()
            )
        let store = ProductionDiagnosticsStore(
            directoryURL: directoryURL
        )
        try await store.record(
            ProductionDiagnosticEvent(
                operationID: UUID(),
                category: .configuration,
                stage: "configuration.save",
                outcome: .failed,
                errorCode: failure.code,
                systemError: failure.systemError,
                context: ProductionDiagnosticContext(
                    aggregateRevision: 9,
                    configurationRevision: 4,
                    regionMetrics: [
                        .init(
                            region: "slotA",
                            characterCount: 240,
                            newlineCount: 3
                        )
                    ]
                )
            )
        )

        let legacySecret =
            "fileName=private-child.heic, path=/private/location"
        let exportURL = try await store.makeExport(
            metadata: ProductionDiagnosticEnvironment(
                appVersion: "4.0",
                buildNumber: "400",
                operatingSystem: "iOS 26.0",
                deviceFamily: "iPhone"
            ),
            legacyEvents: [
                PhotoMemoShareDiagnosticEvent(
                    stage: .extensionError,
                    message: legacySecret,
                    requestID: UUID(),
                    jobID: UUID()
                ),
                PhotoMemoShareDiagnosticEvent(
                    stage: .livePhotoAssetReadback,
                    message:
                        "result=invalid, livePhoto=false, pairedVideoResource=false, fileName=private.heic, path=/private/location",
                    requestID: UUID(),
                    jobID: UUID()
                )
            ],
            exportDirectoryURL: exportDirectoryURL
        )
        let exportText = try String(
            contentsOf: exportURL,
            encoding: .utf8
        )

        #expect(!exportText.contains(secret))
        #expect(!exportText.contains("photo-name.heic"))
        #expect(!exportText.contains(legacySecret))
        #expect(!exportText.contains("private-child.heic"))
        #expect(exportText.contains("extension.error"))
        #expect(
            exportText.contains(
                "result=invalid, livePhoto=false, pairedVideoResource=false"
            )
        )
        #expect(!exportText.contains("private.heic"))
        #expect(!exportText.contains("/private/location"))
        #expect(exportText.contains("configuration.write.permissionDenied"))
        #expect(exportText.contains("characterCount"))
        #expect(exportText.contains("240"))
    }

    private func temporaryDirectoryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkProductionDiagnosticsTests-\(UUID().uuidString)",
                isDirectory: true
            )
    }
}

private struct FailingPhotoLibraryExportService:
    PhotoLibraryExporting {

    let error: PhotoLibraryExportError

    func fetchAlbumOptions()
    async throws -> [PhotoAlbumOption] {
        throw error
    }

    func ensureAlbum(
        named title: String
    ) async throws -> PhotoAlbumOption {
        throw error
    }

    func saveImageResult(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?
    ) async throws -> PhotoLibrarySaveResult {
        throw error
    }
}
