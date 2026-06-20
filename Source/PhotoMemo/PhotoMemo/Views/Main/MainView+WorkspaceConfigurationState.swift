import Foundation

extension MainView {

    var currentBatchConfigurationSnapshot:
        BatchConfigurationSnapshot {

        settings.buildBatchConfigurationSnapshot(
            selectedAnchorID: selectedAnchorID,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
        )
    }

    var activeWorkspaceConfigurationSlot:
        WorkspaceConfigurationSlot {

        settings.configurationSlot(
            for: settings.activeConfigurationSlotID
        )
        ?? WorkspaceConfigurationSlot.defaultSlots[0]
    }

    func saveCurrentConfiguration() {

        settings.updateConfigurationSlot(
            settings.activeConfigurationSlotID,
            snapshot:
                currentBatchConfigurationSnapshot
        )

        persistEditorDraftState(
            selectedAnchorID: selectedAnchorID,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
        )

        settings.saveAll()
        syncBatchQueueDefaultConfiguration()

        presentAlert(
            title: "风格已保存",
            message: "当前内容已经保存到\(activeWorkspaceConfigurationSlot.displayTitleWithReference)，以后切换到这套风格时会一起恢复。"
        )
    }

    func selectWorkspaceConfigurationSlot(
        _ slotID: WorkspaceConfigurationSlotID
    ) {

        guard
            settings.activeConfigurationSlotID
            != slotID
        else {
            return
        }

        settings.activeConfigurationSlotID = slotID
        settings.saveConfigurationSlots()
        personalProfileStore
            .updateDefaultStyleIdentifier(
                slotID.rawValue
            )

        let slot =
            settings.configurationSlot(for: slotID)
            ?? WorkspaceConfigurationSlot(
                id: slotID,
                customTitle: nil,
                snapshot: nil,
                updatedAt: nil
            )

        let snapshot =
            slot.snapshot
            ?? defaultWorkspaceConfigurationSnapshot(
                for: slotID
            )

        applyWorkspaceConfigurationSnapshot(
            snapshot
        )
    }

    func restoreActiveWorkspaceConfigurationToDefault() {

        let activeSlotID =
            settings.activeConfigurationSlotID

        settings.updateConfigurationSlot(
            activeSlotID,
            snapshot: nil
        )

        applyWorkspaceConfigurationSnapshot(
            defaultWorkspaceConfigurationSnapshot(
                for: activeSlotID
            )
        )

        presentAlert(
            title: "已恢复默认",
            message: "\(activeWorkspaceConfigurationSlot.displayTitleWithReference) 已恢复为初始默认风格。"
        )
    }

    func defaultWorkspaceConfigurationSnapshot(
        for slotID: WorkspaceConfigurationSlotID
    ) -> BatchConfigurationSnapshot {

        BatchConfigurationSnapshot(
            template:
                templatePresetEngine.build(
                    preset: .template1
                )
                .normalizedForEditing,
            badge: nil,
            anchor: selectedAnchor,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
        )
    }

    func applyWorkspaceConfigurationSnapshot(
        _ snapshot: BatchConfigurationSnapshot
    ) {

        settings.selectedTemplate =
            normalizedPrimaryTemplate(
                snapshot.template
            )
        settings.selectedBadge =
            snapshot.badge ?? Badge.none
        settings.shouldWritePhotoDescription =
            snapshot.shouldWritePhotoDescription
        settings.photoDescriptionOverride =
            snapshot.photoDescriptionOverride

        settings.saveTemplate()
        settings.saveBadge()
        settings.savePhotoDescriptionSettings()
        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
        syncBatchQueueDefaultConfiguration()
    }

    func persistEditorDraftState(
        selectedAnchorID: UUID? = nil,
        selectedAlbumIdentifier: String? = nil,
        selectedAlbumTitle: String? = nil,
        immediately: Bool = false
    ) {

        if immediately {
            settings.saveEditorState(
                selectedAnchorID: selectedAnchorID,
                selectedAlbumIdentifier:
                    selectedAlbumIdentifier,
                selectedAlbumTitle:
                    selectedAlbumTitle
            )
            return
        }

        settings.scheduleEditorStateSave(
            selectedAnchorID: selectedAnchorID,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier,
            selectedAlbumTitle:
                selectedAlbumTitle
        )
    }

    func syncBatchQueueDefaultConfiguration() {

        batchQueueStore.updateDefaultConfiguration(
            currentBatchConfigurationSnapshot
        )
        ExternalPhotoIntakeCenter.shared
            .updateDefaultConfiguration(
                currentBatchConfigurationSnapshot
            )
    }
}
