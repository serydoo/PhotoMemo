#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("module usage tracking")
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
            ModuleUsageTracker
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
            ModuleUsageTracker
            .recordedStorage(
                for: .smartTime,
                storage: "{broken"
            )
        let firstCounts =
            ModuleUsageTracker
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
            ModuleUsageTracker
            .recordedStorage(
                for: .smartTime,
                storage: firstEncoded ?? ""
            )
        let secondCounts =
            ModuleUsageTracker
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

    @Test("categoryTitle distinguishes smart expression from EXIF labeling")
    func categoryTitlePreservesCurrentLabeling() {

        #expect(
            ModuleUsageTracker
            .categoryTitle(
                for: .captureSummary
            ) == "智能表达"
        )
        #expect(
            ModuleUsageTracker
            .categoryTitle(
                for: .cameraModel
            ) == "EXIF"
        )
    }
}
#endif
