import Foundation
import Testing
@testable import PhotoMemo

@Suite("EditorProjectionEngine")
struct EditorProjectionEngineTests {

    @Test("Round-trips mixed literal text and module chips")
    func roundTripsMixedLiteralTextAndModuleChips() {

        let rawValue =
            "{{relationship_label}}手持{{model}}记录"

        let state =
            EditorProjectionEngine.displayState(
                from: rawValue
            )

        #expect(
            state.text == "〔记录者称呼〕手持〔型号〕记录"
        )
        #expect(state.moduleSpans.count == 2)
        #expect(
            EditorProjectionEngine.rawTemplateValue(
                from: state.text,
                moduleSpans: state.moduleSpans
            ) == rawValue
        )
    }

    @Test("Deleting leading literal text keeps following module chip intact")
    func deletingLeadingLiteralTextKeepsFollowingModuleChipIntact() {

        let initialState =
            EditorProjectionEngine.displayState(
                from: "他爹手持{{model}}记录"
            )

        let nextState =
            EditorProjectionEngine.replacementResult(
                for: initialState.text,
                moduleSpans: initialState.moduleSpans,
                replacementRange: NSRange(
                    location: 0,
                    length: 2
                ),
                replacementText: ""
            )

        #expect(
            nextState.text == "手持〔型号〕记录"
        )
        #expect(
            EditorProjectionEngine.rawTemplateValue(
                from: nextState.text,
                moduleSpans: nextState.moduleSpans
            ) == "手持{{model}}记录"
        )
    }
}
