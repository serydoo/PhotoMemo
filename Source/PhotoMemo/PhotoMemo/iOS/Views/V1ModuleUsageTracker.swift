#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1ModuleUsageTracker {

    static func sortedModules(
        defaults: [IOSInsertableModule],
        storage: String
    ) -> [IOSInsertableModule] {

        let usageCounts =
            counts(
                from: storage
            )

        return defaults.sorted { left, right in
            let leftCount =
                usageCounts[left.rawValue] ?? 0
            let rightCount =
                usageCounts[right.rawValue] ?? 0

            if leftCount != rightCount {
                return leftCount > rightCount
            }

            let leftIndex =
                defaults.firstIndex(of: left) ?? 0
            let rightIndex =
                defaults.firstIndex(of: right) ?? 0

            return leftIndex < rightIndex
        }
    }

    static func recordedStorage(
        for module: IOSInsertableModule,
        storage: String
    ) -> String? {

        var usageCounts =
            counts(
                from: storage
            )
        usageCounts[module.rawValue, default: 0] += 1

        guard
            let data =
                try? JSONEncoder().encode(
                    usageCounts
                ),
            let encoded =
                String(
                    data: data,
                    encoding: .utf8
                )
        else {
            return nil
        }

        return encoded
    }

    static func categoryTitle(
        for module: IOSInsertableModule
    ) -> String {

        switch module {
        case .subjectNickname,
             .smartTime,
             .captureSummary:
            return "PhotoMemo"
        default:
            return "EXIF"
        }
    }

    static func counts(
        from storage: String
    ) -> [String: Int] {

        guard
            let data =
                storage.data(
                    using: .utf8
                ),
            let decoded =
                try? JSONDecoder().decode(
                    [String: Int].self,
                    from: data
                )
        else {
            return [:]
        }

        return decoded
    }
}
#endif
