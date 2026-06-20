import Foundation
import Testing
@testable import PhotoMemo

@Suite("ExternalPhotoIntakeStore Diagnostics")
struct ExternalPhotoIntakeStoreDiagnosticsTests {

    @Test("Detailed managed copy reports copy-stage failure for non-file URLs")
    func reportsCopyStageFailureForNonFileURLs() {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let directoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: directoryURL
            )

        let seed =
            PhotoMemoShareIntakeOperationSeed(
                itemProviderCount: 3,
                supportedProviderCount: 2,
                providerIndex: 1,
                requestedTypeIdentifier: "public.image",
                preferredRegisteredTypeIdentifier: "public.heic"
            )

        let result =
            store.createManagedCopyDetailed(
                from: URL(string: "https://example.com/test.heic")!,
                requestID: UUID(),
                index: 0,
                diagnosticsSeed: seed
            )

        #expect(result.managedURL == nil)
        #expect(result.failureContext?.stage == .copy)
        #expect(result.failureContext?.itemProviderCount == 3)
        #expect(result.failureContext?.supportedProviderCount == 2)
        #expect(result.failureContext?.providerIndex == 1)
        #expect(result.failureContext?.requestedTypeIdentifier == "public.image")
        #expect(result.failureContext?.preferredRegisteredTypeIdentifier == "public.heic")
        #expect(result.failureContext?.errorSummary?.domain == "PhotoMemoShareIntake")

        try? FileManager.default.removeItem(
            at: directoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }
}
