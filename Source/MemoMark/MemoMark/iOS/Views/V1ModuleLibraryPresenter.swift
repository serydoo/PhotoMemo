#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum ModuleLibraryPresenter {

    static let defaultModules:
        [IOSInsertableModule] = [
            .subjectNickname,
            .smartTime,
            .captureSummary,
            .captureDate,
            .captureTime,
            .cameraModel,
            .location,
            .imageSize
        ]

    static func modules(
        for region: CardRegion,
        usageStorage: String
    ) -> [IOSInsertableModule] {
        guard CardRegion.memoryCardRegions.contains(region) else {
            return []
        }

        return ModuleUsageTracker
            .sortedModules(
                defaults: defaultModules,
                storage: usageStorage
            )
    }

    static func categoryTitle(
        for module: IOSInsertableModule
    ) -> String {
        ModuleUsageTracker
            .categoryTitle(for: module)
    }

    static func recordedUsageStorage(
        for module: IOSInsertableModule,
        currentStorage: String
    ) -> String? {
        ModuleUsageTracker
            .recordedStorage(
                for: module,
                storage: currentStorage
            )
    }

    static func isSheetPresented(
        activeRegion: CardRegion?
    ) -> Bool {
        activeRegion != nil
    }

    static func resolvedActiveRegion(
        isPresented: Bool,
        currentRegion: CardRegion?
    ) -> CardRegion? {
        isPresented ? currentRegion : nil
    }
}
#endif
