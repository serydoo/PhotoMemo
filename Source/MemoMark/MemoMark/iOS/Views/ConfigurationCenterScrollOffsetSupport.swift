#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

enum ConfigurationCenterScrollOffsetKind: Hashable {

    case profile
    case preview
}

struct ConfigurationCenterScrollOffsetPreferenceKey: PreferenceKey {

    static var defaultValue:
        [ConfigurationCenterScrollOffsetKind: CGFloat] = [:]

    static func reduce(
        value: inout [ConfigurationCenterScrollOffsetKind: CGFloat],
        nextValue: () -> [ConfigurationCenterScrollOffsetKind: CGFloat]
    ) {
        value.merge(
            nextValue(),
            uniquingKeysWith: { $1 }
        )
    }
}
#endif
