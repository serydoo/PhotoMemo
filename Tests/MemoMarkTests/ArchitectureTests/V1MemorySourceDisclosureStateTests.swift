#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("memory source disclosure state")
struct MemorySourceDisclosureStateTests {

    @Test("manual collapse remains while the subject is unchanged")
    func manualCollapseRemainsForSameSubject() {
        let subjectID = UUID()
        var state = MemorySourceDisclosureState(
            selectedSubjectID: subjectID
        )

        state.setExpanded(false)
        state.synchronize(selectedSubjectID: subjectID)

        #expect(state.isExpanded == false)
    }

    @Test("switching subjects forces memory source expansion")
    func switchingSubjectsForcesExpansion() {
        let firstSubjectID = UUID()
        let secondSubjectID = UUID()
        var state = MemorySourceDisclosureState(
            selectedSubjectID: firstSubjectID,
            isExpanded: false
        )

        state.synchronize(selectedSubjectID: secondSubjectID)

        #expect(state.selectedSubjectID == secondSubjectID)
        #expect(state.isExpanded)
    }

    @Test("manual expansion changes presentation state only")
    func manualExpansionChangesPresentationStateOnly() {
        let subjectID = UUID()
        var state = MemorySourceDisclosureState(
            selectedSubjectID: subjectID,
            isExpanded: false
        )

        state.setExpanded(true)

        #expect(state.selectedSubjectID == subjectID)
        #expect(state.isExpanded)
    }
}

@Suite("memory expression disclosure state")
struct MemoryExpressionDisclosureStateTests {

    @Test("memory expression details start expanded")
    func memoryExpressionDetailsStartExpanded() {
        let state = MemoryExpressionDisclosureState()

        #expect(state.isExpanded)
    }

    @Test("manual disclosure changes presentation state only")
    func manualDisclosureChangesPresentationStateOnly() {
        var state = MemoryExpressionDisclosureState()

        state.setExpanded(true)
        #expect(state.isExpanded)

        state.setExpanded(false)
        #expect(state.isExpanded == false)
    }
}

@Suite("configuration disclosure preferences")
struct ConfigurationDisclosureStateTests {

    @Test("all configuration sections start expanded for a new defaults domain")
    func newConfigurationStartsExpanded() {
        let defaults = UserDefaults(
            suiteName: "ConfigurationDisclosureStateTests.new"
        )!
        defaults.removePersistentDomain(
            forName: "ConfigurationDisclosureStateTests.new"
        )

        let state = ConfigurationDisclosureState(defaults: defaults)

        #expect(state.memorySourceDisclosureState.isExpanded)
        #expect(state.memoryExpressionDisclosureState.isExpanded)
        #expect(state.presentationStyleIsExpanded)
        #expect(state.cardLayoutIsExpanded)
        #expect(state.photoDescriptionIsExpanded)
        #expect(state.outputDestinationIsExpanded)
    }

    @Test("manual section changes persist without touching configuration data")
    func manualSectionChangesPersist() {
        let suiteName = "ConfigurationDisclosureStateTests.persist"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var state = ConfigurationDisclosureState(defaults: defaults)
        for section in ConfigurationDisclosureState.Section.allCases {
            state.setExpanded(
                false,
                for: section,
                defaults: defaults
            )
        }

        let restored = ConfigurationDisclosureState(defaults: defaults)

        for section in ConfigurationDisclosureState.Section.allCases {
            #expect(!restored.isExpanded(for: section))
        }
    }

    @Test("changing the selected subject reopens memory source")
    func changingSubjectReopensMemorySource() {
        let suiteName = "ConfigurationDisclosureStateTests.subject"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var state = ConfigurationDisclosureState(defaults: defaults)
        state.synchronizeSelectedSubject(
            selectedSubjectID: UUID(),
            defaults: defaults
        )
        state.setExpanded(
            false,
            for: .memorySource,
            defaults: defaults
        )
        state.synchronizeSelectedSubject(
            selectedSubjectID: UUID(),
            defaults: defaults
        )

        #expect(state.memorySourceDisclosureState.isExpanded)
        #expect(
            defaults.bool(
                forKey:
                    ConfigurationDisclosureState.StorageKey
                    .memorySource
            )
        )
    }

    @Test("initial subject adoption preserves the saved disclosure preference")
    func initialSubjectAdoptionPreservesSavedPreference() {
        let suiteName = "V1ConfigurationDisclosureStateTests.bootstrap"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(
            false,
            forKey:
                ConfigurationDisclosureState.StorageKey.memorySource
        )

        var state = ConfigurationDisclosureState(defaults: defaults)
        state.synchronizeSelectedSubject(
            selectedSubjectID: UUID(),
            defaults: defaults
        )

        #expect(!state.memorySourceDisclosureState.isExpanded)
        #expect(
            !defaults.bool(
                forKey:
                    ConfigurationDisclosureState.StorageKey.memorySource
            )
        )
    }

    @Test("clearing then selecting a subject leaves memory source expanded")
    func clearingThenSelectingSubjectKeepsSourceExpanded() {
        let suiteName = "V1ConfigurationDisclosureStateTests.clear"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var state = ConfigurationDisclosureState(defaults: defaults)
        state.synchronizeSelectedSubject(
            selectedSubjectID: UUID(),
            defaults: defaults
        )
        state.setExpanded(
            false,
            for: .memorySource,
            defaults: defaults
        )

        state.synchronizeSelectedSubject(
            selectedSubjectID: nil,
            defaults: defaults
        )
        state.synchronizeSelectedSubject(
            selectedSubjectID: UUID(),
            defaults: defaults
        )

        #expect(state.isExpanded(for: .memorySource))
    }
}
#endif
