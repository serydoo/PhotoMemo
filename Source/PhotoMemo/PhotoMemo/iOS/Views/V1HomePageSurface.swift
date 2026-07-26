import Foundation

#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1HomePageSurface<ProfileTrackingBackground: View>: View {

    let subjectSummary: V1IOSHomeSubjectSummaryProjection
    let subject: MemorySubject?
    let activitySnapshot: PhotoMemoBackgroundJobSnapshot?
    let completedPhotoCount: Int
    let borderStyleName: String
    let borderStyleDescription: String
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID?
    let isEditingMemoryPresetTitle: Bool
    let memoryPresetTitleDraft: Binding<String>
    let memoryPresetTitleFieldFocused: FocusState<Bool>.Binding
    let isConfigurationReady: Bool
    let isSavingConfiguration: Bool
    let onOpenSubject: () -> Void
    let onOpenProcessing: () -> Void
    let onCommitMemoryPresetTitle: () -> Void
    let onOpenPhotoPicker: () -> Void
    let onOpenSettings: () -> Void
    let onSelectMemoryPreset: (MemoryPreset) -> Void
    let onRenameMemoryPreset: () -> Void
    let onSaveMemoryPreset: (MemoryPreset) -> Void
    let onDeleteMemoryPreset: (MemoryPreset) -> Void
    let onOpenLocalConfigurationLibrary: () -> Void
    let onDismissKeyboard: () -> Void
    let profileTrackingBackground: ProfileTrackingBackground

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topHeaderSection

                topSummaryCluster
            }
            .padding(.top, 16)
            .padding(.bottom, 104)
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
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            processPhotoFooter
        }
    }

    private var topSummaryCluster: some View {
        VStack(spacing: 14) {
            profileSection
                .background(profileTrackingBackground)

            activitySection

            currentPresetSection
        }
    }

    @ViewBuilder
    private var activitySection: some View {
        if let projection =
            V1IOSHomeActivityPresenter
            .projection(from: activitySnapshot),
           V1IOSHomeActivityPresenter
            .shouldShow(projection) {
            V1IOSHomeActivityCard(
                projection: projection,
                onOpenProcessing: onOpenProcessing
            )
        }
    }

    private var topHeaderSection: some View {
        HStack(alignment: .top, spacing: 12) {
            V1HomeAppMark()

            VStack(alignment: .leading, spacing: 7) {
                Text("时光记")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("让照片保留它在人生时间线里的位置。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                adaptiveHeaderPills
            }

            Spacer(minLength: 0)

            Button(action: onOpenSettings) {
                Image(systemName: MemoMarkSymbol.settings.name)
                    .font(.body.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                Color(
                                    uiColor: .secondarySystemFill
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开设置")
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    private var adaptiveHeaderPills: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                privacyHeaderPill
                applePhotosHeaderPill
            }

            VStack(alignment: .leading, spacing: 6) {
                privacyHeaderPill
                applePhotosHeaderPill
            }
        }
    }

    private var privacyHeaderPill: some View {
        V1HomeHeaderPill(
            systemImage: MemoMarkSymbol.privacy.name,
            title: "本地优先"
        )
    }

    private var applePhotosHeaderPill: some View {
        V1HomeHeaderPill(
            systemImage: MemoMarkSymbol.applePhotos.name,
            title: "Apple Photos"
        )
    }

    private var profileSection: some View {
        V1TitledSectionCard(
            title: "记忆对象",
            subtitle: "查看当前对象与时间锚点"
        ) {
            V1IOSSubjectHomeEntryContent(
                subjectSummary: subjectSummary,
                subject: subject,
                availableConfigurationCount:
                    memoryPresets.count,
                completedPhotoCount: completedPhotoCount,
                onOpenSubject: onOpenSubject
            )
        }
    }

    private func anchorType(
        for preset: MemoryPreset
    ) -> AnchorType {
        guard
            let anchorID = preset.selectedTimeAnchorID,
            let anchor = subject?.timeAnchor(id: anchorID)
        else {
            return .custom
        }

        return anchor.resolvedAnchorType
    }

    private var currentPresetSection: some View {
        V1TitledSectionCard(
            title: "我的配置",
            subtitle: "选择当前生效的记录方式",
            trailingAccessory: {
                HStack(spacing: 8) {
                    Text("勾选生效")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Button(action: onOpenLocalConfigurationLibrary) {
                        Image(systemName: "archivebox")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("管理本地备份")
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if memoryPresets.isEmpty {
                    V1HomeEmptyPresetRow()
                } else {
                    VStack(spacing: 8) {
                        ForEach(memoryPresets) { preset in
                            V1HomeMemoryPresetRow(
                                preset: preset,
                                borderStyleName: borderStyleName,
                                anchorType: anchorType(for: preset),
                                subjectAvatarImagePath:
                                    subject?.identity.avatarPreviewImagePath
                                    ?? subject?.identity.avatarImagePath,
                                isSelected:
                                    preset.id == selectedMemoryPresetID,
                                onSelect: {
                                    onSelectMemoryPreset(preset)
                                },
                                onRename: {
                                    if preset.id != selectedMemoryPresetID {
                                        onSelectMemoryPreset(preset)
                                    }
                                    onRenameMemoryPreset()
                                },
                                onSave: {
                                    onSaveMemoryPreset(preset)
                                },
                                isSaveDisabled: isSavingConfiguration,
                                onDelete: {
                                    onDeleteMemoryPreset(preset)
                                }
                            )
                        }
                    }
                }

                if isEditingMemoryPresetTitle {
                    HStack(spacing: 8) {
                        TextField(
                            "配置名称",
                            text: memoryPresetTitleDraft
                        )
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .submitLabel(.done)
                        .focused(memoryPresetTitleFieldFocused)
                        .configurationFieldChrome(isActive: true)
                        .onSubmit {
                            onCommitMemoryPresetTitle()
                        }

                        Button("完成") {
                            onCommitMemoryPresetTitle()
                        }
                        .buttonStyle(.plain)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .fill(ConfigurationUI.controlBackground)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .stroke(ConfigurationUI.faintHairline)
                        )
                        .accessibilityLabel("完成名称编辑")
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }

            }
        }
    }

    private var processPhotoFooter: some View {
        VStack(spacing: 0) {
            Button(action: onOpenPhotoPicker) {
                HStack(spacing: 10) {
                    V1HomeProcessPhotoIcon()

                    Text(
                        isConfigurationReady
                        ? "选择照片"
                        : "先完成配置"
                    )
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .v1CompactBottomPrimaryAction()
            }
            .buttonStyle(
                V1CompactPrimaryActionButtonStyle()
            )
            .accessibilityLabel(
                isConfigurationReady
                ? "选择照片"
                : "先完成配置"
            )
        }
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

private struct V1IOSHomeActivityCard: View {

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    let projection: V1IOSHomeActivityProjection
    let onOpenProcessing: () -> Void

    @State
    private var isMounted =
        V1IOSHomeActivityPresentationState()
        .isMounted

    @State
    private var isVisible =
        V1IOSHomeActivityPresentationState()
        .isVisible

    var body: some View {
        Group {
            if isMounted {
                V1TitledSectionCard(title: "当前任务") {
                    Button(action: onOpenProcessing) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 12) {
                                Text(projection.countText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)

                                Spacer(minLength: 8)

                                Text(projection.statusText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(statusColor)
                                    .lineLimit(1)
                            }

                            activityProgressBar
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ConfigurationUI.innerPanelPadding)
                        .padding(.vertical, ConfigurationUI.innerPanelPadding)
                        .background(
                            RoundedRectangle(
                                cornerRadius: ConfigurationUI.innerPanelCornerRadius,
                                style: .continuous
                            )
                            .fill(ConfigurationUI.controlBackground)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: ConfigurationUI.innerPanelCornerRadius,
                                style: .continuous
                            )
                            .stroke(ConfigurationUI.faintHairline)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(projection.countText)，\(projection.statusText)"
                    )
                    .accessibilityValue(
                        "进度 \(progressPercentText)"
                    )
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible || accessibilityReduceMotion ? 0 : -6)
            }
        }
        .task(id: projection.lifecycleID) {
            await present(projection)
        }
    }

    private var activityProgressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.16))

                Capsule(style: .continuous)
                    .fill(Color.accentColor)
                    .frame(
                        width: proxy.size.width
                            * projection.progressFraction
                    )
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }

    private var statusColor: Color {
        switch projection.state {
        case .processing:
            return .accentColor
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }

    private var progressPercentText: String {
        "\(Int((projection.progressFraction * 100).rounded()))%"
    }

    @MainActor
    private func present(
        _ projection: V1IOSHomeActivityProjection
    ) async {
        let wasVisible = isVisible
        guard V1IOSHomeActivityPresenter.shouldShow(projection) else {
            await dismiss()
            return
        }

        isMounted = true

        if !wasVisible {
            isVisible = false
            await Task.yield()
            withAnimation(
                accessibilityReduceMotion
                ? nil
                : .easeOut(duration: 0.25)
            ) {
                isVisible = true
            }
        } else {
            isVisible = true
        }

        guard projection.state == .completed else {
            return
        }

        let elapsed =
            Date().timeIntervalSince(projection.updatedAt)
        let remaining =
            max(
                V1IOSHomeActivityPresenter
                    .completionDisplayDuration
                    - elapsed,
                0
            )

        if remaining > 0 {
            try? await Task.sleep(
                nanoseconds: UInt64(remaining * 1_000_000_000)
            )
        }

        guard !Task.isCancelled else {
            return
        }

        await dismiss()
    }

    @MainActor
    private func dismiss() async {
        withAnimation(
            accessibilityReduceMotion
            ? nil
            : .easeOut(duration: 0.2)
        ) {
            isVisible = false
        }

        if !accessibilityReduceMotion {
            try? await Task.sleep(
                nanoseconds: 200_000_000
            )
        }

        guard !Task.isCancelled else {
            return
        }

        isMounted = false
    }
}

private struct V1HomeMemoryPresetRow: View {

    let preset: MemoryPreset
    let borderStyleName: String
    let anchorType: AnchorType
    let subjectAvatarImagePath: String?
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onSave: () -> Void
    let isSaveDisabled: Bool
    let onDelete: () -> Void

    @State private var showsDeleteConfirmation = false

    var body: some View {
        rowContent
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
                .tint(.red)
                .accessibilityLabel("删除配置")

                Button(action: onSave) {
                    Label(
                        "保存",
                        systemImage: MemoMarkSymbol.localStorage.name
                    )
                }
                .tint(.blue)
                .disabled(isSaveDisabled)
                .accessibilityLabel("保存配置到本地库")
            }
            .alert(
                "删除“\(preset.title)”配置？",
                isPresented: $showsDeleteConfirmation
            ) {
                Button("取消", role: .cancel) {}
                Button("删除配置", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("本地配置库中的备份会保留。此操作无法撤销。")
            }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 12) {
            presetIdentityMark

            VStack(alignment: .leading, spacing: 4) {
                Text(preset.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(borderStyleName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(presetDetail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            HStack(spacing: 8) {
                Menu {
                    if isSelected {
                        Button(action: onRename) {
                            Label("重命名", systemImage: "pencil")
                        }
                    }

                    Button(action: onSave) {
                        Label(
                            "保存",
                            systemImage: MemoMarkSymbol.localStorage.name
                        )
                    }
                    .disabled(isSaveDisabled)

                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                }
                .accessibilityLabel("更多配置操作")

                Image(
                    systemName:
                        isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3.weight(.semibold))
                .foregroundStyle(
                    isSelected
                    ? Color.accentColor
                    : Color.secondary.opacity(0.58)
                )
                .frame(width: 26, height: 30)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(
            color: Color.black.opacity(0.045),
            radius: 12,
            y: 5
        )
    }

    private var presetDetail: String {
        guard let savedAt = preset.savedAt else {
            return preset.summary
        }

        return "上次修改：\(Self.savedStatusValue(savedAt))"
    }

    private static func savedStatusValue(_ date: Date) -> String {
        V1UserFacingDateFormatter.compactDateTime(date)
    }

    private var presetIdentityMark: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(anchorTint.opacity(0.11))
            .overlay {
                Image(systemName: anchorSystemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(anchorTint)
            }

            logoBadge
                .offset(x: 3, y: 3)
        }
        .frame(width: 48, height: 48)
        .overlay(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(anchorTint.opacity(0.12))
        )
        .accessibilityLabel(
            "\(anchorType.displayName)，Logo 标识：\(preset.logoMode.title)"
        )
    }

    @ViewBuilder
    private var logoBadge: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .stroke(ConfigurationUI.faintHairline)
                )

            switch preset.logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.primary)
            case .customUpload:
                Image(systemName: "photo.badge.checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.purple)
            case .subjectAvatar:
                if let subjectAvatarImagePath,
                   let image = UIImage(
                    contentsOfFile: subjectAvatarImagePath
                   ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                } else {
                    Image(systemName: MemoMarkSymbol.memorySubject.name)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.pink)
                }
            }
        }
        .frame(width: 19, height: 19)
        .shadow(color: Color.black.opacity(0.08), radius: 3, y: 1)
    }

    private var anchorSystemImage: String {
        switch anchorType {
        case .birthday:
            return "birthday.cake.fill"
        case .relationship:
            return "heart.fill"
        case .marriage:
            return "sparkles"
        case .exam:
            return "flag.checkered"
        case .custom:
            return "calendar"
        }
    }

    private var anchorTint: Color {
        switch anchorType {
        case .birthday:
            return .orange
        case .relationship:
            return .pink
        case .marriage:
            return .purple
        case .exam:
            return .green
        case .custom:
            return .blue
        }
    }
}

private struct V1HomeEmptyPresetRow: View {

    var body: some View {
        HStack(spacing: 12) {
            V1HomeConfigurationGlyph()

            VStack(alignment: .leading, spacing: 4) {
                Text("当前对象还没有配置")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("请先在配置中心保存一次完整配置，之后才能开始处理照片。输出部分如果不自定义，会继续按默认规则走。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }
}

private struct V1HomeProcessPhotoIcon: View {

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.92), lineWidth: 1.6)
            .frame(width: 20, height: 16)

            Image(systemName: "sparkles")
                .font(.system(size: 9, weight: .bold))
                .offset(x: 9, y: -8)
        }
        .frame(width: 24, height: 24)
    }
}

private struct V1HomeConfigurationGlyph: View {

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(Color.accentColor.opacity(0.10))

            Image(systemName: MemoMarkSymbol.configuration.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 48, height: 48)
    }
}

private struct V1HomeAppMark: View {

    var body: some View {
        Image("HomeAppIcon")
            .resizable()
            .scaledToFill()
        .frame(width: 76, height: 76)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            y: 3
        )
    }
}

private struct V1HomeHeaderPill: View {

    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.blue)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}
#endif
