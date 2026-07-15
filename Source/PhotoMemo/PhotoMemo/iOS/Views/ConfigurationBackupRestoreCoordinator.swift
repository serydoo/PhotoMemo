#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationBackupRestoreStatusUpdate: Equatable {
    case unchanged
    case replace(String)
}

struct ConfigurationBackupRequest {
    let subject: MemorySubject
    let configuration: MemoryConfigurationRecord
    let sourceURLs: [PortableAssetManifest.Role: URL]
    let previousBackups: [LocalConfigurationBackupRecord]
}

struct ConfigurationBackupResult {
    let succeeded: Bool
    let receipt: LocalConfigurationBackupReceipt?
    let backups: [LocalConfigurationBackupRecord]
    let status: ConfigurationBackupRestoreStatusUpdate
    let backupListRefreshSucceeded: Bool
}

struct ConfigurationBackupListRequest {
    let subjectID: UUID
    let previousBackups: [LocalConfigurationBackupRecord]
}

struct ConfigurationBackupListResult {
    let succeeded: Bool
    let backups: [LocalConfigurationBackupRecord]
    let status: ConfigurationBackupRestoreStatusUpdate
}

struct ConfigurationBackupDeletionRequest {
    let backup: LocalConfigurationBackupRecord
    let previousBackups: [LocalConfigurationBackupRecord]
}

struct ConfigurationBackupDeletionResult {
    let succeeded: Bool
    let receipt: LocalConfigurationBackupDeletionReceipt?
    let backups: [LocalConfigurationBackupRecord]
    let status: ConfigurationBackupRestoreStatusUpdate
}

struct ConfigurationRestoreRequest {
    let fileURL: URL
    let assetRootURL: URL?
    let makeCurrent: Bool
    let aggregate: ConfigurationLibraryRecord
    let availableAlbumIdentifiers: Set<String>
    let currentSubjectID: UUID?
    let previousBackups: [LocalConfigurationBackupRecord]
}

struct ConfigurationRestoreResult {
    let succeeded: Bool
    let aggregate: ConfigurationLibraryRecord?
    let restoreReceipt: ConfigurationImportRestoreReceipt?
    let saveReceipt: ConfigurationLibrarySaveReceipt?
    let warnings: [ConfigurationImportWarning]
    let backups: [LocalConfigurationBackupRecord]
    let status: ConfigurationBackupRestoreStatusUpdate
    let shouldApplyCurrentConfiguration: Bool
    let backupListRefreshSucceeded: Bool
}

@MainActor
struct ConfigurationBackupRestoreDependencies {
    let backup: (
        MemorySubject,
        MemoryConfigurationRecord,
        [PortableAssetManifest.Role: URL]
    ) async throws -> LocalConfigurationBackupReceipt
    let listBackups:
        (UUID) async throws -> [LocalConfigurationBackupRecord]
    let deleteBackup:
        (UUID, UUID) async throws -> LocalConfigurationBackupDeletionReceipt
    let saveAggregate:
        ((ConfigurationLibraryRecord) async throws ->
            ConfigurationLibrarySaveReceipt)?
    let readData: (URL) throws -> Data
    let startSecurityScopedAccess: (URL) -> Bool
    let stopSecurityScopedAccess: (URL) -> Void
}

@MainActor
final class ConfigurationBackupRestoreCoordinator {

    private let dependencies: ConfigurationBackupRestoreDependencies

    init(dependencies: ConfigurationBackupRestoreDependencies) {
        self.dependencies = dependencies
    }

    init(
        localConfigurationLibraryCoordinator:
            LocalConfigurationLibraryCoordinator,
        configurationCoordinator: ConfigurationCoordinator?
    ) {
        self.dependencies = ConfigurationBackupRestoreDependencies(
            backup: { subject, configuration, sourceURLs in
                try await localConfigurationLibraryCoordinator.backup(
                    subject: subject,
                    configuration: configuration,
                    sourceURLs: sourceURLs
                )
            },
            listBackups: { subjectID in
                try await localConfigurationLibraryCoordinator.listBackups(
                    subjectID: subjectID
                )
            },
            deleteBackup: { subjectID, configurationID in
                try await localConfigurationLibraryCoordinator.deleteBackup(
                    subjectID: subjectID,
                    configurationID: configurationID
                )
            },
            saveAggregate: configurationCoordinator.map { coordinator in
                { aggregate in
                    try await coordinator.saveConfigurationLibrary(aggregate)
                }
            },
            readData: { try Data(contentsOf: $0) },
            startSecurityScopedAccess: {
                $0.startAccessingSecurityScopedResource()
            },
            stopSecurityScopedAccess: {
                $0.stopAccessingSecurityScopedResource()
            }
        )
    }

