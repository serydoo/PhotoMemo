import Foundation

enum SharedContainerError:
    LocalizedError {

    case createDirectoryFailed(
        URL,
        underlying: Error
    )

    var errorDescription: String? {
        switch self {
        case .createDirectoryFailed(let url, let error):
            return "无法创建共享目录：\(url.path)。\(String(describing: error))"
        }
    }
}

enum PhotoMemoSharedContainer {

    nonisolated static let appGroupIdentifier =
        "group.com.serydoo.PhotoMemo"

    nonisolated private static let migrationFlagKey =
        "photomemo.sharedDefaults.didMigrate"

    nonisolated static var sharedUserDefaults: UserDefaults {

        let sharedDefaults =
            UserDefaults(
            suiteName: appGroupIdentifier
        ) ?? .standard

        migrateLegacyDefaultsIfNeeded(
            into: sharedDefaults
        )

        return sharedDefaults
    }

    nonisolated static var baseDirectoryURL: URL {

        let fileManager =
            FileManager.default

        if let containerURL =
            fileManager.containerURL(
                forSecurityApplicationGroupIdentifier:
                    appGroupIdentifier
            ) {
            return containerURL
        }

        let applicationSupportURL =
            fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
            ?? fileManager.temporaryDirectory

        return applicationSupportURL
            .appendingPathComponent(
                "PhotoMemo",
                isDirectory: true
            )
    }

    nonisolated static var externalIntakeDirectoryURL: URL {

        baseDirectoryURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
    }

    nonisolated static func ensureDirectory(
        at url: URL
    ) throws {

        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        } catch {
            throw SharedContainerError
                .createDirectoryFailed(
                    url,
                    underlying: error
                )
        }
    }

    nonisolated static func migrateLegacyDefaultsIfNeeded(
        into sharedDefaults: UserDefaults
    ) {

        guard sharedDefaults != .standard else {
            return
        }

        guard !sharedDefaults.bool(
            forKey: migrationFlagKey
        ) else {
            return
        }

        let standardDefaults =
            UserDefaults.standard

        for (key, value) in
            standardDefaults.dictionaryRepresentation() {

            guard sharedDefaults.object(
                forKey: key
            ) == nil else {
                continue
            }

            sharedDefaults.set(
                value,
                forKey: key
            )
        }

        sharedDefaults.set(
            true,
            forKey: migrationFlagKey
        )
    }
}
