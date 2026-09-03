#if os(iOS)
import PhotosUI
import SwiftUI

extension MemoMarkConfigurationCenterView {

    func applyBootstrapFlowPatch(
        _ patch: ConfigurationBootstrapFlowPatch
    ) {
        bootstrapRuntimeCoordinator.apply(patch)
    }

    func consumeNotificationDeepLinkIfNeeded() {
        guard let notificationDeepLink else {
            return
        }

        switch notificationDeepLink {
        case .share:
            break
        case .processing(let jobID):
            backgroundStatusService.focus(jobID: jobID)
            entryFlowState = EntryFlowCoordinator.openTasksTab(
                from: entryFlowState
            )
        }

        onNotificationDeepLinkHandled()
    }

    @discardableResult
    @MainActor
    func applyCurrentConfiguration() async -> Bool {
        guard !isSavingConfiguration else {
            return false
        }

        let presetPersistenceSnapshot =
            session
            .persistenceSnapshotForCurrentConfiguration(
                logoMode: logoMode,
                outputConfiguration:
                    currentSavedOutputConfiguration
            )

        let payload = ConfigurationSavePayloadBuilder.build(
            from: ConfigurationSavePayloadInput(
                state: session.state,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                persistenceMemoryPresets:
                    presetPersistenceSnapshot.memoryPresets,
                persistenceSelectedMemoryPresetID:
                    presetPersistenceSnapshot.selectedMemoryPresetID,
                title: session.currentMemoryPresetTitle,
                regionDrafts: Dictionary(
                    uniqueKeysWithValues:
                        CardRegion.memoryCardRegions.map {
                            ($0, draft(for: $0))
                        }
                ),
                regionDraftsByPresentationStyle:
                    regionDraftsForSaving,
                regionTemplateIDs: Dictionary(
                    uniqueKeysWithValues:
                        CardRegion.memoryCardRegions.compactMap {
                            region in
                            session.activeTemplateID(for: region)
                                .map { (region, $0) }
                        }
                ),
                locationConfiguration: locationDisplayConfiguration,
                logoMode: logoMode,
                badge: selectedBadgeForSaving,
                usesCustomMemoryWriteText:
                    session.usesCustomMemoryWriteText,
                customMemoryWriteText: session.customMemoryWriteText,
                shouldWritePhotosDescription:
                    outputDraftState.shouldWritePhotosDescription,
                photosDescriptionOverride:
                    outputDraftState.photosDescriptionOverride,
                birthdayDate: birthdayDate,
                outputTarget: outputDraftState.outputTarget,
                mediaOutputMode: outputDraftState.mediaOutputMode,
                availableAlbums: outputDraftState.availableAlbums,
                selectedAlbumIdentifier:
                    outputDraftState.selectedExistingAlbumIdentifier,
                newAlbumName: outputDraftState.newAlbumName,
                configurationAlbumTitle:
                    outputDraftState.configurationAlbumTitle,
                livePhotoPolicy: outputDraftState.livePhotoPolicy,
                presentationRoute: presentationStyle,
                selectedTimeAnchorID: session.selectedTimeAnchorID,
                language: session.language,
                savedAt: Date()
            )
        )

        guard let configurationLibrary = payload.configurationLibrary else {
            return await configurationApplyRuntimeCoordinator
                .applyLegacyCompatibility(
                    payload.legacyCompatibilityRequest,
                    outputTarget: outputDraftState.outputTarget
                )
        }

        return await configurationApplyRuntimeCoordinator.applyAggregate(
            configurationLibrary: configurationLibrary,
            aggregateDraft: payload.aggregateDraft,
            availableAlbums: outputDraftState.availableAlbums
        )
    }

    @MainActor
    func saveCurrentConfigurationSnapshot()
    async -> BatchConfigurationSnapshot? {
        guard await applyCurrentConfiguration() else {
            return nil
        }

        let snapshot =
            loadProductionConfigurationSnapshot.apply()
        externalIntakeCenter.updateDefaultConfiguration(snapshot)
        return snapshot
    }

    var hasSavedConfigurationForSelectedSubject: Bool {
        !homeAvailablePresets.isEmpty
    }

