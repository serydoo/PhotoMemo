import SwiftUI

extension MainView {

    func presentAnchorManager() {

        presentationState
            .showsAnchorManager = true
    }

    func presentOperationGuide(
        topic: MainOperationGuideTopic
    ) {

        presentationState
            .selectedOperationGuideTopic =
                topic
        presentationState
            .showsOperationGuideSheet = true
    }

    @ViewBuilder
    var operationGuideSheet: some View {
        MainOperationGuideSheetView(
            selectedTopic:
                presentationState
                .selectedOperationGuideTopic,
            onDismiss: {
                presentationState
                    .showsOperationGuideSheet = false
            }
        )
    }

    @ViewBuilder
    var workspaceConfigurationRenameSheet:
        some View {

        MainWorkspaceConfigurationRenameSheetView(
            slotReferenceTitle:
                activeWorkspaceConfigurationSlot.title,
            currentDisplayTitle:
                activeWorkspaceConfigurationSlot
                .displayTitle,
            titleDraft:
                $presentationState
                .workspaceConfigurationNameDraft,
            onCancel: {
                presentationState
                    .showsWorkspaceConfigurationRenameSheet =
                        false
            },
            onSave: {
                applyWorkspaceConfigurationRename()
            }
        )
    }

    var workspaceConfigurationPanel: some View {
        MainWorkspaceConfigurationPanelView(
            slots: settings.configurationSlots,
            activeSlotID:
                settings.activeConfigurationSlotID,
            activeSlotSummary:
                workspaceConfigurationSummary,
            onSelectSlot: { slotID in
                selectWorkspaceConfigurationSlot(
                    slotID
                )
            },
            onRenameActiveSlot: {
                presentWorkspaceConfigurationRenameSheet()
            },
            onSaveActiveSlot: {
                saveCurrentConfiguration()
            },
            onRestoreActiveSlotDefault: {
                restoreActiveWorkspaceConfigurationToDefault()
            }
        )
    }

    @ViewBuilder
    var templateRenameSheet: some View {
        MainTemplateRenameSheetView(
            templateNameDraft:
                $presentationState
                .templateNameDraft,
            currentPresetDisplayName:
                currentPreset.displayName,
            resolvedTemplateDisplayName:
                resolvedTemplateDisplayName,
            onCancel: {
                presentationState
                    .showsTemplateRenameSheet = false
            },
            onSave: {
                applyTemplateRename()
            }
        )
    }

    func presentTemplateRenameSheet() {

        presentationState
            .templateNameDraft =
            resolvedTemplateDisplayName
        presentationState
            .showsTemplateRenameSheet = true
    }

    func presentWorkspaceConfigurationRenameSheet() {

        presentationState
            .workspaceConfigurationNameDraft =
            activeWorkspaceConfigurationSlot
            .resolvedCustomTitle
            ?? ""
        presentationState
            .showsWorkspaceConfigurationRenameSheet =
                true
    }

    func applyTemplateRename() {

        var template = activeTemplate

        let trimmedName =
            presentationState
            .templateNameDraft
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        template.name =
            trimmedName.isEmpty
            ? currentPreset.displayName
            : trimmedName

        settings.selectedTemplate = template
        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
        settings.scheduleTemplateSave()
        presentationState
            .showsTemplateRenameSheet = false
    }

    func applyWorkspaceConfigurationRename() {

        let trimmedName =
            presentationState
            .workspaceConfigurationNameDraft
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        settings.renameConfigurationSlot(
            settings.activeConfigurationSlotID,
            customTitle:
                trimmedName.isEmpty
                ? nil
                : trimmedName
        )

        presentationState
            .showsWorkspaceConfigurationRenameSheet =
                false
    }

    var selectedBadgeName: Binding<String> {

        Binding(
            get: {

                settings.selectedBadge?.name
                ?? Badge.none.name
            },
            set: { badgeName in

                settings.selectedBadge =
                    BadgeLibrary.defaults.first {
                        $0.name == badgeName
                    } ?? Badge.none

                settings.saveBadge()
            }
        )
    }
}
