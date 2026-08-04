#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCard: View {

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    @ObservedObject
    var session: ConfigurationSession

    @State
    private var isRenamingMemoryPreset = false

    @State
    private var isModuleLibraryExpanded = false

    var body: some View {
        ScrollView {
            VStack(spacing: ConfigurationUI.sectionSpacing) {
                configurationContext
                cardSurface
                regionStrip
                configurationComponentDock
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 48)
            .padding(.vertical, 36)
        }
        .background(ConfigurationUI.appBackground)
    }

    private var configurationContext: some View {
        InteractiveMemoryCardConfigurationContext(
            memoryPresets: session.state.memoryPresets,
            selectedMemoryPresetID: selectedMemoryPresetBinding,
            currentTimeAnchorDescription: session.currentTimeAnchorDescription,
            presetStatusText:
                ConfigurationCenterSessionBindingPresenter
                .presetStatusText(session: session),
            memoryPresetTitle: memoryPresetTitleBinding,
            isRenamingMemoryPreset: $isRenamingMemoryPreset,
            onReset: {
                withAnimation(configurationAnimation) {
                    session.resetSelectedMemoryPreset()
                }
            },
            onSave: {
                withAnimation(configurationAnimation) {
                    session.saveCurrentMemoryPreset()
                }
            },
            onCreate: {
                withAnimation(configurationAnimation) {
                    session.createMemoryPresetFromCurrent()
                }
            }
        )
    }

    private var configurationAnimation: Animation? {
        accessibilityReduceMotion
            ? nil
            : .easeInOut(duration: 0.16)
    }

    private var cardSurface: some View {
        InteractiveMemoryCardCompactPreview(
            leftPrimaryText: previewText(
                for: CardRegion.region(for: .leftPrimary)
            ),
            leftSecondaryText: previewText(
                for: CardRegion.region(for: .leftSecondary)
            ),
            rightPrimaryText: formattedCaptureSummaryText,
            rightSecondaryText: previewText(
                for: CardRegion.region(for: .rightSecondary)
            ),
            badgeSystemImage: selectedBadgeName,
            badgeTitle: selectedBadgeTitle,
            selectedRegion: selectedRegion,
            hoveredRegion: hoveredRegion,
            onSelectRegion: { region in
                session.select(
                    CardRegionBehavior(region: region)
                )
            },
            onHoverRegion: { region in
                session.hoverRegion(region)
            }
        )
    }

    private func textRegion(
        _ region: CardRegion,
        primary: String,
        secondary: String?,
        style: BottomCardTextStyle
    ) -> some View {
        cardRegionButton(
            region,
            accessibilityValue: secondary.map {
                "\(primary), \($0)"
            } ?? primary
        ) {
            VStack(alignment: .leading, spacing: 5) {
                Text(primary)
                    .font(style.primaryFont)
                    .foregroundStyle(style.primaryColor)
                    .lineLimit(style.primaryLineLimit)
                    .minimumScaleFactor(0.74)
                    .fixedSize(horizontal: false, vertical: true)

                if let secondary {
                    Text(secondary)
                        .font(style.secondaryFont)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    private func pm004TextRegion(
        _ region: CardRegion,
        spec _: SlotSpec,
        title: String,
        value: String,
        systemImage: String,
        style: BottomCardTextStyle
    ) -> some View {
        cardRegionButton(
            region,
            accessibilityValue: value
        ) {
            VStack(
                alignment: .leading,
                spacing: RendererConstants.Grid.xSmall / 2
            ) {
                HStack(spacing: RendererConstants.Grid.xSmall / 2) {
                    Image(systemName: systemImage)
                        .font(
                            .system(
                                size:
                                    RendererConstants
                                    .Typography
                                    .captionSize,
                                weight:
                                    RendererConstants
                                    .Typography
                                    .regularWeight
                            )
                        )

                    Text(title)
                        .font(
                            .system(
                                size:
                                    RendererConstants
                                    .Typography
                                    .captionSize,
                                weight:
                                    RendererConstants
                                    .Typography
                                    .regularWeight
                            )
                        )
                }
                .foregroundStyle(
                    RendererConstants.ColorPalette.secondaryText
                )

                Text(value.isEmpty ? " " : value)
                    .font(style.primaryFont)
                    .foregroundStyle(style.primaryColor)
                    .lineLimit(style.primaryLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var formattedTimelineText: String {
        let parts =
            previewText(
                for: CardRegion.region(for: .leftSecondary)
            )
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return "记录于\n\(parts[0])\n\(parts[1])"
        }

        return previewText(
            for: CardRegion.region(for: .leftSecondary)
        )
    }

    private var formattedCaptureSummaryText: String {
        let facts =
            previewText(
                for: CardRegion.region(for: .rightPrimary)
            )
            .split(separator: " ")
            .map(String.init)
            .prefix(RendererConstants.CaptureSummary.allowedFactCount)

        guard !facts.isEmpty else {
            return previewText(
                for: CardRegion.region(for: .rightPrimary)
            )
        }

        return facts.joined(separator: " ")
    }

    private func slotPosition(
        _ spec: SlotSpec,
        in size: CGSize
    ) -> CGPoint {
        CGPoint(
            x:
                size.width * spec.anchor.x
                + slotWidth(spec, in: size) / 2,
            y:
                size.height * spec.anchor.y
                + slotHeight(spec, in: size) / 2
        )
    }

    private func slotWidth(
        _ spec: SlotSpec,
        in size: CGSize
    ) -> CGFloat {
        size.width * spec.size.width
    }

    private func slotHeight(
        _ spec: SlotSpec,
        in size: CGSize
    ) -> CGFloat {
        size.height * spec.size.height
    }

    private var regionStrip: some View {
        InteractiveMemoryCardRegionStrip(
            selectedRegion: selectedRegion,
            onSelectRegion: { region in
                session.select(
                    CardRegionBehavior(region: region)
                )
            }
        )
    }

    private var configurationComponentDock: some View {
        InteractiveMemoryCardConfigurationComponentDock(
            isModuleLibraryExpanded: $isModuleLibraryExpanded,
            visibleInsertableModules: visibleInsertableModules,
            selectedRegionSemanticTitle: selectedRegion.semanticTitle,
            currentOutputPreview: session.currentOutputPreview,
            selectedOutputOptionTitle: session.selectedOutputOption.title,
            selectedStorageOptionTitle: session.selectedStorageOption.title,
            selectedStorageOptionNote: session.selectedStorageOption.note,
            memoryWriteDescription:
                ConfigurationCenterSessionBindingPresenter
                .memoryWriteDescription(session: session),
            usesCustomMemoryWriteText: session.usesCustomMemoryWriteText,
            memoryWritePlaceholder:
                ConfigurationCenterSessionBindingPresenter
                .customMemoryWritePlaceholder,
            memoryWritePreviewTitle:
                ConfigurationCenterSessionBindingPresenter
                .memoryWritePreviewTitle(session: session),
            resolvedMemoryWriteText: session.resolvedMemoryWriteText,
            storageOptionBinding: storageOptionBinding,
            memoryWriteToggleBinding: memoryWriteToggleBinding,
            memoryWriteTextBinding: memoryWriteTextBinding,
            onInsertModule: { module in
                session.appendPreviewModule(
                    title: module.title,
                    value: module.previewValue,
                    systemImage: module.systemImage,
                    token: module.centerToken
                )
            }
        )
    }

    private func cardRegionButton<Content: View>(
        _ region: CardRegion,
        accessibilityValue: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            session.select(
                CardRegionBehavior(region: region)
            )
        } label: {
            content()
                .modifier(
                    CardRegionChrome(
                        region: region,
                        selectedRegion: selectedRegion,
                        hoveredRegion: hoveredRegion
                    )
                )
        }
        .buttonStyle(.plain)
        .onHover {
            session.hoverRegion($0 ? region : nil)
        }
        .accessibilityIdentifier(
            region.accessibilityIdentifier
        )
        .accessibilityLabel(
            region.accessibilityLabel
        )
        .accessibilityValue(accessibilityValue)
    }

    private var selectedSubject: MemorySubject? {
        session.state.selectedSubject
    }

    private var selectedRegion: CardRegion {
        session.state.selectedRegion
    }

    private var visibleInsertableModules: [CenterInsertableModule] {
        let modules = CenterInsertableModule.allCases.filter {
            $0 != .custom && $0.isProductionBacked
        }

        if isModuleLibraryExpanded {
            return modules
        }

        return Array(modules.prefix(8))
    }

    private var hoveredRegion: CardRegion? {
        session.state.hoveredRegion
    }

    private var storageOptionBinding: Binding<ConfigurationStorageOption> {
        Binding(
            get: {
                session.selectedStorageOption
            },
            set: {
                session.selectedStorageOption = $0
            }
        )
    }

    private var memoryWriteToggleBinding: Binding<Bool> {
        Binding(
            get: {
                session.usesCustomMemoryWriteText
            },
            set: {
                session.usesCustomMemoryWriteText = $0
            }
        )
    }

    private var memoryWriteTextBinding: Binding<String> {
        Binding(
            get: {
                session.customMemoryWriteText
            },
            set: {
                session.customMemoryWriteText = $0
            }
        )
    }

    private var selectedMemoryPresetBinding: Binding<MemoryPreset.ID> {
        Binding(
            get: {
                session.state.selectedMemoryPreset?.id
                ?? session.state.memoryPresets.first?.id
                ?? UUID()
            },
            set: { presetID in
                guard
                    let preset =
                        session.state.memoryPresets.first(
                            where: { $0.id == presetID }
                        )
                else {
                    return
                }

                session.selectMemoryPreset(preset)
            }
        )
    }

    private var memoryPresetTitleBinding: Binding<String> {
        Binding(
            get: {
                session.currentMemoryPresetTitle
            },
            set: {
                session.updateSelectedMemoryPresetTitle($0)
            }
        )
    }

    private var subjectName: String {
        selectedSubject?.identity.displayName ?? "记忆对象"
    }

    private func previewText(
        for region: CardRegion
    ) -> String {
        session.previewText(for: region)
    }

    private var selectedIconName: String {
        selectedSubject?
            .decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "person.fill"
    }

    private var selectedIconTitle: String {
        selectedSubject?
            .decorations
            .first(where: { $0.kind == .icon })?
            .title ?? "图标"
    }

    private var selectedBadgeName: String {
        selectedSubject?
            .decorations
            .first(where: { $0.kind == .badge })?
            .systemSymbolName ?? "apple.logo"
    }

    private var selectedBadgeTitle: String {
        selectedSubject?
            .decorations
            .first(where: { $0.kind == .badge })?
            .title ?? "徽标"
    }
}

typealias CenterInsertableModule = MemoryCardModuleID

private enum BottomCardTextStyle {
    case headline
    case secondary
    case memory

    var primaryFont: Font {
        switch self {
        case .headline:
            return .system(
                size: RendererConstants.Typography.primarySize,
                weight: RendererConstants.Typography.regularWeight
            )
        case .secondary:
            return .system(
                size: RendererConstants.Typography.secondarySize,
                weight: RendererConstants.Typography.regularWeight
            )
        case .memory:
            return .system(
                size: RendererConstants.Typography.heroSize,
                weight: RendererConstants.Typography.heroWeight
            )
        }
    }

    var secondaryFont: Font {
        switch self {
        case .headline:
            return .system(
                size: RendererConstants.Typography.secondarySize,
                weight: RendererConstants.Typography.regularWeight
            )
        case .secondary,
             .memory:
            return .system(
                size: RendererConstants.Typography.captionSize,
                weight: RendererConstants.Typography.regularWeight
            )
        }
    }

    var primaryColor: Color {
        switch self {
        case .headline:
            return RendererConstants.ColorPalette.secondaryText
        case .secondary:
            return RendererConstants.ColorPalette.secondaryText
        case .memory:
            return RendererConstants.ColorPalette.primaryText
        }
    }

    var primaryLineLimit: Int {
        switch self {
        case .headline:
            return 3
        case .secondary:
            return RendererConstants.CaptureSummary.allowedFactCount
        case .memory:
            return 3
        }
    }
}

private struct CardRegionChrome: ViewModifier {

    let region: CardRegion
    let selectedRegion: CardRegion
    let hoveredRegion: CardRegion?

    func body(
        content: Content
    ) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        strokeColor,
                        lineWidth: strokeWidth
                    )
            )
            .contentShape(
                RoundedRectangle(cornerRadius: cornerRadius)
            )
    }

    private var isSelected: Bool {
        region == selectedRegion
    }

    private var isHovered: Bool {
        region == hoveredRegion
    }

    private var cornerRadius: CGFloat {
        switch region {
        case .slotA,
             .slotB,
             .slotC,
            .slotD:
            return 6
        default:
            return 8
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return ConfigurationUI.selectedBackground
        }

        if isHovered {
            return ConfigurationUI.hoverBackground
        }

        return Color.clear
    }

    private var strokeColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.30)
        }

        if isHovered {
            return ConfigurationUI.hairline
        }

        return Color.clear
    }

    private var strokeWidth: CGFloat {
        isSelected ? 1 : 0.75
    }
}
#endif
