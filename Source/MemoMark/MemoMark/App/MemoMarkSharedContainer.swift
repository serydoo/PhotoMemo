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

struct MemoMarkSharedContainerHandoffReadiness:
    Equatable,
    Sendable {

    let appGroupIdentifier: String

    let userDefaultsSuiteAvailable: Bool

    let appGroupContainerAvailable: Bool

    let userDefaultsReadbackVerified: Bool

    let containerReadbackVerified: Bool

    let usesFallbackUserDefaults: Bool

    let usesFallbackBaseDirectory: Bool

    let baseDirectoryURL: URL

    var canAttemptHandoff: Bool {
        userDefaultsSuiteAvailable
        && appGroupContainerAvailable
    }

    var isHandoffReady: Bool {
        canAttemptHandoff
        && userDefaultsReadbackVerified
        && containerReadbackVerified
    }

    var diagnosticMessage: String {
        [
            "appGroup=\(appGroupIdentifier)",
            "canAttemptHandoff=\(canAttemptHandoff)",
            "handoffReady=\(isHandoffReady)",
            "userDefaultsSuiteAvailable=\(userDefaultsSuiteAvailable)",
            "appGroupContainerAvailable=\(appGroupContainerAvailable)",
            "userDefaultsReadbackVerified=\(userDefaultsReadbackVerified)",
            "containerReadbackVerified=\(containerReadbackVerified)",
            "usesFallbackUserDefaults=\(usesFallbackUserDefaults)",
            "usesFallbackBaseDirectory=\(usesFallbackBaseDirectory)",
            "baseDirectory=\(baseDirectoryURL.path)"
        ]
        .joined(separator: ", ")
    }
}

enum MemoMarkSharedContainer {

    nonisolated static let appGroupIdentifier =
        "group.com.serydoo.PhotoMemo"

    nonisolated static let didUseApplePhotosShareKey =
        "photomemo.ui.didUseApplePhotosShare"

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

        if let containerURL =
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier:
                    appGroupIdentifier
            ) {
            return containerURL
        }

        return fallbackBaseDirectoryURL()
    }

    nonisolated static func handoffReadiness(
        userDefaultsProvider:
            (String) -> UserDefaults? = {
                UserDefaults(
                    suiteName: $0
                )
            },
        containerURLProvider:
            (String) -> URL? = {
                FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier:
                        $0
                )
            },
        userDefaultsProbe:
            ((UserDefaults) -> Bool)? = nil,
        containerProbe:
            ((URL) -> Bool)? = nil,
        fallbackBaseDirectoryURLProvider:
            () -> URL = {
                fallbackBaseDirectoryURL()
            }
    ) -> MemoMarkSharedContainerHandoffReadiness {

        let sharedDefaults =
            userDefaultsProvider(
                appGroupIdentifier
            )
        let appGroupContainerURL =
            containerURLProvider(
                appGroupIdentifier
            )
        let fallbackURL =
            fallbackBaseDirectoryURLProvider()

        let userDefaultsReadbackVerified =
            sharedDefaults.map {
                (userDefaultsProbe ?? probeUserDefaults)($0)
            } ?? false
        let containerReadbackVerified =
            appGroupContainerURL.map {
                (containerProbe ?? probeContainer)($0)
            } ?? false

        return MemoMarkSharedContainerHandoffReadiness(
            appGroupIdentifier:
                appGroupIdentifier,
            userDefaultsSuiteAvailable:
                sharedDefaults != nil,
            appGroupContainerAvailable:
                appGroupContainerURL != nil,
            userDefaultsReadbackVerified:
                userDefaultsReadbackVerified,
            containerReadbackVerified:
                containerReadbackVerified,
            usesFallbackUserDefaults:
                sharedDefaults == nil,
            usesFallbackBaseDirectory:
                appGroupContainerURL == nil,
            baseDirectoryURL:
                appGroupContainerURL
                ?? fallbackURL
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

    nonisolated private static func probeUserDefaults(
        _ defaults: UserDefaults
    ) -> Bool {
        let key =
            "photomemo.sharedContainer.probe.\(UUID().uuidString)"
        let value = Data(UUID().uuidString.utf8)
        defaults.set(value, forKey: key)
        _ = defaults.synchronize()
        let verified = defaults.data(forKey: key) == value
        defaults.removeObject(forKey: key)
        _ = defaults.synchronize()
        return verified
    }

    nonisolated private static func probeContainer(
        _ containerURL: URL
    ) -> Bool {
        let fileManager = FileManager.default
        let probeURL = containerURL
            .appendingPathComponent(
                ".photomemo-handoff-probe-\(UUID().uuidString)",
                isDirectory: false
            )
        let value = Data(UUID().uuidString.utf8)

        do {
            try fileManager.createDirectory(
                at: containerURL,
                withIntermediateDirectories: true
            )
            try value.write(
                to: probeURL,
                options: .atomic
            )
            guard try Data(contentsOf: probeURL) == value else {
                try? fileManager.removeItem(at: probeURL)
                return false
            }
            try fileManager.removeItem(at: probeURL)
            return true
        } catch {
            try? fileManager.removeItem(at: probeURL)
            return false
        }
    }

    nonisolated private static func fallbackBaseDirectoryURL() -> URL {

        let fileManager =
            FileManager.default
        let applicationSupportURL =
            fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
            ?? fileManager.temporaryDirectory

        return applicationSupportURL
            .appendingPathComponent(
                "MemoMark",
                isDirectory: true
            )
    }
}
