#if !PHOTOMEMO_SHARE_EXTENSION
import CryptoKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration import coordinator")
struct ConfigurationImportCoordinatorTests {

    @MainActor
    @Test("validation leaves live state unchanged and same-name subjects with different IDs coexist")
    func validationIsInertAndSubjectIdentityUsesUUID() throws {
        let live = Self.makeAggregate()
        let importedSubject = Self.makeSubject(
            id: Self.importedSubjectID,
            name: live.subjects[0].subject.identity.displayName
        )
        let importedConfiguration = Self.makeConfiguration(
            id: Self.importedConfigurationID,
            title: "Imported"
        )
        let liveDataBeforeImport = try Self.stableEncode(live)
        let document = Self.signedDocument(
            subject: importedSubject,
            configuration: importedConfiguration
        )
        let data = try Self.encode(document)
        let coordinator = ConfigurationImportCoordinator()

        let resolution = try coordinator.resolveImport(
            data: data,
            assetRootURL: nil,
            availableAlbumIdentifiers: []
        )

        #expect(try Self.stableEncode(live) == liveDataBeforeImport)
        let receipt = coordinator.restore(
            resolution,
            into: live
        )
        #expect(receipt.aggregate.subjects.count == 2)
        #expect(
            receipt.aggregate.subjects.map(\.subject.id) == [
                Self.liveSubjectID,
                Self.importedSubjectID
            ]
        )
        #expect(
            receipt.aggregate.subjects.map {
                $0.subject.identity.displayName
            } == ["途途", "途途"]
        )
        #expect(
            receipt.aggregate.activeSubjectID
            == live.activeSubjectID
        )
        #expect(
            receipt.aggregate.activeConfigurationID
            == live.activeConfigurationID
        )
    }

    @MainActor
    @Test("a colliding configuration ID restores as a new copy")
    func sameConfigurationIDRestoresAsCopy() throws {
        let live = Self.makeAggregate()
        let copiedID = UUID(
            uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
        )!
        let document = Self.signedDocument(
            subject: live.subjects[0].subject,
            configuration: live.subjects[0].configurations[0]
        )
        let coordinator = ConfigurationImportCoordinator(
            makeConfigurationID: { copiedID }
        )
        let resolution = try coordinator.resolveImport(
            data: try Self.encode(document),
            assetRootURL: nil,
            availableAlbumIdentifiers: []
        )

        let receipt = coordinator.restore(
            resolution,
            into: live
        )
        let configurations = receipt.aggregate.subjects[0]
            .configurations

        #expect(configurations.map(\.id) == [
            Self.liveConfigurationID,
            copiedID
        ])
        #expect(configurations[1].revision == 1)
        #expect(receipt.restoredConfigurationID == copiedID)
        #expect(
            receipt.warnings.contains(
                .configurationRestoredAsCopy(
                    originalID: Self.liveConfigurationID,
                    restoredID: copiedID
                )
            )
        )
    }

    @MainActor
    @Test("same-subject import preserves live facts and only adds missing anchors")
    func sameSubjectImportPreservesLiveFacts() throws {
        let liveAnchor = MemorySubject.TimeAnchor(
            id: Self.liveAnchorID,
            title: "Live Anchor",
            date: Date(timeIntervalSince1970: 100),
            note: "live"
        )
        let importedAnchor = MemorySubject.TimeAnchor(
            id: Self.importedAnchorID,
            title: "Imported Anchor",
            date: Date(timeIntervalSince1970: 200),
            note: "portable"
        )
        var liveSubject = Self.makeSubject(
            id: Self.liveSubjectID,
            name: "当前名称"
        )
        liveSubject.identity.shortName = "当前昵称"
        liveSubject.relationship = .init(
            role: "live-role",
            label: "live-label"
        )
        liveSubject.referenceDate = Date(timeIntervalSince1970: 900)
        liveSubject.timeAnchors = [liveAnchor]
        liveSubject.activeTimeAnchorID = liveAnchor.id
        liveSubject.behavior.primaryAnchor = "Live Anchor"

        var importedSubject = Self.makeSubject(
            id: Self.liveSubjectID,
            name: "旧备份名称"
        )
        importedSubject.identity.shortName = "旧昵称"
        importedSubject.relationship = .init(
            role: "backup-role",
            label: "backup-label"
        )
        importedSubject.referenceDate = Date(timeIntervalSince1970: 10)
        importedSubject.timeAnchors = [importedAnchor]
        importedSubject.activeTimeAnchorID = importedAnchor.id
        importedSubject.behavior.primaryAnchor = "Imported Anchor"
        var importedConfiguration = Self.makeConfiguration()
        importedConfiguration.selectedTimeAnchorID = liveAnchor.id
        let coordinator = ConfigurationImportCoordinator()

        let resolution = try coordinator.resolveImport(
            data: try Self.encode(
                Self.signedDocument(
                    subject: importedSubject,
                    configuration: importedConfiguration
                )
            ),
            assetRootURL: nil,
            availableAlbumIdentifiers: [],
            liveSubject: liveSubject
        )

        #expect(resolution.subject.identity == liveSubject.identity)
        #expect(resolution.subject.relationship == liveSubject.relationship)
        #expect(resolution.subject.referenceDate == liveSubject.referenceDate)
        #expect(resolution.subject.behavior == liveSubject.behavior)
        #expect(
            resolution.subject.timeAnchors.map(\.id)
            == [Self.liveAnchorID, Self.importedAnchorID]
        )
        #expect(
            resolution.configuration.selectedTimeAnchorID
            == Self.liveAnchorID
        )
        #expect(
            !resolution.warnings.contains(
                .missingAnchor(Self.liveAnchorID)
            )
        )

        let liveAggregate = ConfigurationLibraryRecord(
            revision: 7,
            subjects: [
                .init(
                    subject: liveSubject,
                    configurations: [
                        Self.makeConfiguration(
                            id: Self.liveConfigurationID,
                            title: "Current",
                            revision: 4
                        )
                    ],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: Self.liveSubjectID,
            activeConfigurationID: Self.liveConfigurationID
        )
        let restoredSubject = coordinator.restore(
            resolution,
            into: liveAggregate
        ).aggregate.subjects[0].subject

        #expect(restoredSubject.identity == liveSubject.identity)
        #expect(restoredSubject.relationship == liveSubject.relationship)
        #expect(restoredSubject.referenceDate == liveSubject.referenceDate)
        #expect(restoredSubject.behavior == liveSubject.behavior)
        #expect(
            restoredSubject.timeAnchors.map(\.id)
            == [Self.liveAnchorID, Self.importedAnchorID]
        )
    }

    @MainActor
    @Test("a missing selected anchor imports inactive")
    func missingAnchorFallsBackSafely() throws {
        let missingAnchorID = UUID(
            uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        )!
        var configuration = Self.makeConfiguration()
        configuration.selectedTimeAnchorID = missingAnchorID
        let document = Self.signedDocument(
            subject: Self.makeSubject(),
            configuration: configuration
        )

        let resolution = try ConfigurationImportCoordinator()
            .resolveImport(
                data: try Self.encode(document),
                assetRootURL: nil,
                availableAlbumIdentifiers: []
            )

        #expect(resolution.configuration.selectedTimeAnchorID == nil)
        #expect(
            resolution.warnings.contains(
                .missingAnchor(missingAnchorID)
            )
        )
    }

    @MainActor
    @Test("a missing album retains its title and falls back to automatic")
    func missingAlbumFallsBackSafely() throws {
        var configuration = Self.makeConfiguration()
        configuration.output.album = .init(
            destination: .existingAlbum,
            identifier: "missing-album",
            title: "成长记录"
        )
        let document = Self.signedDocument(
            subject: Self.makeSubject(),
            configuration: configuration
        )

        let resolution = try ConfigurationImportCoordinator()
            .resolveImport(
                data: try Self.encode(document),
                assetRootURL: nil,
                availableAlbumIdentifiers: ["available-album"]
            )

        #expect(
            resolution.configuration.output.album.destination
            == .automatic
        )
        #expect(resolution.configuration.output.album.identifier == "")
        #expect(
            resolution.configuration.output.album.title
            == "成长记录"
        )
        #expect(
            resolution.warnings.contains(
                .missingAlbum(
                    identifier: "missing-album",
                    title: "成长记录"
                )
            )
        )
    }

    @MainActor
    @Test("missing avatar and logo assets use safe fallbacks")
    func missingAssetsFallBackSafely() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let avatarReference = try PortableAssetReference(
            relativePath: "Assets/avatar.heic"
        )
        let logoReference = try PortableAssetReference(
            relativePath: "Assets/logo.png"
        )
        var subject = Self.makeSubject()
        subject.identity.avatarImagePath =
            avatarReference.relativePath
        var configuration = Self.makeConfiguration()
        configuration.presentation.logo = .init(
            mode: .customUpload,
            badge: .init(
                id: UUID(),
                name: "Logo",
                type: .customUpload,
                assetReference: logoReference
            )
        )
        let manifest = PortableAssetManifest(entries: [
            .init(role: .subjectAvatar, reference: avatarReference),
            .init(role: .customLogo, reference: logoReference)
        ])
        let document = Self.signedDocument(
            subject: subject,
            configuration: configuration,
            manifest: manifest
        )

        let resolution = try ConfigurationImportCoordinator()
            .resolveImport(
                data: try Self.encode(document),
                assetRootURL: rootURL,
                availableAlbumIdentifiers: []
            )

        #expect(resolution.subject.identity.avatarImagePath == nil)
        #expect(
            resolution.configuration.presentation.logo.mode
            == .appleMini
        )
        #expect(
            resolution.configuration.presentation.logo.badge?
                .assetReference == nil
        )
        #expect(resolution.assetManifest.entries.isEmpty)
        #expect(
            resolution.warnings.contains(
                .missingAsset(
                    role: .subjectAvatar,
                    path: avatarReference.relativePath
                )
            )
        )
        #expect(
            resolution.warnings.contains(
                .missingAsset(
                    role: .customLogo,
                    path: logoReference.relativePath
                )
            )
        )
    }

    @MainActor
    @Test("a manifest asset without an asset root is missing")
    func nilAssetRootFallsBackSafely() throws {
        let avatarReference = try PortableAssetReference(
            relativePath: "Assets/avatar.heic"
        )
        var subject = Self.makeSubject()
        subject.identity.avatarImagePath =
            avatarReference.relativePath
        let manifest = PortableAssetManifest(entries: [
            .init(role: .subjectAvatar, reference: avatarReference)
        ])

        let resolution = try ConfigurationImportCoordinator()
            .resolveImport(
                data: try Self.encode(
                    Self.signedDocument(
                        subject: subject,
                        configuration: Self.makeConfiguration(),
                        manifest: manifest
                    )
                ),
                assetRootURL: nil,
                availableAlbumIdentifiers: []
            )

        #expect(resolution.subject.identity.avatarImagePath == nil)
        #expect(resolution.assetManifest.entries.isEmpty)
        #expect(
            resolution.warnings.contains(
                .missingAsset(
                    role: .subjectAvatar,
                    path: avatarReference.relativePath
                )
            )
        )
    }

    @MainActor
    @Test("future and corrupt schemas reject without applying")
    func futureAndCorruptDocumentsReject() throws {
        let live = Self.makeAggregate()
        let liveDataBeforeImport = try Self.stableEncode(live)
        var applyCount = 0
        let coordinator = ConfigurationImportCoordinator(
            applyAggregate: { _ in
                applyCount += 1
                return Self.makeSaveReceipt()
            }
        )
        let documentData = try Self.encode(
            Self.signedDocument(
                subject: Self.makeSubject(),
                configuration: Self.makeConfiguration()
            )
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: documentData)
                as? [String: Any]
        )
        object["schemaVersion"] =
            PortableMemoryConfigurationDocument.latestSchemaVersion + 1
        let futureData = try JSONSerialization.data(withJSONObject: object)

        #expect {
            try coordinator.resolveImport(
                data: futureData,
                assetRootURL: nil,
                availableAlbumIdentifiers: []
            )
        } throws: { error in
            error as? ConfigurationImportError
            == .unsupportedFutureSchema(
                found: 2,
                latestSupported: 1
            )
        }
        #expect {
            try coordinator.resolveImport(
                data: Data("not-json".utf8),
                assetRootURL: nil,
                availableAlbumIdentifiers: []
            )
        } throws: { error in
            guard case .corruptDocument =
                error as? ConfigurationImportError else {
                return false
            }
            return true
        }
        #expect(applyCount == 0)
        #expect(try Self.stableEncode(live) == liveDataBeforeImport)
    }

    @MainActor
    @Test("checksum mismatch rejects without applying")
    func checksumMismatchRejects() throws {
        var document = Self.signedDocument(
            subject: Self.makeSubject(),
            configuration: Self.makeConfiguration()
        )
        document = PortableMemoryConfigurationDocument(
            appVersion: document.appVersion,
            subject: document.subject,
            configuration: document.configuration,
            assetManifest: document.assetManifest,
            documentChecksum: "sha256:tampered"
        )

        #expect {
            try ConfigurationImportCoordinator().resolveImport(
                data: try Self.encode(document),
                assetRootURL: nil,
                availableAlbumIdentifiers: []
            )
        } throws: { error in
            guard case .checksumMismatch =
                error as? ConfigurationImportError else {
                return false
            }
            return true
        }
    }

    @MainActor
    @Test("restore-current uses aggregate apply and leaves frozen jobs unchanged")
    func restoreCurrentUsesNormalApplyAndKeepsFrozenJob() async throws {
        let live = Self.makeAggregate()
        let frozenJob = Self.makeFrozenJob()
        let expectedJob = frozenJob
        var appliedAggregate: ConfigurationLibraryRecord?
        let expectedSaveReceipt = Self.makeSaveReceipt(
            subjectID: Self.importedSubjectID,
            configurationID: Self.importedConfigurationID
        )
        let coordinator = ConfigurationImportCoordinator(
            applyAggregate: { aggregate in
                appliedAggregate = aggregate
                return expectedSaveReceipt
            }
        )
        let resolution = try coordinator.resolveImport(
            data: try Self.encode(
                Self.signedDocument(
                    subject: Self.makeSubject(
                        id: Self.importedSubjectID,
                        name: "新对象"
                    ),
                    configuration: Self.makeConfiguration(
                        id: Self.importedConfigurationID,
                        title: "Restored Current"
                    )
                )
            ),
            assetRootURL: nil,
            availableAlbumIdentifiers: []
        )

        let receipt = try await coordinator.restoreAndMakeCurrent(
            resolution,
            into: live
        )

        #expect(
            appliedAggregate?.activeSubjectID
            == Self.importedSubjectID
        )
        #expect(
            appliedAggregate?.activeConfigurationID
            == Self.importedConfigurationID
        )
        #expect(receipt.saveReceipt == expectedSaveReceipt)
        #expect(frozenJob == expectedJob)
        #expect(
            frozenJob.configuration.configurationID
            == Self.liveConfigurationID
        )
        #expect(
            frozenJob.configuration.configurationRevision == 4
        )
    }
}

