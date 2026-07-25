#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class V1IOSSubjectConfigurationFlowState:
    Identifiable {

    let sourceSubjectID: MemorySubject.ID
    let draftSession: ConfigurationSession

    private let liveSession: ConfigurationSession
    private let persistSubject:
        ((MemorySubject) -> Void)?

    init?(
        liveSession: ConfigurationSession,
        persistSubject: ((MemorySubject) -> Void)? = nil
    ) {
        guard let selectedSubject = liveSession.state.selectedSubject else {
            return nil
        }

        self.sourceSubjectID = selectedSubject.id
        self.liveSession = liveSession
        self.persistSubject = persistSubject
        self.draftSession = ConfigurationSession(
            state: liveSession.state
        )
        self.draftSession.selectSubject(selectedSubject)
    }

    var canSaveChanges: Bool {
        guard let updatedSubject =
            draftSession.state.selectedSubject else {
            return false
        }

        return !updatedSubject.identity.displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    @discardableResult
    func saveChanges() -> Bool {
        guard let updatedSubject =
            draftSession.state.selectedSubject,
            updatedSubject.id == sourceSubjectID,
            canSaveChanges
        else {
            return false
        }

        guard var committedSubject = liveSession.state.selectedSubject,
              committedSubject.id == sourceSubjectID else {
            return false
        }

        committedSubject.identity = updatedSubject.identity
        committedSubject.relationship = updatedSubject.relationship
        committedSubject.definition = updatedSubject.definition
        committedSubject.expressionSubjectSource =
            updatedSubject.expressionSubjectSource
        committedSubject.decorations = updatedSubject.decorations
        committedSubject.timeAnchors = updatedSubject.timeAnchors
        committedSubject.referenceDate = updatedSubject.referenceDate
        committedSubject.behavior = updatedSubject.behavior

        liveSession.updateSelectedSubject(committedSubject)
        persistSubject?(committedSubject)
        return true
    }
}
#endif
