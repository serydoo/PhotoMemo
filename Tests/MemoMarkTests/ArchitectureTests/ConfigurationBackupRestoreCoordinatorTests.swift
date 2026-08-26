#if !MEMOMARK_SHARE_EXTENSION
import CryptoKit
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration backup restore coordinator")
struct ConfigurationBackupRestoreCoordinatorTests {

    @MainActor
    @Test("restore and make current reconciles revision and pairs security scope")
    func restoreAndMakeCurrentReconcilesRevision() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let documentURL = rootURL.appendingPathComponent("backup.memomarkconfig")
        let missingAvatar = try PortableAssetReference(
            relativePath: "Assets/missing-avatar.heic"
        )
        var importedSubject = Self.makeSubject(id: Self.importedSubjectID)
        importedSubject.identity.avatarImagePath = missingAvatar.relativePath
        let document = Self.signedDocument(
            subject: importedSubject,
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID,
                title: "Restored"
            ),
            manifest: .init(entries: [
                .init(role: .subjectAvatar, reference: missingAvatar)
            ])
        )
        try Self.encode(document).write(to: documentURL)
        var startCount = 0
        var stopCount = 0
        var appliedAggregate: ConfigurationLibraryRecord?
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { aggregate in
                    appliedAggregate = aggregate
                    return Self.makeSaveReceipt(
                        revision: 42,
                        subjectID: Self.importedSubjectID,
                        configurationID: Self.importedConfigurationID
                    )
                },
                readData: { try Data(contentsOf: $0) },
                startSecurityScopedAccess: { _ in
                    startCount += 1
                    return true
                },
                stopSecurityScopedAccess: { _ in
                    stopCount += 1
                }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: documentURL,
                assetRootURL: nil,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: []
            )
        )

        #expect(result.succeeded)
        #expect(result.aggregate?.revision == 42)
        #expect(
            result.aggregate?.activeSubjectID == Self.importedSubjectID
        )
        #expect(
            result.aggregate?.activeConfigurationID
            == Self.importedConfigurationID
        )
        #expect(
            appliedAggregate?.activeConfigurationID
            == Self.importedConfigurationID
        )
        #expect(result.shouldApplyCurrentConfiguration)
        #expect(
            result.warnings.contains(
                .missingAsset(
                    role: .subjectAvatar,
                    path: missingAvatar.relativePath
                )
            )
        )
        #expect(result.status == .replace("已恢复并设为当前配置。 部分缺失资源已使用安全回退。"))
        #expect(startCount == 1)
        #expect(stopCount == 1)
    }

    @MainActor
    @Test("restore copy preserves current selection and reconciles revision")
    func restoreCopyPreservesCurrentSelection() async throws {
        let document = Self.signedDocument(
            subject: Self.makeSubject(id: Self.importedSubjectID),
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID,
                title: "Copy"
            )
        )
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { aggregate in
                    #expect(aggregate.activeSubjectID == Self.liveSubjectID)
                    #expect(
                        aggregate.activeConfigurationID
                        == Self.liveConfigurationID
                    )
                    return Self.makeSaveReceipt(revision: 19)
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in
                    Issue.record("Security scope should not stop when start returned false")
                }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: URL(fileURLWithPath: "/tmp/copy.memomarkconfig"),
                assetRootURL: nil,
                makeCurrent: false,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: []
            )
        )

        #expect(result.succeeded)
        #expect(result.aggregate?.revision == 19)
        #expect(result.aggregate?.activeSubjectID == Self.liveSubjectID)
        #expect(
            result.aggregate?.activeConfigurationID
            == Self.liveConfigurationID
        )
        #expect(!result.shouldApplyCurrentConfiguration)
        #expect(result.status == .replace("已恢复配置副本。"))
    }

    @MainActor
    @Test("restore into an empty library makes the first configuration current")
    func restoreIntoEmptyLibraryMakesFirstConfigurationCurrent() async throws {
        let document = Self.signedDocument(
            subject: Self.makeSubject(id: Self.importedSubjectID),
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID,
                title: "First Restored"
            )
        )
        var savedAggregate: ConfigurationLibraryRecord?
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { aggregate in
                    savedAggregate = aggregate
                    return Self.makeSaveReceipt(
                        revision: 23,
                        subjectID: Self.importedSubjectID,
                        configurationID: Self.importedConfigurationID
                    )
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: URL(fileURLWithPath: "/tmp/first.memomarkconfig"),
                assetRootURL: nil,
                makeCurrent: false,
                aggregate: nil,
                availableAlbumIdentifiers: [],
                currentSubjectID: nil,
                previousBackups: []
            )
        )

        #expect(result.succeeded)
        #expect(savedAggregate?.activeSubjectID == Self.importedSubjectID)
        #expect(
            savedAggregate?.activeConfigurationID
            == Self.importedConfigurationID
        )
        #expect(result.shouldApplyCurrentConfiguration)
        #expect(result.status == .replace("已恢复并设为当前配置。"))
    }

    @MainActor
    @Test("restore copies verified avatar and logo before committing aggregate")
    func restoreCopiesAssetsBeforeAggregateCommit() async throws {
        let backupRootURL = Self.makeTemporaryDirectory()
        let destinationRootURL = Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: backupRootURL)
            try? FileManager.default.removeItem(at: destinationRootURL)
        }
        let avatar = try PortableAssetReference(
            relativePath: "Assets/subjectAvatar/avatar.png"
        )
        let logo = try PortableAssetReference(
            relativePath: "Assets/customLogo/logo.png"
        )
        let avatarData = Data("avatar".utf8)
        let logoData = Data("logo".utf8)
        for (reference, data) in [(avatar, avatarData), (logo, logoData)] {
            let url = backupRootURL.appendingPathComponent(
                reference.relativePath
            )
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        }
        var subject = Self.makeSubject(id: Self.importedSubjectID)
        subject.identity.avatarImagePath = avatar.relativePath
        var configuration = Self.makeConfiguration(
            id: Self.importedConfigurationID
        )
        configuration.presentation.logo = .init(
            mode: .customUpload,
            badge: .init(
                id: UUID(),
                name: "Logo",
                type: .customUpload,
                assetReference: logo
            )
        )
        let document = Self.signedDocument(
            subject: subject,
            configuration: configuration,
            manifest: .init(entries: [
                .init(
                    role: .subjectAvatar,
                    reference: avatar,
                    checksum: Self.assetChecksum(avatarData)
                ),
                .init(
                    role: .customLogo,
                    reference: logo,
                    checksum: Self.assetChecksum(logoData)
                )
            ])
        )
        var didSave = false
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { _ in
                    let restoredAvatarData = try? Data(
                        contentsOf: destinationRootURL
                            .appendingPathComponent(avatar.relativePath)
                    )
                    let restoredLogoData = try? Data(
                        contentsOf: destinationRootURL
                            .appendingPathComponent(logo.relativePath)
                    )
                    #expect(
                        restoredAvatarData == avatarData
                    )
                    #expect(
                        restoredLogoData == logoData
                    )
                    didSave = true
                    return Self.makeSaveReceipt()
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: backupRootURL.appendingPathComponent("backup.memomarkconfig"),
                assetRootURL: backupRootURL,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: [],
                destinationRootURL: destinationRootURL
            )
        )

        #expect(result.succeeded)
        #expect(didSave)
    }

    @MainActor
    @Test("restore copies only canonical subject assets after a historical role change")
    func restoreIgnoresStaleSubjectRoleAssets() async throws {
        let backupRootURL = Self.makeTemporaryDirectory()
        let destinationRootURL = Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: backupRootURL)
            try? FileManager.default.removeItem(at: destinationRootURL)
        }
        let staleReference = try PortableAssetReference(
            relativePath: "Assets/subjectAvatarBadge/old.png"
        )
        let currentReference = try PortableAssetReference(
            relativePath: "Assets/customLogo/current.png"
        )
        let currentData = Data("current-avatar".utf8)
        let currentSourceURL = backupRootURL.appendingPathComponent(
            currentReference.relativePath
        )
        try FileManager.default.createDirectory(
            at: currentSourceURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try currentData.write(to: currentSourceURL)

        var subject = Self.makeSubject(id: Self.importedSubjectID)
        subject.identity.avatarBadgeImagePath =
            currentReference.relativePath
        var configuration = Self.makeConfiguration(
            id: Self.importedConfigurationID
        )
        configuration.presentation.logo = .init(
            mode: .customUpload,
            badge: .init(
                id: UUID(),
                name: "错误复用当前对象头像",
                type: .customUpload,
                assetReference: currentReference
            )
        )
        let document = Self.signedDocument(
            subject: subject,
            configuration: configuration,
            manifest: .init(entries: [
                .init(
                    role: .subjectAvatarBadge,
                    reference: staleReference
                ),
                .init(
                    role: .customLogo,
                    reference: currentReference,
                    checksum: Self.assetChecksum(currentData)
                )
            ])
        )
        var savedAggregate: ConfigurationLibraryRecord?
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { aggregate in
                    savedAggregate = aggregate
                    return Self.makeSaveReceipt(
                        subjectID: Self.importedSubjectID,
                        configurationID: Self.importedConfigurationID
                    )
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: backupRootURL.appendingPathComponent(
                    "legacy.memomarkconfig"
                ),
                assetRootURL: backupRootURL,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: [],
                destinationRootURL: destinationRootURL
            )
        )

        #expect(result.succeeded)
        #expect(
            savedAggregate?.subjects.last?.configurations.last?
                .presentation.logo.mode == .appleMini
        )
        #expect(
            savedAggregate?.subjects.last?.assetManifest.entries
                .map(\.role) == [.subjectAvatarBadge]
        )
        #expect(
            try Data(
                contentsOf: destinationRootURL.appendingPathComponent(
                    currentReference.relativePath
                )
            ) == currentData
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: destinationRootURL.appendingPathComponent(
                    staleReference.relativePath
                ).path
            )
        )
    }

    @MainActor
    @Test("restore commits the safe fallback when a packaged asset is missing")
    func restoreMissingPackagedAssetUsesResolvedDocument() async throws {
        let backupRootURL = Self.makeTemporaryDirectory()
        let destinationRootURL = Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: backupRootURL)
            try? FileManager.default.removeItem(at: destinationRootURL)
        }
        let missingReference = try PortableAssetReference(
            relativePath: "Assets/subjectAvatar/missing.png"
        )
        var subject = Self.makeSubject(id: Self.importedSubjectID)
        subject.identity.avatarImagePath = missingReference.relativePath
        var configuration = Self.makeConfiguration(
            id: Self.importedConfigurationID
        )
        configuration.presentation.logo = .init(
            mode: .subjectAvatar,
            badge: nil
        )
        let document = Self.signedDocument(
            subject: subject,
            configuration: configuration,
            manifest: .init(entries: [
                .init(
                    role: .subjectAvatar,
                    reference: missingReference
                )
            ])
        )
        var savedAggregate: ConfigurationLibraryRecord?
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { aggregate in
                    savedAggregate = aggregate
                    return Self.makeSaveReceipt(
                        subjectID: Self.importedSubjectID,
                        configurationID: Self.importedConfigurationID
                    )
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: backupRootURL.appendingPathComponent(
                    "missing.memomarkconfig"
                ),
                assetRootURL: backupRootURL,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: [],
                destinationRootURL: destinationRootURL
            )
        )

        #expect(result.succeeded)
        #expect(
            result.warnings.contains(
                .missingAsset(
                    role: .subjectAvatar,
                    path: missingReference.relativePath
                )
            )
        )
        #expect(
            savedAggregate?.subjects.last?.subject.identity
                .avatarImagePath == nil
        )
        #expect(
            savedAggregate?.subjects.last?.configurations.last?
                .presentation.logo.mode == .appleMini
        )
        #expect(
            savedAggregate?.subjects.last?.assetManifest.entries.isEmpty
            == true
        )
    }

    @MainActor
    @Test("asset checksum failure never commits the aggregate")
    func assetChecksumFailureNeverCommitsAggregate() async throws {
        let backupRootURL = Self.makeTemporaryDirectory()
        let destinationRootURL = Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: backupRootURL)
            try? FileManager.default.removeItem(at: destinationRootURL)
        }
        let avatar = try PortableAssetReference(
            relativePath: "Assets/subjectAvatar/avatar.png"
        )
        let sourceURL = backupRootURL.appendingPathComponent(
            avatar.relativePath
        )
        try FileManager.default.createDirectory(
            at: sourceURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("tampered".utf8).write(to: sourceURL)
        var subject = Self.makeSubject(id: Self.importedSubjectID)
        subject.identity.avatarImagePath = avatar.relativePath
        let document = Self.signedDocument(
            subject: subject,
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID
            ),
            manifest: .init(entries: [
                .init(
                    role: .subjectAvatar,
                    reference: avatar,
                    checksum: Self.assetChecksum(Data("expected".utf8))
                )
            ])
        )
        var didSave = false
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { _ in
                    didSave = true
                    return Self.makeSaveReceipt()
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: backupRootURL.appendingPathComponent("backup.memomarkconfig"),
                assetRootURL: backupRootURL,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: [],
                destinationRootURL: destinationRootURL
            )
        )

        #expect(!result.succeeded)
        #expect(!didSave)
        #expect(
            !FileManager.default.fileExists(
                atPath: destinationRootURL
                    .appendingPathComponent(avatar.relativePath).path
            )
        )
    }

    @MainActor
    @Test("aggregate save failure removes newly copied restore assets")
    func aggregateSaveFailureRemovesNewlyCopiedAssets() async throws {
        let backupRootURL = Self.makeTemporaryDirectory()
        let destinationRootURL = Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: backupRootURL)
            try? FileManager.default.removeItem(at: destinationRootURL)
        }
        let avatar = try PortableAssetReference(
            relativePath: "Assets/subjectAvatar/avatar.png"
        )
        let avatarData = Data("avatar".utf8)
        let sourceURL = backupRootURL.appendingPathComponent(
            avatar.relativePath
        )
        try FileManager.default.createDirectory(
            at: sourceURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try avatarData.write(to: sourceURL)
        var subject = Self.makeSubject(id: Self.importedSubjectID)
        subject.identity.avatarImagePath = avatar.relativePath
        let document = Self.signedDocument(
            subject: subject,
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID
            ),
            manifest: .init(entries: [
                .init(
                    role: .subjectAvatar,
                    reference: avatar,
                    checksum: Self.assetChecksum(avatarData)
                )
            ])
        )
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { _ in throw TestFailure.expected },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: backupRootURL.appendingPathComponent("backup.memomarkconfig"),
                assetRootURL: backupRootURL,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: [],
                destinationRootURL: destinationRootURL
            )
        )

        #expect(!result.succeeded)
        #expect(
            !FileManager.default.fileExists(
                atPath: destinationRootURL
                    .appendingPathComponent(avatar.relativePath).path
            )
        )
    }

    @MainActor
    @Test("concurrent restores never let a failed rollback delete a successful shared asset")
    func concurrentRestoreRollbackPreservesSuccessfulSharedAsset() async throws {
        let backupRootURL = Self.makeTemporaryDirectory()
        let destinationRootURL = Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: backupRootURL)
            try? FileManager.default.removeItem(at: destinationRootURL)
        }
        let avatar = try PortableAssetReference(
            relativePath: "Assets/subjectAvatar/avatar.png"
        )
        let avatarData = Data("shared-avatar".utf8)
        let sourceURL = backupRootURL.appendingPathComponent(
            avatar.relativePath
        )
        try FileManager.default.createDirectory(
            at: sourceURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try avatarData.write(to: sourceURL)
        var subject = Self.makeSubject(id: Self.importedSubjectID)
        subject.identity.avatarImagePath = avatar.relativePath
        let document = Self.signedDocument(
            subject: subject,
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID
            ),
            manifest: .init(entries: [
                .init(
                    role: .subjectAvatar,
                    reference: avatar,
                    checksum: Self.assetChecksum(avatarData)
                )
            ])
        )
        var saveCallCount = 0
        var firstSaveContinuation:
            CheckedContinuation<ConfigurationLibrarySaveReceipt, Error>?
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { _ in
                    saveCallCount += 1
                    if saveCallCount == 1 {
                        return try await withCheckedThrowingContinuation {
                            firstSaveContinuation = $0
                        }
                    }
                    return Self.makeSaveReceipt()
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )
        let request = ConfigurationRestoreRequest(
            fileURL: backupRootURL.appendingPathComponent("backup.memomarkconfig"),
            assetRootURL: backupRootURL,
            makeCurrent: true,
            aggregate: Self.makeAggregate(),
            availableAlbumIdentifiers: [],
            currentSubjectID: Self.liveSubjectID,
            previousBackups: [],
            destinationRootURL: destinationRootURL
        )

        let firstTask = Task { await coordinator.restore(request) }
        while firstSaveContinuation == nil {
            await Task.yield()
        }
        let secondTask = Task { await coordinator.restore(request) }
        await Task.yield()
        await Task.yield()
        #expect(saveCallCount == 1)
        firstSaveContinuation?.resume(throwing: TestFailure.expected)

        let firstResult = await firstTask.value
        let secondResult = await secondTask.value
        let destinationURL = destinationRootURL.appendingPathComponent(
            avatar.relativePath
        )
        #expect(!firstResult.succeeded)
        #expect(secondResult.succeeded)
        #expect(try Data(contentsOf: destinationURL) == avatarData)
    }

    @MainActor
    @Test("read failure still balances security scope and retains backups")
    func readFailureBalancesScopeAndRetainsBackups() async {
        let previous = [Self.makeBackupRecord()]
        var stopCount = 0
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { _ in Self.makeSaveReceipt() },
                readData: { _ in throw TestFailure.expected },
                startSecurityScopedAccess: { _ in true },
                stopSecurityScopedAccess: { _ in stopCount += 1 }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: URL(fileURLWithPath: "/tmp/missing.memomarkconfig"),
                assetRootURL: nil,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: previous
            )
        )

        #expect(!result.succeeded)
        #expect(result.backups == previous)
        #expect(result.aggregate == nil)
        #expect(result.status == .replace("导入或恢复失败：expected"))
        #expect(stopCount == 1)
    }

    @MainActor
    @Test("backup core success and list refresh success returns receipt")
    func backupCoreSuccessAndRefreshSuccess() async {
        let receipt = Self.makeBackupReceipt()
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in receipt },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.backup(
            .init(
                subject: Self.makeSubject(id: Self.liveSubjectID),
                configuration: Self.makeConfiguration(
                    id: Self.liveConfigurationID,
                    title: "Stable"
                ),
                sourceURLs: [:],
                previousBackups: []
            )
        )

        #expect(result.succeeded)
        #expect(result.backupListRefreshSucceeded)
        #expect(result.receipt == receipt)
        #expect(
            result.status
            == .replace("已保存“Stable”版本 4 到本地配置库。")
        )
    }

    @MainActor
    @Test("backup core failure does not return a receipt")
    func backupCoreFailure() async {
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.backup(
            .init(
                subject: Self.makeSubject(id: Self.liveSubjectID),
                configuration: Self.makeConfiguration(
                    id: Self.liveConfigurationID,
                    title: "Stable"
                ),
                sourceURLs: [:],
                previousBackups: [Self.makeBackupRecord()]
            )
        )

        #expect(!result.succeeded)
        #expect(!result.backupListRefreshSucceeded)
        #expect(result.receipt == nil)
        #expect(result.backups == [Self.makeBackupRecord()])
    }

    @MainActor
    @Test("missing custom-logo asset gives a recoverable backup message")
    func missingCustomLogoBackupMessage() async {
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in
                    throw ConfigurationAssetPackagingError
                        .missingSource(.customLogo)
                },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.backup(
            .init(
                subject: Self.makeSubject(id: Self.liveSubjectID),
                configuration: Self.makeConfiguration(
                    id: Self.liveConfigurationID,
                    title: "Stable"
                ),
                sourceURLs: [:],
                previousBackups: []
            )
        )

        #expect(!result.succeeded)
        #expect(
            result.status
            == .replace("自选标识图片已不存在，请重新选择图片并保存配置后再备份。")
        )
    }

    @MainActor
    @Test("backup core success keeps receipt when list refresh fails")
    func backupCoreSuccessAndRefreshFailure() async {
        let receipt = Self.makeBackupReceipt()
        let previous = [Self.makeBackupRecord()]
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in receipt },
                listBackups: { _ in throw TestFailure.expected },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.backup(
            .init(
                subject: Self.makeSubject(id: Self.liveSubjectID),
                configuration: Self.makeConfiguration(
                    id: Self.liveConfigurationID,
                    title: "Stable"
                ),
                sourceURLs: [:],
                previousBackups: previous
            )
        )

        #expect(result.succeeded)
        #expect(!result.backupListRefreshSucceeded)
        #expect(result.receipt == receipt)
        #expect(result.backups == previous)
        #expect(
            result.status
            == .replace("已完成备份，但本地备份列表刷新失败，请稍后刷新。")
        )
    }

    @MainActor
    @Test("restore success survives backup-list refresh failure")
    func restoreSuccessSurvivesRefreshFailure() async throws {
        let previous = [Self.makeBackupRecord()]
        let document = Self.signedDocument(
            subject: Self.makeSubject(id: Self.importedSubjectID),
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID
            )
        )
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in throw TestFailure.expected },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { _ in
                    Self.makeSaveReceipt(
                        revision: 31,
                        subjectID: Self.importedSubjectID,
                        configurationID: Self.importedConfigurationID
                    )
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: URL(fileURLWithPath: "/tmp/refresh.memomarkconfig"),
                assetRootURL: nil,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: previous
            )
        )

        #expect(result.succeeded)
        #expect(!result.backupListRefreshSucceeded)
        #expect(result.aggregate?.revision == 31)
        #expect(
            result.aggregate?.activeConfigurationID
            == Self.importedConfigurationID
        )
        #expect(result.shouldApplyCurrentConfiguration)
        #expect(result.backups == previous)
        #expect(
            result.status
            == .replace("已恢复并设为当前配置，但本地备份列表刷新失败，请稍后刷新。")
        )
    }

    @MainActor
    @Test("list and delete failures retain the previous backup list")
    func failuresRetainPreviousBackups() async {
        let previous = [Self.makeBackupRecord()]
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in throw TestFailure.expected },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let listResult = await coordinator.listBackups(
            .init(subjectID: Self.liveSubjectID, previousBackups: previous)
        )
        let deleteResult = await coordinator.deleteBackup(
            .init(backup: previous[0], previousBackups: previous)
        )

        #expect(!listResult.succeeded)
        #expect(listResult.backups == previous)
        #expect(
            listResult.status
            == .replace("本地配置库操作失败：expected")
        )
        #expect(!deleteResult.succeeded)
        #expect(deleteResult.backups == previous)
        #expect(
            deleteResult.status
            == .replace("本地配置库操作失败：expected")
        )
    }

    @MainActor
    @Test("asset collection includes only existing absolute managed files")
    func assetCollectionUsesExistingManagedFiles() throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let avatarURL = rootURL.appendingPathComponent("avatar.png")
        let logoURL = rootURL.appendingPathComponent("logo.png")
        try Data("avatar".utf8).write(to: avatarURL)
        try Data("logo".utf8).write(to: logoURL)
        var subject = Self.makeSubject(id: Self.liveSubjectID)
        subject.identity.avatarImagePath = avatarURL.path
        subject.identity.avatarBadgeImagePath = "relative/badge.png"

        var configuration = Self.makeConfiguration(
            id: Self.liveConfigurationID
        )
        configuration.presentation.logo = .init(
            mode: .customUpload,
            badge: nil
        )
        let urls = ConfigurationBackupRestoreCoordinator.assetURLs(
            subject: subject,
            configuration: configuration,
            selectedConfigurationID: Self.liveConfigurationID,
            selectedCustomLogoPath: logoURL.path,
            baseDirectoryURL: rootURL
        )

        #expect(urls == [
            .subjectAvatar: avatarURL,
            .customLogo: logoURL
        ])
    }

    @MainActor
    @Test("asset collection rejects absolute files outside managed storage")
    func assetCollectionRejectsUnmanagedAbsoluteFiles() throws {
        let managedRootURL = Self.makeTemporaryDirectory()
        let outsideRootURL = Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: managedRootURL)
            try? FileManager.default.removeItem(at: outsideRootURL)
        }
        let outsideURL = outsideRootURL.appendingPathComponent("private.txt")
        try Data("private".utf8).write(to: outsideURL)
        var subject = Self.makeSubject(id: Self.liveSubjectID)
        subject.identity.avatarImagePath = outsideURL.path

        let urls = ConfigurationBackupRestoreCoordinator.assetURLs(
            subject: subject,
            configuration: Self.makeConfiguration(
                id: Self.liveConfigurationID
            ),
            selectedConfigurationID: nil,
            selectedCustomLogoPath: nil,
            baseDirectoryURL: managedRootURL
        )

        #expect(urls.isEmpty)
    }

    @MainActor
    @Test("asset collection resolves persisted relative references from the managed container")
    func assetCollectionResolvesPersistedRelativeReferences() throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let relativePath = "Assets/family-logo.png"
        let logoURL = rootURL.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: logoURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("logo".utf8).write(to: logoURL)

        var configuration = Self.makeConfiguration(
            id: Self.liveConfigurationID
        )
        configuration.presentation.logo = .init(
            mode: .customUpload,
            badge: .init(
                id: UUID(),
                name: "家庭标识",
                type: .customUpload,
                assetReference: try PortableAssetReference(
                    relativePath: relativePath
                )
            )
        )

        let urls = ConfigurationBackupRestoreCoordinator.assetURLs(
            subject: Self.makeSubject(id: Self.liveSubjectID),
            configuration: configuration,
            selectedConfigurationID: nil,
            selectedCustomLogoPath: nil,
            baseDirectoryURL: rootURL
        )

        #expect(urls[.customLogo] == logoURL)
    }

    @MainActor
    @Test("subject-avatar backup ignores stale custom-logo state")
    func subjectAvatarBackupDoesNotCollectCustomLogo() throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let avatarURL = rootURL.appendingPathComponent("avatar-badge.png")
        let staleLogoURL = rootURL.appendingPathComponent("stale-logo.png")
        try Data("avatar".utf8).write(to: avatarURL)
        try Data("stale".utf8).write(to: staleLogoURL)
        var subject = Self.makeSubject(id: Self.liveSubjectID)
        subject.identity.avatarBadgeImagePath = avatarURL.path
        var configuration = Self.makeConfiguration(
            id: Self.liveConfigurationID
        )
        configuration.presentation.logo = .init(
            mode: .subjectAvatar,
            badge: .init(
                id: UUID(),
                name: "旧错误头像描述",
                type: .customUpload,
                assetReference: try PortableAssetReference(
                    relativePath: "stale-logo.png"
                )
            )
        )

        let urls = ConfigurationBackupRestoreCoordinator.assetURLs(
            subject: subject,
            configuration: configuration,
            selectedConfigurationID: Self.liveConfigurationID,
            selectedCustomLogoPath: staleLogoURL.path,
            baseDirectoryURL: rootURL
        )

        #expect(urls[.subjectAvatarBadge] == avatarURL)
        #expect(urls[.customLogo] == nil)
    }
}

