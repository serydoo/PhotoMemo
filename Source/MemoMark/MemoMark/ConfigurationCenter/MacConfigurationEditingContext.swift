#if os(macOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

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
#endif
