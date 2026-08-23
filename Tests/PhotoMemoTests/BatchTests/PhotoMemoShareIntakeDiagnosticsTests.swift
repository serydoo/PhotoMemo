import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("PhotoMemoShareIntakeDiagnostics")
struct PhotoMemoShareIntakeDiagnosticsTests {

    @Test("Static Live Photo fallback EXIF dates without timezone use local capture timezone")
    func staticLivePhotoFallbackEXIFDatesWithoutTimezoneUseLocalCaptureTimezone() throws {

        let shanghai =
            try #require(
                TimeZone(identifier: "Asia/Shanghai")
            )
        let parsedDate =
            try #require(
                LivePhotoStaticFallbackDateParser.parse(
                    "2026:07:11 09:18:12",
                    timeZone: shanghai
                )
            )
        let expectedDate =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from:
                        DateComponents(
                            timeZone: shanghai,
                            year: 2026,
                            month: 7,
                            day: 11,
                            hour: 9,
                            minute: 18,
                            second: 12
                        )
                )
            )

        #expect(parsedDate == expectedDate)
    }

    @Test("Builds codable media intake rejection reports from policy verdicts")
    func buildsCodableMediaIntakeRejectionReportsFromPolicyVerdicts() throws {

        let verdict =
            PhotoProcessingInputPolicy
            .standard
            .verdict(
                contentType: .gif,
                pixelWidth: 100,
                pixelHeight: 100
            )

        let report =
            PhotoMemoMediaIntakeRejectionReport(
                verdict: verdict,
                fileName: "animated.gif",
                contentTypeIdentifier:
                    UTType.gif.identifier,
                pixelSize:
                    MediaPixelSize(
                        width: 100,
                        height: 100
                    )
            )

        #expect(report.reason == .unsupportedFormat)
        #expect(report.reasonRawValue == "unsupportedFormat")
        #expect(report.title == verdict.title)
        #expect(report.message == verdict.message)
        #expect(report.fileName == "animated.gif")
        #expect(report.contentTypeIdentifier == UTType.gif.identifier)
        #expect(report.pixelSize == MediaPixelSize(width: 100, height: 100))

        let decoded =
            try JSONDecoder()
            .decode(
                PhotoMemoMediaIntakeRejectionReport.self,
                from:
                    JSONEncoder()
                    .encode(report)
            )

        #expect(decoded == report)
        #expect(
            decoded.debugDescription
            .contains("unsupportedFormat")
        )
    }

    @Test("Share Extension unsupported skips preserve policy rejection reports")
    func shareExtensionUnsupportedSkipsPreservePolicyRejectionReports() throws {

        let intakeSource =
            try sourceText(
                relativePaths: [
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift",
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
                ]
            )
        let resultSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionImportResult.swift"
            )

        #expect(
            intakeSource
            .contains(
                "case skippedUnsupported(\n            PhotoMemoMediaIntakeRejectionReport"
            )
        )
        #expect(
            intakeSource
            .contains(
                "unsupportedRejectionReports.append("
            )
        )
        #expect(
            intakeSource
            .contains(
                "PhotoMemoMediaIntakeRejectionReport("
            )
        )
        #expect(
            resultSource
            .contains(
                "let unsupportedRejectionReports:"
            )
        )
        #expect(
            resultSource
            .contains(
                "firstUnsupportedRejectionReport"
            )
        )
    }

    @Test("Share Extension intake rejects oversized provider batches before persistence")
    func shareExtensionIntakeRejectsOversizedProviderBatchesBeforePersistence() throws {
        let intakeSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
            )
        let viewControllerSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
            )
        let rendererSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift"
            )
        let chineseLocalization =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
            )

        #expect(
            intakeSource
            .contains(
                "var maxSupportedPhotoCount: Int"
            )
        )
        #expect(
            intakeSource
            .contains(
                "snapshot.batchLimit"
            )
        )
        #expect(
            intakeSource
            .contains(
                "snapshot.remainingRecords"
            )
        )
        #expect(
            intakeSource
            .contains(
                "case tooManySharedItems"
            )
        )
        #expect(intakeSource.contains("providers.count <= maxSupportedPhotoCount"))
        #expect(
            intakeSource
            .contains(
                "persistSharedItems.tooManySharedItems"
            )
        )
        #expect(
            viewControllerSource
            .contains(
                ".maxSupportedPhotoCount"
            )
        )
        #expect(
            viewControllerSource
            .contains(
                "stage: .extensionInputTooManyPhotos"
            )
        )
        #expect(intakeSource.contains("share.error.too_many.recovery"))
        #expect(rendererSource.contains("share.status.stage.batch_too_large"))
        #expect(rendererSource.contains("share.status.message.batch_too_large"))
        #expect(rendererSource.contains("share.status.button.share_smaller_batches"))
        #expect(chineseLocalization.contains("\"share.error.too_many.recovery\""))
        #expect(chineseLocalization.contains("\"share.status.button.share_smaller_batches\""))
    }

    @Test("Share Extension intake uses the Live Photo-first provider selector")
    func shareExtensionIntakeUsesLivePhotoFirstProviderSelector() throws {
        let intakeSource =
            try sourceText(
                relativePaths: [
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift",
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareItemProviderLoader.swift",
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift",
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareLivePhotoRecovery.swift",
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareIntakeDiagnostics.swift"
                ]
            )

        #expect(
            intakeSource
            .contains(
                "let preferredImportType =\n                PhotoMemoShareProviderTypeSelection\n                .preferredImportTypeIdentifier("
            )
        )
        #expect(
            intakeSource
            .contains(
                "let preferredTypeIdentifier ="
            )
        )
        #expect(
            intakeSource
            .contains(
                "func preferredImportTypeIdentifier("
            )
        )
        #expect(
            intakeSource
            .contains(
                "allowsLivePhoto: true"
            )
        )
        #expect(
            intakeSource
            .contains(
                "requestedTypeIdentifier:\n                        livePhotoTypeIdentifier"
            )
        )
        #expect(
            intakeSource
            .contains(
                "allowsDirectoryPackage:\n                        true"
            )
        )
        #expect(
            intakeSource
            .contains(
                "recordStaticLivePhotoPayloadIfNeeded("
            )
        )
        #expect(
            intakeSource
            .contains(
                "stage:\n                .extensionLivePhotoRepresentationStaticPayload"
            )
        )
        #expect(
            intakeSource
            .contains(
                "routeWillFallbackToStaticWithoutAssetIdentity=true"
            )
        )
        #expect(
            intakeSource
            .contains(
                "let preferredStaticImageTypeIdentifier ="
            )
        )
        #expect(
            intakeSource
            .contains(
                "preferredRegisteredTypeIdentifier:"
            )
        )
        #expect(
            intakeSource
            .contains(
                "preferredStaticImageTypeIdentifier"
            )
        )
        #expect(
            intakeSource
            .contains(
                "func staticContentTypeIdentifier("
            )
        )
        #expect(
            intakeSource
            .contains(
                "livePhotoStaticFallbackCount"
            )
        )
    }

    @Test("Share Extension Live Photo intake does not preflight destructive provider loads")
    func shareExtensionLivePhotoIntakeDoesNotPreflightDestructiveProviderLoads() throws {
        let intakeSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
            )

        #expect(
            !intakeSource
            .contains(
                "await probeLivePhotoRepresentation("
            )
        )
    }

    @Test("Share Extension queues incomplete Live Photo provider payloads as recoverable still handoff")
    func shareExtensionQueuesIncompleteLivePhotoProviderPayloadsAsRecoverableStillHandoff() throws {
        let intakeCoordinatorSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionIntakeCoordinator.swift"
            )
        let rendererSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift"
            )

        #expect(
            intakeCoordinatorSource
                .contains("livePhotoStaticFallback=\\(result.livePhotoStaticFallbackCount)")
        )
        #expect(!rendererSource.contains("Live Photo 已按静态照片接收"))
        let importerSource = try sourceText(
            relativePath:
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
        )
        #expect(importerSource.contains("recordStaticLivePhotoPayloadIfNeeded"))
        #expect(importerSource.contains("livePhotoStaticFallback"))
        #expect(!importerSource.contains("livePhotoStaticFallbackRejected"))
        #expect(!importerSource.contains("static fallback is not permitted"))

        let recoverySource = try sourceText(
            relativePath:
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareLivePhotoRecovery.swift"
        )
        #expect(recoverySource.contains("sourceIdentifier:\n                    nil"))
    }

    @Test("Share Extension data fallback does not invent a Live Photo asset identity")
    func shareExtensionDataFallbackDoesNotInventLivePhotoAssetIdentity() throws {
        let intakeSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
            )

        #expect(
            intakeSource
            .contains(
                ".fallbackDataSourceIdentifier("
            )
        )
        #expect(
            intakeSource
            .contains(
                "func fallbackDataSourceIdentifier("
            )
        )
        #expect(
            !intakeSource
            .contains(
                "sourceIdentifier:\n                                                Self\n                                                .dedupeKey("
            )
        )
    }

    @Test("Share Extension records intake entry before provider filtering can fail")
    func shareExtensionRecordsIntakeEntryBeforeProviderFilteringCanFail() throws {
        let intakeServiceSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
            )
        let diagnosticsSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareIntakeDiagnostics.swift"
            )

        try expectOrdered(
            source: intakeServiceSource,
            earlier: "let requestID = UUID()",
            later: "diagnostics.recordReceived("
        )
        try expectOrdered(
            source: intakeServiceSource,
            earlier: "diagnostics.recordProviderDiagnostics(",
            later: "guard !providers.isEmpty"
        )
        #expect(
            diagnosticsSource.contains(
                "stage: .extensionInput"
            )
        )
        #expect(
            diagnosticsSource.contains(
                "itemProviders=\\(itemProviderCount), supportedProviders=\\(supportedProviderCount)"
            )
        )
    }

    @Test("Share Extension Live Photo intake includes in-place provider fallback")
    func shareExtensionLivePhotoIntakeIncludesInPlaceProviderFallback() throws {
        let importerSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
            )

        #expect(
            importerSource.contains(
                "func loadInPlaceFileRepresentationResult("
            )
        )
        #expect(
            importerSource.contains(
                "provider.loadInPlaceFileRepresentation("
            )
        )
        try expectOrdered(
            source: importerSource,
            earlier: "let liveFileLoadResult =",
            later: "let liveInPlaceLoadResult ="
        )
        try expectOrdered(
            source: importerSource,
            earlier: "let fileLoadResult =",
            later: "let inPlaceLoadResult ="
        )
        try expectOrdered(
            source: importerSource,
            earlier: "let inPlaceLoadResult =",
            later: "await loadFallbackItem("
        )
    }

    @Test("Share Extension loadItem diagnostics preserve unsupported payload class")
    func shareExtensionLoadItemDiagnosticsPreserveUnsupportedPayloadClass() throws {
        let importerSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
            )

        #expect(
            importerSource.contains(
                "let payloadClassDescription ="
            )
        )
        #expect(
            importerSource.contains(
                "itemClass=\\(String(reflecting: type(of: $0)))"
            )
        )
        #expect(
            importerSource.contains(
                "operation: \"loadItem\""
            )
        )
    }

    @Test("Captures nested underlying NSError summaries")
    func capturesNestedUnderlyingNSErrorSummaries() {

        let leafError =
            NSError(
                domain: "LeafDomain",
                code: 99,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Leaf failure"
                ]
            )

        let rootError =
            NSError(
                domain: "RootDomain",
                code: 12,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Root failure",
                    NSUnderlyingErrorKey:
                        leafError
                ]
            )

        let summary =
            PhotoMemoShareIntakeNSErrorSummary(
                nsError: rootError
            )

        #expect(summary.domain == "RootDomain")
        #expect(summary.code == 12)
        #expect(summary.localizedDescription == "Root failure")
        #expect(summary.underlyingError?.domain == "LeafDomain")
        #expect(summary.underlyingError?.code == 99)
        #expect(summary.underlyingError?.localizedDescription == "Leaf failure")
    }

    private func sourceText(
        relativePath: String
    ) throws -> String {

        try String(
            contentsOf:
                sourceURL(
                    relativePath: relativePath
                ),
            encoding: .utf8
        )
    }

    private func sourceText(
        relativePaths: [String]
    ) throws -> String {

        try relativePaths
            .map {
                try sourceText(
                    relativePath: $0
                )
            }
            .joined(
                separator: "\n"
            )
    }

    private func sourceURL(
        relativePath: String
    ) -> URL {

        let testsDirectory =
            URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot =
            testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        return repositoryRoot
            .appendingPathComponent(
                relativePath
            )
    }

    private func expectOrdered(
        source: String,
        earlier: String,
        later: String
    ) throws {

        let earlierIndex =
            try #require(
                source.range(of: earlier)?.lowerBound
            )
        let laterIndex =
            try #require(
                source.range(of: later)?.lowerBound
            )

        #expect(
            earlierIndex < laterIndex
        )
    }
}