private extension ConfigurationBackupRestoreCoordinatorTests {

    enum TestFailure: Error, LocalizedError {
        case expected

        var errorDescription: String? { "expected" }
    }

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

    static func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    static func makeAggregate() -> ConfigurationLibraryRecord {
        ConfigurationLibraryRecord(
            revision: 7,
            subjects: [
                .init(
                    subject: makeSubject(id: liveSubjectID),
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

    static func makeSubject(id: UUID) -> MemorySubject {
        MemorySubject(
            id: id,
            identity: .init(displayName: "小宝", shortName: "小宝"),
            relationship: .init(role: "family", label: "成长记录"),
            referenceDate: Date(timeIntervalSince1970: 0),
            timeAnchors: [],
            activeTimeAnchorID: nil,
            behavior: .init(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )
    }

    static func makeConfiguration(
        id: UUID,
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
                memoryCopy: .init(usesCustomText: false, customText: "")
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
        manifest: PortableAssetManifest
    ) -> PortableMemoryConfigurationDocument {
        let unsigned = PortableMemoryConfigurationDocument(
            appVersion: "1.7",
            subject: subject,
            configuration: configuration,
            assetManifest: manifest,
            documentChecksum: ""
        )
        let checksum = "sha256:\(SHA256.hash(data: try! encode(unsigned)).hexString)"
        return PortableMemoryConfigurationDocument(
            appVersion: unsigned.appVersion,
            subject: unsigned.subject,
            configuration: unsigned.configuration,
            assetManifest: unsigned.assetManifest,
            documentChecksum: checksum
        )
    }

    static func signedDocument(
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord
    ) -> PortableMemoryConfigurationDocument {
        signedDocument(
            subject: subject,
            configuration: configuration,
            manifest: .init(entries: [])
        )
    }

    static func encode(
        _ document: PortableMemoryConfigurationDocument
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document)
    }

    static func assetChecksum(_ data: Data) -> String {
        "sha256:\(SHA256.hash(data: data).hexString)"
    }

    static func makeSaveReceipt(
        revision: Int = 8,
        subjectID: UUID = liveSubjectID,
        configurationID: UUID = liveConfigurationID
    ) -> ConfigurationLibrarySaveReceipt {
        ConfigurationLibrarySaveReceipt(
            revision: revision,
            subjectID: subjectID,
            configurationID: configurationID,
            configurationRevision: 4,
            compatibilityProjectionFailure: nil
        )
    }

    static func makeBackupReceipt() -> LocalConfigurationBackupReceipt {
        LocalConfigurationBackupReceipt(
            disposition: .saved,
            subjectID: liveSubjectID,
            configurationID: liveConfigurationID,
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 100),
            checksum: "sha256:test",
            fileURL: URL(fileURLWithPath: "/tmp/stable.memomarkconfig")
        )
    }

    static func makeBackupRecord() -> LocalConfigurationBackupRecord {
        LocalConfigurationBackupRecord(
            subjectID: liveSubjectID,
            configurationID: liveConfigurationID,
            title: "Stable",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 100),
            checksum: "sha256:test",
            fileURL: URL(fileURLWithPath: "/tmp/stable.memomarkconfig")
        )
    }
}

private extension SHA256.Digest {
    nonisolated var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
