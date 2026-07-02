#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1ModuleLibraryPresenter {

    static let defaultModules:
        [IOSInsertableModule] = [
            .subjectNickname,
            .smartTime,
            .captureSummary,
            .captureDate,
            .captureTime,
            .cameraModel,
            .location,
            .imageSize,
            .fileFormat
        ]

    static func modules(
        for region: CardRegion,
        usageStorage: String
    ) -> [IOSInsertableModule] {
        guard CardRegion.memoryCardRegions.contains(region) else {
            return []
        }

        return V1ModuleUsageTracker
            .sortedModules(
                defaults: defaultModules,
                storage: usageStorage
            )
    }

    static func categoryTitle(
        for module: IOSInsertableModule
    ) -> String {
        V1ModuleUsageTracker
            .categoryTitle(for: module)
    }

    static func recordedUsageStorage(
        for module: IOSInsertableModule,
        currentStorage: String
    ) -> String? {
        V1ModuleUsageTracker
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
