import Foundation
import Testing
@testable import PhotoMemo

@Suite("SharedBatchConfigurationSnapshotService")
struct SharedBatchConfigurationSnapshotServiceTests {

    @Test("typed template reads surface decoding failures while preserving the tolerant snapshot convenience API")
    func typedTemplateReadsSurfaceDecodingFailures() throws {

        let suiteName =
            "PhotoMemo.SharedBatchConfigurationSnapshotServiceTests.template.\(UUID().uuidString)"
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
            Data("corrupted-template".utf8),
            forKey: "photomemo.selectedTemplate"
        )

        let service =
            SharedBatchConfigurationSnapshotService(
                defaults: defaults
            )

        switch service.loadTemplateResult() {
        case .decodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.selectedTemplate"
            )
            #expect(
                failure.payloadByteCount
                == Data("corrupted-template".utf8).count
            )

        default:
            Issue.record(
                "Expected corrupted shared template defaults to surface a decoding failure."
            )
        }

        #expect(
            service.loadSnapshot().template
            == Template.template1
            .normalizedForEditing
        )
    }

    @Test("shared snapshot carries the saved location display configuration")
    func sharedSnapshotCarriesLocationDisplayConfiguration() throws {

        let suiteName =
            "PhotoMemo.SharedBatchConfigurationSnapshotServiceTests.locationDisplay.\(UUID().uuidString)"
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

        let configuration =
            LocationDisplayInspectorPresenter
            .configuration(
                for: "cityDistrict"
            )
        let data =
            try JSONEncoder()
            .encode(configuration)
        defaults.set(
            data,
            forKey:
                "photomemo.locationDisplayConfiguration"
        )

        let service =
            SharedBatchConfigurationSnapshotService(
                defaults: defaults
            )

        #expect(
            service
                .loadSnapshot()
                .locationDisplayConfiguration
            == configuration
        )
    }
}