private extension ConfigurationImportCoordinatorTests {

    static let liveSubjectID = UUID(
        uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    )!
    static let importedSubjectID = UUID(
        uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    )!
    static let liveConfigurationID = UUID(
        uuidString: "11111111-1111-1111-1111-111111111111"
    )!
    static let importedConfigurationID = UUID(
        uuidString: "22222222-2222-2222-2222-222222222222"
    )!
    static let liveAnchorID = UUID(
        uuidString: "33333333-3333-3333-3333-333333333333"
    )!
    static let importedAnchorID = UUID(
        uuidString: "44444444-4444-4444-4444-444444444444"
    )!

    static func makeAggregate() -> ConfigurationLibraryRecord {
        ConfigurationLibraryRecord(
            revision: 7,
            subjects: [
                .init(
                    subject: makeSubject(
                        id: liveSubjectID,
                        name: "途途"
                    ),
                    configurations: [
                        makeConfiguration(
                            id: liveConfigurationID,
                            title: "Current",
                            revision: 4
                        )
                    ],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: liveSubjectID,
            activeConfigurationID: liveConfigurationID
        )
    }

    static func makeSubject(
        id: UUID = importedSubjectID,
        name: String = "导入对象"
    ) -> MemorySubject {
        MemorySubject(
            id: id,
            identity: .init(
                displayName: name,
                shortName: name
            ),
            relationship: .init(
                role: "family",
                label: "成长记录"
            ),
            referenceDate: Date(timeIntervalSince1970: 0),
            timeAnchors: [],
            activeTimeAnchorID: nil,
            behavior: .init(
                primaryAnchor: "生日",
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

    static func makeConfiguration(
        id: UUID = importedConfigurationID,
        title: String = "Imported",
        revision: Int = 3
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: id,
            title: title,
            revision: revision,
            savedAt: Date(timeIntervalSince1970: 300),
            selectedTimeAnchorID: nil,
            editor: .init(
                template: .classicWhite,
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

    static func signedDocument(
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord,
        manifest: PortableAssetManifest = .init(entries: [])
    ) -> PortableMemoryConfigurationDocument {
        let unsigned = PortableMemoryConfigurationDocument(
            appVersion: "1.6",
            subject: subject,
            configuration: configuration,
            assetManifest: manifest,
            documentChecksum: ""
        )
        let data = try! encode(unsigned)
        let checksum = "sha256:\(SHA256.hash(data: data).hexString)"
        return PortableMemoryConfigurationDocument(
            appVersion: unsigned.appVersion,
            subject: unsigned.subject,
            configuration: unsigned.configuration,
            assetManifest: unsigned.assetManifest,
            documentChecksum: checksum
        )
    }

    static func encode(
        _ document: PortableMemoryConfigurationDocument
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document)
    }

    static func stableEncode<Value: Encodable>(
        _ value: Value
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    static func makeSaveReceipt(
        subjectID: UUID = liveSubjectID,
        configurationID: UUID = liveConfigurationID
    ) -> ConfigurationLibrarySaveReceipt {
        ConfigurationLibrarySaveReceipt(
            revision: 8,
            subjectID: subjectID,
            configurationID: configurationID,
            configurationRevision: 4,
            compatibilityProjectionFailure: nil
        )
    }

    static func makeFrozenJob() -> BatchJob {
        BatchJob(
            title: "Frozen",
            state: .running,
            configuration: BatchConfigurationSnapshot(
                configurationID: liveConfigurationID,
                configurationRevision: 4,
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            ),
            tasks: []
        )
    }
}

private extension SHA256.Digest {

    nonisolated var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
