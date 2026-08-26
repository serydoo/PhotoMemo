#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct V1ConfigurationOutputBindings {

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

    @Binding
    var usesCustomMemoryWriteText: Bool

    @Binding
    var customMemoryWriteText: String

    let shouldWritePhotosDescription: Bool

    let resolvedMemoryWriteText: String
}

struct V1ConfigurationOptionList: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State
    private var showsAdvancedModulesSheet = false

    let subject: MemorySubject?
    @Binding var disclosureState: V1ConfigurationDisclosureState
    let subjectAvatarPreviewImagePath: String?
    @Binding var presentationStyle: RecordCardPresentationStyle
    @Binding var logoMode: V1LogoMode
    @Binding var selectedLogoItem: PhotosPickerItem?
    @Binding var isLogoPickerPresented: Bool
    let logoValue: String
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
    let output: V1ConfigurationOutputBindings
    let configurationStatus: V1ConfigurationStatus
    let onOpenRegionContent: () -> Void

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            memorySourceSection
            configurationSectionDivider

            memoryExpressionSection
            configurationSectionDivider

            expressionStyleSection
            configurationSectionDivider

            groupedSection(
                title: "configuration.layout.title",
                subtitle: "configuration.layout.subtitle",
                isExpanded: disclosureBinding(for: .cardLayout),
                resultTitle: "configuration.layout.result.preview",
                expandedAccessibilityLabel: "configuration.layout.accessibility.collapse",
                collapsedAccessibilityLabel: "configuration.layout.accessibility.expand"
            ) {
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
            configurationSectionDivider

            photoDescriptionSection
            configurationSectionDivider

            outputDestinationSection

        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.2),
            value: disclosureState
        )
        .sheet(isPresented: $showsAdvancedModulesSheet) {
            V1AdvancedModulesSheet(
                locationPresentation: locationPresentation,
                selectedLocationOptionID: selectedLocationOptionID,
                timePresentation: timePresentation,
                selectedTimeOptionID: selectedTimeOptionID,
                selectedTimeSupplement: selectedTimeSupplement
            )
        }
        .photosPicker(
            isPresented: $isLogoPickerPresented,
            selection: $selectedLogoItem,
            matching: .images
        )
    }

    private var configurationSectionDivider: some View {
        V1HorizontalDivider(horizontalInset: 2)
    }

    private var photoDescriptionSection: some View {
        return groupedSection(
            title: "configuration.photo_description.title",
            subtitle: "configuration.photo_description.subtitle",
            isExpanded: disclosureBinding(for: .photoDescription),
            resultTitle: output.shouldWritePhotosDescription
                ? "configuration.state.enabled"
                : "configuration.state.disabled",
            expandedAccessibilityLabel: "configuration.photo_description.accessibility.collapse",
            collapsedAccessibilityLabel: "configuration.photo_description.accessibility.expand"
        ) {
            V1OutputPhotoDescriptionContent(
                usesCustomMemoryWriteText:
                    output.$usesCustomMemoryWriteText,
                customMemoryWriteText:
                    output.$customMemoryWriteText,
                resolvedMemoryWriteText:
                    output.resolvedMemoryWriteText
            )
            .padding(.horizontal, 14)
            .padding(
                .vertical,
                V1SectionCardMetrics.cardVerticalPadding
            )
        }
    }

    private var outputDestinationSection: some View {
        groupedSection(
            title: "configuration.save_location.title",
            subtitle: "configuration.save_location.subtitle",
            isExpanded: disclosureBinding(for: .outputDestination),
            resultTitle: outputDestinationCurrentValue,
            expandedAccessibilityLabel: "configuration.save_location.accessibility.collapse",
            collapsedAccessibilityLabel: "configuration.save_location.accessibility.expand"
        ) {
            V1OutputDestinationContent(
                automaticallyFocusesNewAlbumName: false,
                outputTarget: output.$outputTarget,
                availableAlbums: output.availableAlbums,
                selectedExistingAlbumIdentifier:
                    output.$selectedExistingAlbumIdentifier,
                newAlbumName: output.$newAlbumName,
                isLoadingAlbums: output.isLoadingAlbums,
                albumStatusMessage: output.albumStatusMessage,
                onReloadAlbums: output.onReloadAlbums
            )
            .padding(.horizontal, 14)
            .padding(
                .vertical,
                V1SectionCardMetrics.cardVerticalPadding
            )
        }
    }

    private var expressionStyleSection: some View {
        VStack(
            alignment: .leading,
            spacing: V1SectionCardMetrics.cardHeaderContentSpacing
        ) {
            presentationStyleSectionHeader

            if disclosureState.isExpanded(for: .presentationStyle) {
                VStack(spacing: 0) {
                    configurationTextRow(
                        title: "当前样式",
                        subtitle: "configuration.card_style.subtitle",
                        value: presentationStyleTitle,
                        detail: "",
                        showsTrailingChevron: false
                    ) {
                        Menu {
                            ForEach(
                                RecordCardPresentationStyle.allCases,
                                id: \.self
                            ) { style in
                                Button {
                                    presentationStyle = style
                                } label: {
                                    menuOptionLabel(
                                        localized(title(for: style)),
                                        isSelected: style == presentationStyle
                                    )
                                }
                            }
                        } label: {
                            V1CompactSelectionLabel(
                                title: localized(presentationStyleTitle)
                            )
                        }
                        .accessibilityLabel(localized("卡片样式"))
                        .accessibilityValue(localized(presentationStyleTitle))
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(ConfigurationUI.panelBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ConfigurationUI.faintHairline)
                )
                .transition(.identity)
            }
        }
        .v1SectionSurfaceLayout()
    }

    private var presentationStyleTitle: String {
        title(for: presentationStyle)
    }

    private func title(
        for style: RecordCardPresentationStyle
    ) -> String {
        switch style {
        case .classicWhite:
            TemplatePreset.classicWhite.displayName(
                for: .interfaceStored
            )
        case .minimal:
            localized("极简")
        }
    }

    private var presentationStyleSectionHeader: some View {
        configurationSectionHeader(
            title: "configuration.card_style.title",
            subtitle: "configuration.card_style.subtitle",
            resultTitle: presentationStyleTitle,
            isExpanded: disclosureBinding(for: .presentationStyle),
            expandedAccessibilityLabel: "configuration.card_style.accessibility.collapse",
            collapsedAccessibilityLabel: "configuration.card_style.accessibility.expand"
        )
    }

    private var memorySourceSection: some View {
        VStack(
            alignment: .leading,
            spacing: V1SectionCardMetrics.cardHeaderContentSpacing
        ) {
            memorySourceSectionHeader

            if disclosureState.isExpanded(for: .memorySource) {
                VStack(spacing: 0) {
                    subjectRow
                    V1HorizontalDivider(
                        horizontalInset:
                            V1CompactInformationRowMetrics.horizontalPadding
                    )
                    timeAnchorRow
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
                .transition(.identity)
            }
        }
        .v1SectionSurfaceLayout()
    }

    private var memorySourceSectionHeader: some View {
        configurationSectionHeader(
            title: "configuration.memory_start.title",
            subtitle: "configuration.memory_start.subtitle",
            resultTitle: memorySourceSummary,
            isExpanded: disclosureBinding(for: .memorySource),
            expandedAccessibilityLabel: "configuration.memory_start.accessibility.collapse",
            collapsedAccessibilityLabel: "configuration.memory_start.accessibility.expand"
        )
    }

    private var memorySourceSummary: String {
        [
            subjectDisplayName,
            availableTimeAnchors.isEmpty
                ? localized("暂无时间锚点")
                : timeAnchorTitle
        ]
        .joined(separator: " · ")
    }

    private var memoryExpressionSection: some View {
        VStack(
            alignment: .leading,
            spacing: V1SectionCardMetrics.cardHeaderContentSpacing
        ) {
            memoryExpressionSectionHeader

            if disclosureState.isExpanded(for: .memoryExpression) {
                VStack(spacing: 0) {
                    memoryDisplayRow
                    memoryExpressionPreview
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
                .transition(.identity)
            }
        }
        .v1SectionSurfaceLayout()
    }

    private var memoryExpressionSectionHeader: some View {
        configurationSectionHeader(
            title: "configuration.expression.title",
            subtitle: "configuration.expression.subtitle",
            resultTitle: memoryDisplayValue,
            isExpanded: disclosureBinding(for: .memoryExpression),
            expandedAccessibilityLabel: "configuration.expression.accessibility.collapse",
            collapsedAccessibilityLabel: "configuration.expression.accessibility.expand"
        )
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
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var logoRow: some View {
        configurationRow(
            icon: logoIcon,
            title: "Logo 标识",
            subtitle: logoSubtitle,
            value: logoValue,
            detail: "",
            showsTrailingChevron: false
        ) {
            HStack(spacing: 6) {
                Menu {
                    ForEach(V1LogoMode.allCases) { mode in
                        Button {
                            logoMode = mode
                        } label: {
                            menuOptionLabel(
                                localized(mode.title),
                                isSelected: mode == logoMode
                            )
                        }
                    }
                } label: {
                    V1CompactSelectionLabel(
                        title: localized(logoValue)
                    )
                }
                .accessibilityLabel(localized("Logo 标识"))
                .accessibilityValue(localized(logoValue))

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
                    .frame(
                        minWidth: ConfigurationUI.minimumInteractiveHeight,
                        minHeight: ConfigurationUI.minimumInteractiveHeight
                    )
                    .contentShape(Rectangle())
                    .disabled(isOptimizingLogo)
                    .accessibilityLabel(
                        localized(
                            isOptimizingLogo
                            ? "正在优化 Logo"
                            : "选择 Logo"
                        )
                    )
                }
            }
        }
    }

    private var timeAnchorRow: some View {
        configurationTextRow(
            title: "时间锚点",
            subtitle: timeAnchorSubtitle,
            value:
                availableTimeAnchors.isEmpty
                ? "暂无"
                : timeAnchorTitle,
            detail: "",
            showsTrailingChevron: false
        ) {
            if availableTimeAnchors.isEmpty {
                V1CompactSelectionLabel(title: localized("暂无"))
                    .opacity(0.56)
                    .accessibilityLabel(localized("时间锚点"))
                    .accessibilityValue(localized("暂无"))
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
                    V1CompactSelectionLabel(title: timeAnchorTitle)
                }
                .accessibilityLabel(localized("时间锚点"))
                .accessibilityValue(timeAnchorTitle)
            }
        }
    }

    private var memoryDisplayRow: some View {
        configurationTextRow(
            title: "表达方式",
            subtitle: memoryDisplaySubtitle,
            value: memoryDisplayValue,
            detail: "",
            showsTrailingChevron: false
        ) {
            if availableMemoryDisplayStyles.isEmpty {
                V1CompactSelectionLabel(title: localized("暂无"))
                    .opacity(0.56)
                    .accessibilityLabel(localized("表达方式"))
                    .accessibilityValue(localized("暂无"))
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
                                localized(style.displayTitle),
                                isSelected:
                                    style
                                    == selectedMemoryDisplayStyle
                                    .wrappedValue
                            )
                        }
                    }
                } label: {
                    V1CompactSelectionLabel(
                        title: localized(memoryDisplayValue)
                    )
                }
                .accessibilityLabel(localized("表达方式"))
                .accessibilityValue(localized(memoryDisplayValue))
            }
        }
    }

    private var memoryDisplaySubtitle: String {
        String.localizedStringWithFormat(
            localized("围绕时间锚点，可选择 %lld 种表达方式。"),
            Int64(availableMemoryDisplayStyles.count)
        )
    }

    private var memoryExpressionPreviewLines: [String] {
        let lines =
            memoryDisplayDetail
            .split(separator: "｜", omittingEmptySubsequences: true)
            .map(String.init)

        return lines.isEmpty ? [localized("暂无表达预览")] : lines
    }

    private var memoryExpressionPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localized("这张照片会这样表达"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(
                Array(memoryExpressionPreviewLines.enumerated()),
                id: \.offset
            ) { _, line in
                Text(line)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
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
        .padding(.horizontal, V1CompactInformationRowMetrics.horizontalPadding)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(localized("这张照片会这样表达"))
        .accessibilityValue(memoryExpressionPreviewLines.joined(separator: "，"))
    }

    private var regionContentRow: some View {
        Button(action: onOpenRegionContent) {
            configurationTextRow(
                title: "卡片内容",
                subtitle: "决定这段回忆最终如何呈现。",
                value: "",
                detail: "",
                showsTrailingChevron: true
            ) {
                EmptyView()
            }
        }
        .buttonStyle(
            V1ConfigurationNavigationRowButtonStyle()
        )
        .accessibilityLabel(localized("卡片内容"))
        .accessibilityHint(localized("决定这段回忆最终如何呈现。"))
    }

    private var advancedModulesRow: some View {
        Button {
            showsAdvancedModulesSheet = true
        } label: {
            configurationTextRow(
                title: "时间与地点",
                subtitle: "configuration.time_place.subtitle",
                value: "",
                detail: "",
                showsTrailingChevron: true
            ) {
                EmptyView()
            }
        }
        .buttonStyle(
            V1ConfigurationNavigationRowButtonStyle()
        )
        .accessibilityLabel(localized("时间与地点"))
        .accessibilityHint(localized("configuration.time_place.subtitle"))
    }

    private var configurationStatusCard: some View {
        HStack(spacing: 10) {
            Image(systemName: configurationStatusSystemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(configurationStatusColor)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(localized(configurationStatusTitle))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(configurationStatusColor)

            Spacer(minLength: 0)
        }
        .padding(
            .horizontal,
            V1CompactInformationRowMetrics.horizontalPadding
        )
        .padding(
            .vertical,
            V1CompactInformationRowMetrics.verticalPadding
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var configurationStatusTitle: String {
        switch configurationStatus {
        case .idle: return "尚未保存当前配置"
        case .dirty: return "有未保存的修改"
        case .saving: return "正在保存当前配置"
        case .saved: return "当前配置已保存"
        case .savedWithWarning: return "配置已保存，但需要留意"
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
        case .savedWithWarning: return "exclamationmark.triangle.fill"
        case .subjectSynced: return "person.crop.circle.badge.checkmark"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }

    private var configurationStatusColor: Color {
        switch configurationStatus {
        case .failure: return Color.red
        case .savedWithWarning: return Color.orange
        case .idle, .dirty, .saving, .saved, .subjectSynced:
            return Color.secondary
        }
    }

    private func disclosureBinding(
        for section: V1ConfigurationDisclosureState.Section
    ) -> Binding<Bool> {
        Binding(
            get: {
                disclosureState.isExpanded(for: section)
            },
            set: { isExpanded in
                disclosureState.setExpanded(
                    isExpanded,
                    for: section
                )
            }
        )
    }

    private func groupedSection<Content: View>(
        title: String,
        subtitle: String,
        isExpanded: Binding<Bool>,
        resultTitle: String,
        expandedAccessibilityLabel: String,
        collapsedAccessibilityLabel: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: V1SectionCardMetrics.cardHeaderContentSpacing
        ) {
            configurationSectionHeader(
                title: title,
                subtitle: subtitle,
                resultTitle: resultTitle,
                isExpanded: isExpanded,
                expandedAccessibilityLabel: expandedAccessibilityLabel,
                collapsedAccessibilityLabel: collapsedAccessibilityLabel
            )

            if isExpanded.wrappedValue {
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
                .transition(.identity)
            }
        }
        .v1SectionSurfaceLayout()
    }

    private func configurationSectionHeader(
        title: String,
        subtitle: String,
        resultTitle: String,
        isExpanded: Binding<Bool>,
        expandedAccessibilityLabel: String,
        collapsedAccessibilityLabel: String
    ) -> some View {
        V1ConfigurationCompactSectionRow(
            title: title,
            subtitle: subtitle,
            resultTitle: resultTitle,
            resultAccessibilityLabel: title,
            resultAccessibilityValue: resultTitle,
            isExpanded: isExpanded.wrappedValue,
            expandedAccessibilityLabel: expandedAccessibilityLabel,
            collapsedAccessibilityLabel: collapsedAccessibilityLabel,
            action: {
                isExpanded.wrappedValue.toggle()
            }
        )
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }

    private var outputDestinationCurrentValue: String {
        switch output.outputTarget {
        case .automatic:
            return MemoMarkAlbumSelection.defaultAlbumTitle

        case .applePhotos:
            return localized("output.destination.target.apple_photos")

        case .existingAlbum:
            return output.availableAlbums.first {
                $0.id == output.selectedExistingAlbumIdentifier
            }?.title ?? localized("configuration.save_location.unselected")

        case .newAlbum:
            let title = output.newAlbumName
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty
                ? localized("configuration.save_location.new_album")
                : title
        }
    }

    private var timeAnchorCountDetail: String {
        String(
            format: localized("%d 个锚点"),
            locale: MemoMarkLanguage.interfaceStored.locale,
            timeAnchorCount
        )
    }

    private var timeAnchorSubtitle: String {
        String(
            format: localized("回忆对象重要时刻 · %@"),
            locale: MemoMarkLanguage.interfaceStored.locale,
            timeAnchorCountDetail
        )
    }

    private var logoSubtitle: String {
        localized("让卡片留下你的标识。")
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
            return localized("记忆对象")
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
                    .clipShape(Circle())
            } else if logoMode == .customUpload,
                      let customLogoImagePath,
                      let image = UIImage(
                        contentsOfFile:
                            customLogoImagePath
                      ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(
                            Color.primary.opacity(0.08),
                            lineWidth: 1
                        )
                    )
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
        horizontalTrailingWidth: CGFloat =
            ConfigurationUI.compactTrailingControlWidth,
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
        horizontalTrailingWidth: CGFloat =
            ConfigurationUI.compactTrailingControlWidth,
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
                trailing: trailing
            )
        } else {
            horizontalConfigurationRow(
                icon: icon,
                title: title,
                subtitle: subtitle,
                detail: detail,
                trailingSpacing: trailingSpacing,
                horizontalTrailingWidth: horizontalTrailingWidth,
                showsTrailingChevron: showsTrailingChevron,
                trailing: trailing
            )
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
                Text(localized(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(localized(subtitle))
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
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(alignment: .trailing, spacing: trailingSpacing) {
            trailing()

            if !detail.isEmpty {
                configurationRowDetailLabel(detail)
            }

            if showsTrailingChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private func configurationRowDetailLabel(
        _ detail: String
    ) -> some View {
        Text(localized(detail))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private func rowValueText(
        _ title: String,
        isAction: Bool = false
    ) -> some View {
        Text(localized(title))
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

    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

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
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .alert(isPresented: $showsResetConfigurationConfirmation) {
                Alert(
                    title: Text(localized("configuration.action.reset.title", fallback: "恢复默认配置？")),
                    message: Text(localized("当前未保存的修改会被默认内容替换。此操作无法撤销。")),
                    primaryButton: .cancel(Text(localized("取消"))),
                    secondaryButton: .destructive(
                        Text(localized("恢复默认")),
                        action: onResetConfiguration
                    )
                )
            }
            .alert(isPresented: $showsDeleteConfigurationConfirmation) {
                Alert(
                    title: Text(localized("configuration.action.delete.title", fallback: "删除当前配置？")),
                    message: Text(localized("本地配置库中的备份会保留。此操作无法撤销。")),
                    primaryButton: .cancel(Text(localized("取消"))),
                    secondaryButton: .destructive(
                        Text(localized("删除配置")),
                        action: onDeleteConfiguration
                    )
                )
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
        .padding(.horizontal, MemoMarkDesignTokens.Layout.compactActionClusterHorizontalPadding)
        .padding(.vertical, MemoMarkDesignTokens.Layout.compactActionClusterVerticalPadding)
        .frame(maxWidth: MemoMarkDesignTokens.Layout.compactActionClusterMaxWidth)
        .background {
            if reduceTransparency {
                RoundedRectangle(
                    cornerRadius: MemoMarkDesignTokens.Layout.compactActionClusterCornerRadius,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            } else {
                RoundedRectangle(
                    cornerRadius: MemoMarkDesignTokens.Layout.compactActionClusterCornerRadius,
                    style: .continuous
                )
                .fill(.regularMaterial)
            }
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: MemoMarkDesignTokens.Layout.compactActionClusterCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
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
            Button {
                onCreateConfiguration()
            } label: {
                Label(localized("另存为新配置"), systemImage: "plus.square")
            }
            Button {
                showsResetConfigurationConfirmation = true
            } label: {
                Label(localized("恢复默认"), systemImage: "arrow.counterclockwise")
            }
            Button(role: .destructive) {
                showsDeleteConfigurationConfirmation = true
            } label: {
                Label(localized("删除当前配置"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(localized("更多配置操作"))
    }

    private var saveActionTitle: String {
        if isSavingConfiguration {
            return localized("output.save.saving")
        }
        switch configurationStatus {
        case .saved: return localized("output.save.saved")
        case .failure: return localized("output.save.retry")
        default: return localized("configuration.editor.save")
        }
    }

    private func localized(_ key: String, fallback: String? = nil) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: key,
            fallback: fallback ?? key
        )
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
                : MemoMarkDesignTokens.Semantic.onAccent
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
                    : Color.accentColor.opacity(
                        MemoMarkDesignTokens
                            .Layout
                            .compactPrimaryActionShadowOpacity
                    ),
                radius: MemoMarkDesignTokens
                    .Layout
                    .compactPrimaryActionShadowRadius,
                y: MemoMarkDesignTokens
                    .Layout
                    .compactPrimaryActionShadowOffsetY
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
