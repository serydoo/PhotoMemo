#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterInsertableModulePolicy {

    static func shouldShowModules(
        for region: CardRegion
    ) -> Bool {
        CardRegion.memoryCardRegions.contains(
            region
        )
    }

    static func visibleModules(
        for region: CardRegion
    ) -> [IOSInsertableModule] {
        return [
            .subjectNickname,
            .smartTime,
            .cameraModel,
            .captureSummary,
            .captureDate,
            .captureTime,
            .location,
            .custom
        ]
    }

    static func additionalModules(
        for region: CardRegion
    ) -> [IOSInsertableModule] {
        IOSInsertableModule.allCases
            .filter {
                !visibleModules(
                    for: region
                )
                .contains($0)
            }
    }
}
#endif
