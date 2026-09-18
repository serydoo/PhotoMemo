#if os(macOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import Combine

/// Identifies the durable editing context currently projected into the Mac
/// editor. Local control state must be re-projected whenever this value
/// changes so a subject or preset cannot inherit another context's draft.
struct MacConfigurationEditingContext: Hashable {

    let subjectID: UUID?
    let configurationID: UUID?
    let configurationRevision: Int?

    init(
        subjectID: UUID?,
        configuration: MemoryConfigurationRecord?
    ) {
        self.subjectID = subjectID
        self.configurationID = configuration?.id
        self.configurationRevision = configuration?.revision
    }

    func requiresProjection(
        comparedWith previous: Self?
    ) -> Bool {
        self != previous
    }

    static func statusAfterProjection(
        isDurable: Bool
    ) -> ConfigurationPersistenceStatus {
        isDurable ? .saved : .idle
    }
}

/// The undo boundary for the Mac Configuration Center is the in-memory draft,
/// not the durable configuration library. Saving remains owned by the existing
/// aggregate transaction and therefore cannot be accidentally triggered by an
/// Edit-menu action.
struct MacConfigurationDraftSnapshot: Equatable {

    let regionDraftsByPresentationStyle:
        [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]]

    init(
        regionDraftsByPresentationStyle:
            [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]]
    ) {
        self.regionDraftsByPresentationStyle = regionDraftsByPresentationStyle
    }
}

@MainActor
final class MacConfigurationUndoCoordinator: ObservableObject {

    static let shared = MacConfigurationUndoCoordinator()

    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    private var currentSnapshot: MacConfigurationDraftSnapshot?
    private var undoStack: [MacConfigurationDraftSnapshot] = []
    private var redoStack: [MacConfigurationDraftSnapshot] = []
    private var restoreHandler:
        ((MacConfigurationDraftSnapshot) -> Void)?

    func setRestoreHandler(
        _ handler: @escaping (MacConfigurationDraftSnapshot) -> Void
    ) {
        restoreHandler = handler
    }

    func clearRestoreHandler() {
        restoreHandler = nil
    }

    func reset(to snapshot: MacConfigurationDraftSnapshot) {
        currentSnapshot = snapshot
        undoStack.removeAll()
        redoStack.removeAll()
        publishAvailability()
    }

    func record(
        before: MacConfigurationDraftSnapshot,
        after: MacConfigurationDraftSnapshot
    ) {
        guard before != after else {
            return
        }

        if currentSnapshot != before {
            reset(to: before)
        }
        undoStack.append(before)
        currentSnapshot = after
        redoStack.removeAll()
        publishAvailability()
    }

    @discardableResult
    func undo() -> MacConfigurationDraftSnapshot? {
        guard let currentSnapshot,
              let previousSnapshot = undoStack.popLast()
        else {
            return nil
        }

        redoStack.append(currentSnapshot)
        self.currentSnapshot = previousSnapshot
        publishAvailability()
        restoreHandler?(previousSnapshot)
        return previousSnapshot
    }

    @discardableResult
    func redo() -> MacConfigurationDraftSnapshot? {
        guard let currentSnapshot,
              let nextSnapshot = redoStack.popLast()
        else {
            return nil
        }

        undoStack.append(currentSnapshot)
        self.currentSnapshot = nextSnapshot
        publishAvailability()
        restoreHandler?(nextSnapshot)
        return nextSnapshot
    }

    private func publishAvailability() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}
#endif
