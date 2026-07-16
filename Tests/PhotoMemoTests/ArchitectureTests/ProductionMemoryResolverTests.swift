#if !PHOTOMEMO_SHARE_EXTENSION
import AppKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Production memory resolver", .serialized)
struct ProductionMemoryResolverTests {

    @Test("resolves directly from frozen ConfigurationSnapshot")
    func resolvesDirectlyFromFrozenConfigurationSnapshot() throws {
        let suite =
            suiteName("directFrozenConfigurationSnapshot")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let liveProfile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "妈妈",
            babyNickname: "运行期对象"
        )
        defaults.set(
            try JSONEncoder().encode(liveProfile),
            forKey: "photomemo.personalProfile"
        )

        let anchorDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()
        let subject =
            MemorySubjectAdapter.adapt(
                profile:
                    PersonalProfile(
                        relationshipRole: .custom,
                        customRelationshipLabel: "爸爸",
                        babyNickname: "直接Snapshot对象"
                    ),
                anchors: [
                    Anchor(
                        type: .birthday,
                        title: "直接Snapshot生日",
                        date: anchorDate
                    )
                ],
                referenceDate: anchorDate
            )
        let snapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )

        let payload =
            try #require(
                ProductionMemoryResolver()
                .resolve(
                    photo: selectedPhoto(
                        captureDate: captureDate
                    ),
                    frozenSnapshot: snapshot
                )
            )

        #expect(
            payload.subject.identity.displayName
            == "直接Snapshot对象"
        )
        #expect(
            payload.snapshot == snapshot
        )
        #expect(
            payload.module.renderedText
            == "今天直接Snapshot对象18天"
        )
        #expect(
            payload
                .productionExpressionContext?
                .value(
                    for: MemoryProvider.memoryToken
                )?
                .resolvedText
            == "今天直接Snapshot对象18天"
        )
        #expect(
            payload.result.primaryAnchorResult?
                .anchorTitle
            == "直接Snapshot生日"
        )
    }

    @Test("direct frozen snapshot resolution requires embedded MemorySubject")
    func directFrozenSnapshotResolutionRequiresEmbeddedMemorySubject() throws {
        let suite =
            suiteName("directSnapshotWithoutSubject")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        var snapshot =
            ConfigurationSnapshotBuilder.build(
                from:
                    try #require(
                        ConfigurationCenterState
                            .mock
                            .selectedSubject
                    )
            )
        snapshot.memorySubject = nil

        let payload =
            ProductionMemoryResolver()
            .resolve(
                photo: selectedPhoto(
                    captureDate: Date(
                        timeIntervalSince1970:
                            1_725_206_400
                    )
                ),
                frozenSnapshot: snapshot
            )

        #expect(payload == nil)
    }

    @Test("resolves memory payload from production inputs using capture time")
    func resolvesMemoryPayloadFromProductionInputsUsingCaptureTime() throws {
        let suite =
            suiteName("resolvesMemoryPayload")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let profile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "妈妈",
            babyNickname: "小宝"
        )
        let profileData =
            try #require(
                try? JSONEncoder().encode(profile)
            )
        defaults.set(
            profileData,
            forKey: "photomemo.personalProfile"
        )

        let birthday =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()

        let payload =
            ProductionMemoryResolver()
            .resolveLegacyBatchConfiguration(
                photo: selectedPhoto(
                    captureDate: captureDate
                ),
                configuration:
                    BatchConfigurationSnapshot(
                        template:
                            .classicWhite
                            .normalizedForEditing,
                        badge: nil,
                        anchor: Anchor(
                            type: .birthday,
                            title: "生日",
                            date: birthday
                        ),
                        shouldWritePhotoDescription:
                            false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    )
            )

        #expect(
            payload.subject.identity.displayName
            == "家人"
        )
        #expect(
            payload.snapshot.subjectID
            == payload.subject.id
        )
        #expect(
            payload.module.sourceAnchor?.title
            == "生日"
        )
        #expect(
            payload.module.renderedText
            == "今天家人18天"
        )
        #expect(
            payload.result.subjectID
            == payload.subject.id
        )
        #expect(
            payload.result.captureDate
            == captureDate
        )
        #expect(
            payload.result.primaryAnchorResult?
                .elapsed.totalDays
            == 18
        )
        #expect(
            payload.result.primaryAnchorResult?
                .source
            == .frozenConfiguration
        )
    }

    @Test("prefers frozen memory configuration over legacy fallback")
    func prefersFrozenMemoryConfigurationOverLegacyFallback() throws {
        let suite =
            suiteName("frozenMemoryConfiguration")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let liveProfile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "妈妈",
            babyNickname: "运行期对象"
        )
        let liveProfileData =
            try #require(
                try? JSONEncoder().encode(liveProfile)
            )
        defaults.set(
            liveProfileData,
            forKey: "photomemo.personalProfile"
        )

        let anchorDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()
        let subject =
            MemorySubjectAdapter.adapt(
                profile:
                    PersonalProfile(
                        relationshipRole: .custom,
                        customRelationshipLabel: "爸爸",
                        babyNickname: "冻结对象"
                    ),
                anchors: [
                    Anchor(
                        type: .birthday,
                        title: "冻结生日",
                        date: anchorDate
                    )
                ],
                referenceDate: anchorDate
            )
        let snapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )

        let payload =
            ProductionMemoryResolver()
            .resolveLegacyBatchConfiguration(
                photo: selectedPhoto(
                    captureDate: captureDate
                ),
                configuration:
                    BatchConfigurationSnapshot(
                        template:
                            .classicWhite
                            .normalizedForEditing,
                        badge: nil,
                        anchor: nil,
                        shouldWritePhotoDescription:
                            false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    )
                    .withLegacyPairedFrozenMemoryConfiguration(
                        subject: subject,
                        snapshot: snapshot
                    )
            )

        #expect(
            payload.subject.identity.displayName
            == "冻结对象"
        )
        #expect(
            payload.snapshot.subjectID
            == subject.id
        )
        #expect(
            payload.module.sourceAnchor?.title
            == "冻结生日"
        )
        #expect(
            payload.module.renderedText
            == "今天冻结对象18天"
        )
        #expect(
            payload.result.subjectID
            == subject.id
        )
        #expect(
            payload.result.captureDate
            == captureDate
        )
        #expect(
            payload.result.primaryAnchorResult?
                .anchorTitle
            == "冻结生日"
        )
        #expect(
            payload.result.primaryAnchorResult?
                .elapsed.totalDays
            == 18
        )
    }

    @Test("resolves from embedded ConfigurationSnapshot subject without legacy frozen subject")
    func resolvesFromEmbeddedConfigurationSnapshotSubjectWithoutLegacyFrozenSubject() throws {
        let suite =
            suiteName("embeddedConfigurationSnapshotSubject")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let liveProfile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "妈妈",
            babyNickname: "运行期对象"
        )
        let liveProfileData =
            try #require(
                try? JSONEncoder().encode(liveProfile)
            )
        defaults.set(
            liveProfileData,
            forKey: "photomemo.personalProfile"
        )

        let anchorDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()
        let subject =
            MemorySubjectAdapter.adapt(
                profile:
                    PersonalProfile(
                        relationshipRole: .custom,
                        customRelationshipLabel: "爸爸",
                        babyNickname: "Snapshot对象"
                    ),
                anchors: [
                    Anchor(
                        type: .birthday,
                        title: "Snapshot生日",
                        date: anchorDate
                    )
                ],
                referenceDate: anchorDate
            )
        let snapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        let configuration =
            BatchConfigurationSnapshot(
                template:
                    .classicWhite
                    .normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription:
                    false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withCanonicalProductionSnapshot(
                snapshot
            )

        let payload =
            ProductionMemoryResolver()
            .resolveLegacyBatchConfiguration(
                photo: selectedPhoto(
                    captureDate: captureDate
                ),
                configuration: configuration
            )

        #expect(
            payload.subject.identity.displayName
            == "Snapshot对象"
        )
        #expect(
            payload.snapshot.subjectID
            == subject.id
        )
        #expect(
            payload.module.sourceAnchor?.title
            == "Snapshot生日"
        )
        #expect(
            payload.module.renderedText
            == "今天Snapshot对象18天"
        )
        #expect(
            payload.result.subjectID
            == subject.id
        )
    }

    @Test("completes legacy paired frozen snapshot with frozen subject")
    func completesLegacyPairedFrozenSnapshotWithFrozenSubject() throws {
        let suite =
            suiteName("legacyPairedFrozenSnapshot")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let liveProfile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "妈妈",
            babyNickname: "运行期对象"
        )
        let liveProfileData =
            try #require(
                try? JSONEncoder().encode(liveProfile)
            )
        defaults.set(
            liveProfileData,
            forKey: "photomemo.personalProfile"
        )

        let anchorDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()
        let subject =
            MemorySubjectAdapter.adapt(
                profile:
                    PersonalProfile(
                        relationshipRole: .custom,
                        customRelationshipLabel: "爸爸",
                        babyNickname: "配对冻结对象"
                    ),
                anchors: [
                    Anchor(
                        type: .birthday,
                        title: "配对冻结生日",
                        date: anchorDate
                    )
                ],
                referenceDate: anchorDate
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.memorySubject = nil
        let configuration =
            BatchConfigurationSnapshot(
                template:
                    .classicWhite
                    .normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription:
                    false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot: frozenSnapshot
            )

        let payload =
            ProductionMemoryResolver()
            .resolveLegacyBatchConfiguration(
                photo: selectedPhoto(
                    captureDate: captureDate
                ),
                configuration: configuration
            )

        #expect(
            payload.subject.identity.displayName
            == "配对冻结对象"
        )
        #expect(
            payload.snapshot.subjectID
            == subject.id
        )
        #expect(
            payload.snapshot.memorySubject?.id
            == subject.id
        )
        #expect(
            payload.module.sourceAnchor?.title
            == "配对冻结生日"
        )
        #expect(
            payload.module.renderedText
            == "今天配对冻结对象18天"
        )
    }

    @Test("resolves from legacy frozen subject when frozen snapshot is missing")
    func resolvesFromLegacyFrozenSubjectWhenFrozenSnapshotIsMissing() throws {
        let suite =
            suiteName("legacyFrozenSubjectWithoutSnapshot")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let liveProfile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "妈妈",
            babyNickname: "运行期对象"
        )
        let liveProfileData =
            try #require(
                try? JSONEncoder().encode(liveProfile)
            )
        defaults.set(
            liveProfileData,
            forKey: "photomemo.personalProfile"
        )

        let anchorDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()
        let subject =
            MemorySubjectAdapter.adapt(
                profile:
                    PersonalProfile(
                        relationshipRole: .custom,
                        customRelationshipLabel: "爸爸",
                        babyNickname: "旧冻结对象"
                    ),
                anchors: [
                    Anchor(
                        type: .birthday,
                        title: "旧冻结生日",
                        date: anchorDate
                    )
                ],
                referenceDate: anchorDate
            )
        let configuration =
            BatchConfigurationSnapshot(
                template:
                    .classicWhite
                    .normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription:
                    false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withLegacyFrozenMemorySubject(
                subject
            )

        let payload =
            ProductionMemoryResolver()
            .resolveLegacyBatchConfiguration(
                photo: selectedPhoto(
                    captureDate: captureDate
                ),
                configuration: configuration
            )

        #expect(
            payload.subject.identity.displayName
            == "旧冻结对象"
        )
        #expect(
            payload.snapshot.subjectID
            == subject.id
        )
        #expect(
            payload.snapshot.memorySubject?.id
            == subject.id
        )
        #expect(
            payload.module.sourceAnchor?.title
            == "旧冻结生日"
        )
        #expect(
            payload.module.renderedText
            == "今天旧冻结对象18天"
        )
        #expect(
            payload.result.subjectID
            == subject.id
        )
    }

    @Test("uses selected subject identity projection when frozen memory configuration is missing")
    func usesSelectedSubjectIdentityProjectionWhenFrozenMemoryConfigurationIsMissing() throws {
        let anchorDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()

        let payload =
            ProductionMemoryResolver()
            .resolveLegacyBatchConfiguration(
                photo:
                    selectedPhoto(
                        captureDate: captureDate
                    ),
                configuration:
                    BatchConfigurationSnapshot(
                        template:
                            .classicWhite
                            .normalizedForEditing,
                        badge: nil,
                        anchor:
                            Anchor(
                                type: .birthday,
                                title: "生日",
                                date: anchorDate
                            ),
                        memorySubjectText: "小宝",
                        shouldWritePhotoDescription:
                            false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    )
            )

        #expect(
            payload.subject.identity.displayName
            == "小宝"
        )
        #expect(
            payload.module.sourceAnchor?.title
            == "生日"
        )
        #expect(
            payload.module.renderedText
            == "今天小宝18天"
        )
    }

    @Test("falls back to default profile without preview state")
    func fallsBackToDefaultProfileWithoutPreviewState() {
        let suite =
            suiteName("defaultProfileFallback")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let payload =
            ProductionMemoryResolver()
            .resolveLegacyBatchConfiguration(
                photo: selectedPhoto(
                    captureDate: nil
                ),
                configuration:
                    BatchConfigurationSnapshot(
                        template:
                            .classicWhite
                            .normalizedForEditing,
                        badge: nil,
                        anchor: nil,
                        shouldWritePhotoDescription:
                            false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    )
            )

        #expect(
            payload.subject.identity.displayName
            == "家人"
        )
        #expect(
            payload.module.renderedText
            == "家人"
        )
        #expect(
            payload.module.sourceAnchor == nil
        )
        #expect(
            payload.result.subjectID
            == payload.subject.id
        )
        #expect(
            payload.result.primaryAnchorResult
            == nil
        )
    }
}

private extension ProductionMemoryResolverTests {

    func selectedPhoto(
        captureDate: Date?
    ) -> SelectedPhoto {
        SelectedPhoto(
            sourceURL: URL(
                fileURLWithPath: "/tmp/test.jpg"
            ),
            image: NSImage(
                size: NSSize(
                    width: 32,
                    height: 32
                )
            ),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 4032,
                imageHeight: 3024
            )
        )
    }

    func suiteName(
        _ suffix: String
    ) -> String {
        "ProductionMemoryResolverTests.\(suffix).\(UUID().uuidString)"
    }
}
#endif