    func backup(
        _ request: ConfigurationBackupRequest
    ) async -> ConfigurationBackupResult {
        do {
            let receipt = try await dependencies.backup(
                request.subject,
                request.configuration,
                request.sourceURLs
            )
            do {
                let backups = try await dependencies.listBackups(
                    request.subject.id
                )
                return ConfigurationBackupResult(
                    succeeded: true,
                    receipt: receipt,
                    backups: backups,
                    status: .replace(
                        V1LocalConfigurationLibraryPresenter.backupFeedback(
                            title: request.configuration.title,
                            receipt: receipt
                        )
                    ),
                    backupListRefreshSucceeded: true
                )
            } catch {
                return ConfigurationBackupResult(
                    succeeded: true,
                    receipt: receipt,
                    backups: request.previousBackups,
                    status: .replace(
                        "已完成备份，但本地备份列表刷新失败，请稍后刷新。"
                    ),
                    backupListRefreshSucceeded: false
                )
            }
        } catch {
            return ConfigurationBackupResult(
                succeeded: false,
                receipt: nil,
                backups: request.previousBackups,
                status: .replace(
                    Self.localLibraryErrorMessage(error)
                ),
                backupListRefreshSucceeded: false
            )
        }
    }

    func listBackups(
        _ request: ConfigurationBackupListRequest
    ) async -> ConfigurationBackupListResult {
        do {
            let backups = try await dependencies.listBackups(
                request.subjectID
            )
            return ConfigurationBackupListResult(
                succeeded: true,
                backups: backups,
                status: backups.isEmpty
                    ? .replace("当前记忆对象还没有本地备份。")
                    : .unchanged
            )
        } catch {
            return ConfigurationBackupListResult(
                succeeded: false,
                backups: request.previousBackups,
                status: .replace(
                    Self.localLibraryErrorMessage(error)
                )
            )
        }
    }

    func deleteBackup(
        _ request: ConfigurationBackupDeletionRequest
    ) async -> ConfigurationBackupDeletionResult {
        do {
            let receipt = try await dependencies.deleteBackup(
                request.backup.subjectID,
                request.backup.configurationID
            )
            return ConfigurationBackupDeletionResult(
                succeeded: true,
                receipt: receipt,
                backups: request.previousBackups.filter {
                    $0.configurationID
                    != request.backup.configurationID
                },
                status: .replace(
                    "已删除“\(request.backup.title)”的本地备份，不影响当前配置。"
                )
            )
        } catch {
            return ConfigurationBackupDeletionResult(
                succeeded: false,
                receipt: nil,
                backups: request.previousBackups,
                status: .replace(
                    Self.localLibraryErrorMessage(error)
                )
            )
        }
    }

    func restore(
        _ request: ConfigurationRestoreRequest
    ) async -> ConfigurationRestoreResult {
        guard let saveAggregate = dependencies.saveAggregate else {
            return ConfigurationRestoreResult(
                succeeded: false,
                aggregate: nil,
                restoreReceipt: nil,
                saveReceipt: nil,
                warnings: [],
                backups: request.previousBackups,
                status: .replace("当前配置库不可用，无法恢复。"),
                shouldApplyCurrentConfiguration: false,
                backupListRefreshSucceeded: false
            )
        }

        let didAccessSecurityScopedResource =
            dependencies.startSecurityScopedAccess(request.fileURL)
        defer {
            if didAccessSecurityScopedResource {
                dependencies.stopSecurityScopedAccess(request.fileURL)
            }
        }

        do {
            let data = try dependencies.readData(request.fileURL)
            let importCoordinator = ConfigurationImportCoordinator(
                applyAggregate: saveAggregate
            )
            let resolution = try importCoordinator.resolveImport(
                data: data,
                assetRootURL: request.assetRootURL,
                availableAlbumIdentifiers:
                    request.availableAlbumIdentifiers
            )

            let restoreReceipt: ConfigurationImportRestoreReceipt
            let saveReceipt: ConfigurationLibrarySaveReceipt
            if request.makeCurrent {
                let applyReceipt = try await importCoordinator
                    .restoreAndMakeCurrent(
                        resolution,
                        into: request.aggregate
                    )
                restoreReceipt = applyReceipt.restoreReceipt
                saveReceipt = applyReceipt.saveReceipt
            } else {
                restoreReceipt = importCoordinator.restore(
                    resolution,
                    into: request.aggregate
                )
                saveReceipt = try await saveAggregate(
                    restoreReceipt.aggregate
                )
            }

            var durableAggregate = restoreReceipt.aggregate
            durableAggregate.revision = saveReceipt.revision
            let warnings = restoreReceipt.warnings
            let successStatus = Self.importSuccessStatus(
                makeCurrent: request.makeCurrent,
                warnings: warnings
            )
            let refreshSubjectID = request.makeCurrent
                ? restoreReceipt.restoredSubjectID
                : request.currentSubjectID

            guard let refreshSubjectID else {
                return ConfigurationRestoreResult(
                    succeeded: true,
                    aggregate: durableAggregate,
                    restoreReceipt: restoreReceipt,
                    saveReceipt: saveReceipt,
                    warnings: warnings,
                    backups: request.previousBackups,
                    status: .replace(successStatus),
                    shouldApplyCurrentConfiguration: request.makeCurrent,
                    backupListRefreshSucceeded: true
                )
            }

            do {
                let backups = try await dependencies.listBackups(
                    refreshSubjectID
                )
                return ConfigurationRestoreResult(
                    succeeded: true,
                    aggregate: durableAggregate,
                    restoreReceipt: restoreReceipt,
                    saveReceipt: saveReceipt,
                    warnings: warnings,
                    backups: backups,
                    status: .replace(successStatus),
                    shouldApplyCurrentConfiguration: request.makeCurrent,
                    backupListRefreshSucceeded: true
                )
            } catch {
                return ConfigurationRestoreResult(
                    succeeded: true,
                    aggregate: durableAggregate,
                    restoreReceipt: restoreReceipt,
                    saveReceipt: saveReceipt,
                    warnings: warnings,
                    backups: request.previousBackups,
                    status: .replace(
                        request.makeCurrent
                            ? "已恢复并设为当前配置，但本地备份列表刷新失败，请稍后刷新。"
                            : "已恢复配置副本，但本地备份列表刷新失败，请稍后刷新。"
                    ),
                    shouldApplyCurrentConfiguration: request.makeCurrent,
                    backupListRefreshSucceeded: false
                )
            }
        } catch {
            return ConfigurationRestoreResult(
                succeeded: false,
                aggregate: nil,
                restoreReceipt: nil,
                saveReceipt: nil,
                warnings: [],
                backups: request.previousBackups,
                status: .replace(Self.importErrorMessage(error)),
                shouldApplyCurrentConfiguration: false,
                backupListRefreshSucceeded: false
            )
        }
    }

