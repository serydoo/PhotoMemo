#if !PHOTOMEMO_SHARE_EXTENSION
import AppKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Production configuration contract")
struct ProductionConfigurationContractTests {

    @Test("exact durable configuration resolution freezes every production field")
    func exactResolutionFreezesCompleteProductionConfiguration() throws {
        let fixture = try Self.makeFixture()

        let snapshot = try ProductionConfigurationSnapshotFactory.resolve(
            reference: ProductionConfigurationReference(
                configurationID: fixture.configuration.id,
                revision: fixture.configuration.revision
            ),
            from: fixture.aggregate
        )

        #expect(snapshot.productionContractVersion == 1)
        #expect(snapshot.configurationID == fixture.configuration.id)
        #expect(
            snapshot.configurationRevision
            == fixture.configuration.revision
        )
        #expect(snapshot.template == fixture.configuration.editor.template)
        #expect(
            snapshot.locationDisplayConfiguration
            == fixture.configuration.presentation.locationConfiguration
        )
        #expect(snapshot.shouldWritePhotoDescription == false)
        #expect(snapshot.photoDescriptionOverride == "照片说明")
        #expect(snapshot.selectedAlbumIdentifier == "album-123")
        #expect(snapshot.usesCustomMemoryWriteText == false)
        #expect(snapshot.customMemoryWriteText.isEmpty)
        #expect(
            snapshot.presentationRouteRawValue
            == MemoryConfigurationRecord.Presentation.Route
                .classicWhite.rawValue
        )
        #expect(snapshot.logoModeRawValue == V1LogoMode.appleMini.rawValue)
        #expect(
            snapshot.mediaOutputModeRawValue
            == V1MediaOutputMode.staticImage.rawValue
        )
        #expect(
            snapshot.livePhotoPolicyRawValue
            == MemoryConfigurationRecord.Output.LivePhotoPolicy
                .preserveMotion.rawValue
        )
        #expect(
            snapshot.canonicalProductionSnapshot?.configurationID
            == fixture.configuration.id
        )
        #expect(
            snapshot.canonicalProductionSnapshot?.configurationRevision
            == fixture.configuration.revision
        )
        #expect(
            snapshot.canonicalProductionSnapshot?.memorySubject?.id
            == fixture.subject.id
        )
        #expect(
            snapshot.canonicalProductionSnapshot?.primaryAnchor?.id
            == fixture.anchor.id
        )
    }

    @Test("durable resolution rejects a configuration revision mismatch")
    func exactResolutionRejectsRevisionMismatch() throws {
        let fixture = try Self.makeFixture()

        #expect(throws: ProductionConfigurationContractError.self) {
            _ = try ProductionConfigurationSnapshotFactory.resolve(
                reference: ProductionConfigurationReference(
                    configurationID: fixture.configuration.id,
                    revision: fixture.configuration.revision + 1
                ),
                from: fixture.aggregate
            )
        }
    }

    @Test("subject avatar logo resolves its managed asset for production")
    func subjectAvatarLogoResolvesManagedAssetForProduction() throws {
        let fixture = try Self.makeFixture()
        let reference = try PortableAssetReference(
            relativePath: "SubjectAssets/avatar-badge.png"
        )
        var aggregate = fixture.aggregate
        aggregate.subjects[0].subject.identity.avatarBadgeImagePath =
            reference.relativePath
        aggregate.subjects[0].assetManifest.entries = [
            .init(
                role: .subjectAvatarBadge,
                reference: reference
            )
        ]
        aggregate.subjects[0].configurations[0]
            .presentation.logo = .init(
                mode: .subjectAvatar,
                badge: .init(
                    id: UUID(),
                    name: OptimizedSubjectAvatarAsset
                        .subjectAvatarBadgeName,
                    type: .customUpload
                )
            )

        let snapshot = try ProductionConfigurationSnapshotFactory.resolve(
            reference: ProductionConfigurationReference(
                configurationID: fixture.configuration.id,
                revision: fixture.configuration.revision
            ),
            from: aggregate
        )

        #expect(snapshot.logoModeRawValue == V1LogoMode.subjectAvatar.rawValue)
        #expect(snapshot.badge?.name == "对象头像")
        #expect(
            snapshot.badge?.imagePath
            == PhotoMemoSharedContainer.baseDirectoryURL
                .appendingPathComponent(reference.relativePath)
                .standardizedFileURL.path
        )
    }

    @Test("durable resolution rejects an unknown configuration identity")
    func exactResolutionRejectsUnknownConfiguration() throws {
        let fixture = try Self.makeFixture()
        let unknownID = UUID(
            uuidString: "55555555-5555-5555-5555-555555555555"
        )!

        do {
            _ = try ProductionConfigurationSnapshotFactory.resolve(
                reference: ProductionConfigurationReference(
                    configurationID: unknownID,
                    revision: 1
                ),
                from: fixture.aggregate
            )
            Issue.record("Expected unknown configuration rejection")
        } catch let error as ProductionConfigurationContractError {
            #expect(error == .configurationNotFound(unknownID))
        }
    }

    @Test("snapshot contract rejects top-level and canonical identity mismatch")
    func snapshotContractRejectsIdentityMismatch() throws {
        let fixture = try Self.makeFixture()
        var snapshot = try ProductionConfigurationSnapshotFactory.resolve(
            reference: ProductionConfigurationReference(
                configurationID: fixture.configuration.id,
                revision: fixture.configuration.revision
            ),
            from: fixture.aggregate
        )
        snapshot.configurationID = UUID(
            uuidString: "66666666-6666-6666-6666-666666666666"
        )!

        do {
            try ProductionConfigurationSnapshotContract.validate(snapshot)
            Issue.record("Expected snapshot identity mismatch rejection")
        } catch let error as ProductionConfigurationContractError {
            #expect(error == .snapshotIdentityMismatch)
        }
    }

    @Test("legacy batch snapshots decode without production-only fields")
    func legacyBatchSnapshotRemainsDecodable() throws {
        let snapshot = BatchConfigurationSnapshot(
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
        let encoded = try JSONEncoder().encode(snapshot)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: Any]
        )
        [
            "productionContractVersion",
            "usesCustomMemoryWriteText",
            "customMemoryWriteText",
            "presentationRouteRawValue",
            "logoModeRawValue",
            "livePhotoPolicyRawValue"
        ].forEach {
            object.removeValue(forKey: $0)
        }
        let legacyData = try JSONSerialization.data(
            withJSONObject: object
        )

        let decoded = try JSONDecoder().decode(
            BatchConfigurationSnapshot.self,
            from: legacyData
        )

        #expect(decoded.productionContractVersion == nil)
        #expect(decoded.usesCustomMemoryWriteText == false)
        #expect(decoded.customMemoryWriteText.isEmpty)
        #expect(decoded.presentationRouteRawValue == nil)
        #expect(decoded.logoModeRawValue == nil)
        #expect(decoded.livePhotoPolicyRawValue == nil)
    }

    @MainActor
    @Test("every launch source rejects the same invalid production snapshot")
    func allLaunchSourcesUseProductionAdmissionContract() throws {
        let context = try Self.makeEnvironment()
        defer { Self.cleanup(context) }
        let sourceURL = try SyntheticFixtureLibrary.fixtureURL(
            .iphoneJPEG
        )
        let invalid = BatchConfigurationSnapshot(
            productionContractVersion: 1,
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
        let sources: [BatchJobLaunchSource] = [
            .shareExtension,
            .fileOpen,
            .quickAction,
            .automation,
            .inAppPreview
        ]

        for source in sources {
            let job = context.environment.repositories.queue.enqueue(
                payloads: [
                    BatchTaskIntakePayload(
                        sourceURL: sourceURL
                    )
                ],
                configuration: invalid,
                launchSource: source
            )
            #expect(job == nil)
        }

        #expect(context.environment.repositories.queue.jobs.isEmpty)
        let rejectedSources = Set(
            PhotoMemoShareDiagnostics.loadEvents(
                defaults: context.defaults
            )
            .filter {
                $0.stage == .configurationContractViolation
            }
            .compactMap { event in
                sources.first {
                    event.message.contains("source=\($0.rawValue)")
                }
            }
        )
        #expect(rejectedSources == Set(sources))
    }

    @MainActor
    @Test("an invalid current production configuration remains versioned and is rejected")
    func invalidCurrentConfigurationDoesNotBecomeLegacyCompatibility() async throws {
        let fixture = try Self.makeFixture()
        let context = try Self.makeEnvironment()
        defer { Self.cleanup(context) }
        var invalid = fixture.aggregate
        invalid.subjects[0].subject.timeAnchors = []
        invalid.subjects[0].subject.activeTimeAnchorID = nil
        invalid.subjects[0].configurations[0].selectedTimeAnchorID = nil
        _ = try await context.environment.coordinators.configuration
            .saveConfigurationLibrary(invalid)

        let snapshot = context.environment.repositories.configuration
            .loadDefaultBatchConfigurationSnapshot()

        #expect(snapshot.productionContractVersion == 1)
        #expect(snapshot.configurationID == fixture.configuration.id)
        #expect(
            snapshot.configurationRevision
            == fixture.configuration.revision
        )
        #expect(throws: ProductionConfigurationContractError.self) {
            try ProductionConfigurationSnapshotContract.validate(snapshot)
        }
    }

    @MainActor
    @Test("durable production identity survives an app environment restart")
    func productionIdentitySurvivesEnvironmentRestart() async throws {
        let fixture = try Self.makeFixture()
        let suiteName =
            "PhotoMemo.ProductionConfigurationRestart.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        let intakeURL = rootURL.appendingPathComponent(
            "ExternalIntake",
            isDirectory: true
        )
        defer {
            try? FileManager.default.removeItem(at: rootURL)
            defaults.removePersistentDomain(forName: suiteName)
        }

        var environment: AppEnvironment? = AppEnvironment.live(
            defaults: defaults,
            configurationLibraryBaseDirectoryURL: rootURL,
            intakeDirectoryURL: intakeURL
        )
        _ = try await environment?.coordinators.configuration
            .saveConfigurationLibrary(fixture.aggregate)
        environment = nil

        let restarted = AppEnvironment.live(
            defaults: defaults,
            configurationLibraryBaseDirectoryURL: rootURL,
            intakeDirectoryURL: intakeURL
        )
        let snapshot = restarted.repositories.configuration
            .loadDefaultBatchConfigurationSnapshot()

        #expect(snapshot.configurationID == fixture.configuration.id)
        #expect(
            snapshot.configurationRevision
            == fixture.configuration.revision
        )
        #expect(snapshot.productionContractVersion == 1)
        #expect(
            snapshot.canonicalProductionSnapshot?.configurationID
            == fixture.configuration.id
        )
    }

    @Test("request identity wins after active configuration switches")
    func requestIdentityWinsAfterActiveConfigurationSwitch() throws {
        let fixture = try Self.makeFixture()
        let secondConfiguration = MemoryConfigurationRecord(
            id: UUID(
                uuidString: "44444444-4444-4444-4444-444444444444"
            )!,
            title: "另一配置",
            revision: 3,
            savedAt: fixture.captureDate,
            selectedTimeAnchorID: fixture.anchor.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: fixture.configuration.presentation,
            output: fixture.configuration.output
        )
        var switched = fixture.aggregate
        switched.subjects[0].configurations.append(
            secondConfiguration
        )
        switched.activeConfigurationID = secondConfiguration.id

        let snapshot = try ProductionConfigurationSnapshotFactory.resolve(
            reference: ProductionConfigurationReference(
                configurationID: fixture.configuration.id,
                revision: fixture.configuration.revision
            ),
            from: switched
        )

        #expect(snapshot.configurationID == fixture.configuration.id)
        #expect(snapshot.template == fixture.configuration.editor.template)
        #expect(snapshot.configurationID != switched.activeConfigurationID)
    }

    @Test("save-current draft keeps configuration identity and advances its revision")
    func saveCurrentPreservesIdentityAndAdvancesRevision() throws {
        let fixture = try Self.makeFixture()
        let draft = V1ConfigurationAggregateDraft(
            title: "重命名后的配置",
            regionDrafts: V1ConfigurationDraftProjection(
                configuration: fixture.configuration
            ).regionDrafts,
            regionTemplateIDs:
                fixture.configuration.editor.regionTemplateIDs,
            locationConfiguration:
                fixture.configuration.presentation.locationConfiguration,
            logoMode: fixture.configuration.presentation.logo.mode,
            badge: nil,
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: "",
            shouldWritePhotosDescription: false,
            photosDescriptionOverride: "更新后的说明",
            outputTarget: .existingAlbum,
            selectedAlbumIdentifier: "album-456",
            albumTitle: "更新后的相册",
            mediaOutputMode: .staticImage,
            livePhotoPolicy: .preserveMotion,
            selectedTimeAnchorID: fixture.anchor.id,
            savedAt: fixture.captureDate
        )

        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: fixture.aggregate,
            draft: draft
        )

        #expect(candidate.configuration.id == fixture.configuration.id)
        #expect(
            candidate.configuration.revision
            == fixture.configuration.revision + 1
        )
        #expect(
            candidate.aggregate.activeConfigurationID
            == fixture.configuration.id
        )
    }

    @Test("real card build and text engine keep enabled memory summary non-empty")
    func realCardBuildKeepsSmartOutputNonEmpty() throws {
        let fixture = try Self.makeFixture()
        let snapshot = try ProductionConfigurationSnapshotFactory.resolve(
            reference: ProductionConfigurationReference(
                configurationID: fixture.configuration.id,
                revision: fixture.configuration.revision
            ),
            from: fixture.aggregate
        )
        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_1171.jpg"),
            image: NSImage(
                size: NSSize(width: 4032, height: 3024)
            ),
            metadata: PhotoMetadata(
                captureDate: fixture.captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                imageWidth: 4032,
                imageHeight: 3024
            )
        )

        let card = RecordCardBuildService().buildCard(
            from: photo,
            configuration: snapshot
        )
        let memorySummary = CardVariableProvider.build(from: card)[
            MetadataContext.Key.memorySummary
        ]
        let blocks = try ProductionRenderHealthCheck.validate(
            card: card,
            configuration: snapshot
        )

        #expect(!memorySummary.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty)
        #expect(blocks.contains(where: {
            $0.value.contains(memorySummary)
        }))
    }

    @Test("enabled memory summary fails health check when semantic output is empty")
    func emptyEnabledSmartOutputFailsHealthCheck() throws {
        let fixture = try Self.makeFixture()
        let snapshot = try ProductionConfigurationSnapshotFactory.resolve(
            reference: ProductionConfigurationReference(
                configurationID: fixture.configuration.id,
                revision: fixture.configuration.revision
            ),
            from: fixture.aggregate
        )
        let card = RecordCard(
            template: snapshot.template,
            metadata: PhotoMetadata(),
            context: MetadataContext(),
            memorySubjectText: "小宝"
        )

        #expect(throws: ProductionConfigurationContractError.self) {
            _ = try ProductionRenderHealthCheck.validate(
                card: card,
                configuration: snapshot
            )
        }
    }

    @Test("custom memory copy appends to the renderer smart text")
    func customMemoryCopyAppendsToRendererSmartText() throws {
        let fixture = try Self.makeFixture()
        var aggregate = fixture.aggregate
        aggregate.subjects[0].configurations[0]
            .editor.memoryCopy = .init(
                usesCustomText: true,
                customText: "今天是小宝的重要一天"
            )
        let configuration = aggregate.subjects[0].configurations[0]
        let snapshot = try ProductionConfigurationSnapshotFactory.resolve(
            reference: ProductionConfigurationReference(
                configurationID: configuration.id,
                revision: configuration.revision
            ),
            from: aggregate
        )
        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/custom-memory.jpg"),
            image: NSImage(size: NSSize(width: 1200, height: 900)),
            metadata: PhotoMetadata(captureDate: fixture.captureDate)
        )
        let card = RecordCardBuildService().buildCard(
            from: photo,
            configuration: snapshot
        )
        let variableSummary = CardVariableProvider.build(from: card)[
            MetadataContext.Key.memorySummary
        ]
        let expressionSummary = card.productionExpressionContext?
            .value(
                for: MemoryProvider.memoryToken
            )?
            .resolvedText
        let renderedBlocks = CardTextBlockEngine().build(from: card)
        let expectedSummary =
            "陪小宝走到1岁1个月17天\n今天是小宝的重要一天"

        #expect(variableSummary == expectedSummary)
        #expect(expressionSummary == expectedSummary)
        #expect(renderedBlocks.contains(where: {
            $0.value.contains(expectedSummary)
        }))
        let blocks = try ProductionRenderHealthCheck.validate(
            card: card,
            configuration: snapshot
        )

        #expect(
            CardVariableProvider.build(from: card)[
                MetadataContext.Key.memorySummary
            ] == expectedSummary
        )
        #expect(blocks.contains(where: {
            $0.value.contains(expectedSummary)
        }))
    }

    @MainActor
    @Test("drained request keeps share-time configuration after active selection switches")
    func drainedRequestKeepsShareTimeConfigurationAfterSwitch() async throws {
        let fixture = try Self.makeFixture()
        let context = try Self.makeEnvironment()
        defer { Self.cleanup(context) }
        _ = try await context.environment.coordinators.configuration
            .saveConfigurationLibrary(fixture.aggregate)

        let transport = BatchConfigurationSnapshot(
            template: fixture.configuration.editor.template,
            badge: nil,
            anchor: nil,
            memorySubjectText: "小宝",
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        ).withProductionConfigurationReference(
            ProductionConfigurationReference(
                configurationID: fixture.configuration.id,
                revision: fixture.configuration.revision
            )
        )

        var switched = fixture.aggregate
        let secondConfiguration = Self.secondConfiguration(
            from: fixture
        )
        switched.subjects[0].configurations.append(
            secondConfiguration
        )
        switched.activeConfigurationID = secondConfiguration.id
        _ = try await context.environment.coordinators.configuration
            .saveConfigurationLibrary(switched)

        let sourceURL = try SyntheticFixtureLibrary.fixtureURL(
            .iphoneJPEG
        )
        let result = context.environment.coordinators.share.process(
            request: ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [sourceURL],
                configurationSnapshot: transport
            ),
            consumedPayloadKeys: []
        )
        let job = try #require(result.value?.job)

        #expect(job.configuration.configurationID == fixture.configuration.id)
        #expect(
            job.configuration.configurationRevision
            == fixture.configuration.revision
        )
        #expect(
            job.configuration.template
            == fixture.configuration.editor.template
        )
        #expect(
            job.configuration.configurationID
            != switched.activeConfigurationID
        )
    }

    @MainActor
    @Test("drained versioned request rejects a revision mismatch")
    func drainedVersionedRequestRejectsRevisionMismatch() async throws {
        let fixture = try Self.makeFixture()
        let context = try Self.makeEnvironment()
        defer { Self.cleanup(context) }
        _ = try await context.environment.coordinators.configuration
            .saveConfigurationLibrary(fixture.aggregate)

        let sourceURL = try SyntheticFixtureLibrary.fixtureURL(
            .iphoneJPEG
        )
        let transport = BatchConfigurationSnapshot(
            template: fixture.configuration.editor.template,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        ).withProductionConfigurationReference(
            ProductionConfigurationReference(
                configurationID: fixture.configuration.id,
                revision: fixture.configuration.revision + 1
            )
        )

        let result = context.environment.coordinators.share.process(
            request: ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [sourceURL],
                configurationSnapshot: transport
            ),
            consumedPayloadKeys: []
        )

        #expect(result.value == nil)
        #expect(context.environment.repositories.queue.jobs.isEmpty)
        #expect(
            PhotoMemoShareDiagnostics.loadEvents(
                defaults: context.defaults
            ).contains(where: {
                $0.stage == .configurationContractViolation
            })
        )
    }

    private struct Fixture {
        let aggregate: ConfigurationLibraryRecord
        let subject: MemorySubject
        let anchor: MemorySubject.TimeAnchor
        let configuration: MemoryConfigurationRecord
        let captureDate: Date
    }

    private struct EnvironmentContext {
        let suiteName: String
        let defaults: UserDefaults
        let rootURL: URL
        let environment: AppEnvironment
    }

    @MainActor
    private static func makeEnvironment() throws -> EnvironmentContext {
        let suiteName =
            "PhotoMemo.ProductionConfigurationContractTests.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        let intakeURL = rootURL.appendingPathComponent(
            "ExternalIntake",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: intakeURL,
            withIntermediateDirectories: true
        )
        return EnvironmentContext(
            suiteName: suiteName,
            defaults: defaults,
            rootURL: rootURL,
            environment: AppEnvironment.live(
                defaults: defaults,
                configurationLibraryBaseDirectoryURL:
                    rootURL,
                intakeDirectoryURL: intakeURL
            )
        )
    }

    private static func cleanup(_ context: EnvironmentContext) {
        try? FileManager.default.removeItem(at: context.rootURL)
        context.defaults.removePersistentDomain(
            forName: context.suiteName
        )
    }

    private static func secondConfiguration(
        from fixture: Fixture
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: UUID(
                uuidString: "44444444-4444-4444-4444-444444444444"
            )!,
            title: "另一配置",
            revision: 3,
            savedAt: fixture.captureDate,
            selectedTimeAnchorID: fixture.anchor.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: fixture.configuration.presentation,
            output: fixture.configuration.output
        )
    }

    private static func makeFixture() throws -> Fixture {
        let calendar = Calendar(identifier: .gregorian)
        let birthday = try #require(calendar.date(
            from: DateComponents(year: 2025, month: 5, day: 26)
        ))
        let captureDate = try #require(calendar.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: 13,
                hour: 10,
                minute: 30
            )
        ))
        let anchor = MemorySubject.TimeAnchor(
            id: UUID(
                uuidString: "33333333-3333-3333-3333-333333333333"
            )!,
            title: "生日",
            date: birthday,
            note: "",
            anchorType: .birthday,
            expressionStyle: .birthdayWarm
        )
        let subject = MemorySubject(
            id: UUID(
                uuidString: "11111111-1111-1111-1111-111111111111"
            )!,
            identity: .init(displayName: "示例对象", shortName: "小宝"),
            relationship: .init(role: "宝宝", label: "孩子"),
            referenceDate: birthday,
            timeAnchors: [anchor],
            activeTimeAnchorID: anchor.id,
            expressionSubjectSource: .shortName,
            behavior: MemoryBehavior(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .autoMatch,
                memoryExpression: MemoryExpression(
                    title: "生日记忆",
                    blocks: [.text("成长记录")]
                )
            ),
            decorations: []
        )
        let template = Template(
            preset: .classicWhite,
            name: "生日回顾",
            leftTopArea: .empty,
            leftBottomArea: .empty,
            rightTopArea: .empty,
            rightBottomArea: TemplateArea(
                name: "Memory",
                items: [
                    TemplateItem(
                        type: .variable,
                        name: "智能模块",
                        value: "{{memory_summary}}"
                    )
                ]
            ),
            badgeArea: .empty
        ).normalizedForEditing
        let location = ExpressionModuleConfiguration(
            token: "location",
            options: ["presentationMode": "provinceCity"]
        )
        let configuration = MemoryConfigurationRecord(
            id: UUID(
                uuidString: "22222222-2222-2222-2222-222222222222"
            )!,
            title: "生日回顾",
            revision: 7,
            savedAt: captureDate,
            selectedTimeAnchorID: anchor.id,
            editor: .init(
                template: template,
                regionTemplateIDs: [.slotD: "memory-summary"],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: location,
                logo: .init(mode: .appleMini, badge: nil)
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: "照片说明"
                ),
                album: .init(
                    destination: .existingAlbum,
                    identifier: "album-123",
                    title: "测试文档"
                )
            )
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 19,
            subjects: [
                SubjectConfigurationRecord(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )

        return Fixture(
            aggregate: aggregate,
            subject: subject,
            anchor: anchor,
            configuration: configuration,
            captureDate: captureDate
        )
    }
}
#endif
