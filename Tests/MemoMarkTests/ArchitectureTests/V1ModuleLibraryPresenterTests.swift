#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("module library presenter")
struct ModuleLibraryPresenterTests {

    @Test("modules returns an empty list for non-memory-card regions")
    func modulesReturnsEmptyForNonMemoryRegions() {
        #expect(
            ModuleLibraryPresenter
                .modules(
                    for: .icon,
                    usageStorage: "{}"
                )
                .isEmpty
        )
    }

    @Test("modules sorts the default catalog using persisted usage counts")
    func modulesSortUsingPersistedUsageCounts() throws {
        let storage =
            try #require(
                String(
                    data: JSONEncoder().encode([
                        IOSInsertableModule
                            .cameraModel
                            .rawValue: 4,
                        IOSInsertableModule
                            .subjectNickname
                            .rawValue: 2
                    ]),
                    encoding: .utf8
                )
            )

        let modules =
            ModuleLibraryPresenter
            .modules(
                for: .slotA,
                usageStorage: storage
            )

        #expect(modules.first == .cameraModel)
        #expect(modules.dropFirst().first == .subjectNickname)
    }

    @Test("recordedUsageStorage increments module usage counts")
    func recordedUsageStorageIncrementsCounts() {
        let encoded =
            ModuleLibraryPresenter
            .recordedUsageStorage(
                for: .smartTime,
                currentStorage: "{}"
            )
        let counts =
            ModuleUsageTracker
            .counts(from: encoded ?? "")

        #expect(
            counts[
                IOSInsertableModule
                    .smartTime
                    .rawValue
            ] == 1
        )
    }

    @Test("sheet presentation helpers preserve the active-region dismissal rule")
    func sheetPresentationHelpersPreserveDismissRule() {
        #expect(
            ModuleLibraryPresenter
                .isSheetPresented(
                    activeRegion: .slotD
                )
        )
        #expect(
            !ModuleLibraryPresenter
                .isSheetPresented(
                    activeRegion: nil
                )
        )
        #expect(
            ModuleLibraryPresenter
                .resolvedActiveRegion(
                    isPresented: false,
                    currentRegion: .slotD
                ) == nil
        )
        #expect(
            ModuleLibraryPresenter
                .resolvedActiveRegion(
                    isPresented: true,
                    currentRegion: .slotD
                ) == .slotD
        )
    }
}
#endif
