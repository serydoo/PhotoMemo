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

    func saveChanges() {
        guard let updatedSubject =
            draftSession.state.selectedSubject,
            updatedSubject.id == sourceSubjectID
        else {
            return
        }

        liveSession.updateSelectedSubject(updatedSubject)
        persistSubject?(updatedSubject)
    }
}
#endif
