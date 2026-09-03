import Foundation
import Testing
@testable import MemoMark

@Suite("Memory Subject editor accessibility contract")
struct MemorySubjectEditorAccessibilityContractTests {

    @Test("all identity editing modes expose the same field identifiers")
    func identityModesShareStableFieldIdentifiers() throws {
        let source = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
            ),
            encoding: .utf8
        )

        #expect(source.contains("identityFieldAccessibilityIdentifier(for: title)"))
        #expect(source.contains(".accessibilityIdentifier(\"subject-identity-fields-group\")"))
        for identifier in [
            "subject-field-display-name",
            "subject-field-short-name",
            "subject-field-relationship-role",
            "subject-field-relationship-label"
        ] {
            #expect(source.contains(identifier))
        }
    }
}
