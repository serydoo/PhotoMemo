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

    @Test("Default and shared snapshot loading keep raw anchor expression-style payloads through round-trip re-encoding")
    func defaultAndSharedSnapshotLoadingKeepRawAnchorExpressionStylePayloadsThroughRoundTripReEncoding() throws {

        let suiteName =
            "PhotoMemo.BatchConfigurationSnapshotProviderDiagnosticsTests.expressionStyle.\(UUID().uuidString)"
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

        let anchor =
            Anchor(
                id: UUID(),
                type: .birthday,
                title: "生日",
                date: Date(
                    timeIntervalSince1970:
                        1_725_206_400
                )
            )

        defaults.set(
            try anchorsPayloadData(
                for: [anchor],
                expressionStyle:
                    "birthdayAgeToday"
            ),
            forKey: "photomemo.anchors"
        )
        defaults.set(
            anchor.id.uuidString,
            forKey: "photomemo.selectedAnchorID"
        )

        let provider =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )
        let sharedService =
            SharedBatchConfigurationSnapshotService(
                defaults: defaults
            )

        #expect(
            try encodedExpressionStyle(
                from: provider.loadSnapshot().anchor
            ) == "birthdayNatural"
        )
        #expect(
            try encodedExpressionStyle(
                from: sharedService.loadSnapshot().anchor
            ) == "birthdayNatural"
        )
    }
}

private extension BatchConfigurationSnapshotProviderDiagnosticsTests {

    func anchorsPayloadData(
        for anchors: [Anchor],
        expressionStyle: String
    ) throws -> Data {

        let data =
            try JSONEncoder().encode(anchors)
        guard
            var payload =
                try JSONSerialization
                .jsonObject(with: data)
                as? [[String: Any]],
            !payload.isEmpty
        else {
            throw CocoaError(.coderInvalidValue)
        }

        payload[0]["expressionStyle"] =
            expressionStyle

        return try JSONSerialization.data(
            withJSONObject: payload
        )
    }

    func encodedExpressionStyle(
        from anchor: Anchor?
    ) throws -> String? {

        guard let anchor else {
            return nil
        }

        let data =
            try JSONEncoder().encode(anchor)

        return (
            try JSONSerialization
            .jsonObject(with: data)
            as? [String: Any]
        )?["expressionStyle"] as? String
    }
}
