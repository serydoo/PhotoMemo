import Foundation
import Testing
@testable import PhotoMemo

@Suite("BatchConfigurationSnapshotProvider diagnostics")
struct BatchConfigurationSnapshotProviderDiagnosticsTests {

    @Test("legacy V1 snapshot does not fabricate aggregate configuration identity")
    func legacyV1SnapshotKeepsConfigurationIdentityNil() throws {
        let suiteName =
            "PhotoMemo.BatchConfigurationSnapshotProviderDiagnosticsTests.legacyIdentity.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let snapshot = BatchConfigurationSnapshotProvider(
            defaults: defaults
        ).loadSnapshot()

        #expect(snapshot.configurationID == nil)
        #expect(snapshot.configurationRevision == nil)
        #expect(
            snapshot.canonicalProductionSnapshot?.configurationID
            == nil
        )
        #expect(
            snapshot.canonicalProductionSnapshot?
                .configurationRevision
            == nil
        )
    }

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
            == Template.classicWhite
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

#if !PHOTOMEMO_SHARE_EXTENSION
    @Test("Loaded batch snapshot embeds memory subject in frozen configuration snapshot")
    func loadedBatchSnapshotEmbedsMemorySubjectInFrozenConfigurationSnapshot() throws {
        let suiteName =
            "PhotoMemo.BatchConfigurationSnapshotProviderDiagnosticsTests.frozenMemory.\(UUID().uuidString)"
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

        let profile =
            PersonalProfile(
                relationshipRole: .custom,
                customRelationshipLabel: "妈妈",
                babyNickname: "途途"
            )
        defaults.set(
            try JSONEncoder().encode(profile),
            forKey: "photomemo.personalProfile"
        )

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
            try JSONEncoder().encode([anchor]),
            forKey: "photomemo.anchors"
        )
        defaults.set(
            anchor.id.uuidString,
            forKey: "photomemo.selectedAnchorID"
        )

        let snapshot =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )
            .loadSnapshot()

        #expect(
            snapshot.frozenMemorySubject
            == nil
        )

        let configurationSnapshot =
            try #require(
                snapshot.frozenConfigurationSnapshot
            )
        let subject =
            try #require(
                configurationSnapshot.memorySubject
            )

        #expect(
            subject.identity.displayName
            == "途途"
        )
        #expect(
            subject.primaryTimeAnchor?.title
            == "生日"
        )
        #expect(
            configurationSnapshot.subjectID
            == subject.id
        )
        #expect(
            configurationSnapshot.memorySubject
            == subject
        )
        #expect(
            configurationSnapshot.primaryAnchor?.title
            == "生日"
        )
    }

    @Test("Loaded batch snapshot prefers saved MemorySubject over legacy personal profile")
    func loadedBatchSnapshotPrefersSavedMemorySubjectOverLegacyPersonalProfile() throws {
        let suiteName =
            "PhotoMemo.BatchConfigurationSnapshotProviderDiagnosticsTests.selectedMemorySubject.\(UUID().uuidString)"
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

        let profile =
            PersonalProfile(
                relationshipRole: .custom,
                customRelationshipLabel: "妈妈",
                babyNickname: "旧Profile对象"
            )
        defaults.set(
            try JSONEncoder().encode(profile),
            forKey: "photomemo.personalProfile"
        )

        let anchorDate =
            Date(
                timeIntervalSince1970:
                    1_725_206_400
            )
        let selectedSubject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "配置中心对象",
                        shortName: "中心对象"
                    ),
                relationship:
                    .init(
                        role: "家庭",
                        label: "爸爸"
                    ),
                referenceDate: anchorDate,
                timeAnchors: [
                    .init(
                        title: "配置中心生日",
                        date: anchorDate,
                        note: "生日",
                        anchorType: .birthday,
                        expressionStyle:
                            .birthdayAgeToday
                    )
                ],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor:
                            "配置中心生日",
                        iconStrategy:
                            .autoMatch,
                        badgeStrategy:
                            .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "配置中心表达",
                                blocks: [
                                    .text(
                                        "配置中心对象"
                                    )
                                ]
                            )
                    ),
                decorations: []
            )

        defaults.set(
            try JSONEncoder().encode(selectedSubject),
            forKey: "photomemo.selectedMemorySubject"
        )
        defaults.set(
            "旧兼容对象",
            forKey: "photomemo.selectedMemorySubjectText"
        )

        let snapshot =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )
            .loadSnapshot()
        #expect(
            snapshot.frozenMemorySubject
            == nil
        )

        let configurationSnapshot =
            try #require(
                snapshot.frozenConfigurationSnapshot
            )
        let subject =
            try #require(
                configurationSnapshot.memorySubject
            )

        #expect(
            subject.identity.displayName
            == "配置中心对象"
        )
        #expect(
            snapshot.memorySubjectText
            == "中心对象"
        )
        #expect(
            subject.primaryTimeAnchor?.title
            == "配置中心生日"
        )
        #expect(
            configurationSnapshot.expression.title
            == "配置中心表达"
        )
        #expect(
            configurationSnapshot.memorySubject
            == subject
        )
        #expect(
            configurationSnapshot.primaryAnchor?
                .expressionStyle
            == .birthdayAgeToday
        )
    }

    @Test("Loaded batch snapshot prefers selected subject library record over stale standalone subject and default profile")
    func loadedBatchSnapshotPrefersSelectedSubjectLibraryRecordOverStaleStandaloneSubjectAndDefaultProfile() throws {
        let suiteName =
            "PhotoMemo.BatchConfigurationSnapshotProviderDiagnosticsTests.subjectLibraryFallback.\(UUID().uuidString)"
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

        let fallbackProfile =
            PersonalProfile(
                relationshipRole: .familyMember,
                customRelationshipLabel: "",
                babyNickname: ""
            )
        defaults.set(
            try JSONEncoder().encode(fallbackProfile),
            forKey: "photomemo.personalProfile"
        )

        let anchorDate =
            Date(
                timeIntervalSince1970:
                    1_748_217_600
            )
        let selectedSubject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "途途",
                        shortName: "途途"
                    ),
                relationship:
                    .init(
                        role: "家庭",
                        label: "儿子"
                    ),
                referenceDate: anchorDate,
                timeAnchors: [
                    .init(
                        title: "途途生日",
                        date: anchorDate,
                        note: "生日",
                        anchorType: .birthday,
                        expressionStyle:
                            .birthdayAgeToday
                    )
                ],
                expressionSubjectSource:
                    .displayName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor:
                            "途途生日",
                        iconStrategy:
                            .autoMatch,
                        badgeStrategy:
                            .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "途途表达",
                                blocks: [
                                    .text("途途")
                                ]
                            )
                    ),
                decorations: []
            )
        let otherSubject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "备用对象",
                        shortName: "备用"
                    ),
                relationship:
                    .init(
                        role: "家庭",
                        label: "家人"
                    ),
                referenceDate: anchorDate,
                timeAnchors: [],
                expressionSubjectSource:
                    .displayName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "备用表达",
                                blocks: []
                            )
                    ),
                decorations: []
            )
        let record =
            V1SubjectLibraryRecord(
                subjects: [
                    otherSubject,
                    selectedSubject
                ],
                selectedSubjectID:
                    selectedSubject.id
            )
        defaults.set(
            try JSONEncoder().encode(record),
            forKey: "photomemo.v1.subjectLibrary"
        )
        defaults.set(
            try JSONEncoder().encode(otherSubject),
            forKey: "photomemo.selectedMemorySubject"
        )
        defaults.set(
            "家人",
            forKey: "photomemo.selectedMemorySubjectText"
        )

        let snapshot =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )
            .loadSnapshot()
        let configurationSnapshot =
            try #require(
                snapshot.frozenConfigurationSnapshot
            )
        let subject =
            try #require(
                configurationSnapshot.memorySubject
            )

        #expect(
            subject.identity.displayName
            == "途途"
        )
        #expect(
            snapshot.memorySubjectText
            == "途途"
        )
        #expect(
            subject.primaryTimeAnchor?.title
            == "途途生日"
        )
        #expect(
            configurationSnapshot.expression.title
            == "途途表达"
        )
    }
#endif
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
