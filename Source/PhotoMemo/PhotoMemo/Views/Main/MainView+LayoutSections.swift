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

            compactContent
            .navigationTitle("PhotoMemo")
            .navigationBarTitleDisplayMode(.inline)
        }
#endif
    }
}

// MARK: - Sidebar
extension MainView {

    @ViewBuilder
    var compactContent: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                compactHeroHeader

                compactTabPicker

                if presentationState.compactTab
                    == .preview {

                    compactPreviewContent

                } else {

                    compactEditorContent
                }
            }
            .padding(16)
        }
    }

    var compactHeroHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("PhotoMemo")
                .font(.system(
                    size: 28,
                    weight: .semibold
                ))

            Text("iPhone 上优先先看预览，再逐项校准内容。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            heroPanel
        }
    }

    var compactTabPicker: some View {

        Picker(
            "主界面模式",
            selection:
                $presentationState.compactTab
        ) {

            Text("预览")
                .tag(
                    MainPresentationState
                    .CompactTab.preview
                )

            Text("编辑")
                .tag(
                    MainPresentationState
                    .CompactTab.editor
                )
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    var compactPreviewContent: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            workspaceConfigurationPanel

            GroupBox("照片") {
                photoSection
            }
            .groupBoxStyle(
                MinimalCardGroupBoxStyle()
            )

            detailContent

            GroupBox("输出") {
                MainOutputSection(
                    selectedAlbumIdentifier:
                        $selectedAlbumIdentifier,
                    availableAlbums: availableAlbums,
                    selectedAlbumSummary:
                        selectedAlbumSummary,
                    isSavingToAlbum:
                        isSavingToAlbum,
                    canExportCurrentCard:
                        canExportCurrentCard,
                    isCompactLayout: true,
                    saveCurrentCardToAlbum:
                        saveCurrentCardToAlbumAction,
                    saveFeedbackTitle:
                        saveFeedbackState.title,
                    saveFeedbackMessage:
                        saveFeedbackState.message,
                    showsSaveFeedback:
                        saveFeedbackState.isPresented
                )
            }
            .groupBoxStyle(
                MinimalCardGroupBoxStyle()
            )
        }
    }

    @ViewBuilder
    var compactEditorContent: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            workspaceConfigurationPanel

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
        }
        .groupBoxStyle(
            MinimalCardGroupBoxStyle()
        )
    }

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
            resolvedTemplateDisplayName:
                resolvedTemplateDisplayName,
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

            MainDismissibleGuideCard(
                storageKey:
                    "photomemo.guide.composer.dismissed",
                title: "个性化区域说明",
                message: "先点选左上、右上、左下或右下任意一个区域，再直接输入短语；如果想补右上常用内容，优先用下方识别数据里的参数摘要、型号、镜头和完整时间。熟悉后可以关闭这条提示，完整说明会继续保留在右侧操作指南里。"
            )

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
            isCompactLayout: false,
            saveCurrentCardToAlbum:
                saveCurrentCardToAlbumAction,
            saveFeedbackTitle: nil,
            saveFeedbackMessage: nil,
            showsSaveFeedback: false
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
