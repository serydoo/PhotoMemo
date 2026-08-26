#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Owns root-local lifecycle flags and the user-visible configuration status.
///
/// This is not a domain store. `ConfigurationSession`, durable configuration,
/// and persistence coordinators remain the owners of configuration truth.
struct V1RootLifecycleState {

    var isSavingConfiguration = false
    var didBootstrap = false
    var isApplyingBootstrapState = false
    var isApplyingSavedOutputConfiguration = false
    var birthdayDateChangeBehavior:
        V1BirthdayDateChangeBehavior = .userInitiated
    var shouldSaveSubjectLibrary = true
    var isPersistingSubjectChanges = false
    var activeConfigurationStatus:
        V1ConfigurationStatus = .idle
}
#endif
