import Foundation

enum PhotoMemoSharedContainer {

    static let appGroupIdentifier =
        "group.com.serydoo.PhotoMemo"

    private static let migrationFlagKey =
        "photomemo.sharedDefaults.didMigrate"

    static var sharedUserDefaults: UserDefaults {

        let sharedDefaults =
            UserDefaults(
            suiteName: appGroupIdentifier
        ) ?? .standard

        migrateLegacyDefaultsIfNeeded(
            into: sharedDefaults
        )

        return sharedDefaults
    }

    static var baseDirectoryURL: URL {

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

    static var externalIntakeDirectoryURL: URL {

        baseDirectoryURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
    }

    @discardableResult
    static func ensureDirectory(
        at url: URL
    ) -> Bool {

        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
            return true
        } catch {
            return false
        }
    }

    static func migrateLegacyDefaultsIfNeeded(
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
