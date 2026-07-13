#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1OutputPageSurface: View {

    @Binding
    var outputTarget: V1IOSOutputTarget

    @Binding
    var mediaOutputMode: V1MediaOutputMode

    let availableAlbums: [PhotoAlbumOption]

    @Binding
    var selectedExistingAlbumIdentifier: String

    @Binding
    var newAlbumName: String

    let isLoadingAlbums: Bool
    let albumStatusMessage: String
    let onReloadAlbums: () -> Void
    let isSavingConfiguration: Bool
    let onSaveConfiguration: () -> Void

    @Binding
    var usesCustomMemoryWriteText: Bool

    @Binding
    var customMemoryWriteText: String

    let resolvedMemoryWriteText: String
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                pageHeader

                V1OutputSection(
                    outputTarget: $outputTarget,
                    availableAlbums: availableAlbums,
                    selectedExistingAlbumIdentifier: $selectedExistingAlbumIdentifier,
                    newAlbumName: $newAlbumName,
                    isLoadingAlbums: isLoadingAlbums,
                    albumStatusMessage: albumStatusMessage,
                    onReloadAlbums: onReloadAlbums
                )

                V1MemoryWriteSection(
                    usesCustomMemoryWriteText: $usesCustomMemoryWriteText,
                    customMemoryWriteText: $customMemoryWriteText,
                    resolvedMemoryWriteText: resolvedMemoryWriteText
                )
            }
            .padding(.top, 10)
            .padding(.bottom, 76)
            .v1AdaptiveScrollContent(
                horizontalPadding: 16
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onDismissKeyboard()
                }
        )
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            outputConfigurationFooter
        }
    }

    private var pageHeader: some View {
        V1PageHeader(
            "输出",
            subtitle: "选择结果图的保存位置，并管理写入图片说明。"
        )
    }

    private var outputConfigurationFooter: some View {
        V1OutputSaveConfigurationButton(
            isSaving: isSavingConfiguration,
            action: onSaveConfiguration
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            ConfigurationUI.appBackground
                .opacity(0.96)
                .ignoresSafeArea()
        )
    }
}

private struct V1OutputSaveConfigurationButton: View {

    let isSaving: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(
                    systemName:
                        isSaving
                        ? "hourglass"
                        : "square.and.arrow.down.fill"
                )
                .font(.caption.weight(.semibold))
                .frame(width: 16)

                Text(
                    isSaving
                    ? "正在保存"
                    : "保存到当前配置"
                )
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            }
            .v1CompactBottomPrimaryAction()
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .opacity(isSaving ? 0.72 : 1)
        .accessibilityLabel("保存到当前配置")
    }
}

private struct V1OutputSection: View {

    @Binding
    var outputTarget: V1IOSOutputTarget

    let availableAlbums: [PhotoAlbumOption]

    @Binding
    var selectedExistingAlbumIdentifier: String

    @Binding
    var newAlbumName: String

    let isLoadingAlbums: Bool
    let albumStatusMessage: String
    let onReloadAlbums: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            V1OutputCompactCard(title: "输出目标") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker(
                        "输出目标",
                        selection: presentedOutputTargetBinding
                    ) {
                        ForEach(selectableOutputTargets) { target in
                            Label(
                                target.title,
                                systemImage: target.symbolName
                            )
                            .tag(target)
                        }
                    }
                    .pickerStyle(.segmented)

