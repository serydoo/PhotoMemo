import SwiftUI

extension MainView {

    @ViewBuilder
    var rootContent: some View {

#if os(macOS)
        NavigationSplitView {

            sidebar

        } detail: {

            detail
        }
#else
        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    detailContent

                    editorContent
                }
                .padding(20)
            }
            .navigationTitle("PhotoMemo")
            .navigationBarTitleDisplayMode(.inline)
        }
#endif
    }
}

// MARK: - Sidebar
extension MainView {

    var editorContent: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            Text("PhotoMemo")
                .font(.system(
                    size: 32,
                    weight: .semibold
                ))

            Text("本地 EXIF 卡片生成")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            heroPanel

            memoryProgressPanel

            if shouldShowPermissionSection {
                GroupBox("本地权限") {
                    permissionSection
                }
            }

            GroupBox("照片") {
                photoSection
            }

            GroupBox("模板") {
                templateSection
            }

            GroupBox("时间锚点") {
                anchorSection
            }

            GroupBox("个性化区域") {
                fieldEditorSection
            }

            GroupBox("补充信息") {
                customContentSection
            }

            GroupBox("Logo 标识") {
                badgeSection
            }

            GroupBox("输出") {
                outputSection
            }

            Spacer(minLength: 0)
        }
        .groupBoxStyle(
            MinimalCardGroupBoxStyle()
        )
    }

    var sidebar: some View {

        ScrollView {

            editorContent
        }
        .padding(24)
        .frame(
            minWidth: 360,
            maxWidth: .infinity,
            alignment: .topLeading
        )
    }
}

extension MainView {

    var photoSection: some View {
        MainPhotoSectionView(
            selectedPhotoDeviceModel:
                selectedPhotoDeviceModelText,
            selectedPhotoCaptureDateText:
                selectedPhotoCaptureDateText,
            importer: {
                PhotoImporterView(
                    onImport: handleImportedPhoto
                )
            }
        )
    }

    var templateSection: some View {
        MainTemplateSectionView(
            selectedPreset: selectedTemplatePreset,
            resolvedTemplateDisplayName:
                resolvedTemplateDisplayName,
            currentPresetDisplayName:
                currentPreset.displayName,
            currentPresetDefaultOutput:
                currentPresetDefaultOutput,
            currentPresetSummary:
                currentPreset.summary,
            onPresentTemplateRename: {
                presentTemplateRenameSheet()
            },
            onResetTemplateDefaults: {
                resetCurrentTemplateToPresetDefaults()
            }
        )
    }

    var anchorSection: some View {
        MainAnchorSectionView(
            anchors: settings.anchors,
            selectedAnchorID: $selectedAnchorID,
            anchorPhotoSummary: anchorPhotoSummary,
            selectedAnchorDateText:
                selectedAnchor.map {
                    anchorDateText($0)
                },
            previewSummaryText:
                anchorPreviewResult?.summaryText,
            quickFacts: anchorQuickFactItems,
            emptyStateText:
                "选择一个时间点后，系统会按照片 EXIF 拍摄时间自动计算年岁、纪念时长、已过天数、未来倒计时，以及第几天、周数、月龄等时间结果模块。",
            onPresentAnchorManager: {
                presentAnchorManager()
            }
        )
    }

    var fieldEditorSection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            variableLibraryPanel(
                title: "识别数据",
                variables: TemplateVariableLibrary.recognized
            )

            variableLibraryPanel(
                title: "智能数据",
                variables: TemplateVariableLibrary.intelligent
            )

            templateFieldEditors
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var templateFieldEditors: some View {

        ForEach(
            MainFieldSlot.allCases,
            id: \.self
        ) { slot in

            templateFieldEditor(for: slot)
        }
    }

    var customContentSection: some View {
        MainCustomContentSectionView(
            titleText: $titleText,
            storyText: $storyText,
            shouldWritePhotoDescription:
                $settings.shouldWritePhotoDescription,
            photoDescriptionOverride:
                $settings.photoDescriptionOverride,
            defaultPhotoDescriptionHint:
                defaultPhotoDescriptionHint
        )
    }

    var badgeSection: some View {
        MainBadgeSectionView(
            badgeNames:
                BadgeLibrary.defaults.map(\.name),
            selectedBadgeName: selectedBadgeName,
            selectedBadgeTitle: selectedBadgeTitle,
            selectedBadgeSummary: selectedBadgeSummary,
            preview: {
                badgePreviewIcon
            }
        )
    }

    var outputSection: some View {
        MainOutputSection(
            selectedAlbumIdentifier:
                $selectedAlbumIdentifier,
            availableAlbums: availableAlbums,
            selectedAlbumSummary:
                selectedAlbumSummary,
            isSavingToAlbum: isSavingToAlbum,
            canExportCurrentCard:
                canExportCurrentCard,
            saveCurrentCardToAlbum:
                saveCurrentCardToAlbumAction
        )
    }

