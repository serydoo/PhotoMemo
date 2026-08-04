#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

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
    let configurationStatus: V1ConfigurationStatus
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

                V1OutputResultSection(
                    mediaOutputMode: $mediaOutputMode,
                    usesCustomMemoryWriteText:
                        $usesCustomMemoryWriteText,
                    customMemoryWriteText: $customMemoryWriteText,
                    resolvedMemoryWriteText: resolvedMemoryWriteText
                )

                V1OutputSection(
                    outputTarget: $outputTarget,
                    availableAlbums: availableAlbums,
                    selectedExistingAlbumIdentifier: $selectedExistingAlbumIdentifier,
                    newAlbumName: $newAlbumName,
                    isLoadingAlbums: isLoadingAlbums,
                    albumStatusMessage: albumStatusMessage,
                    onReloadAlbums: onReloadAlbums
                )
            }
            .padding(.top, 10)
            .padding(.bottom, 76)
            .v1AdaptiveScrollContent(
                horizontalPadding: ConfigurationUI.contentColumnPadding
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
            "保存这段回忆",
            subtitle: "决定最后留下的照片，也选择它回到哪里。"
        )
    }

    private var outputConfigurationFooter: some View {
        V1OutputSaveConfigurationButton(
            isSaving: isSavingConfiguration,
            configurationStatus: configurationStatus,
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
    let configurationStatus: V1ConfigurationStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(
                    systemName: systemImage
                )
                .font(.caption.weight(.semibold))
                .frame(width: 16)

                Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            }
        }
        .buttonStyle(
            V1OutputSaveButtonStyle(
                isSaved: configurationStatus == .saved
            )
        )
        .disabled(isSaving || configurationStatus == .saved)
        .accessibilityLabel(title)
    }

    private var title: String {
        if isSaving {
            return "正在保存"
        }

        switch configurationStatus {
        case .saved:
            return "已保存"
        case .savedWithWarning:
            return "再次保存"
        case .failure:
            return "重新保存"
        case .idle,
             .dirty,
             .saving,
             .subjectSynced:
            return "保存这次选择"
        }
    }

    private var systemImage: String {
        if isSaving {
            return "hourglass"
        }

        switch configurationStatus {
        case .saved:
            return "checkmark.circle.fill"
        case .savedWithWarning:
            return "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .failure:
            return "arrow.clockwise.circle.fill"
        case .idle,
             .dirty,
             .saving,
             .subjectSynced:
            return "square.and.arrow.down.fill"
        }
    }
}

private struct V1OutputSaveButtonStyle: ButtonStyle {

    let isSaved: Bool

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSaved ? Color.secondary : Color.white)
            .padding(.horizontal, 14)
            .frame(
                width: V1CompactBottomActionMetrics.width,
                height: V1CompactBottomActionMetrics.height
            )
            .background(
                RoundedRectangle(
                    cornerRadius: V1CompactBottomActionMetrics.cornerRadius,
                    style: .continuous
                )
                .fill(
                    isSaved
                    ? ConfigurationUI.controlBackground
                    : Color.accentColor.opacity(
                        MemoMarkDesignTokens.Layout
                            .compactPrimaryActionTintOpacity
                    )
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: V1CompactBottomActionMetrics.cornerRadius,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )
            .opacity(
                isEnabled
                ? (configuration.isPressed ? 0.78 : 1)
                : (isSaved ? 1 : 0.56)
            )
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct V1OutputResultSection: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @Binding
    var mediaOutputMode: V1MediaOutputMode

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

        V1TitledSectionCard(
            title: "最终结果",
            subtitle: "先看看这段回忆会以什么样子留下。"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                mediaModePicker

                Text(mediaOutputSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                V1OutputRetentionRow(
                    title: "保留拍摄信息",
                    subtitle: "新照片会带上能够保留的拍摄信息。"
                )

                V1OutputRetentionRow(
                    title: "保留 Live Photo",
                    subtitle:
                        mediaOutputMode == .originalFormat
                        ? "原格式会保留动态效果。"
                        : "静态图片只留下单张图片。"
                )

                V1HorizontalDivider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("照片说明")
                        .font(.subheadline.weight(.semibold))

                    Text(presentation.resolvedDescription)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(presentation.fallbackNote)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)

                Toggle(isOn: $usesCustomMemoryWriteText) {
                    V1OutputRetentionLabel(
                        title: presentation.toggleTitle,
                        subtitle: presentation.toggleDescription
                    )
                }
                .toggleStyle(.switch)
                .padding(.vertical, 2)

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
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Text("最终会写入 Apple Photos")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .animation(
                .easeOut(duration: MemoMarkDesignTokens.Motion.standard),
                value: usesCustomMemoryWriteText
            )
        }
    }

    @ViewBuilder
    private var mediaModePicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("照片形式", selection: $mediaOutputMode) {
                ForEach(V1MediaOutputMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
        } else {
            Picker("照片形式", selection: $mediaOutputMode) {
                ForEach(V1MediaOutputMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var mediaOutputSummary: String {
        switch mediaOutputMode {
        case .originalFormat:
            return "普通照片照常保留；Live Photo 会带着动态效果一起留下。"
        case .staticImage:
            return "普通照片照常保留；Live Photo 会留下加边框后的静态图片。"
        }
    }
}

private struct V1OutputSection: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @FocusState
    private var isNewAlbumNameFocused: Bool

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
        V1TitledSectionCard(
            title: "回到哪里",
            subtitle: "以后保存都会默认使用这里。"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                adaptiveOutputTargetPicker

                targetSpecificControls

            }
        }
    }

    private var presentedOutputTarget: V1IOSOutputTarget {
        outputTarget == .automatic ? .applePhotos : outputTarget
    }

    @ViewBuilder
    private var adaptiveOutputTargetPicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker(
                "回到哪里",
                selection: presentedOutputTargetBinding
            ) {
                outputTargetOptions
            }
        .pickerStyle(.menu)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else {
            Picker(
                "回到哪里",
                selection: presentedOutputTargetBinding
            ) {
                outputTargetOptions
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var outputTargetOptions: some View {
        ForEach(selectableOutputTargets) { target in
            Label(
                target.title,
                systemImage: target.symbolName
            )
            .tag(target)
        }
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
                Text("选择已有相册")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                existingAlbumControlRow

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
                    .focused($isNewAlbumNameFocused)
                    .configurationFieldChrome(isActive: true)

                Text("保存配置时创建相册；后续自动存入这个已有相册。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .onAppear {
                isNewAlbumNameFocused = true
            }
        }
    }

    private var existingAlbumControlRow: some View {
        HStack(alignment: .center, spacing: 8) {
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
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onReloadAlbums) {
                Group {
                    if isLoadingAlbums {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(uiColor: .secondarySystemFill))
                )
                .overlay(
                    Circle()
                        .stroke(ConfigurationUI.faintHairline)
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isLoadingAlbums)
            .accessibilityLabel(
                isLoadingAlbums
                ? "正在刷新相册"
                : "刷新相册"
            )
            .accessibilityHint("重新读取可用于保存结果的系统相册")
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

private struct V1OutputRetentionRow: View {

    let title: String
    let subtitle: String

    var body: some View {
        V1OutputRetentionLabel(
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

    let title: String
    let subtitle: String

    var body: some View {
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
