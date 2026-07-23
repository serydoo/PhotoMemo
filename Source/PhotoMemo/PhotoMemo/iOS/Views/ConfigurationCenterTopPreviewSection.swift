#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterTopPreviewSection<
    ProfilePresetControl: View
>: View {

    @ObservedObject
    var session: ConfigurationSession

    let isCurrentPresetApplied: Bool
    let currentBorderStyleName: String
    let currentPresetStatusText: String
    let previewPinProgress: CGFloat
    let showsNavigatorButton: Bool
    let showsMemoMarkPlusBadge: Bool

    @Binding
    var isRenamingProfile: Bool

    let profileTitle: Binding<String>
    let onDismissKeyboard: () -> Void
    let onBeginRename: () -> Void
    let onResetPreset: () -> Void
    let onOpenSettings: () -> Void
    let onOpenMemoMarkPlus: () -> Void
    let onOpenNavigator: () -> Void
    let onRegionSelection: (CardRegion) -> Void
    let profilePresetControl: ProfilePresetControl

    init(
        session: ConfigurationSession,
        isCurrentPresetApplied: Bool,
        currentBorderStyleName: String,
        currentPresetStatusText: String,
        previewPinProgress: CGFloat,
        showsNavigatorButton: Bool,
        showsMemoMarkPlusBadge: Bool,
        isRenamingProfile: Binding<Bool>,
        profileTitle: Binding<String>,
        onDismissKeyboard: @escaping () -> Void,
        onBeginRename: @escaping () -> Void,
        onResetPreset: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onOpenMemoMarkPlus: @escaping () -> Void,
        onOpenNavigator: @escaping () -> Void,
        onRegionSelection: @escaping (CardRegion) -> Void,
        @ViewBuilder profilePresetControl: () -> ProfilePresetControl
    ) {
        self.session = session
        self.isCurrentPresetApplied = isCurrentPresetApplied
        self.currentBorderStyleName = currentBorderStyleName
        self.currentPresetStatusText = currentPresetStatusText
        self.previewPinProgress = previewPinProgress
        self.showsNavigatorButton = showsNavigatorButton
        self.showsMemoMarkPlusBadge =
            showsMemoMarkPlusBadge
        _isRenamingProfile = isRenamingProfile
        self.profileTitle = profileTitle
        self.onDismissKeyboard = onDismissKeyboard
        self.onBeginRename = onBeginRename
        self.onResetPreset = onResetPreset
        self.onOpenSettings = onOpenSettings
        self.onOpenMemoMarkPlus =
            onOpenMemoMarkPlus
        self.onOpenNavigator = onOpenNavigator
        self.onRegionSelection = onRegionSelection
        self.profilePresetControl = profilePresetControl()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            productStatement
            profilePanel
            compactCardPreview
        }
        .padding(.horizontal, interpolatedValue(8, 6))
        .padding(.top, interpolatedValue(10, 8))
        .padding(.bottom, interpolatedValue(14, 10))
        .background(ConfigurationUI.panelBackground)
        .overlay(
            Rectangle()
                .fill(
                    previewPinProgress > 0.08
                    ? ConfigurationUI.hairline
                    : ConfigurationUI.faintHairline
                )
                .frame(height: 0.5),
            alignment: .bottom
        )
        .shadow(
            color:
                ConfigurationUI.cardShadow
                .opacity(0.4 * previewPinProgress),
            radius: 12 * previewPinProgress,
            y: 8 * previewPinProgress
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onDismissKeyboard()
                }
        )
    }

    private var productStatement: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    ViewThatFits(
                        in: .horizontal
                    ) {
                        HStack(spacing: 9) {
                            productTitle
                            if showsMemoMarkPlusBadge {
                                MemoMarkPlusBadge(
                                    action:
                                        onOpenMemoMarkPlus
                                )
                            }
                        }

                        VStack(
                            alignment: .leading,
                            spacing: 7
                        ) {
                            productTitle
                            if showsMemoMarkPlusBadge {
                                MemoMarkPlusBadge(
                                    action:
                                        onOpenMemoMarkPlus
                                )
                            }
                        }
                    }

                    Text("配置中心")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("这里负责长期配置记忆对象、时间锚点与输出行为，顶部预览会保持锁定，原始照片不会被修改。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        if showsNavigatorButton {
                            topIconButton(
                                title: "配置导航",
                                systemImage: MemoMarkSymbol.module.name,
                                action: onOpenNavigator
                            )
                        }

                        topIconButton(
                            title: "设置",
                            systemImage: "slider.horizontal.3",
                            action: onOpenSettings
                        )
                    }

                    topStatusPill
                }
            }

            workflowChips

            Text("Apple Photos -> Share -> MemoMark -> Processing -> Apple Photos")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
    }

    private var productTitle: some View {
        Text("时光记")
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(.primary)
    }

    private var profilePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            profileHeader

            profileCompactFacts

            profileFooterHint

            if isRenamingProfile {
                TextField(
                    "配置名称",
                    text: profileTitle
                )
                .textFieldStyle(.plain)
                .font(.caption)
                .configurationFieldChrome(isActive: true)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(ConfigurationUI.controlBackground.opacity(0.62))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var profileHeader: some View {
        ViewThatFits {
            profileHeaderWide
            profileHeaderCompact
        }
        .font(.caption.weight(.semibold))
    }

    private var profileHeaderWide: some View {
        HStack(alignment: .center, spacing: 10) {
            profileTitleBlock

            profilePresetControl
                .frame(
                    minWidth: 118,
                    idealWidth: 146,
                    maxWidth: 168,
                    alignment: .leading
                )

            profileUtilityButtons

            Spacer(minLength: 0)

            profileActionCluster(alignment: .trailing)
        }
    }

    private var profileHeaderCompact: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                profileTitleBlock

                Spacer(minLength: 0)

                profileUtilityButtons
            }

            HStack(alignment: .center, spacing: 10) {
                profilePresetControl
                    .frame(maxWidth: .infinity, alignment: .leading)

                profileActionCluster(alignment: .leading)
            }
        }
    }

    private var profileTitleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("当前生效配置")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(profileTitle.wrappedValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(currentPresetStatusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var profileUtilityButtons: some View {
        HStack(spacing: 8) {
            Button(action: onBeginRename) {
                Image(systemName: "pencil")
                    .font(.caption.weight(.semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("重命名")

            Button(action: onResetPreset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("重置")
        }
    }

    private func profileActionCluster(
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(session.currentMemoryPresetSummary)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Label("切换即生效", systemImage: "arrow.left.arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.78))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.86))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(ConfigurationUI.faintHairline)
                    )
            }
        }
    }

    private var compactCardPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("记忆卡片预览")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("当前生效配置")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Text("保持 renderer 比例锁定，仅放大观察尺寸")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            IOSMacStyleMemoryCardPreview(
                session: session,
                onPreviewInteraction: onDismissKeyboard
            )
            .padding(
                .horizontal,
                interpolatedValue(-2, -8)
            )

            regionStrip
        }
        .padding(interpolatedValue(12, 9))
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .configurationPanelChrome()
    }

    private func interpolatedValue(
        _ start: CGFloat,
        _ end: CGFloat
    ) -> CGFloat {
        start + (end - start) * previewPinProgress
    }

    private var topStatusPill: some View {
        Label(
            isCurrentPresetApplied
            ? "已同步"
            : "待保存",
            systemImage: isCurrentPresetApplied
            ? "checkmark.circle.fill"
            : "clock.badge.exclamationmark"
        )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(
                isCurrentPresetApplied
                ? Color.accentColor
                : Color.orange
            )
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isCurrentPresetApplied
                        ? ConfigurationUI.selectedBackground
                        : Color.orange.opacity(0.12)
                    )
            )
    }

    private func topIconButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .background(
            Circle()
                .fill(ConfigurationUI.controlBackground)
        )
        .overlay(
            Circle()
                .stroke(ConfigurationUI.faintHairline)
        )
        .help(title)
    }

    private func topWorkflowChip(
        title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(ConfigurationUI.controlBackground.opacity(0.92))
            )
    }

    private var workflowChips: some View {
        ViewThatFits {
            workflowChipsExpanded
            workflowChipsCompact
        }
    }

    private var workflowChipsExpanded: some View {
        HStack(spacing: 8) {
            topWorkflowChip(
                title: "记忆对象",
                systemImage: MemoMarkSymbol.memorySubject.name
            )
            topWorkflowChip(
                title: "时间锚点",
                systemImage: MemoMarkSymbol.timeAnchor.name
            )
            topWorkflowChip(
                title: "输出行为",
                systemImage: MemoMarkSymbol.output.name
            )
        }
    }

    private var workflowChipsCompact: some View {
        HStack(spacing: 8) {
            topWorkflowChip(
                title: "对象",
                systemImage: MemoMarkSymbol.memorySubject.name
            )
            topWorkflowChip(
                title: "锚点",
                systemImage: MemoMarkSymbol.timeAnchor.name
            )
            topWorkflowChip(
                title: "输出",
                systemImage: MemoMarkSymbol.output.name
            )
        }
    }

    private var profileCompactFacts: some View {
        ViewThatFits {
            profileFactsWide
            profileFactsCompact
        }
        .font(.caption)
        .padding(.horizontal, 2)
    }

    private var profileFactsWide: some View {
        HStack(alignment: .center, spacing: 8) {
            profileInlineFact(
                title: "对象",
                value: currentSubjectTitle,
                systemImage: MemoMarkSymbol.memorySubject.name
            )

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(width: 0.5, height: 16)

            profileInlineFact(
                title: "锚点",
                value: currentAnchorTitle,
                systemImage: MemoMarkSymbol.timeAnchor.name
            )

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(width: 0.5, height: 16)

            profileInlineFact(
                title: "边框",
                value: currentBorderStyleName,
                systemImage: MemoMarkSymbol.configuration.name
            )
        }
    }

    private var profileFactsCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            profileInlineFact(
                title: "对象",
                value: currentSubjectTitle,
                systemImage: MemoMarkSymbol.memorySubject.name
            )

            profileInlineFact(
                title: "锚点",
                value: currentAnchorTitle,
                systemImage: MemoMarkSymbol.timeAnchor.name
            )

            profileInlineFact(
                title: "边框",
                value: currentBorderStyleName,
                systemImage: MemoMarkSymbol.configuration.name
            )
        }
    }

    private func profileInlineFact(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(title) · \(value)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentSubjectTitle: String {
        let shortName =
            session.state.selectedSubject?
            .identity.shortName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !shortName.isEmpty {
            return shortName
        }

        let displayName =
            session.state.selectedSubject?
            .identity.displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        return displayName.isEmpty
            ? "记忆对象"
            : displayName
    }

    private var currentAnchorTitle: String {
        let title =
            session.state.selectedSubject?
            .primaryTimeAnchor?
            .title
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        return title.isEmpty
            ? "时间锚点"
            : title
    }

    private var profileFooterHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.to.line")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("保存为当前配置与新建配置保留在下方操作区，这里只负责查看、切换与重命名。")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }

    private var regionStrip: some View {
        ViewThatFits {
            regionStripExpanded
            regionStripCompact
        }
        .padding(4)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ConfigurationUI.hairline)
        )
    }

    private var regionStripExpanded: some View {
        HStack(spacing: 0) {
            regionStripButton(
                .slotA,
                title: "记录",
                systemImage: MemoMarkSymbol.configuration.name
            )

            regionStripButton(
                .slotB,
                title: "时间线",
                systemImage: MemoMarkSymbol.timeAnchor.name
            )

            regionStripButton(
                .slotC,
                title: "拍摄参数",
                systemImage: MemoMarkSymbol.photoMetadata.name
            )

            regionStripButton(
                .slotD,
                title: "记忆",
                systemImage: MemoMarkSymbol.memoryContent.name
            )
        }
    }

    private var regionStripCompact: some View {
        HStack(spacing: 0) {
            regionStripButton(
                .slotA,
                title: "记录",
                systemImage: MemoMarkSymbol.configuration.name
            )

            regionStripButton(
                .slotB,
                title: "时间",
                systemImage: MemoMarkSymbol.timeAnchor.name
            )

            regionStripButton(
                .slotC,
                title: "参数",
                systemImage: MemoMarkSymbol.photoMetadata.name
            )

            regionStripButton(
                .slotD,
                title: "记忆",
                systemImage: MemoMarkSymbol.memoryContent.name
            )
        }
    }

    private func regionStripButton(
        _ region: CardRegion,
        title: String,
        systemImage: String
    ) -> some View {
        Button {
            onRegionSelection(region)
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
}
#endif
