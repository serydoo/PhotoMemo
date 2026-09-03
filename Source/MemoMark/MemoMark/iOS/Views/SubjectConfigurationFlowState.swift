#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import OSLog

@MainActor
final class SubjectConfigurationFlowState:
    Identifiable {

    private static let subjectLogger = Logger(
        subsystem: "com.serydoo.PhotoMemo.iOS",
        category: "MemorySubjectFlow"
    )

    let sourceSubjectID: MemorySubject.ID
    let draftSession: ConfigurationSession

    private let liveSession: ConfigurationSession
    private let persistSubject:
        ((MemorySubject) async throws -> Void)?
    private let didPersistSubject:
        ((MemorySubject) -> Void)?

    private(set) var lastSaveFailureMessage: String?

    init?(
        liveSession: ConfigurationSession,
        persistSubject: ((MemorySubject) async throws -> Void)? = nil,
        didPersistSubject: ((MemorySubject) -> Void)? = nil
    ) {
        guard let selectedSubject = liveSession.state.selectedSubject else {
            return nil
        }

        self.sourceSubjectID = selectedSubject.id
        self.liveSession = liveSession
        self.persistSubject = persistSubject
        self.didPersistSubject = didPersistSubject
        let draftSession = ConfigurationSession(
            state: liveSession.state
        )

        // Older durable records can legitimately contain no time anchors
        // (the model keeps an empty default for decoding compatibility), but
        // the editor contract requires at least one actionable anchor. Seed
        // the draft with the same deterministic defaults used by the subject
        // editor. This keeps the repair scoped to the editing transaction;
        // persistence still occurs only when the user taps 完成.
        let normalizedAnchors =
            MemorySubjectEditingDraft.defaultedTimeAnchors(
                for: selectedSubject
            )
        var draftSubject = selectedSubject
        draftSubject.timeAnchors = normalizedAnchors
        draftSubject.activeTimeAnchorID =
            selectedSubject.activeTimeAnchorID
            ?? normalizedAnchors.first?.id
        if let activeAnchor = normalizedAnchors.first(where: {
            $0.id == draftSubject.activeTimeAnchorID
        }) ?? normalizedAnchors.first {
            draftSubject.activeTimeAnchorID = activeAnchor.id
            draftSubject.referenceDate = activeAnchor.date
            draftSubject.behavior.primaryAnchor = activeAnchor.title
        }

        self.draftSession = draftSession
        // Restore through the session's replacement boundary rather than
        // selecting only the identifier. `selectSubject` intentionally keeps
        // the existing subject value in state; using it alone would leave a
        // legacy empty-anchor record unchanged in the editor. The restore
        // operation also handles a state snapshot whose subject collection is
        // temporarily empty, while remaining draft-only until saveChanges().
        self.draftSession.restoreSelectedSubject(draftSubject)
        Self.subjectLogger.debug(
            "editor draft prepared subject=\(draftSubject.id.uuidString, privacy: .public) anchors=\(draftSubject.timeAnchors.count, privacy: .public)"
        )
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
    func saveChanges() async -> Bool {
        lastSaveFailureMessage = nil
        guard let updatedSubject =
            draftSession.state.selectedSubject,
            updatedSubject.id == sourceSubjectID,
            canSaveChanges
        else {
            Self.subjectLogger.error(
                "editor.save rejected source=\(self.sourceSubjectID.uuidString, privacy: .public)"
            )
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
        committedSubject.activeTimeAnchorID =
            updatedSubject.activeTimeAnchorID
        committedSubject.referenceDate = updatedSubject.referenceDate
        committedSubject.behavior = updatedSubject.behavior

        do {
            try await persistSubject?(committedSubject)
        } catch {
            lastSaveFailureMessage = "记忆对象暂时无法保存，请稍后再试。"
            Self.subjectLogger.error(
                "editor.save persistence failed subject=\(committedSubject.id.uuidString, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
            )
            return false
        }

        liveSession.updateSelectedSubject(committedSubject)
        didPersistSubject?(committedSubject)
        return true
    }
}
#endif
