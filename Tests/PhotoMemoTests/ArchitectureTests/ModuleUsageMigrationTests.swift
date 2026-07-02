#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 module usage migration")
struct ModuleUsageMigrationTests {

    @Test("sortedModules prioritizes higher-usage modules and preserves default order for ties")
    func sortedModulesPrioritizesUsageAndPreservesDefaultOrderForTies() throws {

        let defaults: [IOSInsertableModule] = [
            .subjectNickname,
            .smartTime,
            .captureSummary,
            .captureDate
        ]
        let storage =
            try #require(
                String(
                    data: JSONEncoder().encode([
                        IOSInsertableModule.captureDate.rawValue: 3,
                        IOSInsertableModule.subjectNickname.rawValue: 1
                    ]),
                    encoding: .utf8
                )
            )

        let sorted =
            V1ModuleUsageTracker
            .sortedModules(
                defaults: defaults,
                storage: storage
            )

        #expect(
            sorted == [
                .captureDate,
                .subjectNickname,
                .smartTime,
                .captureSummary
            ]
        )
    }

    @Test("recordedStorage increments usage and ignores corrupted storage by starting fresh")
    func recordedStorageIncrementsUsageAndIgnoresCorruptedStorage() {

        let firstEncoded =
            V1ModuleUsageTracker
            .recordedStorage(
                for: .smartTime,
                storage: "{broken"
            )
        let firstCounts =
            V1ModuleUsageTracker
            .counts(
                from: firstEncoded ?? ""
            )

        #expect(
            firstCounts[
                IOSInsertableModule
                .smartTime
                .rawValue
            ] == 1
        )

        let secondEncoded =
            V1ModuleUsageTracker
            .recordedStorage(
                for: .smartTime,
                storage: firstEncoded ?? ""
            )
        let secondCounts =
            V1ModuleUsageTracker
            .counts(
                from: secondEncoded ?? ""
            )

        #expect(
            secondCounts[
                IOSInsertableModule
                .smartTime
                .rawValue
            ] == 2
        )
    }

    @Test("categoryTitle preserves current PhotoMemo versus EXIF labeling")
    func categoryTitlePreservesCurrentLabeling() {

        #expect(
            V1ModuleUsageTracker
            .categoryTitle(
                for: .captureSummary
            ) == "PhotoMemo"
        )
        #expect(
            V1ModuleUsageTracker
            .categoryTitle(
                for: .cameraModel
            ) == "EXIF"
        )
    }
}
#endif
