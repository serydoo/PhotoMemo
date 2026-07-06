#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct ConfigurationCenteriOSView: View {

    @StateObject
    private var session =
        ConfigurationSession()

    @State
    private var selectedPanel:
        IOSConfigurationPanel = .card(.slotD)

    @State
    private var isRenamingProfile = false

    @State
    private var regionDraftStore =
        ConfigurationCenterRegionDraftStore()

    private let currentBorderStyleName =
        "Classic White"

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let sidebarWidth =
                    min(
                        max(proxy.size.width * 0.28, 148),
                        204
                    )

                VStack(spacing: 0) {
                    topConfigurationPreview

                    HStack(spacing: 0) {
                        sidebar
                            .frame(width: sidebarWidth)

                        Rectangle()
                            .fill(ConfigurationUI.faintHairline)
                            .frame(width: 0.5)

                        detailSurface
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .background(
                    ConfigurationUI.appBackground
                        .ignoresSafeArea()
                )
            }
            .navigationTitle("PhotoMemo 配置中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                configurationToolbar
            }
        }
        .preferredColorScheme(.light)
    }

    private var sidebar: some View {
        ConfigurationCenterSidebarView(
            subjectGroups: sidebarSubjectGroups,
            cardItems: sidebarCardItems,
            memoryModuleItems: sidebarMemoryModuleItems,
            outputItems: sidebarOutputItems,
            guideItems: sidebarGuideItems,
            onBackgroundTap: dismissKeyboard
        )
    }

    private var detailSurface: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                detailContent
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ConfigurationUI.panelBackground)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    dismissKeyboard()
                }
        )
    }

    private var topConfigurationPreview: some View {
        ConfigurationCenterTopPreviewSection(
            session: session,
            currentBorderStyleName: currentBorderStyleName,
            isRenamingProfile: $isRenamingProfile,
            profileTitle: profileTitleBinding,
            onDismissKeyboard: dismissKeyboard,
            onBeginRename: {
                dismissKeyboard()
                isRenamingProfile.toggle()
            },
            onResetPreset: {
                session.resetSelectedMemoryPreset()
            },
            onApplyPreset: {
                session.applySelectedMemoryPreset()
            },
            onRegionSelection: { region in
                applySelectionUpdate(
                    ConfigurationCenterSelectionCoordinator
                        .showCard(region: region)
                )
            }
        ) {
            profilePresetMenu
        }
    }

    private var profilePresetMenu: some View {
        ConfigurationCenterPresetMenu(
            presets: session.state.memoryPresets,
            selectedPreset: session.state.selectedMemoryPreset,
            currentTitle: session.currentMemoryPresetTitle,
            onSelectPreset: { preset in
                session.selectMemoryPreset(preset)
            }
        )
    }

    @ViewBuilder
    private var detailContent: some View {
        let presentation =
            ConfigurationCenterDetailPresenter
            .panelPresentation(
                for: selectedPanel
            )

        switch presentation.content {
        case .subject:
            subjectDetail(
                using: presentation
            )

        case .card:
            cardDetail

        case .memoryModule:
            ConfigurationCenterDetailPanelSection(
                title: presentation.title ?? "",
                systemImage:
                    presentation.systemImage ?? "",
                content: .memoryModule(
                    model: memoryWritePanelModel,
                    usesCustomText:
                        memoryWriteToggleBinding,
                    customText:
                        memoryWriteTextBinding
                )
            )

        case .output:
            ConfigurationCenterDetailPanelSection(
                title: presentation.title ?? "",
                systemImage:
                    presentation.systemImage ?? "",
                content: .output(
                    model:
                        outputSelectionPanelModel,
                    storageOption:
                        storageOptionBinding
                )
            )

        case .configurationGuide:
            ConfigurationCenterDetailPanelSection(
                title: presentation.title ?? "",
                systemImage:
                    presentation.systemImage ?? "",
                content: .configurationGuide(
                    items:
                        configurationGuideCards
                )
            )
        }
    }

    private func subjectDetail(
        using presentation:
            ConfigurationCenterDetailPanelPresentation
    ) -> some View {
        IOSDetailPanel(
            title: presentation.title ?? "",
            systemImage: presentation.systemImage ?? "",
            subtitle: presentation.subtitle
        ) {
            MemorySubjectEditorView(session: session)
        }
    }

    private var cardDetail: some View {
        VStack(alignment: .leading, spacing: 14) {
            activeRegionEditor

            locationDisplayInspector

            if shouldShowInsertableModules {
                fixedInsertableModuleLibrary
            }
        }
    }

    private var locationDisplayInspector: some View {
        ConfigurationCenterLocationDisplayPanel(
            presentation:
                LocationDisplayInspectorPresenter
                .presentation,
            locationModule:
                currentLocationModule,
            selectedOptionID:
                locationDisplayOptionBinding
        )
    }

    private var activeRegionEditor: some View {
        let presentation =
            ConfigurationCenterDetailPresenter
            .regionEditorPresentation(
                for:
                    session.state.selectedRegion
            )

        return ConfigurationCenterActiveRegionEditorSection(
            title: presentation.title,
            systemImage: presentation.systemImage,
            selectedRegion: session.state.selectedRegion
        ) {
            activeRegionEditorContent
        }
    }

    @ViewBuilder
    private var activeRegionEditorContent: some View {
        let presentation =
            ConfigurationCenterDetailPresenter
            .regionEditorPresentation(
                for:
                    session.state.selectedRegion
            )

        switch presentation.content {
        case .iconLibrary:
            IconLibraryView(session: session)
                .padding(8)
                .configurationPanelChrome()
        case .badgeLibrary:
            BadgeLibraryView(session: session)
                .padding(8)
                .configurationPanelChrome()
        case .regionComposer:
            ConfigurationCenterRegionComposerSection(
                region: session.state.selectedRegion,
                configurationOptions:
                    regionDraftStore.configurationOptions(
                        for: session.state.selectedRegion
                    ),
                selectedConfigurationID:
                    selectedRegionConfigurationBinding(
                        for: session.state.selectedRegion
                    ),
                configurationName:
                    regionConfigurationNameBinding(
                        for: session.state.selectedRegion
                    ),
                isRenamingConfiguration:
                    renamingRegionConfigurationBinding(
                        for: session.state.selectedRegion
                    ),
                isSaved:
                    regionDraftStore.isSaved(
                        for: session.state.selectedRegion
                    ),
                text: regionTextBinding(
                    for: session.state.selectedRegion
                ),
                continuationText:
                    regionContinuationTextBinding(
                        for: session.state.selectedRegion
                    ),
                modules: regionModulesBinding(
                    for: session.state.selectedRegion
                ),
                showsMemorySystemModules:
                    CardRegion.memoryCardRegions.contains(
                        session.state.selectedRegion
                    ),
                onSaveConfiguration: {
                    regionDraftStore.markSaved(
                        for: session.state.selectedRegion
                    )
                },
                onDeleteModule: {
                    removeInsertedModule(
                        $0,
                        from: session.state.selectedRegion
                    )
                }
            )
        case .subject:
            MemorySubjectEditorView(session: session)
        }
    }

    private var memoryWritePanelModel:
        ConfigurationCenterMemoryWritePanelModel {
        ConfigurationCenterMemoryWritePanelModel(
            description:
                ConfigurationCenterSessionBindingPresenter
                .memoryWriteDescription(session: session),
            toggleTitle:
                ConfigurationCenterSessionBindingPresenter
                .memoryWriteToggleTitle,
            inputPlaceholder:
                ConfigurationCenterSessionBindingPresenter
                .customMemoryWritePlaceholder,
            resolvedTitle:
                ConfigurationCenterSessionBindingPresenter
                .memoryWritePreviewTitle(session: session),
            resolvedText:
                session.resolvedMemoryWriteText,
            showsCustomTextField:
                session.usesCustomMemoryWriteText
        )
    }

    private var fixedInsertableModuleLibrary: some View {
        ConfigurationCenterInsertableModuleLibrarySection(
            visibleModules: visibleInsertableModules,
            additionalModules: additionalInsertableModules,
            onInsertModule: insertModuleIntoCurrentRegion
        )
    }

    private var outputSelectionPanelModel:
        ConfigurationCenterOutputSelectionPanelModel {
        ConfigurationCenterOutputSelectionPanelModel(
            outputTitle:
                session.selectedOutputOption.title,
            storageTitle:
                session.selectedStorageOption.title,
            storageNote:
                session.selectedStorageOption.note
        )
    }

    private var configurationGuideCards:
        [ConfigurationCenterGuideCardModel] {
        [
            ConfigurationCenterGuideCardModel(
                title: "四个自定义区域",
                note:
                    "插入内容进入当前选中的区域，不走隐式兜底。",
                systemImage:
                    "rectangle.and.pencil.and.ellipsis"
            ),
            ConfigurationCenterGuideCardModel(
                title: "记忆日期与智能结果",
                note:
                    "时间锚点和照片时间会组合成 1 个智能结果，并可插入任意区域。",
                systemImage:
                    "calendar.badge.clock"
            ),
            ConfigurationCenterGuideCardModel(
                title: "输出与相册保存",
                note:
                    "默认生成处理过的新图片，原图保持不变。",
                systemImage:
                    "square.and.arrow.down"
            ),
            ConfigurationCenterGuideCardModel(
                title: "关于 PhotoMemo",
                note:
                    "帮助用户阅读回忆，而不只是保存照片。",
                systemImage: "info.circle"
            )
        ]
    }

    private func subjectIconName(
        _ subject: MemorySubject
    ) -> String {
        subject.decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "person.fill"
    }

    private var shouldShowInsertableModules: Bool {
        ConfigurationCenterInsertableModulePolicy
            .shouldShowModules(
                for: session.state.selectedRegion
            )
    }

    private var visibleInsertableModules: [IOSInsertableModule] {
        ConfigurationCenterInsertableModulePolicy
            .visibleModules(
                for: session.state.selectedRegion
            )
    }

    private var additionalInsertableModules: [IOSInsertableModule] {
        ConfigurationCenterInsertableModulePolicy
            .additionalModules(
                for: session.state.selectedRegion
            )
    }

    private var sidebarSubjectGroups:
        [ConfigurationCenterSidebarSubjectGroup] {
        [
            ConfigurationCenterSidebarSubjectGroup(
                title: "人物",
                addTitle: "新增人物",
                items:
                    session.state.subjects
                    .filter {
                        $0.relationship.role == "家庭"
                    }
                    .map(sidebarItem(for:)),
                addAction: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showSubjectPanel()
                    )
                }
            ),
            ConfigurationCenterSidebarSubjectGroup(
                title: "事件",
                addTitle: "新增事件",
                items:
                    session.state.subjects
                    .filter {
                        $0.relationship.role == "旅行"
                    }
                    .map(sidebarItem(for:)),
                addAction: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showSubjectPanel()
                    )
                }
            )
        ]
    }

    private var sidebarCardItems:
        [ConfigurationCenterSidebarItem] {
        [
            sidebarCardItem(
                title: "图标",
                subtitle: "图标装饰",
                systemImage: "person.crop.circle",
                region: .icon
            ),
            sidebarCardItem(
                title: "区域 A",
                subtitle: "记录",
                systemImage: "camera.fill",
                region: .slotA
            ),
            sidebarCardItem(
                title: "区域 B",
                subtitle: "时间线",
                systemImage: "calendar",
                region: .slotB
            ),
            sidebarCardItem(
                title: "区域 C",
                subtitle: "拍摄参数",
                systemImage: "scope",
                region: .slotC
            ),
            sidebarCardItem(
                title: "区域 D",
                subtitle: "记忆 · 默认承载",
                systemImage: "text.quote",
                region: .slotD
            )
        ]
    }

    private var sidebarMemoryModuleItems:
        [ConfigurationCenterSidebarItem] {
        [
            ConfigurationCenterSidebarItem(
                title: "智能模块",
                subtitle: "生成、承载与写入",
                systemImage: "text.badge.checkmark",
                isSelected:
                    selectedPanel == .memoryModule,
                action: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showPanel(.memoryModule)
                    )
                }
            )
        ]
    }

    private var sidebarOutputItems:
        [ConfigurationCenterSidebarItem] {
        [
            ConfigurationCenterSidebarItem(
                title: "输出",
                subtitle: "处理过的图片",
                systemImage: "square.and.arrow.down",
                isSelected:
                    selectedPanel == .output,
                action: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showPanel(.output)
                    )
                }
            )
        ]
    }

    private var sidebarGuideItems:
        [ConfigurationCenterSidebarItem] {
        [
            ConfigurationCenterSidebarItem(
                title: "配置说明",
                subtitle: "保存位置与原则",
                systemImage: "questionmark.circle",
                isSelected:
                    selectedPanel == .configurationGuide,
                action: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showPanel(.configurationGuide)
                    )
                }
            )
        ]
    }

    private func sidebarItem(
        for subject: MemorySubject
    ) -> ConfigurationCenterSidebarItem {
        ConfigurationCenterSidebarItem(
            title: subject.identity.displayName,
            subtitle: subject.relationship.label,
            systemImage: subjectIconName(subject),
            isSelected:
                ConfigurationCenterSelectionCoordinator
                .isSelectedSubject(
                    panel: selectedPanel,
                    selectedSubjectID:
                        session.state.selectedSubject?.id,
                    candidateSubjectID: subject.id
                ),
            action: {
                applySelectionUpdate(
                    ConfigurationCenterSelectionCoordinator
                        .showSubject(subject)
                )
            }
        )
    }

    private func sidebarCardItem(
        title: String,
        subtitle: String,
        systemImage: String,
        region: CardRegion
    ) -> ConfigurationCenterSidebarItem {
        ConfigurationCenterSidebarItem(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            isSelected:
                selectedPanel == .card(region),
            action: {
                applySelectionUpdate(
                    ConfigurationCenterSelectionCoordinator
                        .showCard(region: region)
                )
            }
        )
    }

    private func regionTextBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .text()
            },
            set: { newValue in
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setText(newValue),
                    for: region
                )
            }
        )
    }

    private func regionModulesBinding(
        for region: CardRegion
    ) -> Binding<[IOSInsertedModule]> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .modules()
            },
            set: {
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setModules($0),
                    for: region
                )
            }
        )
    }

    private func regionContinuationTextBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .continuationText()
            },
            set: {
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setContinuationText($0),
                    for: region
                )
            }
        )
    }

    private func selectedRegionConfigurationBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .selectedConfigurationID()
            },
            set: { newValue in
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setSelectedConfigurationID(
                            newValue
                        ),
                    for: region
                )
            }
        )
    }

    private func regionConfigurationNameBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .configurationName()
            },
            set: { newValue in
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setConfigurationName(
                            newValue
                        ),
                    for: region
                )
            }
        )
    }

    private func renamingRegionConfigurationBinding(
        for region: CardRegion
    ) -> Binding<Bool> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .isRenamingConfiguration()
            },
            set: { isRenaming in
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setRenamingConfiguration(
                            isRenaming
                        ),
                    for: region
                )
            }
        )
    }

    private func insertModuleIntoCurrentRegion(
        _ module: IOSInsertableModule
    ) {
        let region = session.state.selectedRegion
        let expressionConfiguration =
            defaultExpressionConfiguration(
                for: module
            )

        guard let mutation =
            regionBindingAdapter(for: region)
            .insertModule(
                module,
                expressionConfiguration:
                    expressionConfiguration
            )
        else {
            return
        }

        applyRegionBindingMutation(
            mutation,
            for: region
        )
    }

    private var currentLocationModule:
        IOSInsertedModule? {
        regionBindingAdapter(
            for: session.state.selectedRegion
        )
        .modules()
        .first {
            $0.title == IOSInsertableModule.location.title
            && $0.systemImage == IOSInsertableModule.location.systemImage
        }
    }

    private var locationDisplayOptionBinding:
        Binding<String> {
        Binding(
            get: {
                LocationDisplayInspectorPresenter
                    .selectedOptionID(
                        from: currentLocationModule
                    )
            },
            set: { optionID in
                guard let module =
                    currentLocationModule
                else {
                    return
                }

                applyRegionBindingMutation(
                    regionBindingAdapter(
                        for: session.state.selectedRegion
                    )
                    .updateInsertedModule(
                        module,
                        expressionConfiguration:
                            LocationDisplayInspectorPresenter
                            .configuration(
                                for: optionID
                            )
                    ),
                    for: session.state.selectedRegion
                )
            }
        )
    }

    private func defaultExpressionConfiguration(
        for module: IOSInsertableModule
    ) -> ExpressionModuleConfiguration? {
        guard module == .location else {
            return nil
        }

        return LocationDisplayInspectorPresenter
            .configuration(
                for: "legacyDisplay"
            )
    }

    private func removeInsertedModule(
        _ module: IOSInsertedModule,
        from region: CardRegion
    ) {
        applyRegionBindingMutation(
            regionBindingAdapter(for: region)
                .removeInsertedModule(module),
            for: region
        )
    }

    private func applyRegionBindingMutation(
        _ mutation:
            ConfigurationCenterRegionBindingMutation,
        for region: CardRegion
    ) {
        regionDraftStore = mutation.store

        if let previewText = mutation.previewText {
            session.updateRegionPreview(
                region: region,
                text: previewText
            )
        }
    }

    private func applySelectionUpdate(
        _ update:
            ConfigurationCenterSelectionUpdate
    ) {
        if ConfigurationCenterSelectionCoordinator
            .shouldDismissKeyboard(
                for: update,
                currentPanel: selectedPanel,
                currentRegion: session.state.selectedRegion
            ) {
            dismissKeyboard()
        }

        ConfigurationCenterSelectionApplier
            .apply(
                update,
                session: session,
                selectedPanel: &selectedPanel
            )
    }

    private var storageOptionBinding:
        Binding<ConfigurationStorageOption> {
        Binding(
            get: {
                ConfigurationCenterSessionBindingPresenter
                    .selectedStorageOption(session: session)
            },
            set: {
                ConfigurationCenterSessionBindingPresenter
                    .setSelectedStorageOption(
                        $0,
                        session: session
                    )
            }
        )
    }

    private var profileTitleBinding:
        Binding<String> {
        Binding(
            get: {
                ConfigurationCenterSessionBindingPresenter
                    .profileTitle(session: session)
            },
            set: {
                ConfigurationCenterSessionBindingPresenter
                    .setProfileTitle(
                        $0,
                        session: session
                    )
            }
        )
    }

    private var memoryWriteToggleBinding:
        Binding<Bool> {
        Binding(
            get: {
                ConfigurationCenterSessionBindingPresenter
                    .usesCustomMemoryWriteText(session: session)
            },
            set: {
                ConfigurationCenterSessionBindingPresenter
                    .setUsesCustomMemoryWriteText(
                        $0,
                        session: session
                    )
            }
        )
    }

    private var memoryWriteTextBinding:
        Binding<String> {
        Binding(
            get: {
                ConfigurationCenterSessionBindingPresenter
                    .customMemoryWriteText(session: session)
            },
            set: {
                ConfigurationCenterSessionBindingPresenter
                    .setCustomMemoryWriteText(
                        $0,
                        session: session
                    )
            }
        )
    }

    private var previewCompositionHelper:
        ConfigurationCenterPreviewCompositionHelper {

        ConfigurationCenterPreviewCompositionHelper(
            context:
                .init(
                    subject:
                        session.state.selectedSubject
                )
        )
    }

    private var regionEditCoordinator:
        ConfigurationCenterRegionEditCoordinator {
        ConfigurationCenterRegionEditCoordinator(
            previewHelper:
                previewCompositionHelper
        )
    }

    private func regionBindingAdapter(
        for region: CardRegion
    ) -> ConfigurationCenterRegionBindingAdapter {
        ConfigurationCenterRegionBindingAdapter(
            region: region,
            subject:
                session.state.selectedSubject,
            store: regionDraftStore,
            coordinator: regionEditCoordinator
        )
    }

    private var pageChromePresentation:
        ConfigurationCenterPageChromePresentation {
        ConfigurationCenterPageChromePresenter
            .presentation(
                selectedPanel: selectedPanel,
                session: session
            )
    }

    @ToolbarContentBuilder
    private var configurationToolbar: some ToolbarContent {
        ConfigurationCenterToolbarContent(
            presentation: pageChromePresentation,
            onReset: {
                dismissKeyboard()
                session.resetSelectedMemoryPreset()
            },
            onApply: {
                dismissKeyboard()
                session.applySelectedMemoryPreset()
            }
        )
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview("iOS 配置中心") {
    ConfigurationCenteriOSView()
}
#endif
