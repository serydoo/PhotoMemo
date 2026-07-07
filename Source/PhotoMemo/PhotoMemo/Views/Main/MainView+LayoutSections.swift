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
            .navigationTitle("时光记")
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

                compactConfigurationContent
            }
            .padding(16)
        }
    }

    var compactHeroHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("时光记")
                .font(.system(
                    size: 28,
                    weight: .semibold
                ))

            Text("一次设定，自然分享，永久记录。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var compactConfigurationContent: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            GroupBox("当前记忆对象") {
                subjectSection
            }
            .groupBoxStyle(
                MinimalCardGroupBoxStyle()
            )

            GroupBox("默认风格") {
                styleSection
            }
            .groupBoxStyle(
                MinimalCardGroupBoxStyle()
            )

            GroupBox("输出设置") {
                compactOutputSection
            }
            .groupBoxStyle(
                MinimalCardGroupBoxStyle()
            )

            GroupBox("设置") {
                settingsSection
            }
            .groupBoxStyle(
                MinimalCardGroupBoxStyle()
            )

            GroupBox("关于") {
                aboutSection
            }
            .groupBoxStyle(
                MinimalCardGroupBoxStyle()
            )
        }
    }

    var sidebar: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                Text("时光记")
                    .font(.system(
                        size: 32,
                        weight: .semibold
                    ))

                Text("把宝宝照片变成值得长期保存的成长记录。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                GroupBox("当前记忆对象") {
                    subjectSection
                }

                GroupBox("默认风格") {
                    styleSection
                }

                GroupBox("输出设置") {
                    outputSection
                }

                GroupBox("设置") {
                    settingsSection
                }

                GroupBox("关于") {
                    aboutSection
                }

                Spacer(minLength: 0)
            }
            .groupBoxStyle(
                MinimalCardGroupBoxStyle()
            )
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

    var subjectSection: some View {
        MainSubjectSectionView(
            profile: personalProfileStore.profile,
            anchors: settings.anchors,
            selectedAnchorID: $selectedAnchorID,
            selectedAnchorTitle:
                selectedAnchor?.title,
            selectedAnchorDateText:
                selectedAnchor?.date.formatted(
                    date: .abbreviated,
                    time: .omitted
                ),
            anchorQuickFacts:
                anchorQuickFactItems,
            saveDestinationSummary:
                personalProfileDestinationSummary,
            onPresentAnchorManager: {
                presentAnchorManager()
            },
            onUpdateProfile: { profile in
                personalProfileStore.updateProfile(
                    profile
                )
            }
        )
    }

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

    var styleSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            workspaceConfigurationPanel

            templateSection

#if !os(macOS)
            previewSection
#endif

            DisclosureGroup("进一步调整") {
                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {
                    anchorSection

                    fieldEditorSection

                    customContentSection

                    badgeSection
                }
                .padding(.top, 12)
            }
            .font(.subheadline.weight(.medium))
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
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

            variableLibraryPanel(
                title: "照片信息",
                variables: TemplateVariableLibrary.recognized
            )

            variableLibraryPanel(
                title: "记忆信息",
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
                defaultPhotoDescriptionHint,
            onBeginCustomDescriptionEditing: {
                editorSession.focusedField = nil
            }
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

    var compactOutputSection: some View {
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

    var heroPanel: some View {

        HStack(spacing: 10) {

            MainStatusPillView(
                title: "风格",
                value: resolvedTemplateDisplayName
            )

            MainStatusPillView(
                title: "记忆日期",
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

    var settingsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            if shouldShowPermissionSection {
                permissionSection
            } else {
                MinimalInsetCard {
                    LabeledContent("本地权限") {
                        Text("已就绪")
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Text("时光记已具备读取照片、保存结果和发送本地提醒所需的权限。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var aboutSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            MinimalInsetCard {
                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {
                    Text("时光记不是修图工具，而是围绕系统相册构建的记忆生成器。")
                        .font(.body)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

                    Text("日常使用里，大多数时候你只需要在系统相册中分享照片给时光记。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }

            Button("打开使用帮助") {
                presentOperationGuide(topic: .overview)
            }
            .buttonStyle(.bordered)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
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
#if os(iOS)
        .presentationDetents([
            .medium,
            .large
        ])
        .presentationDragIndicator(.visible)
#endif
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
                EditorProjectionEngine
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

            VStack(
                alignment: .leading,
                spacing: 22
            ) {

                previewSection
            }
            .frame(
                maxWidth: 900,
                alignment: .leading
            )
            .padding()
        }
    }

    @ViewBuilder
    var detailContent: some View {

        VStack(
            alignment: .center,
            spacing: 22
        ) {

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
                    maxWidth: .infinity
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    var previewSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            photoSection

            detailContent
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
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
               selectedBadge.type != .none {

                if let imageName = selectedBadge.imageName {

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(8)

                } else if let symbol = selectedBadge.systemSymbol {

                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(MinimalPalette.accent)
                }

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
