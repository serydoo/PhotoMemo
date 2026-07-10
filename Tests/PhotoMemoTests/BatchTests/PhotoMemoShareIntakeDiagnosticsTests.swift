import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("PhotoMemoShareIntakeDiagnostics")
struct PhotoMemoShareIntakeDiagnosticsTests {

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
                "PhotoMemoShareExtensionIntakeService\n            .maxSupportedPhotoCount"
            )
        )
        #expect(
            viewControllerSource
            .contains(
                "stage: .extensionInputTooManyPhotos"
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
