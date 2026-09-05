#if os(iOS)
import PhotosUI
import SwiftUI

extension MemoMarkConfigurationCenterView {

    func selectConfigurationSummaryTimeAnchor(
        _ anchorID: UUID
    ) {
        guard
            let anchor =
                session.availableTimeAnchors.first(
                    where: { $0.id == anchorID }
                )
        else {
            return
        }

        session.selectTimeAnchor(id: anchorID)
        birthdayDate = anchor.date
        activeConfigurationStatus = .dirty
        refreshDynamicPreview()
    }

    func refreshProcessingState() {
        applyDiagnosticsRefreshState(
            diagnosticsRefreshCoordinator
                .refreshedState()
        )
    }

    func openPhotoLibrary(
        _ link: TaskPhotoLibraryLink
    ) {
        guard let primaryURL =
            URL(string: "photos-redirect://")
        else {
            return
        }

        UIApplication.shared.open(primaryURL) { success in
            guard !success, let fallbackURL = URL(string: "photos://") else {
                if !success {
                    Task { @MainActor in
                        presentHomeConfigurationActionFeedback(
                            "暂时无法打开 Apple Photos，请稍后重试。"
                        )
                    }
                }
                return
            }

            UIApplication.shared.open(fallbackURL) { fallbackSuccess in
                guard !fallbackSuccess else { return }
                Task { @MainActor in
                    presentHomeConfigurationActionFeedback(
                        "暂时无法打开 Apple Photos，请稍后重试。"
                    )
                }
            }
        }
    }

    func applyDiagnosticsRefreshState(
        _ state: DiagnosticsRefreshState
    ) {
        processingDiagnosticsSnapshot = state.snapshot
        shareDiagnosticEvents = state.events
    }

    func applyModulePanelState(
        _ state: ModulePanelCoordinator.State
    ) {
        editorInteractionState.focusedEditorRegion = state.focusedRegion
        editorInteractionState.activeModuleRegion = state.activeRegion
        moduleUsageCountsStorage = state.usageStorage
    }

    var editorRevealProgress: CGFloat {
        entryNavigationState.editorRevealProgress
    }

    var previewPinProgress: CGFloat {
        entryNavigationState.previewPinProgress
    }

