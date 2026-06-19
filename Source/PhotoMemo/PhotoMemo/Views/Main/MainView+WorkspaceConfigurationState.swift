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

        settings.selectedAnchorIDString =
            selectedAnchorID?.uuidString
            ?? ""
        settings.selectedAlbumIdentifier =
            settings.normalizedAlbumIdentifier(
                selectedAlbumIdentifier
            )

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
            title: "配置已保存",
            message: "当前内容已经保存到\(activeWorkspaceConfigurationSlot.displayTitleWithReference)，之后切换这套配置时会整体恢复模板、锚点、标识、文案和输出规则。"
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
            message: "\(activeWorkspaceConfigurationSlot.displayTitleWithReference) 已恢复到\(activeSlotID.defaultPreset.displayName)默认骨架。"
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
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
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

        if let anchor = snapshot.anchor,
           !settings.anchors.contains(
            where: { $0.id == anchor.id }
           ) {
            settings.anchors.append(anchor)
            settings.saveAnchors()
        }

        selectedAnchorID =
            snapshot.anchor?.id
        settings.selectedAnchorIDString =
            snapshot.anchor?.id.uuidString
            ?? ""

        let normalizedAlbumIdentifier =
            snapshot.selectedAlbumIdentifier
            .isEmpty
            ? PhotoAlbumOption.automaticIdentifier
            : snapshot.selectedAlbumIdentifier

        selectedAlbumIdentifier =
            normalizedAlbumIdentifier
        settings.selectedAlbumIdentifier =
            snapshot.selectedAlbumIdentifier

        settings.saveAll()
        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
        syncBatchQueueDefaultConfiguration()
    }

    func persistEditorDraftState(
        selectedAnchorID: UUID? = nil,
        selectedAlbumIdentifier: String? = nil
    ) {

        settings.scheduleEditorStateSave(
            selectedAnchorID: selectedAnchorID,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
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