                    targetSpecificControls
                }
            }
        }
    }

    private var presentedOutputTarget: V1IOSOutputTarget {
        outputTarget == .automatic ? .applePhotos : outputTarget
    }

    private var selectableOutputTargets: [V1IOSOutputTarget] {
        [.applePhotos, .existingAlbum, .newAlbum]
    }

    private var presentedOutputTargetBinding: Binding<V1IOSOutputTarget> {
        Binding(
            get: { presentedOutputTarget },
            set: { outputTarget = $0 }
        )
    }

    @ViewBuilder
    private var targetSpecificControls: some View {
        switch presentedOutputTarget {
        case .automatic,
             .applePhotos:
            EmptyView()

        case .existingAlbum:
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 10) {
                    Text("选择已有相册")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    Button(
                        isLoadingAlbums
                        ? "读取中"
                        : "刷新相册"
                    ) {
                        onReloadAlbums()
                    }
                    .font(.caption.weight(.semibold))
                    .disabled(isLoadingAlbums)
                }

                Picker(
                    "已有相册",
                    selection: $selectedExistingAlbumIdentifier
                ) {
                    if availableAlbums.isEmpty {
                        Text("暂无可用相册").tag("")
                    } else {
                        ForEach(availableAlbums) { album in
                            Text(album.title).tag(album.id)
                        }
                    }
                }
                .pickerStyle(.menu)
                .disabled(availableAlbums.isEmpty)

                Text("读取当前系统相册，只显示可直接加入结果图的相册。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                albumStatusView
            }

        case .newAlbum:
            VStack(alignment: .leading, spacing: 6) {
                TextField("相册名称", text: $newAlbumName)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .lineLimit(1)
                    .submitLabel(.done)
                    .configurationFieldChrome(isActive: true)

                Text("保存配置时创建相册；后续自动存入这个已有相册。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var albumStatusView: some View {
        if isLoadingAlbums {
            Label("正在读取系统相册", systemImage: "photo.on.rectangle")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if !albumStatusMessage.isEmpty {
            Text(albumStatusMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct V1MemoryWriteSection: View {

    @Binding
    var usesCustomMemoryWriteText: Bool

    @Binding
    var customMemoryWriteText: String

    let resolvedMemoryWriteText: String

    var body: some View {
        let presentation = MemoryWriteOptionPresenter.presentation(
            usesCustomText: usesCustomMemoryWriteText,
            resolvedText: resolvedMemoryWriteText
        )

        VStack(alignment: .leading, spacing: 8) {
            V1SectionHeading("写入与保留")

            V1OutputCompactCard(title: "保存选项") {
                VStack(alignment: .leading, spacing: 0) {
                    V1OutputRetentionRow(
                        systemImage: MemoMarkSymbol.photoMetadata.name,
                        tint: .blue,
                        title: "保留 EXIF 信息",
                        subtitle: "保留拍摄参数与元数据"
                    )

                    V1OutputDivider()

                    V1OutputRetentionRow(
                        systemImage: "livephoto",
                        tint: .pink,
                        title: "保留 Live Photo",
                        subtitle: "原格式输出时保留动态效果"
                    )

                    V1OutputDivider()

                    Toggle(isOn: writesMemoryInfoBinding) {
                        V1OutputRetentionLabel(
                            systemImage: MemoMarkSymbol.memoryContent.name,
                            tint: .green,
                            title: presentation.toggleTitle,
                            subtitle: presentation.toggleDescription
                        )
                    }
                    .toggleStyle(.switch)
                    .padding(
                        .vertical,
                        V1CompactInformationRowMetrics
                        .verticalPadding
                    )

                    if usesCustomMemoryWriteText {
                        TextField(
                            presentation.inputPlaceholder,
                            text: $customMemoryWriteText,
                            axis: .vertical
                        )
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .lineLimit(1...3)
                        .submitLabel(.done)
                        .configurationFieldChrome(isActive: true)
                        .padding(.bottom, 8)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(presentation.resolvedTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(presentation.resolvedDescription)
                            .font(.callout.weight(.semibold))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(presentation.fallbackNote)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    V1MemoryWriteExplanation()
                        .padding(.top, 8)
                }
            }
        }
    }

    private var writesMemoryInfoBinding: Binding<Bool> {
        Binding(
            get: {
                !usesCustomMemoryWriteText
            },
            set: { newValue in
                usesCustomMemoryWriteText = !newValue
            }
        )
    }
}

private struct V1OutputRetentionRow: View {

    let systemImage: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        V1OutputRetentionLabel(
            systemImage: systemImage,
            tint: tint,
            title: title,
            subtitle: subtitle
        )
        .padding(
            .vertical,
            V1CompactInformationRowMetrics.verticalPadding
        )
    }
}

private struct V1OutputRetentionLabel: View {

    let systemImage: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(
            alignment: .center,
            spacing:
                V1CompactInformationRowMetrics
                .contentSpacing
        ) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(
                    width: V1CompactInformationRowMetrics.iconSize,
                    height: V1CompactInformationRowMetrics.iconSize
                )
                .background(
                    RoundedRectangle(
                        cornerRadius:
                            V1CompactInformationRowMetrics
                            .iconCornerRadius,
                        style: .continuous
                    )
                    .fill(tint.opacity(0.11))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct V1OutputDivider: View {

    var body: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(height: 0.5)
            .padding(
                .leading,
                V1CompactInformationRowMetrics.iconSize
                + V1CompactInformationRowMetrics.contentSpacing
            )
    }
}

private struct V1MemoryWriteExplanation: View {

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.blue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text("写入图片说明")
                    .font(.callout.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Text("开启使用智能模块结果；关闭后使用手动录入内容。示例：记录于｜2026.07.01｜1岁2个月18天。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
            .fill(Color.blue.opacity(0.10))
        )
    }
}

private struct V1OutputCompactCard<Content: View>: View {

    let title: String
    @ViewBuilder var content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .v1CardChrome()
    }
}

private extension V1IOSOutputTarget {

    var symbolName: String {
        switch self {
        case .automatic:
            return "wand.and.stars"
        case .applePhotos:
                return MemoMarkSymbol.applePhotos.name
        case .existingAlbum:
            return MemoMarkSymbol.localStorage.name
        case .newAlbum:
            return MemoMarkSymbol.output.name
        }
    }

    var tint: Color {
        switch self {
        case .automatic:
            return .blue
        case .applePhotos:
            return .green
        case .existingAlbum:
            return .orange
        case .newAlbum:
            return .purple
        }
    }

    var summaryTitle: String {
        switch self {
        case .automatic:
            return "自动选择保存位置"
        case .applePhotos:
            return "存储到系统图库"
        case .existingAlbum:
            return "存储到已有相册"
        case .newAlbum:
            return "创建或复用新相册"
        }
    }
}

#endif