    func offsetReader(
        for kind: ConfigurationCenterScrollOffsetKind
    ) -> some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: ConfigurationCenterScrollOffsetPreferenceKey.self,
                    value: [
                        kind: proxy.frame(
                            in: .named("configuration-center-scroll")
                        ).minY
                    ]
                )
        }
        .onPreferenceChange(
            ConfigurationCenterScrollOffsetPreferenceKey.self
        ) { values in
            entryNavigationState.updateScrollOffsets(
                profile: values[.profile],
                preview: values[.preview]
            )
        }
    }

    func bootstrapIfNeeded() {
        guard !didBootstrap else {
            return
        }

        didBootstrap = true
        applyBootstrapFlowPatch(
            bootstrapFlowCoordinator
                .bootstrap(
                    hasSeenWelcome: hasSeenWelcome,
                    fallbackBirthdayDate: birthdayDate,
                    makeDefaultDraft: makeDefaultDraft(for:)
                )
        )
    }

    func dismissKeyboard() {
        memoryPresetTitleFieldFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    func completeWelcomeFlow() {
        let update =
            EntryFlowCoordinator
            .completeWelcome(
                from: entryFlowState,
                hasSeenWelcome: hasSeenWelcome
            )
        applyEntryWelcomeUpdate(update)
    }

    @MainActor
    func initializeFirstConfiguration(
        subjectName: String,
        birthday: Date
    ) async -> Bool {
        let previousState = session.state
        let previousBirthdayDate = birthdayDate
        let previousOutputTarget = outputDraftState.outputTarget
        let previousMediaOutputMode = outputDraftState.mediaOutputMode
        let previousLogoMode = logoMode
        let previousPresetTitleDraft =
            rootPresentationState.renamePresentation.titleDraft
        let subject = SubjectLibraryFactory
            .makeFirstRunSubject(
                name: subjectName,
                birthday: birthday
            )
        let anchorID = subject.activeTimeAnchorID
        let existingPreset = session.state.selectedMemoryPreset
            ?? session.state.memoryPresets.first
        let preset = MemoryPreset(
            title: MemoMarkLanguage.interfaceStored.localized(
                key: "welcome.default_preset.title",
                fallback: "生日回顾"
            ),
            summary: MemoMarkLanguage.interfaceStored.localized(
                key: "welcome.default_preset.summary",
                fallback: "以生日为时间锚点，自然回顾照片拍摄时的年龄。"
            ),
            regionTemplateIDs: existingPreset?.regionTemplateIDs ?? [:],
            selectedSubjectID: subject.id,
            selectedTimeAnchorID: anchorID,
            outputOption: .processedImage,
            storageOption: .appFolder,
            logoMode: .appleMini,
            savedOutputConfiguration:
                SavedOutputConfigurationSchemaV1(
                    outputTarget: .automatic,
                    mediaOutputMode: .originalFormat,
                    selectedExistingAlbumIdentifier: "",
                    newAlbumName: MemoMarkAlbumSelection.defaultAlbumTitle
                )
        )

        session.restoreSubjectLibrary(
            [subject],
            selectedSubjectID: subject.id,
            memoryPresets: [preset],
            selectedMemoryPresetID: preset.id
        )
        birthdayDate = birthday
        outputDraftState.outputTarget = .automatic
        outputDraftState.mediaOutputMode = .originalFormat
        logoMode = .appleMini
        rootPresentationState.renamePresentation.titleDraft = preset.title
        bootstrapDrafts()
        refreshDynamicPreview()

        guard await applyCurrentConfiguration() else {
            session.state = previousState
            birthdayDate = previousBirthdayDate
            outputDraftState.outputTarget = previousOutputTarget
            outputDraftState.mediaOutputMode = previousMediaOutputMode
            logoMode = previousLogoMode
            rootPresentationState.renamePresentation.titleDraft =
                previousPresetTitleDraft
            bootstrapDrafts()
            refreshDynamicPreview()
            return false
        }

        completeWelcomeFlow()
        return true
    }

    func applyEntryWelcomeUpdate(
        _ update: EntryWelcomeFlowUpdate
    ) {
        hasSeenWelcome = update.hasSeenWelcome
        entryFlowState = update.flowState
    }

    func applyWelcomeFlowState(
        _ state: WelcomeFlowState
    ) {
        hasSeenWelcome = state.hasSeenWelcome
        entryFlowState = EntryFlowCoordinator
            .applyWelcomeState(state, to: entryFlowState)
    }

    func bootstrapDrafts() {
        draftRuntimeCoordinator.bootstrapDrafts(
            using: ConfigurationDraftBootstrapCoordinator(
                session: session,
                context: previewCompositionContext,
                engine: previewCompositionEngine
            )
        )
    }

    @MainActor
    func importPickedPhotos(
        _ items: [PhotosPickerItem]
    ) async {
        rootPresentationState
            .mediaPickerPresentation
            .selectedProcessingItems = []
        await performPhotoQuickAction(
            importItems: {
                await PhotoIntakeImporter.importItems(from: items)
            },
            requestedCount: items.count
        )
    }

    @MainActor
    func importPickedPHPickerResults(
        _ results: [PHPickerResult]
    ) async {
        await performPhotoQuickAction(
            importItems: {
                await PhotoIntakeImporter.importPHPickerResults(from: results)
            },
            requestedCount: results.count
        )
    }

    @MainActor
    func performPhotoQuickAction(
        importItems: @escaping () async -> [ExternalPhotoIntakeItem],
        requestedCount: Int
    ) async {
        guard let result =
            await photoIntakeRuntimeCoordinator.perform(
                requestedCount: requestedCount,
                saveCurrentConfiguration: saveCurrentConfigurationSnapshot,
                importItems: importItems,
                submit: { items, configuration in
                    externalIntakeCenter.submit(
                        items: items,
                        source: .quickAction,
                        configurationSnapshot: configuration
                    )
                },
                discardUnsubmittedItems: { items in
                    PhotoIntakeURLResolver
                        .discardTemporaryPickerFiles(
                            items.map { $0.managedURL }
                        )
                }
            )
        else {
            return
        }

        switch result.status {
        case .configurationSaveFailed:
            presentHomeConfigurationActionFeedback(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "configuration.save_failed",
                    fallback: "当前配置没有保存成功，请稍后重试。"
                )
            )
            return
        case .noSupportedPhotos:
            presentHomeConfigurationActionFeedback(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "photo.no_supported",
                    fallback: "没有找到可处理的照片，请确认照片已从 iCloud 下载完成。"
                )
            )
        case .submitted:
            if result.failedCount > 0 {
                presentHomeConfigurationActionFeedback(
                    String(
                        format: MemoMarkLanguage.interfaceStored.localized(
                            key: "photo.submitted_format",
                            fallback: "已接收 %lld 张，另有 %lld 张无法读取，请确认原图已下载完成。"
                        ),
                        locale: MemoMarkLanguage.interfaceStored.locale,
                        result.submittedItems.count,
                        result.failedCount
                    ),
                    isBlocking: false
                )
            }
            refreshExternalIntake()
            refreshProcessingState()
        }

        entryFlowState =
            EntryFlowCoordinator
            .applyQuickActionResult(result, to: entryFlowState)
    }

    var homeAvailablePresets: [MemoryPreset] {
        session.availableMemoryPresetsForSelectedSubject
    }

    func expansionBinding(
        for section: ConfigurationCenterSection
    ) -> Binding<Bool> {
        Binding(
            get: {
                entryNavigationState.expandedEditorSections.contains(section)
            },
            set: { isExpanded in
                entryNavigationState.setEditorSection(
                    section,
                    isExpanded: isExpanded
                )
            }
        )
    }
}

#endif
