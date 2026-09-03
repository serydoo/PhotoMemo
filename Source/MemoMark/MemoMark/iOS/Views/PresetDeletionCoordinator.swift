#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
enum PresetDeletionCoordinator {

    @discardableResult
    static func deleteSelectedPreset(
        in session: ConfigurationSession,
        configurationCoordinator:
            ConfigurationCoordinator?
    ) -> Bool {
        let didDelete =
            session.deleteSelectedMemoryPreset()

        guard didDelete else {
            return false
        }

        SubjectLibraryResolver.persist(
            subjects: session.state.subjects,
            selectedSubjectID:
                session.state.selectedSubjectID,
            coordinator:
                configurationCoordinator,
            memoryPresets:
                session.state.memoryPresets,
            selectedMemoryPresetID:
                session.state.selectedMemoryPresetID
        )
        return true
    }
}
#endif
