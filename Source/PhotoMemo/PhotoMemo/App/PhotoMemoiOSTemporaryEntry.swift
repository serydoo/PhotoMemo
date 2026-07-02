import Foundation

enum PhotoMemoiOSTemporaryEntry:
    String,
    CaseIterable,
    Hashable {

    case configurationCenter
    case v1Preview

    static func resolve(
        storedValue: String?,
        defaultEntry: Self
    ) -> Self {

        guard
            let storedValue,
            let resolvedEntry = Self(
                rawValue: storedValue
            )
        else {
            return defaultEntry
        }

        return resolvedEntry
    }

    var displayTitle: String {

        switch self {
        case .configurationCenter:
            return "当前配置中心"
        case .v1Preview:
            return "V1.0 预览"
        }
    }
}

struct PhotoMemoiOSTemporaryEntryConfiguration:
    Hashable {

    let storageKey: String

    let defaultEntry:
        PhotoMemoiOSTemporaryEntry

    static let standard =
        PhotoMemoiOSTemporaryEntryConfiguration(
            storageKey:
                "photomemo.ios.temporaryEntry",
            defaultEntry:
                .configurationCenter
        )

    static let v1 =
        PhotoMemoiOSTemporaryEntryConfiguration(
            storageKey:
                "photomemo.ios.v1.temporaryEntry",
            defaultEntry:
                .v1Preview
        )
}
