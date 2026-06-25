#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

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
    private var selectedRegionConfigurationIDs: [CardRegion: String] = [:]

    @State
    private var regionDraftTexts: [String: String] = [:]

    @State
    private var regionInsertedModules: [String: [IOSInsertedModule]] = [:]

    @State
    private var regionContinuationTexts: [String: String] = [:]

    @State
    private var savedRegionConfigurationIDs: Set<String> = []

    @State
    private var regionConfigurationNames: [String: String] = [:]

    @State
    private var renamingRegionConfigurationID: String?

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let sidebarWidth =
                    min(
                        max(proxy.size.width * 0.28, 132),
                        188
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
        }
        .preferredColorScheme(.light)
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                sidebarHeader

                sidebarSubjectSection(
                    title: "人物",
                    addTitle: "新增人物",
                    subjects:
                        session.state.subjects.filter {
                            $0.relationship.role == "家庭"
                        }
                )

                sidebarSubjectSection(
                    title: "事件",
                    addTitle: "新增事件",
                    subjects:
                        session.state.subjects.filter {
                            $0.relationship.role == "旅行"
                        }
                )

                sidebarSection("卡片区域") {
                    sidebarAction(
                        title: "图标",
                        subtitle: "图标装饰",
                        systemImage: "person.crop.circle",
                        isSelected: selectedPanel == .card(.icon)
                    ) {
                        session.selectRegion(.icon)
                        selectedPanel = .card(.icon)
                    }

                    sidebarAction(
                        title: "记录",
                        subtitle: "区域 A",
                        systemImage: "camera.fill",
                        isSelected: selectedPanel == .card(.slotA)
                    ) {
                        session.selectRegion(.slotA)
                        selectedPanel = .card(.slotA)
                    }

                    sidebarAction(
                        title: "时间线",
                        subtitle: "区域 B",
                        systemImage: "calendar",
                        isSelected: selectedPanel == .card(.slotB)
                    ) {
                        session.selectRegion(.slotB)
                        selectedPanel = .card(.slotB)
                    }

                    sidebarAction(
                        title: "上下文",
                        subtitle: "区域 C",
                        systemImage: "scope",
                        isSelected: selectedPanel == .card(.slotC)
                    ) {
                        session.selectRegion(.slotC)
                        selectedPanel = .card(.slotC)
                    }

                    sidebarAction(
                        title: "记忆",
                        subtitle: "区域 D",
                        systemImage: "text.quote",
                        isSelected: selectedPanel == .card(.slotD)
                    ) {
                        session.selectRegion(.slotD)
                        selectedPanel = .card(.slotD)
                    }
                }

                sidebarSection("记忆模块") {
                    sidebarAction(
                        title: "写入记忆",
                        subtitle: "相册说明",
                        systemImage: "text.badge.checkmark",
                        isSelected: selectedPanel == .writeMemory
                    ) {
                        selectedPanel = .writeMemory
                    }
                }

                sidebarSection("输出内容") {
                    sidebarAction(
                        title: "输出",
                        subtitle: "处理过的图片",
                        systemImage: "square.and.arrow.down",
                        isSelected: selectedPanel == .output
                    ) {
                        selectedPanel = .output
                    }
                }

                sidebarSection("说明") {
                    sidebarAction(
                        title: "配置说明",
                        subtitle: "保存位置与原则",
                        systemImage: "questionmark.circle",
                        isSelected: selectedPanel == .configurationGuide
                    ) {
                        selectedPanel = .configurationGuide
                    }
                }

                sidebarFooter
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ConfigurationUI.appBackground)
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("资料库")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text("记忆对象与卡片配置")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 2)
    }

    private func sidebarSubjectSection(
        title: String,
        addTitle: String,
        subjects: [MemorySubject]
    ) -> some View {
        sidebarSection(title) {
            if subjects.isEmpty {
                Text("暂无内容")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            } else {
                ForEach(subjects) { subject in
                    sidebarAction(
                        title: subject.identity.displayName,
                        subtitle: subject.relationship.label,
                        systemImage: subjectIconName(subject),
                        isSelected:
                            selectedPanel == .subject
                            && subject.id
                            == session.state.selectedSubject?.id
                    ) {
                        session.selectSubject(subject)
                        selectedPanel = .subject
                    }
                }
            }

            sidebarAddAction(title: addTitle) {
                selectedPanel = .subject
            }
        }
    }

    private func sidebarAddAction(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 15)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func sidebarSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 7)

            VStack(spacing: 2) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sidebarAction(
        title: String,
        subtitle: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        isSelected
                        ? Color.accentColor
                        : Color.secondary
                    )
                    .frame(width: 15)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        isSelected
                        ? ConfigurationUI.selectedBackground
                        : Color.clear
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .opacity(0.45)

            VStack(alignment: .leading, spacing: 4) {
                Text("时间锚点")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text("不同记忆对象拥有不同锚点，也拥有不同的回忆角度。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("记忆对象资料库")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text("PhotoMemo 用锚点帮助你阅读回忆。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private var detailSurface: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                detailContent
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ConfigurationUI.panelBackground)
    }

    private var topConfigurationPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            profilePanel
            compactCardPreview
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 9)
        .background(ConfigurationUI.panelBackground)
        .overlay(
            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var profilePanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Label("总体配置", systemImage: "rectangle.stack.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .labelStyle(.iconOnly)

                profilePresetMenu
                    .frame(minWidth: 118, idealWidth: 146, maxWidth: 168, alignment: .leading)

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isRenamingProfile.toggle()
                    }
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("重命名")

                Button {
                    session.resetSelectedMemoryPreset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption.weight(.semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("重置")

                Spacer(minLength: 0)

                Button {
                    session.applySelectedMemoryPreset()
                } label: {
                    Label(
                        session.selectedMemoryPresetIsApplied
                        ? "已生效"
                        : "保存并生效",
                        systemImage:
                            session.selectedMemoryPresetIsApplied
                            ? "checkmark.circle.fill"
                            : "checkmark.circle"
                    )
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .font(.caption.weight(.semibold))

            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 1) {
                    Text("自动输出")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.currentConfigurationLabel)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.86))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 0)

                Text(session.currentMemoryPresetSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            if isRenamingProfile {
                TextField(
                    "配置名称",
                    text: Binding(
                        get: {
                            session.currentMemoryPresetTitle
                        },
                        set: {
                            session.updateSelectedMemoryPresetTitle($0)
                        }
                    )
                )
                .textFieldStyle(.plain)
                .font(.caption)
                .configurationFieldChrome(isActive: true)
                .transition(
                    .opacity
                        .combined(with: .move(edge: .top))
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ConfigurationUI.faintHairline)
        )
        .animation(
            .easeInOut(duration: 0.16),
            value: isRenamingProfile
        )
    }

    private var profilePresetMenu: some View {
        Menu {
            ForEach(session.state.memoryPresets) { preset in
                Button {
                    session.selectMemoryPreset(preset)
                } label: {
                    HStack {
                        Text(preset.title)

                        if preset.id == session.state.selectedMemoryPreset?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(session.currentMemoryPresetTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.085))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.16))
            )
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedPanel {
        case .subject:
            subjectDetail

        case .card:
            cardDetail

        case .writeMemory:
            IOSDetailPanel(
                title: "写入记忆",
                systemImage: "text.badge.checkmark"
            ) {
                memoryWritePanel
            }

        case .output:
            IOSDetailPanel(
                title: "输出",
                systemImage: "square.and.arrow.down"
            ) {
                outputSelection
            }

        case .configurationGuide:
            IOSDetailPanel(
                title: "配置说明",
                systemImage: "questionmark.circle"
            ) {
                configurationGuide
            }
        }
    }

    private var subjectDetail: some View {
        IOSDetailPanel(
            title: "记忆对象",
            systemImage: "person.fill",
            subtitle: "身份、关系、时间锚点与行为映射"
        ) {
            MemorySubjectEditorView(session: session)
        }
    }

    private var cardDetail: some View {
        VStack(alignment: .leading, spacing: 8) {
            activeRegionEditor

            if shouldShowInsertableModules {
                fixedInsertableModuleLibrary
            }
        }
    }

    private var compactCardPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("当前配置预览")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            IOSMacStyleMemoryCardPreview(session: session)
                .frame(height: 152)

            regionStrip
        }
        .padding(8)
        .configurationPanelChrome()
    }

    private var activeRegionEditor: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(
                    "\(session.state.selectedRegion.semanticTitle)配置",
                    systemImage: inspectorSystemImage
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

                Spacer(minLength: 0)

                Text("随预览实时刷新")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            activeRegionEditorContent
            .id(session.state.selectedRegion)
            .transition(
                .opacity
                    .combined(with: .move(edge: .trailing))
            )
        }
        .padding(.top, 2)
        .animation(
            .easeInOut(duration: 0.16),
            value: session.state.selectedRegion
        )
    }

    @ViewBuilder
    private var activeRegionEditorContent: some View {
        switch session.state.selectedRegion {
        case .icon:
            IconLibraryView(session: session)
                .padding(8)
                .configurationPanelChrome()
        case .badge:
            BadgeLibraryView(session: session)
                .padding(8)
                .configurationPanelChrome()
        case .slotA,
             .slotB,
             .slotC,
             .slotD:
            IOSRegionComposer(
                region: session.state.selectedRegion,
                configurationOptions:
                    configurationOptions(
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
                    savedRegionConfigurationIDs
                    .contains(
                        activeConfigurationID(
                            for: session.state.selectedRegion
                        )
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
                    session.state.selectedRegion == .slotD,
                onSaveConfiguration: {
                    savedRegionConfigurationIDs
                        .insert(
                            activeConfigurationID(
                                for: session.state.selectedRegion
                            )
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

    private var regionStrip: some View {
        HStack(spacing: 0) {
            regionStripButton(
                .slotA,
                title: "记录",
                systemImage: "camera.fill"
            )

            regionStripButton(
                .slotB,
                title: "时间线",
                systemImage: "calendar"
            )

            regionStripButton(
                .slotC,
                title: "上下文",
                systemImage: "scope"
            )

            regionStripButton(
                .slotD,
                title: "记忆",
                systemImage: "text.quote"
            )
        }
        .padding(4)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ConfigurationUI.hairline)
        )
    }

    private func regionStripButton(
        _ region: CardRegion,
        title: String,
        systemImage: String
    ) -> some View {
        Button {
            session.selectRegion(region)
            selectedPanel = .card(region)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(
                region == session.state.selectedRegion
                ? Color.accentColor
                : Color.secondary
            )
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        region == session.state.selectedRegion
                        ? ConfigurationUI.selectedBackground
                        : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var memoryWritePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("保存处理过的图片时，将这段文字写入相册说明，便于在 Apple Photos 中搜索和回看。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(
                "自定义写入内容",
                isOn: memoryWriteToggleBinding
            )
            .font(.subheadline.weight(.semibold))

            if session.usesCustomMemoryWriteText {
                TextField(
                    "输入要写入图库的记忆说明",
                    text: memoryWriteTextBinding,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(1...3)
                .configurationFieldChrome(isActive: true)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "text.magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 15)

                VStack(alignment: .leading, spacing: 3) {
                    Text("实际写入")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.resolvedMemoryWriteText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.82))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .configurationPanelChrome()
        }
        .padding(10)
        .configurationPanelChrome()
    }

    private var fixedInsertableModuleLibrary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(
                    "可插入模块",
                    systemImage: "tag.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

                Spacer(minLength: 0)

                Menu {
                    ForEach(additionalInsertableModules) { module in
                        Button {
                            insertModuleIntoCurrentRegion(module)
                        } label: {
                            Label(
                                module.title,
                                systemImage: module.systemImage
                            )
                        }
                    }
                } label: {
                    Label("更多模块", systemImage: "chevron.down.circle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(visibleInsertableModules) { module in
                        Button {
                            insertModuleIntoCurrentRegion(module)
                        } label: {
                            insertableModuleChip(module)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }

            Text("默认展示当前最常用的 6 个模块。更多 EXIF 字段可从下拉栏插入；若照片中没有该信息，输出保持为空。")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(9)
        .configurationPanelChrome()
    }

    private func insertableModuleChip(
        _ module: IOSInsertableModule
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: module.systemImage)
                .font(.caption2.weight(.semibold))

            Text(module.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.085))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.16))
        )
    }

    private var outputSelection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "photo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 3) {
                    Text("输出结果")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.selectedOutputOption.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.86))
                }
            }

            Picker(
                "存放地点",
                selection: storageOptionBinding
            ) {
                ForEach(ConfigurationStorageOption.allCases) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "folder")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 3) {
                    Text("图片存放地点")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.selectedStorageOption.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.86))
                }
            }

            Text(session.selectedStorageOption.note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .configurationPanelChrome()
    }

    private var configurationGuide: some View {
        VStack(alignment: .leading, spacing: 10) {
            guideCard(
                title: "四个自定义区域",
                note: "插入内容进入当前选中的区域，不走隐式兜底。",
                systemImage: "rectangle.and.pencil.and.ellipsis"
            )

            guideCard(
                title: "记忆日期与智能结果",
                note: "时间锚点和照片时间会组合成可复用结果。",
                systemImage: "calendar.badge.clock"
            )

            guideCard(
                title: "输出与相册保存",
                note: "默认生成处理过的新图片，原图保持不变。",
                systemImage: "square.and.arrow.down"
            )

            guideCard(
                title: "关于 PhotoMemo",
                note: "帮助用户阅读回忆，而不只是保存照片。",
                systemImage: "info.circle"
            )
        }
    }

    private func guideCard(
        title: String,
        note: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(11)
        .configurationPanelChrome()
    }

    private var inspectorSystemImage: String {
        switch session.state.selectedRegion {
        case .subject:
            return "person.fill"
        case .icon:
            return "person.crop.circle"
        case .badge:
            return "camera.fill"
        case .slotA:
            return "camera.fill"
        case .slotB:
            return "calendar"
        case .slotC:
            return "scope"
        case .slotD:
            return "text.quote"
        }
    }

    private func subjectIconName(
        _ subject: MemorySubject
    ) -> String {
        subject.decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "person.fill"
    }

    private var shouldShowInsertableModules: Bool {
        CardRegion.memoryCardRegions
            .contains(session.state.selectedRegion)
    }

    private var visibleInsertableModules: [IOSInsertableModule] {
        if session.state.selectedRegion == .slotD {
            return [
                .subjectNickname,
                .smartTime,
                .captureDate,
                .captureTime,
                .location,
                .custom
            ]
        }

        return [
            .cameraModel,
            .captureDate,
            .captureTime,
            .captureSummary,
            .location,
            .custom
        ]
    }

    private var additionalInsertableModules: [IOSInsertableModule] {
        IOSInsertableModule.allCases
            .filter {
                !visibleInsertableModules.contains($0)
            }
    }

    private func regionTextBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                let configurationID =
                    activeConfigurationID(for: region)

                return regionDraftTexts[configurationID]
                ?? defaultText(
                    for: region,
                    configurationID: configurationID
                )
            },
            set: { newValue in
                regionDraftTexts[
                    activeConfigurationID(for: region)
                ] = newValue
                refreshRegionPreview(region)
            }
        )
    }

    private func regionModulesBinding(
        for region: CardRegion
    ) -> Binding<[IOSInsertedModule]> {
        Binding(
            get: {
                regionInsertedModules[
                    activeConfigurationID(for: region)
                ] ?? []
            },
            set: {
                regionInsertedModules[
                    activeConfigurationID(for: region)
                ] = $0
                refreshRegionPreview(region)
            }
        )
    }

    private func regionContinuationTextBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionContinuationTexts[
                    activeConfigurationID(for: region)
                ] ?? ""
            },
            set: {
                regionContinuationTexts[
                    activeConfigurationID(for: region)
                ] = $0
                refreshRegionPreview(region)
            }
        )
    }

    private func selectedRegionConfigurationBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                activeConfigurationID(for: region)
            },
            set: { newValue in
                selectedRegionConfigurationIDs[region] = newValue
                refreshRegionPreview(region)
            }
        )
    }

    private func regionConfigurationNameBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                let configurationID =
                    activeConfigurationID(for: region)

                return regionConfigurationNames[configurationID]
                ?? defaultConfigurationTitle(
                    for: region,
                    configurationID: configurationID
                )
            },
            set: { newValue in
                regionConfigurationNames[
                    activeConfigurationID(for: region)
                ] = newValue
            }
        )
    }

    private func renamingRegionConfigurationBinding(
        for region: CardRegion
    ) -> Binding<Bool> {
        Binding(
            get: {
                renamingRegionConfigurationID
                == activeConfigurationID(for: region)
            },
            set: { isRenaming in
                renamingRegionConfigurationID =
                    isRenaming
                    ? activeConfigurationID(for: region)
                    : nil
            }
        )
    }

    private func insertModuleIntoCurrentRegion(
        _ module: IOSInsertableModule
    ) {
        let region = session.state.selectedRegion

        guard CardRegion.memoryCardRegions.contains(region) else {
            return
        }

        let configurationID =
            activeConfigurationID(for: region)

        if regionDraftTexts[configurationID] == nil {
            regionDraftTexts[configurationID] =
                defaultText(
                    for: region,
                    configurationID: configurationID
                )
        }

        let insertedModule =
            IOSInsertedModule(
                title: module.title,
                value: moduleValue(module),
                systemImage: module.systemImage
            )

        var currentModules =
            regionInsertedModules[configurationID] ?? []
        currentModules.append(insertedModule)
        regionInsertedModules[configurationID] = currentModules
        refreshRegionPreview(region)
    }

    private func removeInsertedModule(
        _ module: IOSInsertedModule,
        from region: CardRegion
    ) {
        regionInsertedModules[
            activeConfigurationID(for: region),
            default: []
        ]
            .removeAll {
                $0.id == module.id
            }
        refreshRegionPreview(region)
    }

    private func refreshRegionPreview(
        _ region: CardRegion
    ) {
        let configurationID =
            activeConfigurationID(for: region)

        let baseText =
            (regionDraftTexts[configurationID]
             ?? defaultText(
                for: region,
                configurationID: configurationID
             ))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let moduleText =
            (regionInsertedModules[configurationID] ?? [])
            .map(\.value)
            .filter {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            }
            .joined(separator: " ")

        let continuationText =
            (regionContinuationTexts[configurationID] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let composedText =
            [baseText, moduleText, continuationText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        session.updateRegionPreview(
            region: region,
            text: composedText
        )
    }

    private func activeConfigurationID(
        for region: CardRegion
    ) -> String {
        selectedRegionConfigurationIDs[region]
        ?? defaultConfigurationID(for: region)
    }

    private func defaultConfigurationID(
        for region: CardRegion
    ) -> String {
        switch region {
        case .slotA:
            return "recorder.configuration1"
        case .slotB:
            return "timeline.configuration1"
        case .slotC:
            return "context.configuration1"
        case .slotD:
            return "memory.configuration1"
        case .subject,
             .icon,
             .badge:
            return "\(region.rawValue).configuration1"
        }
    }

    private func configurationOptions(
        for region: CardRegion
    ) -> [IOSRegionConfigurationOption] {
        switch region {
        case .slotA:
            return [
                option(region, "recorder.configuration1", "配置 1：记录者信息"),
                option(region, "recorder.configuration2", "配置 2：自定义记录"),
                option(region, "recorder.configuration3", "配置 3：自定义记录")
            ]
        case .slotB:
            return [
                option(region, "timeline.configuration1", "配置 1：拍摄时间"),
                option(region, "timeline.configuration2", "配置 2：日期"),
                option(region, "timeline.configuration3", "配置 3：自定义时间线")
            ]
        case .slotC:
            return [
                option(region, "context.configuration1", "配置 1：拍摄参数概要"),
                option(region, "context.configuration2", "配置 2：位置"),
                option(region, "context.configuration3", "配置 3：自定义上下文")
            ]
        case .slotD:
            return [
                option(region, "memory.configuration1", "配置 1：当天多大"),
                option(region, "memory.configuration2", "配置 2：自定义记忆"),
                option(region, "memory.configuration3", "配置 3：自定义记忆")
            ]
        case .subject,
             .icon,
             .badge:
            return []
        }
    }

    private func option(
        _ region: CardRegion,
        _ id: String,
        _ defaultTitle: String
    ) -> IOSRegionConfigurationOption {
        IOSRegionConfigurationOption(
            id: id,
            title:
                regionConfigurationNames[id]
                ?? defaultTitle
        )
    }

    private func defaultConfigurationTitle(
        for region: CardRegion,
        configurationID: String
    ) -> String {
        configurationOptions(for: region)
            .first {
                $0.id == configurationID
            }?
            .title
        ?? "自定义配置"
    }

    private func defaultText(
        for region: CardRegion,
        configurationID: String
    ) -> String {
        ConfigurationSession.defaultPreviewText(
            for: region,
            templateID: configurationID,
            subject: session.state.selectedSubject
        )
    }

    private var selectedMemoryPresetBinding:
        Binding<MemoryPreset.ID> {
        Binding(
            get: {
                session.state.selectedMemoryPreset?.id
                ?? session.state.memoryPresets.first?.id
                ?? UUID()
            },
            set: { presetID in
                guard
                    let preset =
                        session.state.memoryPresets.first(
                            where: { $0.id == presetID }
                        )
                else {
                    return
                }

                session.selectMemoryPreset(preset)
            }
        )
    }

    private var storageOptionBinding:
        Binding<ConfigurationStorageOption> {
        Binding(
            get: {
                session.selectedStorageOption
            },
            set: {
                session.selectedStorageOption = $0
            }
        )
    }

    private var memoryWriteToggleBinding:
        Binding<Bool> {
        Binding(
            get: {
                session.usesCustomMemoryWriteText
            },
            set: {
                session.usesCustomMemoryWriteText = $0
            }
        )
    }

    private var memoryWriteTextBinding:
        Binding<String> {
        Binding(
            get: {
                session.customMemoryWriteText
            },
            set: {
                session.customMemoryWriteText = $0
            }
        )
    }

    private func moduleValue(
        _ module: IOSInsertableModule
    ) -> String {
        switch module {
        case .subjectNickname:
            return session.state.selectedSubject?.identity.shortName
            ?? session.state.selectedSubject?.identity.displayName
            ?? "Tutu"
        case .smartTime:
            return smartTimeResult
        case .captureDate:
            return "2026.05.24"
        case .captureTime:
            return "14:33:13"
        case .cameraMaker:
            return ""
        case .cameraModel:
            return "iPhone 17 Pro Max"
        case .lensModel:
            return ""
        case .focalLength:
            return ""
        case .aperture:
            return ""
        case .shutterSpeed:
            return ""
        case .iso:
            return ""
        case .exposureBias:
            return ""
        case .meteringMode:
            return ""
        case .flash:
            return ""
        case .whiteBalance:
            return ""
        case .captureSummary:
            return "20mm f/1.9 1/117s ISO80"
        case .location:
            return "河南 · 商丘"
        case .altitude:
            return ""
        case .imageSize:
            return ""
        case .orientation:
            return ""
        case .fileFormat:
            return ""
        case .custom:
            return "自定义内容"
        }
    }

    private var smartTimeResult: String {
        guard
            let subject = session.state.selectedSubject,
            let anchor =
                subject.timeAnchors.first(where: {
                    $0.title == subject.behavior.primaryAnchor
                })
                ?? subject.timeAnchors.first
        else {
            return "未设置时间"
        }

        let captureDate =
            Calendar.current.date(
                from:
                    DateComponents(
                        year: 2026,
                        month: 5,
                        day: 24
                    )
            ) ?? Date()

        let components =
            Calendar.current.dateComponents(
                [.year, .month, .day],
                from: anchor.date,
                to: captureDate
            )

        let years = max(components.year ?? 0, 0)
        let months = max(components.month ?? 0, 0)
        let days = max(components.day ?? 0, 0)

        if years > 0 {
            return "\(years)岁\(months)个月\(days)天"
        }

        if months > 0 {
            return "\(months)个月\(days)天"
        }

        return "\(days)天"
    }
}

private struct IOSMacStyleMemoryCardPreview: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                previewTextRegion(.slotA, style: .primary)
                previewTextRegion(.slotB, style: .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            decorationRegion

            VStack(alignment: .leading, spacing: 10) {
                previewTextRegion(.slotC, style: .primary)
                previewTextRegion(.slotD, style: .memory)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.white,
                    ConfigurationUI.panelBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(
            color: ConfigurationUI.cardShadow,
            radius: 14,
            y: 6
        )
    }

    private var decorationRegion: some View {
        HStack(spacing: 11) {
            Button {
                session.selectRegion(.icon)
            } label: {
                Image(systemName: selectedIconName)
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        session.state.selectedRegion == .icon
                        ? Color.accentColor
                        : Color.secondary.opacity(0.78)
                    )
                    .frame(width: 40, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                session.state.selectedRegion == .icon
                                ? ConfigurationUI.selectedBackground
                                : Color.clear
                            )
                    )
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(ConfigurationUI.hairline)
                .frame(width: 1, height: 56)
        }
        .padding(.horizontal, 13)
    }

    private func previewTextRegion(
        _ region: CardRegion,
        style: IOSPreviewTextStyle
    ) -> some View {
        Button {
            session.selectRegion(region)
        } label: {
            Text(session.previewText(for: region))
                .font(style.font)
                .foregroundStyle(
                    region == session.state.selectedRegion
                    ? Color.accentColor
                    : style.color
                )
                .lineLimit(style.lineLimit)
                .minimumScaleFactor(0.72)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 34,
                    alignment: .leading
                )
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            region == session.state.selectedRegion
                            ? ConfigurationUI.selectedBackground
                            : Color.clear
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var selectedIconName: String {
        session.state.selectedSubject?
            .decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "person.fill"
    }
}

private enum IOSPreviewTextStyle {
    case primary
    case secondary
    case memory

    var font: Font {
        switch self {
        case .primary:
            return .subheadline.weight(.semibold)
        case .secondary:
            return .caption.weight(.medium)
        case .memory:
            return .headline.weight(.semibold)
        }
    }

    var color: Color {
        switch self {
        case .primary:
            return Color.primary.opacity(0.86)
        case .secondary:
            return Color.secondary
        case .memory:
            return Color.primary
        }
    }

    var lineLimit: Int {
        switch self {
        case .memory:
            return 2
        case .primary,
             .secondary:
            return 1
        }
    }
}

private struct IOSDetailPanel<Content: View>: View {

    let title: String
    let systemImage: String
    let subtitle: String?
    @ViewBuilder var content: Content

    init(
        title: String,
        systemImage: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }

            content
        }
        .padding(14)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ConfigurationUI.faintHairline)
        )
    }
}

