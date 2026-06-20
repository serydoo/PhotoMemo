import SwiftUI

extension MainView {

    var baseScene: some View {

        ZStack {

            MinimalPalette.background
                .ignoresSafeArea()

            rootContent
        }
        .tint(
            MinimalPalette.accent
        )
    }

    var sceneWithSheets: some View {

        baseScene
        .sheet(
            isPresented: $presentationState.showsAnchorManager
        ) {
            anchorManagerSheet
        }
        .sheet(
            isPresented: $presentationState.showsTemplateRenameSheet
        ) {

            templateRenameSheet
        }
        .sheet(
            isPresented: $presentationState.showsPermissionSetupSheet
        ) {

            permissionSetupSheet
        }
        .sheet(
            isPresented: $presentationState.showsOperationGuideSheet
        ) {

            operationGuideSheet
        }
        .sheet(
            isPresented:
                $presentationState
                .showsWorkspaceConfigurationRenameSheet
        ) {

            workspaceConfigurationRenameSheet
        }
    }

    var mainScene: some View {

        sceneWithSheets
        .onAppear {
            configureLifecycle()
        }
        .onChange(
            of: scenePhase
        ) { _, newValue in
            handleScenePhaseChange(newValue)
        }
        .onChange(
            of: settings.anchors
        ) { _, anchors in
            handleAnchorsChange(anchors)
        }
        .onChange(
            of: settings.selectedTemplate
        ) { _, _ in
            handleSelectedTemplateChange()
        }
        .onChange(
            of: selectedAnchorID
        ) { _, newValue in
            handleSelectedAnchorChange(newValue)
        }
        .onChange(
            of: selectedAlbumIdentifier
        ) { _, newValue in
            handleSelectedAlbumIdentifierChange(
                newValue
            )
        }
        .onChange(
            of: settings.selectedBadge
        ) { _, _ in
            handleSelectedBadgeChange()
        }
        .onChange(
            of: settings.shouldWritePhotoDescription
        ) { _, _ in
            handlePhotoDescriptionSettingsChange()
        }
        .onChange(
            of: settings.photoDescriptionOverride
        ) { _, _ in
            handlePhotoDescriptionSettingsChange()
        }
        .onChange(
            of: saveFeedbackState.isPresented
        ) { _, isPresented in
            guard isPresented else {
                return
            }

            Task { @MainActor in
                try? await Task.sleep(
                    for: .seconds(2.8)
                )

                if saveFeedbackState.isPresented {
                    saveFeedbackState.isPresented = false
                }
            }
        }
        .background(mainAlert)
    }

    @ViewBuilder
    var anchorManagerSheet: some View {

        NavigationStack {

            AnchorListView(
                anchors: $settings.anchors,
                selectedAnchorID: $selectedAnchorID
            ) {

                settings.saveAnchors()
            }
        }
#if os(iOS)
        .presentationDetents([
            .large
        ])
        .presentationDragIndicator(.visible)
#else
        .frame(
            minWidth: 520,
            minHeight: 420
        )
#endif
    }

    @ViewBuilder
    var mainAlert: some View {

        EmptyView()
            .alert(
                alertState.title,
                isPresented: $alertState.isPresented
            ) {

                Button("好") {
                }

            } message: {

                Text(alertState.message)
            }
    }

    func configureLifecycle() {

        configureInitialState()
        migrateLegacyConfigurationIntoActiveSlotIfNeeded()
        syncBatchQueueDefaultConfiguration()

        Task {
            await preparePermissionsOnAppear()
        }
    }

    func handleScenePhaseChange(
        _ newValue: ScenePhase
    ) {

        guard newValue == .active else {
            return
        }

        Task {
            await refreshPermissionsForActiveScene()
        }
    }

    func handleAnchorsChange(
        _ anchors: [Anchor]
    ) {

        syncSelectedAnchor(
            with: anchors
        )
        syncBatchQueueDefaultConfiguration()
    }

    func handleSelectedTemplateChange() {

        guard
            shouldRefreshComposerItemsFromTemplate()
        else {
            return
        }

        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
        syncBatchQueueDefaultConfiguration()
    }

    func handleSelectedAnchorChange(
        _ newValue: Anchor.ID?
    ) {

        persistEditorDraftState(
            selectedAnchorID: newValue
        )
        syncBatchQueueDefaultConfiguration()
    }

    func handleSelectedAlbumIdentifierChange(
        _ newValue: String
    ) {

        let normalizedIdentifier =
            settings.normalizedAlbumIdentifier(
                newValue
            )
        let resolvedTitle =
            resolvedAlbumTitle(
                for: newValue
            ) ?? ""

        persistEditorDraftState(
            selectedAlbumIdentifier:
                normalizedIdentifier,
            selectedAlbumTitle:
                resolvedTitle,
            immediately: true
        )

        let destination:
            PersonalProfileSaveDestination

        if normalizedIdentifier
            == PhotoMemoAlbumSelection
            .systemLibraryIdentifier {
            destination = .systemLibrary
        } else if normalizedIdentifier.isEmpty
            || normalizedIdentifier
            == PhotoAlbumOption.automaticIdentifier {
            destination = .photoMemoAlbum
        } else {
            destination = .selectedAlbum
        }

        personalProfileStore.updateSaveDestination(
            defaultSaveDestination: destination,
            selectedAlbumIdentifier:
                destination == .selectedAlbum
                ? normalizedIdentifier
                : "",
            selectedAlbumTitle:
                destination == .selectedAlbum
                ? resolvedTitle
                : ""
        )

        syncBatchQueueDefaultConfiguration()
    }

    func handleSelectedBadgeChange() {

        syncBatchQueueDefaultConfiguration()
    }

    func handlePhotoDescriptionSettingsChange() {

        settings.schedulePhotoDescriptionSettingsSave()
        syncBatchQueueDefaultConfiguration()
    }
}