    static func assetURLs(
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord,
        selectedConfigurationID: UUID?,
        selectedCustomLogoPath: String?,
        fileManager: FileManager = .default
    ) -> [PortableAssetManifest.Role: URL] {
        var urls: [PortableAssetManifest.Role: URL] = [:]
        appendAssetURL(
            subject.identity.avatarImagePath,
            role: .subjectAvatar,
            to: &urls,
            fileManager: fileManager
        )
        appendAssetURL(
            subject.identity.avatarBadgeImagePath,
            role: .subjectAvatarBadge,
            to: &urls,
            fileManager: fileManager
        )
        appendAssetURL(
            subject.identity.avatarPreviewImagePath,
            role: .subjectAvatarPreview,
            to: &urls,
            fileManager: fileManager
        )
        let customLogoPath =
            configuration.presentation.logo.badge?
            .assetReference?.relativePath
            ?? (configuration.id == selectedConfigurationID
                ? selectedCustomLogoPath
                : nil)
        appendAssetURL(
            customLogoPath,
            role: .customLogo,
            to: &urls,
            fileManager: fileManager
        )
        return urls
    }
}

private extension ConfigurationBackupRestoreCoordinator {

    static func appendAssetURL(
        _ path: String?,
        role: PortableAssetManifest.Role,
        to urls: inout [PortableAssetManifest.Role: URL],
        fileManager: FileManager
    ) {
        guard let path, path.hasPrefix("/") else {
            return
        }
        let url = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        urls[role] = url
    }

    static func importSuccessStatus(
        makeCurrent: Bool,
        warnings: [ConfigurationImportWarning]
    ) -> String {
        let prefix = makeCurrent
            ? "已恢复并设为当前配置。"
            : "已恢复配置副本。"
        guard !warnings.isEmpty else {
            return prefix
        }
        return "\(prefix) 部分缺失资源已使用安全回退。"
    }

    static func localLibraryErrorMessage(_ error: Error) -> String {
        guard let error = error as? LocalConfigurationLibraryError else {
            return "本地配置库操作失败：\(error.localizedDescription)"
        }
        switch error {
        case .backupNotFound:
            return "找不到这份本地备份，可能已被移动或删除。"
        case .checksumMismatch:
            return "备份校验失败，文件可能已损坏。"
        case .invalidDocument:
            return "配置包含无法备份的资源引用，请先重新保存当前配置。"
        case .encodingFailed,
             .readFailed,
             .writeFailed,
             .deleteFailed,
             .pathIdentityMismatch:
            return "本地配置库操作失败，请稍后重试。"
        }
    }

    static func importErrorMessage(_ error: Error) -> String {
        guard let error = error as? ConfigurationImportError else {
            return "导入或恢复失败：\(error.localizedDescription)"
        }
        switch error {
        case .unsupportedOlderSchema:
            return "这份备份版本过旧，当前版本无法读取。"
        case .unsupportedFutureSchema:
            return "这份备份来自更新版本，请升级时光记后再导入。"
        case .corruptDocument,
             .checksumMismatch:
            return "备份文件已损坏或校验失败。"
        case .invalidDocument:
            return "备份内容不完整，无法安全恢复。"
        case .aggregateApplyUnavailable:
            return "当前配置库不可用，无法设为当前配置。"
        }
    }
}
#endif