    var currentSavedOutputConfiguration:
        SavedOutputConfigurationSchemaV1 {
        SavedOutputConfigurationSchemaV1(
            outputTarget: outputDraftState.outputTarget,
            mediaOutputMode: outputDraftState.mediaOutputMode,
            selectedExistingAlbumIdentifier:
                outputDraftState.selectedExistingAlbumIdentifier,
            newAlbumName: outputDraftState.newAlbumName
        )
    }

    func beginPhotoProcessingFlow() {
        guard hasSavedConfigurationForSelectedSubject else {
            rootPresentationState
                .switchPresentation
                .showsConfigurationRequiredAlert = true
            return
        }

        entryFlowState =
            EntryFlowCoordinator
            .openProcessingPhotoPicker(
                from:
                    entryFlowState
            )
    }

    func applySavedOutputConfiguration(
        _ preset: MemoryPreset
    ) {
        guard let savedOutputConfiguration =
            preset.savedOutputConfiguration
        else {
            return
        }

        isApplyingSavedOutputConfiguration = true
        outputDraftState.outputTarget =
            savedOutputConfiguration.outputTarget
        outputDraftState.mediaOutputMode =
            savedOutputConfiguration.mediaOutputMode
        outputDraftState.selectedExistingAlbumIdentifier =
            savedOutputConfiguration
            .selectedExistingAlbumIdentifier
        outputDraftState.newAlbumName =
            savedOutputConfiguration.newAlbumName
                .isEmpty
            ? MemoMarkAlbumSelection
                .defaultAlbumTitle
            : savedOutputConfiguration
                .newAlbumName
        isApplyingSavedOutputConfiguration = false

        if outputDraftState.outputTarget == .existingAlbum {
            Task {
                await loadAlbumOptions()
            }
        }
    }

    var timeAnchorTitle: String {
        let anchorTitle =
            alignedSelectedSubject()?
            .primaryTimeAnchor?
            .title
            ?? alignedSelectedSubject()?
            .behavior.primaryAnchor
            ?? session.state.selectedSubject?
            .primaryTimeAnchor?
            .title
            ?? session.state.selectedSubject?
            .behavior.primaryAnchor
            ?? "时间锚点"

        let trimmedTitle =
            anchorTitle.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmedTitle.isEmpty
            ? "时间锚点"
            : trimmedTitle
    }

    @MainActor
    func loadAlbumOptions() async {
        let context = currentOutputAlbumLoadContext
        let currentAvailableAlbums =
            outputDraftState.availableAlbums

        await outputAlbumRuntimeCoordinator.load(
            context: context,
            performLoad: {
                await ExportAlbumLoadingPresenter
                    .loadProjection(
                        currentAvailableAlbums:
                            currentAvailableAlbums,
                        selectedExistingAlbumIdentifier:
                            context.selectedExistingAlbumIdentifier,
                        transaction:
                            loadPhotoLibraryAlbums
                    )
            },
            currentContext: {
                currentOutputAlbumLoadContext
            },
            apply: applyOutputAlbumRuntimeUpdate
        )
    }

    var currentOutputAlbumLoadContext:
        OutputAlbumLoadContext {
        OutputAlbumLoadContext(
            subjectID: session.state.selectedSubject?.id,
            configurationID: session.state.selectedMemoryPresetID,
            outputTarget: outputDraftState.outputTarget,
            selectedExistingAlbumIdentifier:
                outputDraftState.selectedExistingAlbumIdentifier
        )
    }

    func applyOutputAlbumRuntimeUpdate(
        _ update: OutputAlbumRuntimeUpdate
    ) {
        switch update {
        case .loadingStarted:
            outputDraftState.isLoadingAlbums = true

        case .loadingEnded:
            outputDraftState.isLoadingAlbums = false

        case .completed(let projection):
            outputDraftState.isLoadingAlbums = false
            outputDraftState.availableAlbums = projection.availableAlbums
            outputDraftState.selectedExistingAlbumIdentifier =
                projection.selectedExistingAlbumIdentifier
            outputDraftState.albumStatusMessage =
                projection.albumStatusMessage
        }
    }

    @MainActor
    func optimizeSelectedLogo(
        _ item: PhotosPickerItem
    ) async {
        rootPresentationState.mediaPickerPresentation.selectedLogoItem = nil
        await logoAssetRuntimeCoordinator.optimize(
            editingContext: currentLogoAssetEditingContext,
            performOptimization: {
                await logoAssetCoordinator.optimize(item)
            },
            currentContext: {
                currentLogoAssetEditingContext
            },
            discardUnappliedAsset:
                discardUnappliedLogoAsset,
            apply: applyLogoAssetUpdate
        )
    }

