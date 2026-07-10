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
    let onOpenSubject: () -> Void
    let onCommitMemoryPresetTitle: () -> Void
    let onOpenPhotoPicker: () -> Void
    let onOpenSettings: () -> Void
    let onSelectMemoryPreset: (MemoryPreset) -> Void
    let onRenameMemoryPreset: () -> Void
    let onDeleteMemoryPreset: (MemoryPreset) -> Void
    let onDismissKeyboard: () -> Void
    let profileTrackingBackground: ProfileTrackingBackground
    @State
    private var revealedDeletePresetID: MemoryPreset.ID?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topHeaderSection

                topSummaryCluster
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 104)
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

                HStack(spacing: 8) {
                    V1HomeHeaderPill(
                        systemImage: "lock.shield",
                        title: "本地优先"
                    )

                    V1HomeHeaderPill(
                        systemImage: "photo.on.rectangle",
                        title: "Apple Photos"
                    )
                }
            }

            Spacer(minLength: 0)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
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
                    ForEach(memoryPresets) { preset in
                        V1HomeMemoryPresetRow(
                            preset: preset,
                            borderStyleName: borderStyleName,
                            anchorType:
                                anchorType(for: preset),
                            subjectAvatarImagePath:
                                subject?
                                .identity
                                .avatarPreviewImagePath
                                ?? subject?
                                .identity
                                .avatarImagePath,
                            isSelected:
                                preset.id == selectedMemoryPresetID,
                            isDeleteRevealed:
                                revealedDeletePresetID == preset.id,
                            onSelect: {
                                revealedDeletePresetID = nil
                                onSelectMemoryPreset(preset)
                            },
                            onRename: {
                                revealedDeletePresetID = nil
                                if preset.id != selectedMemoryPresetID {
                                    onSelectMemoryPreset(preset)
                                }
                                onRenameMemoryPreset()
                            },
                            onRevealDelete: {
                                withAnimation(.snappy(duration: 0.2)) {
                                    revealedDeletePresetID = preset.id
                                }
                            },
                            onHideDelete: {
                                withAnimation(.snappy(duration: 0.2)) {
                                    if revealedDeletePresetID == preset.id {
                                        revealedDeletePresetID = nil
                                    }
                                }
                            },
                            onDelete: {
                                revealedDeletePresetID = nil
                                onDeleteMemoryPreset(preset)
                            }
                        )
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
    let isDeleteRevealed: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onRevealDelete: () -> Void
    let onHideDelete: () -> Void
    let onDelete: () -> Void

    @GestureState
    private var horizontalDragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Text("删除")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 74)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
            }
            .offset(x: rowHorizontalOffset == 0 ? 86 : 0)
            .opacity(deleteButtonOpacity)
            .allowsHitTesting(rowHorizontalOffset < -40)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )

            rowContent
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                }
            .offset(x: rowHorizontalOffset)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .updating($horizontalDragOffset) {
                        value,
                        state,
                        _ in

                        guard
                            abs(value.translation.width)
                            > abs(value.translation.height)
                        else {
                            state = 0
                            return
                        }

                        if isDeleteRevealed {
                            state = min(
                                82,
                                max(0, value.translation.width)
                            )
                        } else {
                            state = max(
                                -82,
                                min(0, value.translation.width)
                            )
                        }
                    }
                    .onEnded { value in
                        guard
                            abs(value.translation.width)
                            > abs(value.translation.height)
                        else {
                            return
                        }

                        let baseOffset: CGFloat =
                            isDeleteRevealed ? -82 : 0
                        let projectedOffset =
                            baseOffset
                            + value.predictedEndTranslation.width

                        if projectedOffset < -42 {
                            onRevealDelete()
                        } else {
                            onHideDelete()
                        }
                    }
            )
        }
        .animation(
            .snappy(duration: 0.2),
            value: isDeleteRevealed
        )
    }

    private var rowHorizontalOffset: CGFloat {
        let baseOffset: CGFloat =
            isDeleteRevealed ? -82 : 0
        let proposedOffset =
            baseOffset + horizontalDragOffset

        return min(0, max(-82, proposedOffset))
    }

    private var deleteButtonOpacity: Double {
        min(
            1,
            max(
                0,
                Double(abs(rowHorizontalOffset) / 42)
            )
        )
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
        date.formatted(
            .dateTime
                .month()
                .day()
                .hour()
                .minute()
        )
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
                    Image(systemName: "person.fill")
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

            Image(systemName: "rectangle.stack")
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
    }
}
#endif
