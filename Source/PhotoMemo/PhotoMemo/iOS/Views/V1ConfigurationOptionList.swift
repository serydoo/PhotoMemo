#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct V1ConfigurationOptionList: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

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
    let selectedLocationValue: String
    let selectedLocationOptionID: Binding<String>
    let isLocationSelectable: Bool
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
                logoRow
                V1HorizontalDivider(
                    horizontalInset:
                        V1CompactInformationRowMetrics.horizontalPadding
                )
                borderStyleRow
                V1HorizontalDivider(
                    horizontalInset:
                        V1CompactInformationRowMetrics.horizontalPadding
                )
                locationRow
                V1HorizontalDivider(
                    horizontalInset:
                        V1CompactInformationRowMetrics.horizontalPadding
                )
                regionContentRow
                V1HorizontalDivider(
                    horizontalInset:
                        V1CompactInformationRowMetrics.horizontalPadding
                )
                configurationStatusCard
            }

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
        HStack(alignment: .center, spacing: 10) {
            adaptiveSectionHeader(
                title: "记忆来源",
                subtitle: "决定智能模块生成的内容"
            )

            Spacer(minLength: 8)

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
            subtitle: "当前生效主体",
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
            subtitle: "设置输出卡片左侧标识",
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
            subtitle: "定义时间参考，计算年龄与天数",
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

    private var locationRow: some View {
        configurationTextRow(
            title: locationPresentation.title,
            subtitle: "控制位置信息的显示内容",
            value: selectedLocationValue,
            detail:
                isLocationSelectable
                ? locationValueDetail
                : "未插入位置模块",
            showsTrailingChevron: false
        ) {
            Menu {
                ForEach(locationPresentation.options) { option in
                    Button {
                        selectedLocationOptionID.wrappedValue =
                            option.id
                    } label: {
                        menuOptionLabel(
                            option.title,
                            isSelected:
                                option.id
                                == selectedLocationOptionID
                                .wrappedValue
                        )
                    }
                }
            } label: {
                optionSelectionPill(title: selectedLocationValue)
            }
            .accessibilityLabel(locationPresentation.title)
            .accessibilityValue(selectedLocationValue)
        }
    }

    private var memoryDisplayRow: some View {
        configurationTextRow(
            title: "记忆显示",
            subtitle: "自定义表达方式与记忆内容",
            value: memoryDisplayValue,
            detail: memoryDisplayDetail,
            showsTrailingChevron: false
        ) {
            if availableMemoryDisplayStyles.isEmpty {
                optionSelectionPill(title: "暂无")
                    .opacity(0.56)
                    .accessibilityLabel("记忆显示")
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
                    optionSelectionPill(title: memoryDisplayValue)
                }
                .accessibilityLabel("记忆显示")
                .accessibilityValue(memoryDisplayValue)
            }
        }
    }

    private var borderStyleRow: some View {
        configurationTextRow(
            title: "边框样式",
            subtitle: "当前公开边框样式",
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
                subtitle: "编辑卡片四个区域的模块与文字",
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
        .accessibilityLabel("编辑卡片内容")
        .accessibilityHint("编辑卡片四个区域的模块与文字")
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
        case .saved: return Color.accentColor
        case .dirty, .subjectSynced: return Color.orange
        case .failure: return Color.red
        case .idle, .saving: return Color.secondary
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

    private var locationValueDetail: String {
        locationPresentation.options
            .first { option in
                option.title == selectedLocationValue
            }?
            .note
        ?? "当前展示方式"
    }

    private func configurationTextRow<Trailing: View>(
        title: String,
        subtitle: String,
        value: String,
        detail: String,
        showsTrailingChevron: Bool = true,
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
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        let trailingSpacing: CGFloat =
            detail.isEmpty && showsTrailingChevron == false
            ? 0
            : 4

        return HStack(
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
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: trailingSpacing) {
                trailing()

                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                if showsTrailingChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(
                minWidth: 72,
                maxWidth: 128,
                alignment: .trailing
            )
        }
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

    private func optionSelectionPill(title: String) -> some View {
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
        .frame(maxWidth: .infinity, alignment: .trailing)
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
                .v1CompactBottomPrimaryAction()
        }
        .buttonStyle(V1CompactPrimaryActionButtonStyle())
        .disabled(isSavingConfiguration)
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
