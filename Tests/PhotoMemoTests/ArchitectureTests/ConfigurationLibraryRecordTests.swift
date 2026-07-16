#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration library record")
struct ConfigurationLibraryRecordTests {

    @Test("version one deterministically round trips complete configuration state")
    func versionOneDeterministicallyRoundTripsCompleteState() throws {
        let subject = Self.makeSubject()
        let configurationID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let badgeAsset = try PortableAssetReference(
            relativePath: "Assets/logo.png"
        )
        let configuration = MemoryConfigurationRecord(
            id: configurationID,
            title: "成长配置",
            revision: 7,
            savedAt: Date(timeIntervalSince1970: 1_725_206_400),
            selectedTimeAnchorID: subject.timeAnchors[1].id,
            editor: .init(
                template: Self.makeTemplate(),
                regionTemplateIDs: [
                    .slotA: "recorder.configuration1",
                    .slotD: "memory.configuration1"
                ],
                memoryCopy: .init(
                    usesCustomText: true,
                    customText: "第一次一起看海"
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: .init(
                    token: "{{location}}",
                    options: ["displayStyle": "provinceCityDistrict"]
                ),
                logo: .init(
                    mode: .customUpload,
                    badge: .init(
                        id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
                        name: "家庭标识",
                        type: .customUpload,
                        assetReference: badgeAsset
                    )
                )
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: true,
                    overrideText: "照片图库说明"
                ),
                album: .init(
                    destination: .existingAlbum,
                    identifier: "album-88",
                    title: "成长记录"
                )
            )
        )
        let record = ConfigurationLibraryRecord(
            revision: 11,
            subjects: [
                SubjectConfigurationRecord(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(
                        entries: [
                            .init(
                                id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
                                role: .customLogo,
                                reference: badgeAsset,
                                checksum: "sha256:logo"
                            )
                        ]
                    )
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let firstData = try encoder.encode(record)
        let decoded = try JSONDecoder().decode(
            ConfigurationLibraryRecord.self,
            from: firstData
        )
        let secondData = try encoder.encode(decoded)

        #expect(decoded == record)
        #expect(secondData == firstData)
        #expect(decoded.schemaVersion == 1)
        #expect(decoded.subjects[0].subject == subject)
        #expect(decoded.subjects[0].configurations[0].editor.template == Self.makeTemplate())
        #expect(decoded.activeSubjectID == subject.id)
        #expect(decoded.activeConfigurationID == configuration.id)
        #expect(decoded.subjects[0].configurations[0].selectedTimeAnchorID == subject.timeAnchors[1].id)

        let json = try #require(String(data: firstData, encoding: .utf8))
        #expect(!json.localizedCaseInsensitiveContains("renderer"))
        #expect(!json.localizedCaseInsensitiveContains("layoutConstant"))
        #expect(!json.contains("/Users/"))
    }

    @Test("future schema is rejected through a typed compatibility result")
    func futureSchemaIsRejectedSafely() throws {
        let data = Data(#"{"schemaVersion":2,"revision":1,"subjects":[]}"#.utf8)

        let result = ConfigurationLibraryRecord.compatibilityResult(
            decoding: data
        )

        #expect(
            result == .unsupportedFutureSchema(
                found: 2,
                latestSupported: 1
            )
        )
    }

    @Test("schema validation uses the caller's explicit compatibility bounds")
    func schemaValidationUsesExplicitBounds() throws {
        #expect(throws: Never.self) {
            try ConfigurationSchemaCompatibility
                .requireSupportedSchema(
                    2,
                    earliestSupported: 1,
                    latestSupported: 2
                )
        }
        #expect(throws: ConfigurationSchemaDecodingError.self) {
            try ConfigurationSchemaCompatibility
                .requireSupportedSchema(
                    2,
                    earliestSupported: 1,
                    latestSupported: 1
                )
        }
        #expect(throws: ConfigurationSchemaDecodingError.self) {
            try ConfigurationSchemaCompatibility
                .requireSupportedSchema(
                    0,
                    earliestSupported: 1,
                    latestSupported: 2
                )
        }
    }

