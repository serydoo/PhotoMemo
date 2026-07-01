#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCardConfigurationComponentDock: View {

    let isModuleLibraryExpanded: Binding<Bool>
    let visibleInsertableModules: [CenterInsertableModule]
    let selectedRegionSemanticTitle: String
    let currentOutputPreview: String
    let selectedOutputOptionTitle: String
    let selectedStorageOptionTitle: String
    let selectedStorageOptionNote: String
    let memoryWriteDescription: String
    let usesCustomMemoryWriteText: Bool
    let memoryWritePlaceholder: String
    let memoryWritePreviewTitle: String
    let resolvedMemoryWriteText: String
    let storageOptionBinding: Binding<ConfigurationStorageOption>
    let memoryWriteToggleBinding: Binding<Bool>
    let memoryWriteTextBinding: Binding<String>
    let onInsertModule: (CenterInsertableModule) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    dockSection(
                        title: "智能模块",
                        systemImage: "text.badge.checkmark"
                    ) {
                        memoryWritePanel
                    }

                    dockSection(
                        title: "可插入模块",
                        systemImage: "tag.fill"
                    ) {
                        insertableModuleLibrary
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    dockSection(
                        title: "当前配置展示",
                        systemImage: "checkmark.seal"
                    ) {
                        currentConfigurationPreview
                    }

                    dockSection(
                        title: "输出",
                        systemImage: "square.and.arrow.down"
                    ) {
                        outputSelection
                    }
                }
                .frame(width: 220)
            }

            dockSection(
                title: "配置说明",
                systemImage: "questionmark.circle"
            ) {
                configurationGuide
            }
        }
        .frame(width: 590, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var insertableModuleLibrary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("常用模块优先显示")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isModuleLibraryExpanded.wrappedValue.toggle()
                    }
                } label: {
                    Label(
                        isModuleLibraryExpanded.wrappedValue ? "收起" : "展开",
                        systemImage:
                            isModuleLibraryExpanded.wrappedValue
                            ? "chevron.up"
                            : "chevron.down"
                    )
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderless)
                .font(.caption.weight(.semibold))
            }

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 112),
                        spacing: 7
                    )
                ],
                alignment: .leading,
                spacing: 7
            ) {
                ForEach(visibleInsertableModules) { module in
                    Button {
                        onInsertModule(module)
                    } label: {
                        centerModuleChip(module)
                    }
                    .buttonStyle(.plain)
                    .help("插入到当前选中的\(selectedRegionSemanticTitle)区域")
                }
            }

            Text("照片信息模块包含常见 Apple 设备 EXIF 项；后续会根据用户使用频率自动靠前。")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var currentConfigurationPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(currentOutputPreview)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.primary)
                .lineLimit(3)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("展示当前选中区域与当前记忆预设下的实时配置结果。")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .configurationPanelChrome()
    }

    private var outputSelection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "photo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text("输出结果")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(selectedOutputOptionTitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.84))
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
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "folder")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text("图片存放地点")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(selectedStorageOptionTitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.84))
                }
            }

            Text(selectedStorageOptionNote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .configurationPanelChrome()
    }

    private var configurationGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                guideCard(
                    title: "四个自定义区域",
                    note: "插入内容进入当前选中的区域，不走隐式兜底。",
                    systemImage: "rectangle.and.pencil.and.ellipsis"
                )

                guideCard(
                    title: "记忆日期与智能结果",
                    note: "时间锚点和照片时间会组合成 1 个智能结果，并可插入任意区域。",
                    systemImage: "calendar.badge.clock"
                )
            }

            HStack(spacing: 8) {
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
    }

    private var memoryWritePanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(memoryWriteDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            memoryWriteToggle

            if usesCustomMemoryWriteText {
                TextField(
                    memoryWritePlaceholder,
                    text: memoryWriteTextBinding,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(1...3)
                .configurationFieldChrome(isActive: true)
            }

            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "text.magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(memoryWritePreviewTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(resolvedMemoryWriteText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.82))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(9)
            .configurationPanelChrome()
        }
        .padding(10)
        .configurationPanelChrome()
    }

    private var memoryWriteToggle: some View {
        Toggle(
            ConfigurationCenterSessionBindingPresenter
                .memoryWriteToggleTitle,
            isOn: memoryWriteToggleBinding
        )
        #if os(macOS)
        .toggleStyle(.checkbox)
        #endif
        .font(.caption.weight(.semibold))
    }

    private func dockSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func centerModuleChip(
        _ module: CenterInsertableModule
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
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.085))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.accentColor.opacity(0.16))
        )
    }

    private func guideCard(
        title: String,
        note: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .configurationPanelChrome()
    }
}
#endif
