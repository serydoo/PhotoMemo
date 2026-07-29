#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import PhotosUI
import SwiftUI

struct V1MediaPickerPresentationState {
    var selectedProcessingItems: [PhotosPickerItem] = []
    var selectedLogoItem: PhotosPickerItem?
    var isOptimizingLogo = false
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
#endif
