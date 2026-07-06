import AppKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("RecordCardBuildService", .serialized)
struct RecordCardBuildServiceTests {

    @Test("Location display configuration feeds production render text")
    func locationDisplayConfigurationFeedsProductionRenderText() throws {
        let template =
            Template(
                preset: .template2,
                name: "Location Display",
                leftTopArea:
                    TemplateArea(
                        name: "Location",
                        items: [
                            TemplateItem(
                                type: .variable,
                                name: "Location",
                                value: "{{location_display}}"
                            )
                        ]
                    ),
                leftBottomArea: .empty,
                rightTopArea: .empty,
                rightBottomArea: .empty,
                badgeArea: .empty
            )
        let photo =
            SelectedPhoto(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/location.jpeg"),
                image:
                    NSImage(
                        size:
                            NSSize(
                                width: 1200,
                                height: 900
                            )
                    ),
                metadata:
                    PhotoMetadata(
                        city: "商丘",
                        district: "永城",
                        province: "河南",
                        country: "中国"
                    )
            )
        let configuration =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor: nil,
                locationDisplayConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: "cityDistrict"
                    ),
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )

        let card =
            RecordCardBuildService()
            .buildCard(
                from: photo,
                configuration: configuration
            )
        let block =
            try #require(
                CardTextBlockEngine()
                    .build(
                        from: card
                    )
                    .first
            )

        #expect(block.value == "商丘 · 永城")
    }

    @Test("Builds template1 with profile relationship and Memory Summary phrasing")
    func buildsTemplate1WithProfileRelationshipAndMemorySummaryPhrasing() throws {
        let profile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "他爹",
            babyNickname: "途途"
        )

        let service =
            RecordCardBuildService()

        let captureDate =
            Calendar(identifier: .gregorian)
            .date(
                from: DateComponents(
                    year: 2026,
                    month: 4,
                    day: 11,
                    hour: 10,
                    minute: 13,
                    second: 5
                )
            )!

        let birthday =
            Calendar(identifier: .gregorian)
            .date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 28
                )
            )!

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_5668.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                iso: "125",
                aperture: "1.78",
                shutterSpeed: "1/98",
                focalLength35mm: "24",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )

        let anchor =
            Anchor(
                type: .birthday,
                title: "途途",
                date: birthday,
                isCountdown: false
            )
        let subject =
            MemorySubjectAdapter.adapt(
                profile: profile,
                anchors: [
                    anchor
                ],
                selectedAnchorID:
                    anchor.id,
                referenceDate:
                    birthday
            )
        let configuration =
            BatchConfigurationSnapshot(
            template: .template1.normalizedForEditing,
            badge: nil,
            anchor: anchor,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
        .withLegacyPairedFrozenMemoryConfiguration(
            subject: subject,
            snapshot:
                ConfigurationSnapshotBuilder.build(
                    from: subject
                )
        )

        let card = service.buildCard(
            from: photo,
            configuration: configuration
        )

        let blocks =
            CardTextBlockEngine().build(from: card)

        #expect(
            blocks.first(where: { $0.area == CardTextArea.leftTop })?.value
            == "他爹手持iPhone 15 Pro记录"
        )
        #expect(
            blocks.first(where: { $0.area == CardTextArea.leftBottom })?.value
            == "记录于2026.04.11 10:13:05"
        )
        #expect(
            blocks.first(where: { $0.area == CardTextArea.rightTop })?.value
            == "24mm f/1.78 1/98s ISO125"
        )
        #expect(
            blocks.first(where: { $0.area == CardTextArea.rightBottom })?.value
            == "这一天，途途9个月14天"
        )
        #expect(
            card
                .productionExpressionContext?
                .value(
                    for: MemoryProvider.memoryToken
                )?
                .resolvedText
            == "这一天，途途9个月14天"
        )
    }

    @Test("Frozen ConfigurationSnapshot relationship label wins over legacy fallback")
    func frozenConfigurationSnapshotRelationshipLabelWinsOverLegacyFallback() throws {

        let suiteName =
            "RecordCardBuildServiceTests.FrozenRelationshipLabel.\(UUID().uuidString)"
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

        let liveProfile =
            PersonalProfile(
                relationshipRole: .custom,
                customRelationshipLabel: "运行期关系",
                babyNickname: "运行期对象"
            )
        defaults.set(
            try JSONEncoder().encode(liveProfile),
            forKey: "photomemo.personalProfile"
        )

        let service =
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let anchorDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 6,
                        day: 28
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 4,
                        day: 11,
                        hour: 10,
                        minute: 13,
                        second: 5
                    )
                )
            )
        let anchor =
            Anchor(
                type: .birthday,
                title: "冻结生日",
                date: anchorDate,
                isCountdown: false
            )
        let frozenSubject =
            MemorySubjectAdapter.adapt(
                profile:
                    PersonalProfile(
                        relationshipRole: .custom,
                        customRelationshipLabel: "冻结关系",
                        babyNickname: "冻结对象"
                    ),
                anchors: [
                    anchor
                ],
                selectedAnchorID:
                    anchor.id,
                referenceDate:
                    anchorDate
            )
        let snapshot =
            BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: anchor,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: frozenSubject,
                snapshot:
                    ConfigurationSnapshotBuilder.build(
                        from: frozenSubject
                    )
            )
        let photo =
            SelectedPhoto(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_5669.JPEG"),
                image:
                    NSImage(
                        size:
                            NSSize(
                                width: 1920,
                                height: 1080
                            )
                    ),
                metadata:
                    PhotoMetadata(
                        captureDate: captureDate,
                        deviceBrand: "Apple",
                        deviceModel: "iPhone 15 Pro",
                        imageWidth: 4032,
                        imageHeight: 2268
                    )
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let blocks =
            CardTextBlockEngine()
            .build(from: card)

        #expect(
            card.context[MetadataContext.Key.relationshipLabel]
            == "冻结关系"
        )
        #expect(
            blocks.first(where: { $0.area == CardTextArea.leftTop })?.value
            == "冻结关系手持iPhone 15 Pro记录"
        )
    }

    @Test("Legacy frozen subject relationship label wins when embedded snapshot subject is missing")
    func legacyFrozenSubjectRelationshipLabelWinsWhenEmbeddedSnapshotSubjectIsMissing() throws {

        let suiteName =
            "RecordCardBuildServiceTests.LegacyFrozenSubjectRelationshipLabel.\(UUID().uuidString)"
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

        let liveProfile =
            PersonalProfile(
                relationshipRole: .custom,
                customRelationshipLabel: "运行期关系",
                babyNickname: "运行期对象"
            )
        defaults.set(
            try JSONEncoder().encode(liveProfile),
            forKey: "photomemo.personalProfile"
        )

        let service =
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let anchorDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 6,
                        day: 28
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 4,
                        day: 11,
                        hour: 10,
                        minute: 13,
                        second: 5
                    )
                )
            )
        let anchor =
            Anchor(
                type: .birthday,
                title: "旧冻结生日",
                date: anchorDate,
                isCountdown: false
            )
        let frozenSubject =
            MemorySubjectAdapter.adapt(
                profile:
                    PersonalProfile(
                        relationshipRole: .custom,
                        customRelationshipLabel: "旧冻结关系",
                        babyNickname: "旧冻结对象"
                    ),
                anchors: [
                    anchor
                ],
                selectedAnchorID:
                    anchor.id,
                referenceDate:
                    anchorDate
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: frozenSubject
            )
        frozenSnapshot.memorySubject = nil
        let configuration =
            BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: anchor,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: frozenSubject,
                snapshot: frozenSnapshot
            )
        let photo =
            SelectedPhoto(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_5670.JPEG"),
                image:
                    NSImage(
                        size:
                            NSSize(
                                width: 1920,
                                height: 1080
                            )
                    ),
                metadata:
                    PhotoMetadata(
                        captureDate: captureDate,
                        deviceBrand: "Apple",
                        deviceModel: "iPhone 15 Pro",
                        imageWidth: 4032,
                        imageHeight: 2268
                    )
            )

        let card = service.buildCard(
            from: photo,
            configuration: configuration
        )

        #expect(
            card.context[MetadataContext.Key.relationshipLabel]
            == "旧冻结关系"
        )
    }

    @Test("Incomplete frozen snapshot does not suppress legacy batch anchor fallback")
    func incompleteFrozenSnapshotDoesNotSuppressLegacyBatchAnchorFallback() throws {

        let suiteName =
            "RecordCardBuildServiceTests.IncompleteFrozenSnapshotAnchor.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let anchorDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 6,
                        day: 28
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 4,
                        day: 11,
                        hour: 10,
                        minute: 13,
                        second: 5
                    )
                )
            )
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "Legacy Birthday",
                date: anchorDate,
                isCountdown: false
            )
        let snapshotSubject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var incompleteSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: snapshotSubject
            )
        incompleteSnapshot.memorySubject = nil

        let configuration =
            BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withCanonicalProductionSnapshot(
                incompleteSnapshot
            )

        let photo =
            SelectedPhoto(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_5670.JPEG"),
                image:
                    NSImage(
                        size:
                            NSSize(
                                width: 1920,
                                height: 1080
                            )
                    ),
                metadata:
                    PhotoMetadata(
                        captureDate: captureDate,
                        deviceBrand: "Apple",
                        deviceModel: "iPhone 15 Pro",
                        imageWidth: 4032,
                        imageHeight: 2268
                    )
            )

        let card = service.buildCard(
            from: photo,
            configuration: configuration
        )

        #expect(card.anchor?.title == "Legacy Birthday")
        #expect(card.title == "Legacy Birthday")
    }

    @Test("Falls back to right-bottom content when custom description is disabled")
    func fallsBackToRightBottomContentWhenCustomDescriptionIsDisabled() {

        let suiteName =
            "RecordCardBuildServiceTests.DescriptionFallback.\(UUID().uuidString)"
        let defaults =
            UserDefaults(
                suiteName: suiteName
            )!
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let service =
            RecordCardBuildService()

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            image: NSImage(size: NSSize(width: 10, height: 10)),
            metadata: PhotoMetadata(
                captureDate: Date(),
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 4032,
                imageHeight: 3024
            )
        )

        let template = Template(
            preset: .template1,
            name: "模板 1",
            leftTopArea: .leftTop,
            leftBottomArea: .leftBottom,
            rightTopArea: TemplateArea(
                name: "Right Top",
                items: [.cameraSummary]
            ),
            rightBottomArea: TemplateArea(
                name: "Right Bottom",
                items: [
                    TemplateItem(
                        type: .text,
                        name: "补充说明",
                        value: "右下默认说明"
                    )
                ]
            ),
            badgeArea: .badge
        ).normalizedForEditing

        let configuration = BatchConfigurationSnapshot(
            template: template,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "Should not be written",
            selectedAlbumIdentifier: ""
        )

        let card = service.buildCard(
            from: photo,
            configuration: configuration
        )

        #expect(card.exportDescriptionOverride == "右下默认说明")
        #expect(CardVariableProvider.exportDescription(from: card) == "右下默认说明")
    }

    @Test("Uses explicit override when description writing is enabled")
    func usesExplicitOverrideWhenDescriptionWritingIsEnabled() {

        let service = RecordCardBuildService()

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            image: NSImage(size: NSSize(width: 10, height: 10)),
            metadata: PhotoMetadata(
                captureDate: Date(),
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 4032,
                imageHeight: 3024
            )
        )

        let configuration = BatchConfigurationSnapshot(
            template: .template1.normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: true,
            photoDescriptionOverride: "My export note",
            selectedAlbumIdentifier: ""
        )

        let card = service.buildCard(
            from: photo,
            configuration: configuration
        )

        #expect(card.exportDescriptionOverride == "My export note")
        #expect(CardVariableProvider.exportDescription(from: card) == "My export note")
    }

    @Test("Build chain keeps raw anchor expression-style payloads available to downstream output")
    func buildChainKeepsRawAnchorExpressionStylePayloadsAvailableToDownstreamOutput() throws {

        let suiteName =
            "RecordCardBuildServiceTests.RawAnchorExpressionStyle.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let birthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 5,
                        day: 26
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 6,
                        day: 13,
                        hour: 10,
                        minute: 13,
                        second: 5
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_5668.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                iso: "125",
                aperture: "1.78",
                shutterSpeed: "1/98",
                focalLength35mm: "24",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )

        let legacySnapshot =
            try injectedExpressionStyleSnapshot(
                base:
                    BatchConfigurationSnapshot(
                        template:
                            .template1
                            .normalizedForEditing,
                        badge: nil,
                        anchor: Anchor(
                            type: .birthday,
                            title: "途途",
                            date: birthday,
                            isCountdown: false
                        ),
                        shouldWritePhotoDescription:
                            false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    ),
                expressionStyle:
                    "birthdayAgeToday"
            )
        let subject =
            MemorySubjectAdapter.adapt(
                profile:
                    PersonalProfile(
                        relationshipRole: .custom,
                        customRelationshipLabel: "爸爸",
                        babyNickname: "途途"
                    ),
                anchors:
                    legacySnapshot.anchor.map {
                        [$0]
                    } ?? [],
                selectedAnchorID:
                    legacySnapshot.anchor?.id,
                referenceDate:
                    birthday
            )
        let configurationSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        let snapshot =
            legacySnapshot
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot: configurationSnapshot
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            context[MetadataContext.Key.memorySummary]
            == "这一天，途途18天"
        )
        #expect(
            card.memoryResult?.subjectID
            == subject.id
        )
        #expect(
            card.memoryResult?.captureDate
            == captureDate
        )
        #expect(
            card.memoryResult?
                .primaryAnchorResult?
                .elapsed.totalDays
            == 18
        )
        #expect(
            try encodedExpressionStyle(
                from: card.anchor
            ) == "birthdayNatural"
        )
    }

    @Test("Preview and export share the same frozen Memory expression")
    func previewAndExportShareTheSameFrozenMemoryExpression() throws {

        let suiteName =
            "RecordCardBuildServiceTests.PreviewExportMemoryExpression.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar.current
        let birthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 1,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 3,
                        day: 7,
                        hour: 10,
                        minute: 13,
                        second: 5
                    )
                )
            )
        let template =
            Template(
                preset: .template1,
                name: "Preview Export Memory Expression",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: TemplateArea(
                    name: "Right Top",
                    items: [.cameraSummary]
                ),
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .text,
                            name: "Memory",
                            value: "{{memory_summary}}"
                        )
                    ]
                ),
                badgeArea: .badge
            )
            .normalizedForEditing
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "小满",
                        shortName: "小满"
                    ),
                relationship:
                    .init(
                        role: "孩子",
                        label: "孩子"
                    ),
                definition: "真机反馈回归对象",
                referenceDate:
                    birthday,
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: birthday,
                        note: "生日",
                        anchorType:
                            .birthday,
                        expressionStyle:
                            .birthdayWarm
                    )
                ],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "生日记忆",
                                blocks: [
                                    .text("生日智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let previewText =
            try #require(
                MemoryExpressionPreviewResolver
                    .previewText(
                        subject: subject,
                        captureDate: captureDate
                    )
            )
        let legacyConfiguration =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor:
                    Anchor(
                        type: .birthday,
                        title: "旧生日",
                        date: birthday,
                        isCountdown: false
                    ),
                memorySubjectText: "家人",
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let configuration =
            legacyConfiguration
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot:
                    ConfigurationSnapshotBuilder
                    .build(from: subject)
            )
        let photo =
            SelectedPhoto(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_9999.JPEG"),
                image:
                    NSImage(
                        size:
                            NSSize(
                                width: 1920,
                                height: 1080
                            )
                    ),
                metadata:
                    PhotoMetadata(
                        captureDate: captureDate,
                        deviceBrand: "Apple",
                        deviceModel: "iPhone 15 Pro",
                        imageWidth: 4032,
                        imageHeight: 2268
                    )
            )

        let card =
            service.buildCard(
                from: photo,
                configuration: configuration
            )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(previewText.hasPrefix("陪小满走到"))
        #expect(previewText.contains("1岁2个月6天"))
        #expect(!previewText.contains("家人"))
        #expect(
            context[MetadataContext.Key.memorySummary]
            == previewText
        )
        #expect(
            card.exportDescriptionOverride
            == previewText
        )
    }

    @Test("Frozen MemoryResult keeps production variables from refilling legacy baby age")
    func frozenMemoryResultKeepsProductionVariablesFromRefillingLegacyBabyAge() throws {

        let suiteName =
            "RecordCardBuildServiceTests.FrozenMemoryResultAuthority.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let legacyBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 1,
                        day: 1
                    )
                )
            )
        let relationshipDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 2,
                        hour: 8,
                        minute: 30
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_8888.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )
        let template =
            Template(
                preset: .template1,
                name: "MemoryResult Authority",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: TemplateArea(
                    name: "Right Top",
                    items: [.cameraSummary]
                ),
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .text,
                            name: "Memory",
                            value: "年龄:{{baby_age}}|{{memory_summary}}"
                        )
                    ]
                ),
                badgeArea: .badge
            )
            .normalizedForEditing
        let legacySnapshot =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor: Anchor(
                    type: .birthday,
                    title: "旧生日",
                    date: legacyBirthday,
                    isCountdown: false
                ),
                memorySubjectText: "旧对象",
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "王途途",
                        shortName: "途途"
                    ),
                relationship:
                    .init(
                        role: "朋友",
                        label: "朋友"
                    ),
                definition: "测试对象",
                referenceDate:
                    relationshipDate,
                timeAnchors: [
                    .init(
                        title: "相识",
                        date: relationshipDate,
                        note: "相识日期",
                        anchorType:
                            .relationship,
                        expressionStyle:
                            .relationshipNatural
                    )
                ],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "相识",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "相识记忆",
                                blocks: [
                                    .text("相识智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let configurationSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        let snapshot =
            legacySnapshot
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot:
                    configurationSnapshot
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            card.memoryResult?
                .primaryAnchorResult?
                .anchorType == .relationship
        )
        #expect(
            card.memorySubjectText == "途途"
        )
        #expect(
            card.title == "相识"
        )
        #expect(
            card.anchor?.title == "相识"
        )
        #expect(
            card.anchor?.type == .relationship
        )
        #expect(
            card.anchor?.date == relationshipDate
        )
        #expect(
            card.anchorResult?.title == "相识"
        )
        #expect(
            context[MetadataContext.Key.title]
            == "相识"
        )
        #expect(
            context[MetadataContext.Key.babyAge]
            .isEmpty
        )
        #expect(
            context[MetadataContext.Key.memorySummary]
            == "相识已经1个月1天"
        )
        #expect(
            card.exportDescriptionOverride
            == "年龄:|相识已经1个月1天"
        )
    }

    @Test("Frozen MemoryResult clears legacy anchor display-copy variables in production output")
    func frozenMemoryResultClearsLegacyAnchorDisplayCopyVariablesInProductionOutput() throws {

        let suiteName =
            "RecordCardBuildServiceTests.FrozenMemoryResultDisplayCopy.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let legacyBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 1,
                        day: 1
                    )
                )
            )
        let relationshipDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 2,
                        hour: 8,
                        minute: 30
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_8889.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )
        let template =
            Template(
                preset: .template1,
                name: "MemoryResult Display Copy",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: TemplateArea(
                    name: "Right Top",
                    items: [.cameraSummary]
                ),
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .text,
                            name: "Legacy Copy",
                            value: "{{anchor_summary}}|{{anchor_primary}}|{{anchor_secondary}}"
                        )
                    ]
                ),
                badgeArea: .badge
            )
            .normalizedForEditing
        let legacySnapshot =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor: Anchor(
                    type: .birthday,
                    title: "旧生日",
                    date: legacyBirthday,
                    isCountdown: false
                ),
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "王途途",
                        shortName: "途途"
                    ),
                relationship:
                    .init(
                        role: "朋友",
                        label: "朋友"
                    ),
                definition: "测试对象",
                referenceDate:
                    relationshipDate,
                timeAnchors: [
                    .init(
                        title: "相识",
                        date: relationshipDate,
                        note: "相识日期",
                        anchorType:
                            .relationship,
                        expressionStyle:
                            .relationshipNatural
                    )
                ],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "相识",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "相识记忆",
                                blocks: [
                                    .text("相识智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let configurationSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        let snapshot =
            legacySnapshot
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot:
                    configurationSnapshot
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            card.memoryResult?
                .primaryAnchorResult?
                .anchorTitle == "相识"
        )
        #expect(
            context[MetadataContext.Key.anchorPrimary]
            .isEmpty
        )
        #expect(
            context[MetadataContext.Key.anchorSecondary]
            .isEmpty
        )
        #expect(
            context[MetadataContext.Key.anchorSummary]
            .isEmpty
        )
        #expect(
            card.exportDescriptionOverride
            == "||"
        )
    }

    @Test("Frozen unresolved MemoryResult keeps anchor title authoritative in production output")
    func frozenUnresolvedMemoryResultKeepsAnchorTitleAuthoritativeInProductionOutput() throws {

        let suiteName =
            "RecordCardBuildServiceTests.FrozenMemoryResultTitle.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let legacyBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 1,
                        day: 1
                    )
                )
            )
        let frozenBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 2,
                        hour: 8,
                        minute: 30
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_8890.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )
        let template =
            Template(
                preset: .template1,
                name: "MemoryResult Title Authority",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: TemplateArea(
                    name: "Right Top",
                    items: [.cameraSummary]
                ),
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .text,
                            name: "Frozen Title",
                            value: "{{anchor_title}}|{{anchor_age_text}}"
                        )
                    ]
                ),
                badgeArea: .badge
            )
            .normalizedForEditing
        let legacySnapshot =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor: Anchor(
                    type: .birthday,
                    title: "旧生日",
                    date: legacyBirthday,
                    isCountdown: false
                ),
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "王途途",
                        shortName: "途途"
                    ),
                relationship:
                    .init(
                        role: "孩子",
                        label: "孩子"
                    ),
                definition: "测试对象",
                referenceDate:
                    frozenBirthday,
                timeAnchors: [
                    .init(
                        title: "冻结生日",
                        date: frozenBirthday,
                        note: "冻结生日",
                        anchorType:
                            .birthday,
                        expressionStyle:
                            .birthdayNatural
                    )
                ],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "冻结生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "生日记忆",
                                blocks: [
                                    .text("生日智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        var configurationSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        configurationSnapshot
            .primaryAnchor?
            .isEnabled = false
        let snapshot =
            legacySnapshot
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot:
                    configurationSnapshot
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            card.memoryResult?
                .primaryAnchorResult?
                .status == .disabledAnchor
        )
        #expect(
            context[MetadataContext.Key.anchorTitle]
            == "冻结生日"
        )
        #expect(
            context[MetadataContext.Key.anchorAgeText]
            .isEmpty
        )
        #expect(
            card.exportDescriptionOverride
            == "冻结生日|"
        )
    }

    @Test("Frozen unsupported primary anchor does not refill card anchor from legacy batch input")
    func frozenUnsupportedPrimaryAnchorDoesNotRefillCardAnchorFromLegacyBatchInput() throws {

        let suiteName =
            "RecordCardBuildServiceTests.UnsupportedFrozenAnchor.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let legacyBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 1,
                        day: 1
                    )
                )
            )
        let frozenAnchorDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 2,
                        hour: 8,
                        minute: 30
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_8890B.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )
        let template =
            Template(
                preset: .template1,
                name: "Unsupported Frozen Anchor",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: TemplateArea(
                    name: "Right Top",
                    items: [.cameraSummary]
                ),
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .text,
                            name: "Frozen Title",
                            value: "{{anchor_title}}|{{anchor_age_text}}"
                        )
                    ]
                ),
                badgeArea: .badge
            )
            .normalizedForEditing
        let legacySnapshot =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor: Anchor(
                    type: .birthday,
                    title: "旧生日",
                    date: legacyBirthday,
                    isCountdown: false
                ),
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "王途途",
                        shortName: "途途"
                    ),
                relationship:
                    .init(
                        role: "孩子",
                        label: "孩子"
                    ),
                definition: "测试对象",
                referenceDate:
                    frozenAnchorDate,
                timeAnchors: [
                    .init(
                        title: "冻结未知锚点",
                        date: frozenAnchorDate,
                        note: "冻结未知锚点",
                        anchorType:
                            .birthday,
                        expressionStyle:
                            .birthdayNatural
                    )
                ],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "冻结未知锚点",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "未知锚点记忆",
                                blocks: [
                                    .text("未知锚点智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        var configurationSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        configurationSnapshot
            .primaryAnchor?
            .anchorType = nil
        let snapshot =
            legacySnapshot
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot:
                    configurationSnapshot
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            card.memoryResult?
                .primaryAnchorResult?
                .status == .unsupportedAnchor
        )
        #expect(card.anchor == nil)
        #expect(card.anchorResult == nil)
        #expect(
            context[MetadataContext.Key.anchorTitle]
            == "冻结未知锚点"
        )
        #expect(
            context[MetadataContext.Key.anchorAgeText]
            .isEmpty
        )
        #expect(
            card.exportDescriptionOverride
            == "冻结未知锚点|"
        )
    }

    @Test("Frozen snapshot without primary anchor does not refill card anchor from legacy batch input")
    func frozenSnapshotWithoutPrimaryAnchorDoesNotRefillCardAnchorFromLegacyBatchInput() throws {

        let suiteName =
            "RecordCardBuildServiceTests.NoFrozenPrimaryAnchor.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let legacyBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 1,
                        day: 1
                    )
                )
            )
        let referenceDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 2,
                        hour: 8,
                        minute: 30
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_8890C.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )
        let template =
            Template(
                preset: .template1,
                name: "No Frozen Primary Anchor",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: TemplateArea(
                    name: "Right Top",
                    items: [.cameraSummary]
                ),
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .text,
                            name: "Frozen Empty Anchor",
                            value: "{{anchor_title}}|{{anchor_age_text}}"
                        )
                    ]
                ),
                badgeArea: .badge
            )
            .normalizedForEditing
        let legacySnapshot =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor: Anchor(
                    type: .birthday,
                    title: "旧生日",
                    date: legacyBirthday,
                    isCountdown: false
                ),
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "王途途",
                        shortName: "途途"
                    ),
                relationship:
                    .init(
                        role: "孩子",
                        label: "孩子"
                    ),
                definition: "测试对象",
                referenceDate:
                    referenceDate,
                timeAnchors: [],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "无锚点记忆",
                                blocks: [
                                    .text("无锚点智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let configurationSnapshot =
            ConfigurationSnapshot(
                subjectID: subject.id,
                memorySubject: subject,
                expression:
                    subject.behavior.memoryExpression,
                decorations: [],
                primaryAnchor: nil
            )
        let snapshot =
            legacySnapshot
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot:
                    configurationSnapshot
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            card.memoryResult?
                .primaryAnchorResultID == nil
        )
        #expect(card.anchor == nil)
        #expect(card.anchorResult == nil)
        #expect(
            context[MetadataContext.Key.anchorTitle]
            .isEmpty
        )
        #expect(
            context[MetadataContext.Key.anchorAgeText]
            .isEmpty
        )
        #expect(
            card.exportDescriptionOverride
            == "|"
        )
    }

    @Test("Frozen MemoryResult clears legacy sub-day anchor components in production output")
    func frozenMemoryResultClearsLegacySubDayAnchorComponentsInProductionOutput() throws {

        let suiteName =
            "RecordCardBuildServiceTests.FrozenMemoryResultSubDay.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let legacyBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 1,
                        day: 1,
                        hour: 1,
                        minute: 2,
                        second: 3
                    )
                )
            )
        let frozenBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 2,
                        hour: 8,
                        minute: 30
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_8891.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )
        let template =
            Template(
                preset: .template1,
                name: "MemoryResult SubDay Authority",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: TemplateArea(
                    name: "Right Top",
                    items: [.cameraSummary]
                ),
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .text,
                            name: "SubDay",
                            value: "{{anchor_hours}}|{{anchor_minutes}}|{{anchor_seconds}}"
                        )
                    ]
                ),
                badgeArea: .badge
            )
            .normalizedForEditing
        let legacySnapshot =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor: Anchor(
                    type: .birthday,
                    title: "旧生日",
                    date: legacyBirthday,
                    isCountdown: false
                ),
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "王途途",
                        shortName: "途途"
                    ),
                relationship:
                    .init(
                        role: "孩子",
                        label: "孩子"
                    ),
                definition: "测试对象",
                referenceDate:
                    frozenBirthday,
                timeAnchors: [
                    .init(
                        title: "冻结生日",
                        date: frozenBirthday,
                        note: "冻结生日",
                        anchorType:
                            .birthday,
                        expressionStyle:
                            .birthdayNatural
                    )
                ],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "冻结生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "生日记忆",
                                blocks: [
                                    .text("生日智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let configurationSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        let snapshot =
            legacySnapshot
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot:
                    configurationSnapshot
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            card.memoryResult?
                .primaryAnchorResult?
                .precision == .day
        )
        #expect(
            context[MetadataContext.Key.anchorHours]
            .isEmpty
        )
        #expect(
            context[MetadataContext.Key.anchorMinutes]
            .isEmpty
        )
        #expect(
            context[MetadataContext.Key.anchorSeconds]
            .isEmpty
        )
        #expect(
            card.exportDescriptionOverride
            == "||"
        )
    }

    @Test("Frozen MemoryResult clears legacy milestone text in production output")
    func frozenMemoryResultClearsLegacyMilestoneTextInProductionOutput() throws {

        let suiteName =
            "RecordCardBuildServiceTests.FrozenMemoryResultMilestone.\(UUID().uuidString)"
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
            RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let legacyBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 3,
                        day: 24
                    )
                )
            )
        let frozenBirthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 2,
                        hour: 8,
                        minute: 30
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_8892.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )
        let template =
            Template(
                preset: .template1,
                name: "MemoryResult Milestone Authority",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: TemplateArea(
                    name: "Right Top",
                    items: [.cameraSummary]
                ),
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .text,
                            name: "Milestone",
                            value: "{{anchor_milestone_text}}|{{anchor_total_days}}"
                        )
                    ]
                ),
                badgeArea: .badge
            )
            .normalizedForEditing
        let legacySnapshot =
            BatchConfigurationSnapshot(
                template: template,
                badge: nil,
                anchor: Anchor(
                    type: .birthday,
                    title: "旧生日",
                    date: legacyBirthday,
                    isCountdown: false
                ),
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "王途途",
                        shortName: "途途"
                    ),
                relationship:
                    .init(
                        role: "孩子",
                        label: "孩子"
                    ),
                definition: "测试对象",
                referenceDate:
                    frozenBirthday,
                timeAnchors: [
                    .init(
                        title: "冻结生日",
                        date: frozenBirthday,
                        note: "冻结生日",
                        anchorType:
                            .birthday,
                        expressionStyle:
                            .birthdayNatural
                    )
                ],
                expressionSubjectSource:
                    .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "冻结生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "生日记忆",
                                blocks: [
                                    .text("生日智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let configurationSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        let snapshot =
            legacySnapshot
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot:
                    configurationSnapshot
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            card.memoryResult?
                .primaryAnchorResult?
                .elapsed.totalDays == 31
        )
        #expect(
            context[MetadataContext.Key.anchorMilestoneText]
            .isEmpty
        )
        #expect(
            card.exportDescriptionOverride
            == "|31"
        )
    }

    @MainActor
    @Test("Keeps original base filename and appends copy suffixes for repeated exports")
    func keepsOriginalBaseFilenameAndAppendsCopySuffixesForRepeatedExports() throws {

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/PhotoMemoNamingFixture.HEIC"),
            image: NSImage(size: NSSize(width: 32, height: 32)),
            metadata: PhotoMetadata(
                captureDate: Date(),
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 32,
                imageHeight: 32
            )
        )

        let card = RecordCardBuildService().buildCard(
            from: photo,
            configuration: BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        )

        let exportFolder =
            temporaryExportFolder()

        let firstURL =
            exportFolder.appendingPathComponent(
                "PhotoMemoNamingFixture(1).jpg"
            )
        let secondURL =
            exportFolder.appendingPathComponent(
                "PhotoMemoNamingFixture(2).jpg"
            )

        clearTemporaryExportFolder()

        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }

        let exportService = RecordCardExportService()

        let exportedFirstURL =
            try exportService.exportToTemporaryFile(
                photo: photo,
                card: card
            )
        let exportedSecondURL =
            try exportService.exportToTemporaryFile(
                photo: photo,
                card: card
            )

        #expect(
            exportedFirstURL.lastPathComponent
            == "PhotoMemoNamingFixture(1).jpg"
        )
        #expect(
            exportedSecondURL.lastPathComponent
            == "PhotoMemoNamingFixture(2).jpg"
        )
    }

    @MainActor
    @Test("Export naming prefers the imported original file name over the temporary source URL")
    func exportNamingPrefersImportedOriginalFileName() throws {

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/ManagedShareCopy.jpg"),
            image: NSImage(size: NSSize(width: 32, height: 32)),
            metadata: PhotoMetadata(
                captureDate: Date(),
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 32,
                imageHeight: 32
            ),
            sourceInfo: PhotoSourceInfo(
                originalFileName: "IMG_7581.HEIC",
                assetLocalIdentifier: "asset-7581",
                contentTypeIdentifier: "public.heic"
            )
        )

        let card = RecordCardBuildService().buildCard(
            from: photo,
            configuration: BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        )

        let exportFolder =
            temporaryExportFolder()

        let expectedURL =
            exportFolder.appendingPathComponent(
                "IMG_7581(1).jpg"
            )

        clearTemporaryExportFolder()

        defer {
            try? FileManager.default.removeItem(at: expectedURL)
        }

        let exportedURL =
            try RecordCardExportService()
            .exportToTemporaryFile(
                photo: photo,
                card: card
            )

        #expect(
            exportedURL.lastPathComponent
            == "IMG_7581(1).jpg"
        )
    }

    @MainActor
    @Test("Export naming falls back from placeholder names to a capture-date filename")
    func exportNamingFallsBackFromPlaceholderNamesToCaptureDateFilename() throws {

        var calendar =
            Calendar(identifier: .gregorian)
        calendar.timeZone =
            try #require(
                TimeZone(
                    secondsFromGMT:
                        8 * 60 * 60
                )
            )

        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 20,
                        hour: 9,
                        minute: 8,
                        second: 19
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/PhotoMemo Import.JPG"),
            image: NSImage(size: NSSize(width: 32, height: 32)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                captureTimezoneOffsetSeconds:
                    8 * 60 * 60,
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 32,
                imageHeight: 32
            ),
            sourceInfo: PhotoSourceInfo(
                originalFileName:
                    "PhotoMemo Import.JPG"
            )
        )

        let card = RecordCardBuildService().buildCard(
            from: photo,
            configuration: BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        )

        let exportFolder =
            temporaryExportFolder()

        let expectedURL =
            exportFolder.appendingPathComponent(
                "IMG_20260620_090819(1).jpg"
            )

        clearTemporaryExportFolder()

        defer {
            try? FileManager.default.removeItem(
                at: expectedURL
            )
        }

        let exportedURL =
            try RecordCardExportService()
            .exportToTemporaryFile(
                photo: photo,
                card: card
            )

        #expect(
            exportedURL.lastPathComponent
            == "IMG_20260620_090819(1).jpg"
        )
    }

    @MainActor
    @Test("Uses exported file name as the photo-library original filename")
    func usesExportedFileNameAsPhotoLibraryOriginalFilename() {

        let service =
            PhotoLibraryExportService()

        #expect(
            service.assetOriginalFilename(
                for: URL(fileURLWithPath: "/tmp/IMG_1234.jpg")
            ) == "IMG_1234.jpg"
        )

        #expect(
            service.assetOriginalFilename(
                for: URL(fileURLWithPath: "/tmp/IMG_1234 (1).jpg")
            ) == "IMG_1234 (1).jpg"
        )

        #expect(
            service.assetOriginalFilename(
                for: URL(fileURLWithPath: "/tmp/ ")
            ) == "PhotoMemo.jpg"
        )
    }
}

private extension RecordCardBuildServiceTests {

    func temporaryExportFolder() -> URL {

        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemoExports",
                isDirectory: true
            )
    }

    func clearTemporaryExportFolder() {

        try? FileManager.default.removeItem(
            at:
                temporaryExportFolder()
        )
    }

    func injectedExpressionStyleSnapshot(
        base: BatchConfigurationSnapshot,
        expressionStyle: String
    ) throws -> BatchConfigurationSnapshot {

        let data =
            try JSONEncoder().encode(base)
        guard
            var payload =
                try JSONSerialization
                .jsonObject(with: data)
                as? [String: Any],
            var anchorPayload =
                payload["anchor"]
                as? [String: Any]
        else {
            throw CocoaError(.coderInvalidValue)
        }

        anchorPayload["expressionStyle"] =
            expressionStyle
        payload["anchor"] =
            anchorPayload

        let mutatedData =
            try JSONSerialization.data(
                withJSONObject: payload
            )

        return try JSONDecoder().decode(
            BatchConfigurationSnapshot.self,
            from: mutatedData
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
