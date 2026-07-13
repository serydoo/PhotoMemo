import Foundation

#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1HomePageSurface<ProfileTrackingBackground: View>: View {

    let subjectSummary: V1IOSHomeSubjectSummaryProjection
    let subject: MemorySubject?
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
                horizontalPadding: 18
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

            currentPresetSection
        }
    }

    private var topHeaderSection: some View {
        HStack(alignment: .top, spacing: 14) {
            V1HomeAppMark()

            VStack(alignment: .leading, spacing: 7) {
                Text("时光记")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("本地优先的记忆呈现引擎，让照片不止记录画面，也保留它在人生时间线里的位置。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                adaptiveHeaderPills
            }

            Spacer(minLength: 0)

            Button(action: onOpenSettings) {
                Image(systemName: MemoMarkSymbol.settings.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.blue)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.08))
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
        V1CardSurface(title: "记忆对象") {
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
        V1HomeConfigurationCard(
            title: "我的配置",
            note: "勾选生效"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if memoryPresets.isEmpty {
                    V1HomeEmptyPresetRow()
                } else {
                    List(memoryPresets) { preset in
                        V1HomeMemoryPresetRow(
                            preset: preset,
                            borderStyleName: borderStyleName,
                            anchorType: anchorType(for: preset),
                            subjectAvatarImagePath:
                                subject?.identity.avatarPreviewImagePath
                                ?? subject?.identity.avatarImagePath,
                            isSelected: preset.id == selectedMemoryPresetID,
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
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollDisabled(true)
                    .scrollContentBackground(.hidden)
                    .frame(height: CGFloat(memoryPresets.count) * 92)
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

                Button(action: onOpenLocalConfigurationLibrary) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .fill(Color.blue.opacity(0.07))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("打开当前记忆对象的本地配置库")
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
                        ? "处理照片"
                        : "先完成配置"
                    )
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .v1CompactBottomPrimaryAction()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("处理照片")
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

private struct V1HomeConfigurationCard<Content: View>: View {

    let title: String
    let note: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Text(note)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .v1CardChrome()
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
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
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
            .confirmationDialog(
                "删除这个配置？",
                isPresented: $showsDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("删除配置", role: .destructive) {
                    onDelete()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除当前配置不会删除已经保留在本地配置库中的备份。")
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

            Spacer(minLength: 8)

            if isSelected {
                Button(action: onRename) {
                    Text("重命名")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                            .fill(ConfigurationUI.controlBackground)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                            .stroke(ConfigurationUI.faintHairline)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("重命名配置")
            }

            Spacer(minLength: 6)

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
        }
        .padding(10)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(Color.white.opacity(0.94))
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
            return .pink
        case .relationship:
            return .red
        case .marriage:
            return .purple
        case .exam:
            return .orange
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
            .fill(Color.white.opacity(0.94))
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
        ZStack {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(Color.white)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 12,
                y: 6
            )

            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(Color.black, lineWidth: 4)
            .frame(width: 40, height: 46)
            .offset(x: -5, y: -1)

            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
            .stroke(Color.black.opacity(0.92), lineWidth: 3)
            .frame(width: 34, height: 38)
            .offset(x: 9, y: 6)

            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .offset(x: 15, y: -13)
        }
        .frame(width: 68, height: 68)
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
