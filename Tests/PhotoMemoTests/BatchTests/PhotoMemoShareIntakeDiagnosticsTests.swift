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
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
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

        #expect(
            intakeSource
            .contains(
                "static let maxSupportedPhotoCount = 20"
            )
        )
        #expect(
            intakeSource
            .contains(
                "case tooManySharedItems"
            )
        )
        #expect(
            intakeSource
            .contains(
                "guard providers.count <= Self.maxSupportedPhotoCount"
            )
        )
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
        #expect(
            intakeSource.contains(
                "美好的记忆适合慢慢整理。每次最多分享 20 张，可以分几次完成，也能让处理过程更稳定。"
            )
        )
        #expect(
            rendererSource.contains(
                "这次的照片有点多"
            )
        )
        #expect(
            rendererSource.contains(
                "返回分批分享"
            )
        )
    }

    @Test("Share Extension intake uses the Live Photo-first provider selector")
    func shareExtensionIntakeUsesLivePhotoFirstProviderSelector() throws {
        let intakeSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
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
                "let preferredTypeIdentifier =\n            preferredImportTypeIdentifier("
            )
        )
        #expect(
            intakeSource
            .contains(
                "preferredImportTypeIdentifier(\n        from registeredTypeIdentifiers:"
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
                "preferredRegisteredTypeIdentifier:\n                    preferredStaticImageTypeIdentifier"
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
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
            )

        #expect(
            !intakeSource
            .contains(
                "await probeLivePhotoRepresentation("
            )
        )
    }

    @Test("Share Extension copy tells users when Live Photos fall back to static photos")
    func shareExtensionCopyTellsUsersWhenLivePhotosFallBackToStaticPhotos() throws {
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
            .contains(
                "livePhotoStaticFallback=\\(result.livePhotoStaticFallbackCount)"
            )
        )
        #expect(
            rendererSource
            .contains(
                "张 Live Photo 已按静态照片接收"
            )
        )
    }

    @Test("Share Extension data fallback does not invent a Live Photo asset identity")
    func shareExtensionDataFallbackDoesNotInventLivePhotoAssetIdentity() throws {
        let intakeSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
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
}