    var heroPanel: some View {

        HStack(spacing: 10) {

            MainStatusPillView(
                title: "模板",
                value: resolvedTemplateDisplayName
            )

            MainStatusPillView(
                title: "时间点",
                value:
                    selectedAnchor?.title
                    ?? "未设置"
            )

            MainStatusPillView(
                title: "图库",
                value:
                    permissionCenter.canAccessPhotoLibrary
                    ? "原信息保留"
                    : "待授权"
            )
        }
    }

    var permissionSection: some View {
        MainPermissionSection(
            photoLibraryState:
                permissionCenter
                .photoLibraryState,
            notificationState:
                permissionCenter
                .notificationState,
            requestPhotoLibraryPermission:
                requestPhotoLibraryPermissionAction,
            openPhotoLibrarySettings:
                openPhotoLibrarySettings,
            requestNotificationPermission:
                requestNotificationPermissionAction,
            openNotificationSettings:
                openNotificationSettings
        )
    }

    var shouldShowPermissionSection: Bool {
        !permissionCenter.photoLibraryState.isGranted
            || !permissionCenter.notificationState
            .isGranted
    }

    var memoryProgressPanel: some View {
        MainMemoryProgressPanel(
            snapshot: batchQueueStore.usageSnapshot,
            defaultConfigurationSnapshot:
                batchQueueStore
                .defaultConfigurationSnapshot,
            availableAlbums: availableAlbums,
            latestExternalIntakeSummary:
                batchQueueStore
                .latestExternalIntakeSummary,
            latestFailureSummary:
                batchQueueStore
                .latestFailureSummary,
            recentFailureRecords:
                Array(
                    batchQueueStore
                    .recentFailureRecords
                    .prefix(3)
                ),
            retryFailedTasks: { jobID in
                batchQueueStore.retryFailedTasks(
                    in: jobID
                )
            }
        )
    }

    var permissionSetupSheet: some View {
        MainPermissionSetupSheet(
            dismiss: {
                presentationState
                    .showsPermissionSetupSheet = false
            },
            requestInitialPermissions:
                requestInitialPermissionsAction
        )
    }

    @ViewBuilder
    func variableLibraryPanel(
        title: String,
        variables: [TemplateVariable]
    ) -> some View {
        MainVariableLibraryPanel(
            title: title,
            variables: variables,
            isEnabled:
                currentEditingSlot != nil,
            onInsertVariable: { variable in
                insertToken(variable.token)
            },
            onDismissArrangeMode: {}
        )
    }

    @ViewBuilder
    func templateFieldEditor(
        for slot: MainFieldSlot
    ) -> some View {
        MainTemplateFieldEditorView(
            slot: slot,
            text:
                templateEditorDisplayBinding(
                    for: slot
                ),
            selection:
                templateEditorSelectionBinding(
                    for: slot
                ),
            moduleSpans:
                templateEditorModuleSpansBinding(
                    for: slot
                ),
            placeholder:
                MainTemplateEditorDisplayEngine
                .displayState(
                    from: slot.placeholder
                ).text,
            focusedField:
                editorSession.focusedField,
            isFocused:
                editorSession.focusedField
                == slot,
            onContentChange: {
                displayText,
                selection,
                moduleSpans in

                applyTemplateEditorContentChange(
                    displayText: displayText,
                    selection: selection,
                    moduleSpans: moduleSpans,
                    for: slot
                )
            },
            onActivateEditingSlot: {
                activateEditingSlot(slot)
            }
        )
    }
}

// MARK: - Detail
extension MainView {

    @ViewBuilder
    var detail: some View {

        ScrollView {

            detailContent
                .padding()
        }
    }

    @ViewBuilder
    var detailContent: some View {

        VStack(
            alignment: .center,
            spacing: 22
        ) {

            workspaceConfigurationPanel
                .frame(
                    maxWidth: 900,
                    alignment: .leading
                )

            if let selectedPhoto,
               let card = currentCard {

                let previewWidth =
                    previewCardMaxWidth(
                        for: selectedPhoto
                    )

                MainPreviewDetailView(
                    previewImage:
                        selectedPhoto.image
                        .swiftUIImage,
                    card: card,
                    previewWidth: previewWidth
                )

            } else {

                ContentUnavailableView(
                    "还没有导入照片",
                    systemImage: "photo"
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var badgePreviewIcon: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(
                Color.white.opacity(0.92)
            )

            if let selectedBadge = settings.selectedBadge,
               selectedBadge.type != .none,
               let symbol = selectedBadge.systemSymbol {

                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MinimalPalette.accent)

            } else {

                Image(
                    systemName:
                        currentPreset == .immersWhite
                        ? "applelogo"
                        : "sparkles"
                )
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 48, height: 48)
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
    }
}
