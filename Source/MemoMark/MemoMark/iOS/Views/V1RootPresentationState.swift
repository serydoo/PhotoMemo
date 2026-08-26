#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import PhotosUI
import SwiftUI

struct V1MediaPickerPresentationState {
    var selectedProcessingItems: [PhotosPickerItem] = []
    var selectedLogoItem: PhotosPickerItem?
    var isLogoPickerPresented = false
    var isOptimizingLogo = false
    var activeLogoOptimizationRequest:
        LogoAssetOptimizationRequest?
}

struct V1ConfigurationRenamePresentationState {
    var isEditing = false
    var titleDraft = ""
}

struct V1ConfigurationSwitchPresentationState {
    var showsConfigurationRequiredAlert = false
    var pendingMemoryPresetActivation: MemoryPreset?
    var showsUnsavedPresetSwitchAlert = false
    var pendingSubjectSelectionID: UUID?
    var showsUnsavedSubjectSwitchAlert = false
}

struct V1LocalConfigurationLibraryPresentationState {
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
struct V1RootPresentationState {
    var configurationDisclosureState =
        V1ConfigurationDisclosureState()
    var mediaPickerPresentation =
        V1MediaPickerPresentationState()
    var renamePresentation =
        V1ConfigurationRenamePresentationState()
    var showsRegionContentSheet = false
    var showsWelcomeInformation = false
    var showsMemoMarkPlus = false
    var showsHomeMemoMarkPlus = false
    var switchPresentation =
        V1ConfigurationSwitchPresentationState()
    var localLibraryPresentation =
        V1LocalConfigurationLibraryPresentationState()
}
#endif