private struct IOSRegionComposer: View {

    let region: CardRegion
    let configurationOptions: [IOSRegionConfigurationOption]
    @Binding var selectedConfigurationID: String
    @Binding var configurationName: String
    @Binding var isRenamingConfiguration: Bool
    let isSaved: Bool
    @Binding var text: String
    @Binding var continuationText: String
    @Binding var modules: [IOSInsertedModule]
    let showsMemorySystemModules: Bool
    let onSaveConfiguration: () -> Void
    let onDeleteModule: (IOSInsertedModule) -> Void

    @FocusState
    private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            configurationControls

            if isRenamingConfiguration {
                TextField(
                    "配置名称",
                    text: $configurationName
                )
                .textFieldStyle(.plain)
                .font(.caption)
                .configurationFieldChrome(isActive: true)
                .transition(
                    .opacity
                        .combined(with: .move(edge: .top))
                )
            }

            compositionField

            if showsMemorySystemModules {
                memorySystemModuleStrip
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ConfigurationUI.faintHairline)
        )
        .onTapGesture {
            isFocused = false
        }
    }

    private var configurationControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Menu {
                    ForEach(configurationOptions) { option in
                        Button {
                            selectedConfigurationID = option.id
                        } label: {
                            HStack {
                                Text(option.title)

                                if option.id == selectedConfigurationID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedConfigurationTitle)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.085))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.16))
                    )
                }
                .frame(maxWidth: 210, alignment: .leading)

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isRenamingConfiguration.toggle()
                    }
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    Image(
                        systemName:
                            isSaved
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .font(.caption2.weight(.semibold))

                    Text(isSaved ? "已生效" : "未保存")
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(
                    isSaved
                    ? Color.accentColor
                    : Color.secondary
                )
            }

            HStack(spacing: 8) {
                Text("修改后保存为当前区域配置。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)

                Button {
                    onSaveConfiguration()
                } label: {
                    Label(
                        isSaved ? "已保存" : "保存配置",
                        systemImage:
                            isSaved
                            ? "checkmark.circle.fill"
                            : "checkmark.circle"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .font(.caption.weight(.semibold))
    }

    private var compositionField: some View {
        HStack(alignment: .top, spacing: 8) {
            TextField(
                "输入或补充 \(region.semanticTitle)",
                text: $text,
                axis: .vertical
            )
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(.subheadline)
            .lineLimit(1...3)
            .frame(minWidth: 108, maxWidth: .infinity, alignment: .leading)
            .layoutPriority(modules.isEmpty ? 1 : 0.8)

            if !modules.isEmpty {
                inlineModuleScroller
                    .frame(minWidth: 118, maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1.2)

                TextField(
                    "继续输入",
                    text: $continuationText,
                    axis: .vertical
                )
                .focused($isFocused)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(1...3)
                .frame(minWidth: 82, maxWidth: .infinity, alignment: .leading)
                .layoutPriority(0.9)
            }
        }
        .padding(10)
        .configurationFieldChrome(isActive: isFocused)
    }

    private var inlineModuleScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(modules) { module in
                    HStack(spacing: 4) {
                        Image(systemName: module.systemImage)
                            .font(.caption2.weight(.semibold))

                        Text(module.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)

                        Button {
                            onDeleteModule(module)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.accentColor.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.accentColor.opacity(0.18))
                    )
                }
            }
            .padding(.vertical, 1)
        }
    }

    private var selectedConfigurationTitle: String {
        configurationOptions
            .first(where: { $0.id == selectedConfigurationID })?
            .title
        ?? configurationName
    }

    private var memorySystemModuleStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("系统模块")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 6) {
                systemModuleChip(title: "对象昵称", value: "Subject")
                systemModuleChip(title: "智能时间", value: "Smart")
                systemModuleChip(title: "时间锚点", value: "Anchor")
            }
        }
    }

    private func systemModuleChip(
        title: String,
        value: String
    ) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.secondary.opacity(0.08))
            )
    }
}

