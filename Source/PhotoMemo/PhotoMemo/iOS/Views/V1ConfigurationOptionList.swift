#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct V1ConfigurationOptionList: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @State
    private var showsMemoryDisplayDetail = false

    @State
    private var showsAdvancedModulesSheet = false

    let subject: MemorySubject?
    @Binding var isMemorySourceExpanded: Bool
    let subjectAvatarPreviewImagePath: String?
    @Binding var logoMode: V1LogoMode
    @Binding var selectedLogoItem: PhotosPickerItem?
    let logoValue: String
    let logoDetail: String
    let customLogoImagePath: String?
    let isOptimizingLogo: Bool
    let timeAnchorTitle: String
    let timeAnchorCount: Int
    let availableTimeAnchors:
        [MemorySubject.TimeAnchor]
    let selectedTimeAnchorID: Binding<UUID>
    let locationPresentation:
        LocationDisplayInspectorPresentation
    let selectedLocationOptionID: Binding<String>
    let timePresentation: TimeDisplayInspectorPresentation
    let selectedTimeOptionID: Binding<String>
    let selectedTimeSupplement: Binding<TimeDisplayConfiguration.Supplement>
    let memoryDisplayValue: String
    let memoryDisplayDetail: String
    let availableMemoryDisplayStyles:
        [MemoryAnchorExpressionStyle]
    let selectedMemoryDisplayStyle:
        Binding<MemoryAnchorExpressionStyle>
    let borderStyleName: String
    let configurationStatus: V1ConfigurationStatus
    let onOpenRegionContent: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            memorySourceSection

            groupedSection(
                title: "卡片布局与内容",
                subtitle: "决定卡片各区域的内容与显示形式"
            ) {
                borderStyleRow
                V1HorizontalDivider(
                    horizontalInset:
                        V1CompactInformationRowMetrics.horizontalPadding
                )
                logoRow
                V1HorizontalDivider(
                    horizontalInset:
                        V1CompactInformationRowMetrics.horizontalPadding
                )
                regionContentRow
                V1HorizontalDivider(
                    horizontalInset:
                        V1CompactInformationRowMetrics.horizontalPadding
                )
                advancedModulesRow
                V1HorizontalDivider(
                    horizontalInset:
                        V1CompactInformationRowMetrics.horizontalPadding
                )
                configurationStatusCard
            }

        }
        .sheet(isPresented: $showsMemoryDisplayDetail) {
            V1MemoryExpressionPreviewSheet(
                memoryDisplayValue: memoryDisplayValue,
                memoryDisplayDetail: memoryDisplayDetail
            )
            .presentationDetents([.height(320), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsAdvancedModulesSheet) {
            V1AdvancedModulesSheet(
                locationPresentation: locationPresentation,
                selectedLocationOptionID: selectedLocationOptionID,
                timePresentation: timePresentation,
                selectedTimeOptionID: selectedTimeOptionID,
                selectedTimeSupplement: selectedTimeSupplement
            )
        }
    }

    private var memorySourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            memorySourceSectionHeader

            VStack(spacing: 0) {
                if isMemorySourceExpanded {
                    subjectRow
                    V1HorizontalDivider(
                        horizontalInset:
                            V1CompactInformationRowMetrics.horizontalPadding
                    )
                    timeAnchorRow
                    V1HorizontalDivider(
                        horizontalInset:
                            V1CompactInformationRowMetrics.horizontalPadding
                    )
                    memoryDisplayRow
                } else {
                    memorySourceSummaryRow
                }
            }
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
        .padding(14)
        .v1CardChrome()
    }

    private var memorySourceSectionHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 10) {
                memorySourceHeading
                Spacer(minLength: 8)
                memorySourceDisclosureButton
            }

            VStack(alignment: .leading, spacing: 8) {
                memorySourceHeading
                memorySourceDisclosureButton
            }
        }
    }

    private var memorySourceHeading: some View {
        adaptiveSectionHeader(
            title: "记忆来源",
            subtitle: "你想围绕谁开展回忆。"
        )
    }

    private var memorySourceDisclosureButton: some View {
        Button {
            isMemorySourceExpanded.toggle()
        } label: {
            Label(
                isMemorySourceExpanded ? "收起" : "展开",
                systemImage:
                    isMemorySourceExpanded
                    ? "chevron.up"
                    : "chevron.down"
            )
            .font(.caption.weight(.semibold))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Color.accentColor)
        .padding(.trailing, 8)
        .accessibilityLabel(
            isMemorySourceExpanded
            ? "收起记忆来源"
            : "展开记忆来源"
        )
    }

    private var memorySourceSummaryRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)

            Text(memorySourceSummary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 8)

            Text("已生效")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("当前记忆来源")
        .accessibilityValue(memorySourceSummary)
    }

    private var memorySourceSummary: String {
        [
            subjectDisplayName,
            availableTimeAnchors.isEmpty
                ? "暂无时间锚点"
                : timeAnchorTitle,
            memoryDisplayValue
        ]
        .joined(separator: " · ")
    }

    private var subjectRow: some View {
        configurationRow(
            icon: subjectIcon,
            title: "记忆对象",
            subtitle: "回忆正围绕谁展开。",
            value: subjectDisplayName,
            detail: "随首页同步",
            showsTrailingChevron: false
        ) {
            Text(subjectDisplayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var logoRow: some View {
        configurationRow(
            icon: logoIcon,
            title: "Logo 标识",
            subtitle: "让卡片留下你的标识。",
            value: logoValue,
            detail: logoDetail,
            showsTrailingChevron: false
        ) {
            HStack(spacing: 6) {
                Menu {
                    ForEach(V1LogoMode.allCases) { mode in
                        Button {
                            logoMode = mode
                        } label: {
                            menuOptionLabel(
                                mode.title,
                                isSelected: mode == logoMode
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(title: logoValue)
                }
                .accessibilityLabel("Logo 标识")
                .accessibilityValue(logoValue)

                if logoMode == .customUpload {
                    PhotosPicker(
                        selection: $selectedLogoItem,
                        matching: .images
                    ) {
                        Group {
                            if isOptimizingLogo {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(
                                    systemName:
                                        "photo.badge.plus"
                                )
                                .font(
                                    .caption.weight(.semibold)
                                )
                            }
                        }
                        .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(Color.accentColor)
                    .disabled(isOptimizingLogo)
                    .accessibilityLabel(
                        isOptimizingLogo
                        ? "正在优化 Logo"
                        : "选择 Logo"
                    )
                }
            }
        }
    }

    private var timeAnchorRow: some View {
        configurationTextRow(
            title: "时间锚点",
            subtitle: "从哪个重要时刻开始记录。",
            value:
                availableTimeAnchors.isEmpty
                ? "暂无"
                : timeAnchorTitle,
            detail:
                "\(timeAnchorCount) 个锚点",
            showsTrailingChevron: false
        ) {
            if availableTimeAnchors.isEmpty {
                optionSelectionPill(title: "暂无")
                    .opacity(0.56)
                    .accessibilityLabel("时间锚点")
                    .accessibilityValue("暂无")
            } else {
                Menu {
                    ForEach(availableTimeAnchors) { anchor in
                        Button {
                            selectedTimeAnchorID.wrappedValue =
                                anchor.id
                        } label: {
                            menuOptionLabel(
                                anchor.title,
                                isSelected:
                                    anchor.id
                                    == selectedTimeAnchorID
                                    .wrappedValue
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(title: timeAnchorTitle)
                }
                .accessibilityLabel("时间锚点")
                .accessibilityValue(timeAnchorTitle)
            }
        }
    }

    private var memoryDisplayRow: some View {
        configurationTextRow(
            title: "记忆表达",
            subtitle: "让回忆拥有属于自己的表达方式。",
            value: memoryDisplayValue,
            detail: memoryDisplayDetail,
            showsTrailingChevron: false,
            horizontalTrailingWidth: 112,
            onDetailTap: {
                showsMemoryDisplayDetail = true
            }
        ) {
            if availableMemoryDisplayStyles.isEmpty {
                optionSelectionPill(title: "暂无")
                    .opacity(0.56)
                    .accessibilityLabel("记忆表达")
                    .accessibilityValue("暂无")
            } else {
                Menu {
                    ForEach(
                        availableMemoryDisplayStyles,
                        id: \.self
                    ) { style in
                        Button {
                            selectedMemoryDisplayStyle.wrappedValue =
                                style
                        } label: {
                            menuOptionLabel(
                                style.displayTitle,
                                isSelected:
                                    style
                                    == selectedMemoryDisplayStyle
                                    .wrappedValue
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(
                        title: memoryDisplayValue,
                        expandsToRowWidth: false
                    )
                }
                .accessibilityLabel("记忆表达")
                .accessibilityValue(memoryDisplayValue)
            }
        }
    }

    private var borderStyleRow: some View {
        configurationTextRow(
            title: "边框样式",
            subtitle: "当前预设使用的边框。",
            value: borderStyleName,
            detail: "当前锁定",
            showsTrailingChevron: false
        ) {
            rowValueText(borderStyleName)
        }
    }

    private var regionContentRow: some View {
        Button(action: onOpenRegionContent) {
            configurationTextRow(
                title: "卡片内容",
                subtitle: "决定这段回忆最终如何呈现。",
                value: "编辑",
                detail: "",
                showsTrailingChevron: false
            ) {
                HStack(spacing: 5) {
                    Text("编辑")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
                .lineLimit(1)
                .frame(
                    maxWidth: .infinity,
                    alignment: .trailing
                )
            }
        }
        .buttonStyle(
            V1ConfigurationNavigationRowButtonStyle()
        )
        .accessibilityLabel("编辑卡片呈现")
        .accessibilityHint("决定这段回忆最终如何呈现。")
    }

    private var advancedModulesRow: some View {
        Button {
            showsAdvancedModulesSheet = true
        } label: {
            configurationTextRow(
                title: "高级模块",
                subtitle: "部分高级模块的展示形式选择",
                value: "编辑",
                detail: "",
                showsTrailingChevron: false
            ) {
                HStack(spacing: 5) {
                    Text("编辑")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
                .lineLimit(1)
                .frame(
                    maxWidth: .infinity,
                    alignment: .trailing
                )
            }
        }
        .buttonStyle(
            V1ConfigurationNavigationRowButtonStyle()
        )
        .accessibilityLabel("编辑高级模块")
        .accessibilityHint("部分高级模块的展示形式选择")
    }

    private var configurationStatusCard: some View {
        HStack(spacing: 10) {
            Image(systemName: configurationStatusSystemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(configurationStatusColor)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(configurationStatusTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(configurationStatusColor)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(configurationStatusColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(configurationStatusColor.opacity(0.14))
        )
        .padding(10)
        .accessibilityElement(children: .combine)
    }

    private var configurationStatusTitle: String {
        switch configurationStatus {
        case .idle: return "尚未保存当前配置"
        case .dirty: return "有未保存的修改"
        case .saving: return "正在保存当前配置"
        case .saved: return "当前配置已保存"
        case .subjectSynced: return "记忆对象已同步，等待保存"
        case .failure: return "保存失败"
        }
    }

    private var configurationStatusSystemImage: String {
        switch configurationStatus {
        case .idle: return "info.circle"
        case .dirty: return "pencil.circle.fill"
        case .saving: return "hourglass"
        case .saved: return "checkmark.circle.fill"
        case .subjectSynced: return "person.crop.circle.badge.checkmark"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }

    private var configurationStatusColor: Color {
        switch configurationStatus {
        case .failure: return Color.red
        case .idle, .dirty, .saving, .saved, .subjectSynced:
            return Color.secondary
        }
    }

    private func groupedSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            adaptiveSectionHeader(
                title: title,
                subtitle: subtitle
            )

            VStack(spacing: 0) {
                content()
            }
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
        .padding(14)
        .v1CardChrome()
    }

    @ViewBuilder
    private func adaptiveSectionHeader(
        title: String,
        subtitle: String
    ) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        } else {
            HStack(
                alignment: .firstTextBaseline,
                spacing: 8
            ) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: true, vertical: false)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
        }
    }

    private var subjectDisplayName: String {
        let name =
            subject?
            .identity
            .displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard let name,
              !name.isEmpty else {
            return "记忆对象"
        }

        return name
    }

    private var subjectIcon: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.11))

            if let subjectAvatarPreviewImagePath,
               let image = UIImage(
                contentsOfFile:
                    subjectAvatarPreviewImagePath
               ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.purple)
            }
        }
        .frame(
            width: V1CompactInformationRowMetrics.iconSize,
            height: V1CompactInformationRowMetrics.iconSize
        )
    }


    private var logoIcon: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius:
                    V1CompactInformationRowMetrics.iconCornerRadius,
                style: .continuous
            )
            .fill(Color.blue.opacity(0.10))

            if logoMode == .subjectAvatar,
               let subjectAvatarPreviewImagePath,
               let image = UIImage(
                contentsOfFile:
                    subjectAvatarPreviewImagePath
               ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                V1CompactInformationRowMetrics
                                .iconCornerRadius,
                            style: .continuous
                        )
                    )
            } else if logoMode == .customUpload,
                      let customLogoImagePath,
                      let image = UIImage(
                        contentsOfFile:
                            customLogoImagePath
                      ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(7)
            } else {
                Image(systemName: "apple.logo")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.78))
            }
        }
        .frame(
            width: V1CompactInformationRowMetrics.iconSize,
            height: V1CompactInformationRowMetrics.iconSize
        )
    }

    private func configurationTextRow<Trailing: View>(
        title: String,
        subtitle: String,
        value: String,
        detail: String,
        showsTrailingChevron: Bool = true,
        horizontalTrailingWidth: CGFloat = 128,
        onDetailTap: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        configurationRow(
            icon: Optional<EmptyView>.none,
            title: title,
            subtitle: subtitle,
            value: value,
            detail: detail,
            showsTrailingChevron:
                showsTrailingChevron,
            horizontalTrailingWidth: horizontalTrailingWidth,
            onDetailTap: onDetailTap,
            trailing: trailing
        )
    }

    private func configurationRow<Icon: View, Trailing: View>(
        icon: Icon?,
        title: String,
        subtitle: String,
        value: String,
        detail: String,
        showsTrailingChevron: Bool = true,
        horizontalTrailingWidth: CGFloat = 128,
        onDetailTap: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        let trailingSpacing: CGFloat =
            detail.isEmpty && showsTrailingChevron == false
            ? 0
            : 4

        return adaptiveConfigurationRow(
            icon: icon,
            title: title,
            subtitle: subtitle,
            detail: detail,
            trailingSpacing: trailingSpacing,
            horizontalTrailingWidth: horizontalTrailingWidth,
            showsTrailingChevron: showsTrailingChevron,
            onDetailTap: onDetailTap,
            trailing: trailing
        )
        .padding(
            .horizontal,
            V1CompactInformationRowMetrics.horizontalPadding
        )
        .padding(
            .vertical,
            V1CompactInformationRowMetrics.verticalPadding
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func adaptiveConfigurationRow<Icon: View, Trailing: View>(
        icon: Icon?,
        title: String,
        subtitle: String,
        detail: String,
        trailingSpacing: CGFloat,
        horizontalTrailingWidth: CGFloat,
        showsTrailingChevron: Bool,
        onDetailTap: (() -> Void)?,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalConfigurationRow(
                icon: icon,
                title: title,
                subtitle: subtitle,
                detail: detail,
                trailingSpacing: trailingSpacing,
                showsTrailingChevron: showsTrailingChevron,
                onDetailTap: onDetailTap,
                trailing: trailing
            )
        } else {
            ViewThatFits(in: .horizontal) {
                horizontalConfigurationRow(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    detail: detail,
                    trailingSpacing: trailingSpacing,
                    horizontalTrailingWidth: horizontalTrailingWidth,
                    showsTrailingChevron: showsTrailingChevron,
                    onDetailTap: onDetailTap,
                    trailing: trailing
                )

                verticalConfigurationRow(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    detail: detail,
                    trailingSpacing: trailingSpacing,
                    showsTrailingChevron: showsTrailingChevron,
                    onDetailTap: onDetailTap,
                    trailing: trailing
                )
            }
        }
    }

    private func horizontalConfigurationRow<Icon: View, Trailing: View>(
        icon: Icon?,
        title: String,
        subtitle: String,
        detail: String,
        trailingSpacing: CGFloat,
        horizontalTrailingWidth: CGFloat,
        showsTrailingChevron: Bool,
        onDetailTap: (() -> Void)?,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(
            alignment: .center,
            spacing: V1CompactInformationRowMetrics.contentSpacing
        ) {
            configurationRowHeading(
                icon: icon,
                title: title,
                subtitle: subtitle
            )

            Spacer(minLength: 8)

            configurationRowTrailing(
                detail: detail,
                trailingSpacing: trailingSpacing,
                showsTrailingChevron: showsTrailingChevron,
                onDetailTap: onDetailTap,
                trailing: trailing
            )
            .frame(
                minWidth: 72,
                maxWidth: horizontalTrailingWidth,
                alignment: .trailing
            )
        }
    }

    private func verticalConfigurationRow<Icon: View, Trailing: View>(
        icon: Icon?,
        title: String,
        subtitle: String,
        detail: String,
        trailingSpacing: CGFloat,
        showsTrailingChevron: Bool,
        onDetailTap: (() -> Void)?,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configurationRowHeading(
                icon: icon,
                title: title,
                subtitle: subtitle
            )

            configurationRowTrailing(
                detail: detail,
                trailingSpacing: trailingSpacing,
                showsTrailingChevron: showsTrailingChevron,
                onDetailTap: onDetailTap,
                trailing: trailing
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func configurationRowHeading<Icon: View>(
        icon: Icon?,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(
            alignment: .center,
            spacing: V1CompactInformationRowMetrics.contentSpacing
        ) {
            if let icon {
                icon
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
        }
    }

    private func configurationRowTrailing<Trailing: View>(
        detail: String,
        trailingSpacing: CGFloat,
        showsTrailingChevron: Bool,
        onDetailTap: (() -> Void)?,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(alignment: .trailing, spacing: trailingSpacing) {
            trailing()

            if !detail.isEmpty {
                if let onDetailTap {
                    Button(action: onDetailTap) {
                        interactiveConfigurationRowDetailLabel(
                            detail
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("查看记忆表达完整说明")
                    .accessibilityHint("显示完整内容")
                } else {
                    configurationRowDetailLabel(detail)
                }
            }

            if showsTrailingChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private func interactiveConfigurationRowDetailLabel(
        _ detail: String
    ) -> some View {
        HStack(spacing: 1) {
            Text(compactConfigurationDetail(detail))
                .foregroundStyle(.secondary)

            Text("…")
                .foregroundStyle(Color.accentColor)
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }

    private func configurationRowDetailLabel(
        _ detail: String
    ) -> some View {
        Text(detail)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private func compactConfigurationDetail(
        _ detail: String
    ) -> String {
        let firstPhase =
            detail
            .split(
                separator: "｜",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            .first
            .map(String.init)
            ?? detail

        return String(firstPhase.prefix(10))
    }

    private func rowValueText(
        _ title: String,
        isAction: Bool = false
    ) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(
                isAction
                ? Color.accentColor
                : Color.primary.opacity(0.72)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func optionSelectionPill(
        title: String,
        expandsToRowWidth: Bool = true
    ) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .allowsTightening(true)
                .truncationMode(.tail)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(
            maxWidth: expandsToRowWidth ? CGFloat.infinity : nil,
            alignment: .trailing
        )
        .background(
            RoundedRectangle(
                cornerRadius:
                    ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius:
                    ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    @ViewBuilder
    private func menuOptionLabel(
        _ title: String,
        isSelected: Bool
    ) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

}

struct V1ConfigurationActionFooter: View {

    @State
    private var showsResetConfigurationConfirmation = false

    @State
    private var showsDeleteConfigurationConfirmation = false

    let configurationStatus: V1ConfigurationStatus
    let isSavingConfiguration: Bool
    let onSaveCurrentConfiguration: () -> Void
    let onCreateConfiguration: () -> Void
    let onResetConfiguration: () -> Void
    let onDeleteConfiguration: () -> Void

    var body: some View {
        configurationActionRow
            .padding(.horizontal, ConfigurationUI.contentColumnPadding)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(
                .ultraThinMaterial
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
            }
            .alert(
                "恢复默认配置？",
                isPresented: $showsResetConfigurationConfirmation
            ) {
                Button("取消", role: .cancel) {}
                Button("恢复默认", role: .destructive) {
                    onResetConfiguration()
                }
            } message: {
                Text("当前未保存的修改会被默认内容替换。此操作无法撤销。")
            }
            .alert(
                "删除当前配置？",
                isPresented: $showsDeleteConfigurationConfirmation
            ) {
                Button("取消", role: .cancel) {}
                Button("删除配置", role: .destructive) {
                    onDeleteConfiguration()
                }
            } message: {
                Text("本地配置库中的备份会保留。此操作无法撤销。")
            }
    }

    private var configurationActionRow: some View {
        ZStack(alignment: .bottom) {
            HStack {
                Spacer(minLength: 0)

                moreActionsMenu
            }

            centeredPrimaryAction
        }
    }

    private var centeredPrimaryAction: some View {
        Button(action: onSaveCurrentConfiguration) {
            Label(saveActionTitle, systemImage: saveActionSystemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .buttonStyle(saveActionButtonStyle)
        .disabled(isSavingConfiguration || configurationStatus == .saved)
    }

    private var saveActionButtonStyle:
        V1ConfigurationSaveButtonStyle {
        V1ConfigurationSaveButtonStyle(
            isRestrained: configurationStatus == .saved
        )
    }

    private var moreActionsMenu: some View {
        Menu {
            Button("另存为新配置", systemImage: "plus.square") {
                onCreateConfiguration()
            }
            Button("恢复默认", systemImage: "arrow.counterclockwise") {
                showsResetConfigurationConfirmation = true
            }
            Button("删除当前配置", systemImage: "trash", role: .destructive) {
                showsDeleteConfigurationConfirmation = true
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("更多配置操作")
    }

    private var saveActionTitle: String {
        if isSavingConfiguration { return "正在保存" }
        switch configurationStatus {
        case .saved: return "已保存"
        case .failure: return "重新保存"
        default: return "保存当前配置"
        }
    }

    private var saveActionSystemImage: String {
        if isSavingConfiguration { return "hourglass" }
        switch configurationStatus {
        case .saved: return "checkmark.circle.fill"
        case .failure: return "arrow.clockwise.circle.fill"
        default: return "tray.and.arrow.down"
        }
    }

}

struct V1MemoryExpressionPreviewSheet: View {

    @Environment(\.dismiss)
    private var dismiss

    let memoryDisplayValue: String
    let memoryDisplayDetail: String

    private var detailLines: [String] {
        memoryDisplayDetail
            .split(separator: "｜", omittingEmptySubsequences: true)
            .map(String.init)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("让回忆拥有属于自己的表达方式。")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("当前选择：\(memoryDisplayValue)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("一段回忆会这样呈现")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(
                            Array(detailLines.enumerated()),
                            id: \.offset
                        ) { _, line in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: "text.quote")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 18)

                                Text(line)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(
                            cornerRadius: ConfigurationUI.smallCornerRadius,
                            style: .continuous
                        )
                        .fill(ConfigurationUI.controlBackground)
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: ConfigurationUI.smallCornerRadius,
                            style: .continuous
                        )
                        .stroke(ConfigurationUI.faintHairline)
                    )
                }
                .padding(.horizontal, ConfigurationUI.contentColumnPadding)
                .padding(.vertical, 18)
            }
            .navigationTitle("记忆表达")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct V1ConfigurationSaveButtonStyle: ButtonStyle {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.isEnabled)
    private var isEnabled

    let isRestrained: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(
                isRestrained
                ? Color.primary.opacity(0.58)
                : Color.white
            )
            .padding(.horizontal, 14)
            .frame(
                width: V1CompactBottomActionMetrics.width,
                height: V1CompactBottomActionMetrics.height
            )
            .background(
                RoundedRectangle(
                    cornerRadius:
                        V1CompactBottomActionMetrics.cornerRadius,
                    style: .continuous
                )
                .fill(
                    isRestrained
                    ? ConfigurationUI.controlBackground
                    : Color.accentColor.opacity(
                        MemoMarkDesignTokens
                            .Layout
                            .compactPrimaryActionTintOpacity
                    )
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius:
                        V1CompactBottomActionMetrics.cornerRadius,
                    style: .continuous
                )
                .stroke(
                    isRestrained
                    ? ConfigurationUI.faintHairline
                    : Color.clear
                )
            )
            .opacity(
                isEnabled
                ? (configuration.isPressed ? 0.78 : 1)
                : (isRestrained ? 1 : 0.56)
            )
            .scaleEffect(
                configuration.isPressed && !reduceMotion
                ? 0.97
                : 1
            )
            .shadow(
                color:
                    isRestrained
                    ? Color.clear
                    : Color.accentColor.opacity(0.16),
                radius: 12,
                y: 5
            )
            .animation(
                reduceMotion
                ? nil
                : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct V1ConfigurationActionButtonStyle:
    ButtonStyle {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .opacity(
                isEnabled
                ? (configuration.isPressed ? 0.72 : 1)
                : 0.56
            )
            .scaleEffect(
                configuration.isPressed && !reduceMotion
                ? 0.97
                : 1
            )
            .animation(
                reduceMotion
                ? nil
                : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct V1ConfigurationNavigationRowButtonStyle:
    ButtonStyle {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .background(
                ConfigurationUI.selectedBackground
                    .opacity(
                        configuration.isPressed
                        ? 1
                        : 0
                    )
            )
            .opacity(
                configuration.isPressed
                ? 0.76
                : 1
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .animation(
                reduceMotion
                ? nil
                : .easeOut(duration: 0.1),
                value: configuration.isPressed
            )
    }
}
#endif