    var currentLogoAssetEditingContext:
        LogoAssetEditingContext {
        LogoAssetEditingContext(
            subjectID: session.state.selectedSubject?.id,
            configurationID: session.state.selectedMemoryPresetID
        )
    }

    var logoModeSelectionBinding: Binding<ConfigurationLogoMode> {
        Binding(
            get: { logoMode },
            set: handleRequestedLogoMode
        )
    }

    func handleRequestedLogoMode(
        _ requestedMode: ConfigurationLogoMode
    ) {
        let decision = logoAssetCoordinator.modeSelectionDecision(
            currentMode: logoMode,
            requestedMode: requestedMode
        )

        if decision.shouldCancelActiveOptimization {
            rootPresentationState.mediaPickerPresentation.selectedLogoItem = nil
            logoAssetRuntimeCoordinator.cancelActiveOptimization(
                apply: applyLogoAssetUpdate
            )
        }

        if decision.shouldPresentPhotoPicker {
            rootPresentationState
                .mediaPickerPresentation
                .isLogoPickerPresented = true
            return
        }

        guard let nextLogoMode = decision.nextLogoMode else {
            return
        }
        rootPresentationState
            .mediaPickerPresentation
            .isLogoPickerPresented = false
        logoMode = nextLogoMode
    }

    func resetLogoSelectionPresentation() {
        rootPresentationState.mediaPickerPresentation.selectedLogoItem = nil
        rootPresentationState
            .mediaPickerPresentation
            .isLogoPickerPresented = false
        logoAssetRuntimeCoordinator.cancelActiveOptimization(
            apply: applyLogoAssetUpdate
        )
        rootPresentationState.mediaPickerPresentation.isOptimizingLogo = false
    }

    func discardUnappliedLogoAsset(_ badge: Badge?) {
        guard let path = badge?.imagePath else { return }
        LogoAssetOptimizationService.discardUncommittedAsset(
            atPath: path
        )
    }

    func applyLogoAssetUpdate(
        _ update: LogoAssetUpdate
    ) {
        rootPresentationState.mediaPickerPresentation.isOptimizingLogo =
            update.isOptimizingLogo

        if let customLogoBadge = update.customLogoBadge {
            self.customLogoBadge = customLogoBadge
        }

        if let logoMode = update.logoMode {
            self.logoMode = logoMode
        }

        if let activeConfigurationStatus =
            update.activeConfigurationStatus {
            self.activeConfigurationStatus = activeConfigurationStatus
        }
    }

    func applyConfigurationDraftProjection(
        _ projection: ConfigurationDraftProjection
    ) {
        customLogoBadge = projection.badge
        logoMode = projection.logoMode
        presentationStyle = projection.route
        locationDisplayConfiguration =
            projection.locationConfiguration
        session.language = projection.language
        session.restoreMemoryCopy(
            usesCustomText:
                projection.usesCustomMemoryWriteText,
            customText:
                projection.customMemoryWriteText
        )
        outputDraftState.shouldWritePhotosDescription =
            projection.shouldWritePhotosDescription
        outputDraftState.photosDescriptionOverride =
            projection.photosDescriptionOverride
        outputDraftState.outputTarget = projection.outputTarget
        outputDraftState.mediaOutputMode = projection.mediaOutputMode
        outputDraftState.selectedExistingAlbumIdentifier =
            projection.selectedAlbumIdentifier
        outputDraftState.configurationAlbumTitle = projection.albumTitle
        if projection.outputTarget == .newAlbum {
            outputDraftState.newAlbumName = projection.albumTitle.isEmpty
                ? MemoMarkAlbumSelection.defaultAlbumTitle
                : projection.albumTitle
        }
        outputDraftState.livePhotoPolicy = projection.livePhotoPolicy
        editorDraftState.replace(
            active: projection.regionDrafts,
            byPresentationStyle:
                projection.regionDraftsByPresentationStyle,
            activeStyle: presentationStyle
        )
    }

    var selectedBadgeForSaving: Badge {
        switch logoMode {
        case .appleMini:
            return .appleClassic
        case .customUpload:
            return customLogoBadge ?? .none
        case .subjectAvatar:
            return subjectAvatarBadge
        }
    }
}

#endif
