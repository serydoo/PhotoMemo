#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 memory source disclosure state")
struct V1MemorySourceDisclosureStateTests {

    @Test("manual collapse remains while the subject is unchanged")
    func manualCollapseRemainsForSameSubject() {
        let subjectID = UUID()
        var state = V1MemorySourceDisclosureState(
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
        var state = V1MemorySourceDisclosureState(
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
        var state = V1MemorySourceDisclosureState(
            selectedSubjectID: subjectID,
            isExpanded: false
        )

        state.setExpanded(true)

        #expect(state.selectedSubjectID == subjectID)
        #expect(state.isExpanded)
    }
}

@Suite("V1 memory expression disclosure state")
struct V1MemoryExpressionDisclosureStateTests {

    @Test("memory expression details start collapsed")
    func memoryExpressionDetailsStartCollapsed() {
        let state = V1MemoryExpressionDisclosureState()

        #expect(state.isExpanded == false)
    }

    @Test("manual disclosure changes presentation state only")
    func manualDisclosureChangesPresentationStateOnly() {
        var state = V1MemoryExpressionDisclosureState()

        state.setExpanded(true)
        #expect(state.isExpanded)

        state.setExpanded(false)
        #expect(state.isExpanded == false)
    }
}
#endif