    @Test("editor decoding rejects duplicate region bindings")
    func editorDecodingRejectsDuplicateRegionBindings() throws {
        let configuration = Self.makeConfiguration(
            subject: Self.makeSubject()
        )
        let encoded = try JSONEncoder().encode(configuration)
        var object = try #require(
            JSONSerialization.jsonObject(
                with: encoded
            ) as? [String: Any]
        )
        var editor = try #require(
            object["editor"] as? [String: Any]
        )
        var bindings = try #require(
            editor["regionTemplateIDs"] as? [[String: Any]]
        )
        let duplicateBinding: [String: Any] = [
            "region": "slotA",
            "templateID": "duplicate.slotA"
        ]
        bindings.append(duplicateBinding)
        bindings.append(duplicateBinding)
        editor["regionTemplateIDs"] = bindings
        object["editor"] = editor
        let duplicateData = try JSONSerialization.data(
            withJSONObject: object
        )

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                MemoryConfigurationRecord.self,
                from: duplicateData
            )
        }
    }

    @Test("library and configuration revisions reject invalid durable values")
    func revisionsRejectInvalidDurableValues() throws {
        let subject = Self.makeSubject()
        let validConfiguration = Self.makeConfiguration(
            subject: subject
        )
        let validSubjectRecord = SubjectConfigurationRecord(
            subject: subject,
            configurations: [validConfiguration],
            assetManifest: .init(entries: [])
        )
        let zeroLibraryRevision = ConfigurationLibraryRecord(
            revision: 0,
            subjects: [validSubjectRecord],
            activeSubjectID: subject.id,
            activeConfigurationID: validConfiguration.id
        )
        #expect(zeroLibraryRevision.validationResult == .valid)
        #expect(throws: Never.self) {
            _ = try JSONEncoder().encode(zeroLibraryRevision)
        }

        let negativeLibraryRevision = ConfigurationLibraryRecord(
            revision: -1,
            subjects: [],
            activeSubjectID: nil,
            activeConfigurationID: nil
        )
        #expect(
            negativeLibraryRevision.validationResult
            == .invalid([.invalidLibraryRevision(-1)])
        )
        #expect(throws: EncodingError.self) {
            _ = try JSONEncoder().encode(
                negativeLibraryRevision
            )
        }

        let maximumLibraryRevision = ConfigurationLibraryRecord(
            revision: Int.max,
            subjects: [],
            activeSubjectID: nil,
            activeConfigurationID: nil
        )
        #expect(
            maximumLibraryRevision.validationResult
            == .invalid([.invalidLibraryRevision(Int.max)])
        )
        #expect(throws: EncodingError.self) {
            _ = try JSONEncoder().encode(
                maximumLibraryRevision
            )
        }

        let zeroConfigurationRevision = MemoryConfigurationRecord(
            id: validConfiguration.id,
            title: validConfiguration.title,
            revision: 0,
            savedAt: validConfiguration.savedAt,
            selectedTimeAnchorID:
                validConfiguration.selectedTimeAnchorID,
            editor: validConfiguration.editor,
            presentation: validConfiguration.presentation,
            output: validConfiguration.output
        )
        let invalidConfigurationRecord = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [zeroConfigurationRevision],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID:
                zeroConfigurationRevision.id
        )
        #expect(
            invalidConfigurationRecord.validationResult
            == .invalid([
                .invalidConfigurationRevision(
                    configurationID:
                        zeroConfigurationRevision.id,
                    revision: 0
                )
            ])
        )
        #expect(throws: EncodingError.self) {
            _ = try JSONEncoder().encode(
                zeroConfigurationRevision
            )
        }

        let maximumConfigurationRevision = MemoryConfigurationRecord(
            id: validConfiguration.id,
            title: validConfiguration.title,
            revision: Int.max,
            savedAt: validConfiguration.savedAt,
            selectedTimeAnchorID:
                validConfiguration.selectedTimeAnchorID,
            editor: validConfiguration.editor,
            presentation: validConfiguration.presentation,
            output: validConfiguration.output
        )
        #expect(throws: EncodingError.self) {
            _ = try JSONEncoder().encode(
                maximumConfigurationRevision
            )
        }

        var configurationObject = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(
                    validConfiguration
                )
            ) as? [String: Any]
        )
        configurationObject["revision"] = 0
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                MemoryConfigurationRecord.self,
                from: try JSONSerialization.data(
                    withJSONObject:
                        configurationObject
                )
            )
        }

        var libraryObject = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(
                    zeroLibraryRevision
                )
            ) as? [String: Any]
        )
        libraryObject["revision"] = -1
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                ConfigurationLibraryRecord.self,
                from: try JSONSerialization.data(
                    withJSONObject: libraryObject
                )
            )
        }
    }

    @Test("portable assets reject absolute and escaping paths")
    func portableAssetsRejectNonRelativePaths() throws {
        let invalidPaths = [
            "/Users/rui/logo.png",
            "Assets\\logo.png",
            "\\\\server\\share\\logo.png",
            "C:\\Assets\\logo.png",
            "https:logo.png",
            "Assets/./logo.png",
            "Assets/../logo.png",
            "Assets//logo.png",
            "Assets/logo.png/"
        ]

        for path in invalidPaths {
            #expect(throws: PortableAssetValidationError.self) {
                _ = try PortableAssetReference(
                    relativePath: path
                )
            }
        }

        #expect(
            try PortableAssetReference(
                relativePath: "Assets/logo.png"
            ).relativePath == "Assets/logo.png"
        )
    }

    @Test("portable document validates schema ownership and assets")
    func portableDocumentValidatesSchemaOwnershipAndAssets() throws {
        let subject = Self.makeSubject()
        let configuration = Self.makeConfiguration(
            subject: subject
        )
        let document = PortableMemoryConfigurationDocument(
            appVersion: "0.7.0",
            subject: subject,
            configuration: configuration,
            assetManifest: .init(entries: []),
            documentChecksum: "sha256:document"
        )

        #expect(document.validationResult == .valid)
        #expect(
            PortableMemoryConfigurationDocument
                .compatibilityResult(
                    decoding: try JSONEncoder().encode(document)
                )
            == .compatible(document)
        )
    }

    @Test("aggregate and portable document require a unique role-matched manifest closure")
    func manifestReferencesAreClosedUniqueAndRoleMatched() throws {
        let avatar = try PortableAssetReference(
            relativePath: "Assets/avatar.png"
        )
        let avatarBadge = try PortableAssetReference(
            relativePath: "Assets/avatar-badge.png"
        )
        let avatarPreview = try PortableAssetReference(
            relativePath: "Assets/avatar-preview.png"
        )
        let logo = try PortableAssetReference(
            relativePath: "Assets/logo.png"
        )
        var subject = Self.makeSubject()
        subject.identity.avatarImagePath = avatar.relativePath
        subject.identity.avatarBadgeImagePath = avatarBadge.relativePath
        subject.identity.avatarPreviewImagePath = avatarPreview.relativePath
        var configuration = Self.makeConfiguration(
            subject: subject
        )
        configuration.presentation.logo.badge = .init(
            id: UUID(uuidString: "61616161-6161-6161-6161-616161616161")!,
            name: "Logo",
            type: .customUpload,
            assetReference: logo
        )
        let avatarEntryID = UUID(uuidString: "62626262-6262-6262-6262-626262626262")!
        let entries: [PortableAssetManifest.Entry] = [
            .init(
                id: avatarEntryID,
                role: .subjectAvatar,
                reference: avatar
            ),
            .init(
                id: UUID(uuidString: "63636363-6363-6363-6363-636363636363")!,
                role: .subjectAvatarBadge,
                reference: avatarBadge
            ),
            .init(
                id: UUID(uuidString: "64646464-6464-6464-6464-646464646464")!,
                role: .subjectAvatarPreview,
                reference: avatarPreview
            ),
            .init(
                id: UUID(uuidString: "65656565-6565-6565-6565-656565656565")!,
                role: .customLogo,
                reference: logo
            )
        ]
        let validManifest = PortableAssetManifest(
            entries: entries
        )

        func document(
            manifest: PortableAssetManifest
        ) -> PortableMemoryConfigurationDocument {
            PortableMemoryConfigurationDocument(
                appVersion: "0.7.0",
                subject: subject,
                configuration: configuration,
                assetManifest: manifest,
                documentChecksum: "sha256:document"
            )
        }

        func aggregate(
            manifest: PortableAssetManifest
        ) -> ConfigurationLibraryRecord {
            ConfigurationLibraryRecord(
                revision: 1,
                subjects: [
                    .init(
                        subject: subject,
                        configurations: [configuration],
                        assetManifest: manifest
                    )
                ],
                activeSubjectID: subject.id,
                activeConfigurationID: configuration.id
            )
        }

        #expect(document(manifest: validManifest).validationResult == .valid)
        #expect(aggregate(manifest: validManifest).validationResult == .valid)

        let missingLogoManifest = PortableAssetManifest(
            entries: Array(entries.dropLast())
        )
        let missingIssue = ConfigurationRecordValidationIssue
            .missingManifestAsset(
                path: logo.relativePath,
                expectedRole: .customLogo
            )
        #expect(
            document(manifest: missingLogoManifest)
                .validationResult
            == .invalid([missingIssue])
        )
        #expect(
            aggregate(manifest: missingLogoManifest)
                .validationResult
            == .invalid([missingIssue])
        )

        let duplicateIDManifest = PortableAssetManifest(
            entries: entries + [
                .init(
                    id: avatarEntryID,
                    role: .customLogo,
                    reference: try PortableAssetReference(
                        relativePath: "Assets/extra.png"
                    )
                )
            ]
        )
        #expect(
            duplicateIDManifest.validationIssues.contains(
                .duplicateManifestEntryID(avatarEntryID)
            )
        )

        let duplicatePathManifest = PortableAssetManifest(
            entries: entries + [
                .init(
                    id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
                    role: .customLogo,
                    reference: logo
                )
            ]
        )
        #expect(
            document(manifest: duplicatePathManifest)
                .validationResult
            == .invalid([
                .duplicateManifestPath(logo.relativePath)
            ])
        )

        var roleMismatchEntries = entries
        roleMismatchEntries[0] = .init(
            id: avatarEntryID,
            role: .customLogo,
            reference: avatar
        )
        #expect(
            aggregate(
                manifest: .init(
                    entries: roleMismatchEntries
                )
            ).validationResult
            == .invalid([
                .manifestRoleMismatch(
                    path: avatar.relativePath,
                    expectedRole: .subjectAvatar,
                    actualRole: .customLogo
                )
            ])
        )

        let noAssetSubject = Self.makeSubject()
        let noAssetConfiguration = Self.makeConfiguration(
            subject: noAssetSubject
        )
        #expect(
            PortableMemoryConfigurationDocument(
                appVersion: "0.7.0",
                subject: noAssetSubject,
                configuration: noAssetConfiguration,
                assetManifest: .init(entries: []),
                documentChecksum: "sha256:empty"
            ).validationResult == .valid
        )
    }

    @Test("aggregate validation enforces active ownership and globally unique identities")
    func aggregateValidationEnforcesActiveOwnershipAndUniqueIDs() {
        let firstSubject = Self.makeSubject()
        let secondSubject = Self.makeSubject(
            id: UUID(uuidString: "71717171-7171-7171-7171-717171717171")!,
            name: "第二对象"
        )
        let firstConfiguration = Self.makeConfiguration(
            subject: firstSubject
        )
        let secondConfiguration = MemoryConfigurationRecord(
            id: UUID(uuidString: "72727272-7272-7272-7272-727272727272")!,
            title: "第二配置",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 2),
            selectedTimeAnchorID: secondSubject.timeAnchors[0].id,
            editor: firstConfiguration.editor,
            presentation: firstConfiguration.presentation,
            output: firstConfiguration.output
        )

        let activeWithoutSubject = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: firstSubject,
                    configurations: [firstConfiguration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: nil,
            activeConfigurationID: firstConfiguration.id
        )
        #expect(
            activeWithoutSubject.validationResult
            == .invalid([
                .activeConfigurationWithoutActiveSubject(
                    firstConfiguration.id
                )
            ])
        )

        let duplicateSubject = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: firstSubject,
                    configurations: [firstConfiguration],
                    assetManifest: .init(entries: [])
                ),
                .init(
                    subject: firstSubject,
                    configurations: [secondConfiguration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: nil,
            activeConfigurationID: nil
        )
        #expect(
            duplicateSubject.validationResult
            == .invalid([
                .duplicateSubjectID(firstSubject.id)
            ])
        )

        let repeatedConfiguration = MemoryConfigurationRecord(
            id: firstConfiguration.id,
            title: "重复 ID",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 3),
            selectedTimeAnchorID: nil,
            editor: secondConfiguration.editor,
            presentation: secondConfiguration.presentation,
            output: secondConfiguration.output
        )
        let duplicateConfiguration = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: firstSubject,
                    configurations: [firstConfiguration],
                    assetManifest: .init(entries: [])
                ),
                .init(
                    subject: secondSubject,
                    configurations: [repeatedConfiguration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: nil,
            activeConfigurationID: nil
        )
        #expect(
            duplicateConfiguration.validationResult
            == .invalid([
                .duplicateConfigurationID(
                    firstConfiguration.id
                )
            ])
        )
    }

    @Test("V1 migration preserves identities separates copy from description and binds ownerless presets only to active subject")
    func v1MigrationPreservesIdentityAndOwnershipRules() throws {
        var activeSubject = Self.makeSubject()
        activeSubject.identity.avatarImagePath = "/tmp/family/avatar.jpg"
        let otherSubject = Self.makeSubject(
            id: UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!,
            name: "另一个对象"
        )
        let ownerlessPreset = MemoryPreset(
            id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
            title: "当前配置",
            summary: "legacy",
            regionTemplateIDs: [.slotD: "memory.configuration1"],
            savedAt: Date(timeIntervalSince1970: 100),
            selectedSubjectID: nil,
            selectedTimeAnchorID: activeSubject.timeAnchors[0].id,
            logoMode: .customUpload,
            usesCustomMemoryWriteText: true,
            customMemoryWriteText: "Memory 卡片文案"
        )
        let library = V1SubjectLibraryRecord(
            subjects: [activeSubject, otherSubject],
            selectedSubjectID: activeSubject.id,
            memoryPresets: [ownerlessPreset],
            selectedMemoryPresetID: ownerlessPreset.id
        )
        let compatibility = LegacyConfigurationCompatibilitySettings(
            template: Self.makeTemplate(),
            badge: Badge(
                id: UUID(uuidString: "12121212-1212-1212-1212-121212121212")!,
                name: "自定义 Logo",
                type: .customUpload,
                imagePath: "/tmp/family/logo.png"
            ),
            logoMode: .customUpload,
            locationConfiguration: .init(
                token: "{{location}}",
                options: ["displayStyle": "city"]
            ),
            shouldWritePhotosDescription: true,
            photosDescriptionOverride: "Photos 独立说明",
            selectedAlbumIdentifier: "album-legacy",
            selectedAlbumTitle: "家庭相册",
            mediaOutputMode: .staticImage
        )

        let migrated = ConfigurationLibraryRecord.migrating(
            library,
            compatibility: compatibility,
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 200)
        )

        let activeRecord = try #require(
            migrated.subjects.first { $0.subject.id == activeSubject.id }
        )
        let migratedConfiguration = try #require(
            activeRecord.configurations.first
        )
        let otherRecord = try #require(
            migrated.subjects.first { $0.subject.id == otherSubject.id }
        )

        #expect(migrated.schemaVersion == 1)
        #expect(migrated.revision == 3)
        #expect(migrated.activeSubjectID == activeSubject.id)
        #expect(migrated.activeConfigurationID == ownerlessPreset.id)
        #expect(migratedConfiguration.id == ownerlessPreset.id)
        #expect(migratedConfiguration.selectedTimeAnchorID == activeSubject.timeAnchors[0].id)
        #expect(migratedConfiguration.editor.memoryCopy.customText == "Memory 卡片文案")
        #expect(migratedConfiguration.output.photosDescriptionPolicy.overrideText == "Photos 独立说明")
        #expect(migratedConfiguration.output.album.identifier == "album-legacy")
        #expect(migratedConfiguration.output.album.title == "家庭相册")
        #expect(migratedConfiguration.output.mediaMode == .staticImage)
        #expect(activeRecord.subject.identity.avatarImagePath?.hasPrefix("Assets/") == true)
        #expect(migratedConfiguration.presentation.logo.badge?.assetReference?.relativePath.hasPrefix("Assets/") == true)
        #expect(activeRecord.assetManifest.entries.count == 2)
        #expect(otherRecord.configurations.count == 1)
        #expect(otherRecord.configurations[0].id == MemoryConfigurationRecord.fallbackID(for: otherSubject.id))
        #expect(otherRecord.configurations[0].id != ownerlessPreset.id)
        #expect(migrated.validationResult == .valid)
    }

    @Test("V1 migration builds the active deterministic fallback from compatibility settings")
    func v1MigrationBuildsActiveFallbackFromCompatibilitySettings() throws {
        let subject = Self.makeSubject()
        let compatibility = LegacyConfigurationCompatibilitySettings(
            template: Self.makeTemplate(),
            badge: .family,
            logoMode: .appleMini,
            locationConfiguration: .init(
                token: "{{location}}",
                options: ["displayStyle": "city"]
            ),
            shouldWritePhotosDescription: true,
            photosDescriptionOverride: "保留 Photos 说明",
            selectedAlbumIdentifier: "album-fallback",
            selectedAlbumTitle: "保留相册",
            mediaOutputMode: .staticImage
        )
        let legacy = V1SubjectLibraryRecord(
            subjects: [subject],
            selectedSubjectID: subject.id,
            memoryPresets: [],
            selectedMemoryPresetID: nil
        )

        let migrated = ConfigurationLibraryRecord.migrating(
            legacy,
            compatibility: compatibility,
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 300)
        )
        let fallback = try #require(
            migrated.subjects.first?.configurations.first
        )

        #expect(fallback.id == MemoryConfigurationRecord.fallbackID(for: subject.id))
        #expect(fallback.editor.template == compatibility.template)
        #expect(fallback.presentation.locationConfiguration == compatibility.locationConfiguration)
        #expect(fallback.output.photosDescriptionPolicy.overrideText == "保留 Photos 说明")
        #expect(fallback.output.album.identifier == "album-fallback")
        #expect(fallback.output.album.title == "保留相册")
        #expect(fallback.output.mediaMode == .staticImage)
    }

    @Test("V1 migration applies compatibility to the first active configuration when selection is nil")
    func v1MigrationUsesFirstActiveConfigurationWhenSelectionIsNil() throws {
        try assertFirstActiveConfigurationReceivesCompatibility(
            selectedMemoryPresetID: nil
        )
    }

    @Test("V1 migration applies compatibility to the first active configuration when selection is invalid")
    func v1MigrationUsesFirstActiveConfigurationWhenSelectionIsInvalid() throws {
        try assertFirstActiveConfigurationReceivesCompatibility(
            selectedMemoryPresetID:
                UUID(uuidString: "DEDEDEDE-DEDE-DEDE-DEDE-DEDEDEDEDEDE")!
        )
    }

    private func assertFirstActiveConfigurationReceivesCompatibility(
        selectedMemoryPresetID: UUID?
    ) throws {
        let activeSubject = Self.makeSubject()
        let otherSubject = Self.makeSubject(
            id: UUID(uuidString: "31313131-3131-3131-3131-313131313131")!,
            name: "其他对象"
        )
        let firstPreset = MemoryPreset(
            id: UUID(uuidString: "41414141-4141-4141-4141-414141414141")!,
            title: "首个配置",
            summary: "first",
            regionTemplateIDs: [.slotA: "first.slotA"],
            selectedSubjectID: activeSubject.id,
            selectedTimeAnchorID: activeSubject.timeAnchors[0].id
        )
        let secondPreset = MemoryPreset(
            id: UUID(uuidString: "42424242-4242-4242-4242-424242424242")!,
            title: "第二配置",
            summary: "second",
            regionTemplateIDs: [.slotA: "second.slotA"],
            selectedSubjectID: activeSubject.id,
            selectedTimeAnchorID: activeSubject.timeAnchors[1].id
        )
        let otherPreset = MemoryPreset(
            id: UUID(uuidString: "43434343-4343-4343-4343-434343434343")!,
            title: "其他对象配置",
            summary: "other",
            regionTemplateIDs: [.slotA: "other.slotA"],
            selectedSubjectID: otherSubject.id,
            selectedTimeAnchorID: otherSubject.timeAnchors[0].id
        )
        let compatibility = LegacyConfigurationCompatibilitySettings(
            template: Self.makeTemplate(),
            badge: Badge(
                id: UUID(uuidString: "51515151-5151-5151-5151-515151515151")!,
                name: "Compatibility Logo",
                type: .systemSymbol,
                systemSymbol: "heart.fill",
                isSystemDefault: true
            ),
            logoMode: .customUpload,
            locationConfiguration: .init(
                token: "{{location}}",
                options: ["displayStyle": "provinceCityDistrict"]
            ),
            shouldWritePhotosDescription: true,
            photosDescriptionOverride: "Compatibility Photos Description",
            selectedAlbumIdentifier: "compatibility-album",
            selectedAlbumTitle: "Compatibility Album",
            mediaOutputMode: .staticImage
        )
        let legacy = V1SubjectLibraryRecord(
            subjects: [activeSubject, otherSubject],
            selectedSubjectID: activeSubject.id,
            memoryPresets: [firstPreset, secondPreset, otherPreset],
            selectedMemoryPresetID: selectedMemoryPresetID
        )

        let migrated = ConfigurationLibraryRecord.migrating(
            legacy,
            compatibility: compatibility,
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 400)
        )
        let activeRecord = try #require(
            migrated.subjects.first {
                $0.subject.id == activeSubject.id
            }
        )
        let otherRecord = try #require(
            migrated.subjects.first {
                $0.subject.id == otherSubject.id
            }
        )
        let firstConfiguration = try #require(
            activeRecord.configurations.first
        )
        let secondConfiguration = try #require(
            activeRecord.configurations.dropFirst().first
        )
        let otherConfiguration = try #require(
            otherRecord.configurations.first
        )

        #expect(
            activeRecord.configurations.map(\.id)
            == [firstPreset.id, secondPreset.id]
        )
        #expect(migrated.activeConfigurationID == firstPreset.id)
        #expect(firstConfiguration.editor.template == compatibility.template)
        #expect(firstConfiguration.presentation.locationConfiguration == compatibility.locationConfiguration)
        #expect(firstConfiguration.presentation.logo.mode == compatibility.logoMode)
        #expect(firstConfiguration.presentation.logo.badge?.id == compatibility.badge?.id)
        #expect(firstConfiguration.output.photosDescriptionPolicy.isEnabled)
        #expect(firstConfiguration.output.photosDescriptionPolicy.overrideText == compatibility.photosDescriptionOverride)
        #expect(firstConfiguration.output.album.identifier == compatibility.selectedAlbumIdentifier)
        #expect(firstConfiguration.output.album.title == compatibility.selectedAlbumTitle)
        #expect(firstConfiguration.output.mediaMode == compatibility.mediaOutputMode)
        #expect(firstConfiguration.output.livePhotoPolicy == .staticImageOnly)

        #expect(secondConfiguration.editor.template != compatibility.template)
        #expect(secondConfiguration.presentation.locationConfiguration == nil)
        #expect(secondConfiguration.presentation.logo.badge == nil)
        #expect(!secondConfiguration.output.photosDescriptionPolicy.isEnabled)
        #expect(secondConfiguration.output.album.identifier.isEmpty)
        #expect(secondConfiguration.output.mediaMode == .originalFormat)

        #expect(otherConfiguration.editor.template != compatibility.template)
        #expect(otherConfiguration.presentation.locationConfiguration == nil)
        #expect(otherConfiguration.presentation.logo.badge == nil)
        #expect(!otherConfiguration.output.photosDescriptionPolicy.isEnabled)
        #expect(otherConfiguration.output.album.identifier.isEmpty)
        #expect(otherConfiguration.output.mediaMode == .originalFormat)
    }

    private static func makeConfiguration(
        subject: MemorySubject
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: UUID(uuidString: "ABABABAB-ABAB-ABAB-ABAB-ABABABABABAB")!,
            title: "配置",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 1),
            selectedTimeAnchorID: subject.timeAnchors[0].id,
            editor: .init(
                template: makeTemplate(),
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(mode: .appleMini, badge: nil)
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
    }

    private static func makeTemplate() -> Template {
        func area(
            id: String,
            itemID: String,
            name: String,
            source: TemplateItem
        ) -> TemplateArea {
            TemplateArea(
                id: UUID(uuidString: id)!,
                name: name,
                items: [
                    TemplateItem(
                        id: UUID(uuidString: itemID)!,
                        type: source.type,
                        name: source.name,
                        value: source.value,
                        isEnabled: source.isEnabled
                    )
                ]
            )
        }

        return Template(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            preset: .classicWhite,
            name: "Classic White",
            leftTopArea: area(
                id: "91919191-9191-9191-9191-919191919191",
                itemID: "81818181-8181-8181-8181-818181818181",
                name: "Left Top",
                source: .relationshipDeviceLine
            ),
            leftBottomArea: area(
                id: "92929292-9292-9292-9292-929292929292",
                itemID: "82828282-8282-8282-8282-828282828282",
                name: "Left Bottom",
                source: .captureDateLine
            ),
            rightTopArea: area(
                id: "93939393-9393-9393-9393-939393939393",
                itemID: "83838383-8383-8383-8383-838383838383",
                name: "Right Top",
                source: .cameraSummary
            ),
            rightBottomArea: area(
                id: "94949494-9494-9494-9494-949494949494",
                itemID: "84848484-8484-8484-8484-848484848484",
                name: "Right Bottom",
                source: .memorySummary
            ),
            badgeArea: area(
                id: "95959595-9595-9595-9595-959595959595",
                itemID: "85858585-8585-8585-8585-858585858585",
                name: "Badge",
                source: .badge
            ),
        )
    }

    private static func makeSubject(
        id: UUID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        name: String = "小宝"
    ) -> MemorySubject {
        let birthday = MemorySubject.TimeAnchor(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "生日",
            date: Date(timeIntervalSince1970: 0),
            note: "出生"
        )
        let school = MemorySubject.TimeAnchor(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "入园",
            date: Date(timeIntervalSince1970: 86_400),
            note: "第一次上学"
        )

        return MemorySubject(
            id: id,
            identity: .init(
                displayName: name,
                shortName: name
            ),
            relationship: .init(
                role: "family",
                label: "成长记录"
            ),
            definition: "持续记录成长",
            referenceDate: birthday.date,
            timeAnchors: [birthday, school],
            activeTimeAnchorID: birthday.id,
            behavior: .init(
                primaryAnchor: birthday.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: "默认表达",
                    blocks: []
                )
            ),
            decorations: []
        )
    }
}
#endif