private enum IOSConfigurationPanel:
    Hashable {

    case subject
    case card(CardRegion)
    case writeMemory
    case output
    case configurationGuide
}

private struct IOSInsertedModule:
    Identifiable,
    Hashable {

    let id = UUID()
    let title: String
    let value: String
    let systemImage: String
}

private struct IOSRegionConfigurationOption:
    Identifiable,
    Hashable {

    let id: String
    let title: String
}

private enum IOSInsertableModule:
    String,
    CaseIterable,
    Identifiable {

    case subjectNickname
    case smartTime
    case captureDate
    case captureTime
    case cameraMaker
    case cameraModel
    case lensModel
    case focalLength
    case aperture
    case shutterSpeed
    case iso
    case exposureBias
    case meteringMode
    case flash
    case whiteBalance
    case captureSummary
    case location
    case altitude
    case imageSize
    case orientation
    case fileFormat
    case custom

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .subjectNickname:
            return "对象昵称"
        case .smartTime:
            return "智能时间"
        case .captureDate:
            return "拍摄日期"
        case .captureTime:
            return "拍摄时间"
        case .cameraMaker:
            return "设备厂商"
        case .cameraModel:
            return "设备型号"
        case .lensModel:
            return "镜头型号"
        case .focalLength:
            return "焦距"
        case .aperture:
            return "光圈"
        case .shutterSpeed:
            return "快门"
        case .iso:
            return "ISO"
        case .exposureBias:
            return "曝光补偿"
        case .meteringMode:
            return "测光模式"
        case .flash:
            return "闪光灯"
        case .whiteBalance:
            return "白平衡"
        case .captureSummary:
            return "参数概要"
        case .location:
            return "位置"
        case .altitude:
            return "海拔"
        case .imageSize:
            return "图片尺寸"
        case .orientation:
            return "方向"
        case .fileFormat:
            return "文件格式"
        case .custom:
            return "自定义"
        }
    }

    var systemImage: String {
        switch self {
        case .subjectNickname:
            return "person.fill"
        case .smartTime:
            return "calendar.badge.clock"
        case .captureDate:
            return "calendar"
        case .captureTime:
            return "clock"
        case .cameraMaker:
            return "apple.logo"
        case .cameraModel:
            return "camera.fill"
        case .lensModel:
            return "camera.macro"
        case .focalLength:
            return "scope"
        case .aperture:
            return "camera.aperture"
        case .shutterSpeed:
            return "timer"
        case .iso:
            return "dial.low"
        case .exposureBias:
            return "plusminus"
        case .meteringMode:
            return "camera.metering.center.weighted"
        case .flash:
            return "bolt.fill"
        case .whiteBalance:
            return "sun.max"
        case .captureSummary:
            return "camera.metering.center.weighted"
        case .location:
            return "location.fill"
        case .altitude:
            return "mountain.2.fill"
        case .imageSize:
            return "rectangle.inset.filled"
        case .orientation:
            return "rectangle.rotate"
        case .fileFormat:
            return "doc.fill"
        case .custom:
            return "plus.circle"
        }
    }

    var token: String {
        switch self {
        case .subjectNickname:
            return "{{subject_nickname}}"
        case .smartTime:
            return "{{smart_time_result}}"
        case .captureDate:
            return "{{capture_date}}"
        case .captureTime:
            return "{{capture_time}}"
        case .cameraMaker:
            return "{{camera_make}}"
        case .cameraModel:
            return "{{camera_model}}"
        case .lensModel:
            return "{{lens_model}}"
        case .focalLength:
            return "{{focal_length}}"
        case .aperture:
            return "{{aperture}}"
        case .shutterSpeed:
            return "{{shutter_speed}}"
        case .iso:
            return "{{iso}}"
        case .exposureBias:
            return "{{exposure_bias}}"
        case .meteringMode:
            return "{{metering_mode}}"
        case .flash:
            return "{{flash}}"
        case .whiteBalance:
            return "{{white_balance}}"
        case .captureSummary:
            return "{{capture_parameters_summary}}"
        case .location:
            return "{{location}}"
        case .altitude:
            return "{{altitude}}"
        case .imageSize:
            return "{{image_size}}"
        case .orientation:
            return "{{orientation}}"
        case .fileFormat:
            return "{{file_format}}"
        case .custom:
            return "{{custom}}"
        }
    }
}

#Preview("iOS 配置中心") {
    ConfigurationCenteriOSView()
}
#endif
