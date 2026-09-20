#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import PhotosUI
import SwiftUI

struct MediaPickerPresentationState {
    var selectedProcessingItems: [PhotosPickerItem] = []
    var selectedLogoItem: PhotosPickerItem?
    var isLogoPickerPresented = false
    var isOptimizingLogo = false
}

struct ConfigurationRenamePresentationState {
    var isEditing = false
    var titleDraft = ""
}

struct ConfigurationSwitchPresentationState {
    var showsConfigurationRequiredAlert = false
    var pendingMemoryPresetActivation: MemoryPreset?
    var showsUnsavedPresetSwitchAlert = false
    var showsUnsavedPresetCreationAlert = false
    var pendingSubjectSelectionID: UUID?
    var showsUnsavedSubjectSwitchAlert = false
}

struct LocalConfigurationLibraryPresentationState {
    var isPresented = false
    var backups: [LocalConfigurationBackupRecord] = []
    var statusMessage: String?
    var isWorking = false
    var homeActionFeedback: String?
    var showsHomeActionFailureAlert = false
}

/// Groups transient root presentation state without owning configuration data.
///
/// This container intentionally excludes ConfigurationSession, editor drafts,
/// output configuration, bootstrap state, and persistence status. Those values
/// have separate lifecycle and truth boundaries.
struct RootPresentationState {
    var configurationDisclosureState =
        ConfigurationDisclosureState()
    var mediaPickerPresentation =
        MediaPickerPresentationState()
    var renamePresentation =
        ConfigurationRenamePresentationState()
    var showsRegionContentSheet = false
    /// Routes the shared editor presentation to FilmMark's independent
    /// authored-output draft instead of a classic card-region buffer.
    var isEditingFilmMarkContent = false
    var showsWelcomeInformation = false
    var showsMemoMarkPlus = false
    var showsHomeMemoMarkPlus = false
    var showsMemoMarkPlusForPendingExpression = false
    /// The expanded FM calibration canvas is UI-only. It must never become
    /// part of the saved FilmMark configuration or export snapshot.
    var isFilmMarkGeometryExpanded = false
    /// A new revision is emitted only when the FM calibration disclosure opens.
    /// It brings the matching control panel beside the preview once, then the
    /// user resumes ordinary scroll ownership.
    var filmMarkGeometryScrollRequest: ConfigurationEditorScrollRequest?
    var showsSettingsWorkflowGuide = false
    var switchPresentation =
        ConfigurationSwitchPresentationState()
    var localLibraryPresentation =
        LocalConfigurationLibraryPresentationState()
}

#endif
