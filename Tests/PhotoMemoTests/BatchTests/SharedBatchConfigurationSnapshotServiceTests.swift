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
            == Template.classicWhite
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

    @Test("configuration readiness requires at least one saved preset")
    func configurationReadinessRequiresSavedPreset() throws {
        let suiteName =
            "PhotoMemo.SharedBatchConfigurationSnapshotServiceTests.readiness.\(UUID().uuidString)"
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

        let service =
            SharedBatchConfigurationSnapshotService(
                defaults: defaults
            )
        #expect(
            service
                .loadV1ConfigurationReadiness()
            == V1SavedConfigurationReadiness(
                isReady: false,
                presetTitle: nil,
                configurationID: nil,
                configurationRevision: nil
            )
        )

        let record: [String: Any] = [
            "selectedSubjectID": UUID().uuidString,
            "memoryPresets": [
                [
                    "id": UUID().uuidString,
                    "title": "成长记录",
                    "selectedSubjectID": UUID().uuidString
                ]
            ]
        ]
        let data =
            try JSONSerialization.data(
                withJSONObject: record
            )
        defaults.set(
            data,
            forKey: "photomemo.v1.subjectLibrary"
        )

        #expect(
            service
                .loadV1ConfigurationReadiness()
            == V1SavedConfigurationReadiness(
                isReady: true,
                presetTitle: "成长记录",
                configurationID: nil,
                configurationRevision: nil
            )
        )

        let snapshot = service.loadSnapshot()
        #expect(snapshot.configurationID == nil)
        #expect(snapshot.configurationRevision == nil)
    }
}
