import Foundation
import Testing
@testable import PhotoMemo

@Suite("BatchConfigurationSnapshotProvider diagnostics")
struct BatchConfigurationSnapshotProviderDiagnosticsTests {

    @Test("Corrupted template payload is surfaced as a decoding failure while snapshot loading preserves the default template")
    func corruptedTemplatePayloadIsSurfacedAsDecodingFailure() throws {

        let suiteName =
            "PhotoMemo.BatchConfigurationSnapshotProviderDiagnosticsTests.corruptedTemplate.\(UUID().uuidString)"
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

        defaults.set(
            Data("not-a-template".utf8),
            forKey: "photomemo.selectedTemplate"
        )

        let provider =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )

        switch provider.loadTemplateResult() {
        case .decodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.selectedTemplate"
            )
            #expect(
                failure.payloadByteCount
                == Data("not-a-template".utf8).count
            )
            #expect(
                !failure.underlyingDescription.isEmpty
            )

        default:
            Issue.record(
                "Expected a decoding failure for the corrupted template payload."
            )
        }

        let snapshot =
            provider.loadSnapshot()

        #expect(
            snapshot.template
            == Template.template1
            .normalizedForEditing
        )
    }

    @Test("Missing shared-defaults payloads remain distinguishable from decoding failures")
    func missingSharedDefaultsPayloadsRemainDistinguishableFromDecodingFailures() throws {

        let suiteName =
            "PhotoMemo.BatchConfigurationSnapshotProviderDiagnosticsTests.noValue.\(UUID().uuidString)"
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

        let provider =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )

        switch provider.loadAnchorsResult() {
        case .noValue:
            break

        default:
            Issue.record(
                "Expected missing anchors to report .noValue."
            )
        }

        switch provider.loadBadgeResult() {
        case .noValue:
            break

        default:
            Issue.record(
                "Expected missing badge payload to report .noValue."
            )
        }
    }
}
