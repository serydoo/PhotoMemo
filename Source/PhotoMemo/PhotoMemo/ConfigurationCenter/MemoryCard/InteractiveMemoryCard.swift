#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCard: View {

    @ObservedObject
    var session: ConfigurationSession

    @State
    private var isRenamingMemoryPreset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                configurationContext
                cardSurface
                regionStrip
                configurationComponentDock
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
        .background(ConfigurationUI.appBackground)
    }

    private var configurationContext: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 18) {
                contextPresetControl

                Divider()
                    .frame(height: 34)

                contextStatusItem(
                    title: "时间锚点",
                    value: session.currentTimeAnchorDescription,
                    systemImage: "flag.fill"
                )

                Spacer(minLength: 0)
            }

            if isRenamingMemoryPreset {
                TextField(
                    "记忆预设名称",
                    text: Binding(
                        get: {
                            session.currentMemoryPresetTitle
                        },
                        set: {
                            session.updateSelectedMemoryPresetTitle($0)
                        }
                    )
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .configurationFieldChrome(isActive: true)
                .transition(
                    .opacity
                        .combined(with: .move(edge: .top))
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(width: 590, alignment: .leading)
        .configurationPanelChrome()
        .animation(
            .easeInOut(duration: 0.16),
            value: isRenamingMemoryPreset
        )
    }

    private var contextPresetControl: some View {
        HStack(spacing: 9) {
            Image(systemName: "rectangle.stack.fill")
                .font(.caption.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text("记忆预设")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Picker(
                    "记忆预设",
                    selection: selectedMemoryPresetBinding
                ) {
                    ForEach(session.state.memoryPresets) { preset in
                        Text(preset.title)
                            .tag(preset.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 142, alignment: .leading)
            }

            Button {
                isRenamingMemoryPreset.toggle()
            } label: {
                Image(systemName: "pencil")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("重命名记忆预设")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("记忆预设")
        .accessibilityValue(session.currentMemoryPresetTitle)
    }

    private func contextStatusItem(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }

    private var cardSurface: some View {
        bottomCardPreview
            .frame(width: 590, height: 220)
        .background(
            LinearGradient(
                colors: [
                    Color.white,
                    ConfigurationUI.panelBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ConfigurationUI.faintHairline, lineWidth: 1)
        )
        .shadow(
            color: ConfigurationUI.cardShadow,
            radius: 18,
            y: 8
        )
        .animation(
            .easeInOut(duration: 0.16),
            value: selectedRegion
        )
        .animation(
            .easeInOut(duration: 0.12),
            value: hoveredRegion
        )
    }

    private var bottomCardPreview: some View {
        HStack(spacing: 0) {
            leftSlotColumn
                .frame(maxWidth: .infinity, alignment: .leading)

            decorationDivider

            rightSlotColumn
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 28)
    }

    private var leftSlotColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            textRegion(
                .slotA,
                primary: previewText(for: .slotA),
                secondary: nil,
                style: .headline
            )

            textRegion(
                .slotB,
                primary: previewText(for: .slotB),
                secondary: nil,
                style: .secondary
            )
        }
    }

    private var rightSlotColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            textRegion(
                .slotC,
                primary: previewText(for: .slotC),
                secondary: nil,
                style: .headline
            )

            textRegion(
                .slotD,
                primary: previewText(for: .slotD),
                secondary: nil,
                style: .memory
            )
        }
    }

    private var decorationDivider: some View {
        HStack(spacing: 16) {
            cardRegionButton(
                .icon,
                accessibilityValue: selectedIconTitle
            ) {
                Image(systemName: selectedIconName)
                    .font(.system(size: 36, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.secondary.opacity(0.78))
                    .frame(width: 52, height: 68)
            }

            Rectangle()
                .fill(ConfigurationUI.hairline)
                .frame(width: 1, height: 76)
        }
        .padding(.horizontal, 24)
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

    private var regionStrip: some View {
        HStack(spacing: 0) {
            regionStripButton(
                .slotA,
                title: "记录",
                systemImage: "camera.fill"
            )

            regionStripButton(
                .slotB,
                title: "时间线",
                systemImage: "calendar"
            )

            regionStripButton(
                .slotC,
                title: "上下文",
                systemImage: "scope"
            )

            regionStripButton(
                .slotD,
                title: "记忆",
                systemImage: "text.quote"
            )
        }
        .padding(4)
        .frame(width: 590)
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ConfigurationUI.hairline)
        )
    }

    private func regionStripButton(
        _ region: CardRegion,
        title: String,
        systemImage: String
    ) -> some View {
        Button {
            session.select(
                CardRegionBehavior(region: region)
            )
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(
                region == selectedRegion
                ? Color.accentColor
                : Color.secondary
            )
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        region == selectedRegion
                        ? ConfigurationUI.selectedBackground
                        : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            "\(region.accessibilityIdentifier).strip"
        )
        .accessibilityLabel(
            "\(title), \(region.semanticTitle)"
        )
    }

    private var configurationComponentDock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                dockSection(
                    title: "可插入模块",
                    systemImage: "tag.fill"
                ) {
                    LazyVGrid(
                        columns: [
                            GridItem(
                                .adaptive(minimum: 112),
                                spacing: 7
                            )
                        ],
                        alignment: .leading,
                        spacing: 7
                    ) {
                        ForEach(CenterInsertableModule.allCases) { module in
                            Button {
                                session.appendPreviewModule(
                                    title: module.title,
                                    value: module.previewValue
                                )
                            } label: {
                                centerModuleChip(module)
                            }
                            .buttonStyle(.plain)
                            .help("插入到当前选中的\(selectedRegion.semanticTitle)区域")
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    dockSection(
                        title: "当前输出",
                        systemImage: "checkmark.seal"
                    ) {
                        Text(session.currentOutputPreview)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.primary)
                            .lineLimit(3)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .configurationPanelChrome()
                    }

                    dockSection(
                        title: "输出",
                        systemImage: "square.and.arrow.down"
                    ) {
                        outputSelection
                    }
                }
                .frame(width: 220)
            }

            dockSection(
                title: "配置说明",
                systemImage: "questionmark.circle"
            ) {
                configurationGuide
            }
        }
        .frame(width: 590, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ConfigurationUI.faintHairline)
        )
    }

    private func dockSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func centerModuleChip(
        _ module: CenterInsertableModule
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: module.systemImage)
                .font(.caption2.weight(.semibold))

            Text(module.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.085))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.accentColor.opacity(0.16))
        )
    }

    private var outputSelection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Picker(
                "输出选择",
                selection: outputOptionBinding
            ) {
                ForEach(ConfigurationOutputOption.allCases) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(session.selectedOutputOption.note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .configurationPanelChrome()
    }

    private var configurationGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                guideCard(
                    title: "四个自定义区域",
                    note: "插入内容进入当前选中的区域，不走隐式兜底。",
                    systemImage: "rectangle.and.pencil.and.ellipsis"
                )

                guideCard(
                    title: "记忆日期与智能结果",
                    note: "时间锚点和照片时间会组合成可复用结果。",
                    systemImage: "calendar.badge.clock"
                )
            }

            HStack(spacing: 8) {
                guideCard(
                    title: "输出与相册保存",
                    note: "默认生成处理过的新图片，原图保持不变。",
                    systemImage: "square.and.arrow.down"
                )

                guideCard(
                    title: "关于 PhotoMemo",
                    note: "帮助用户阅读回忆，而不只是保存照片。",
                    systemImage: "info.circle"
                )
            }
        }
    }

    private func guideCard(
        title: String,
        note: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .configurationPanelChrome()
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

    private var hoveredRegion: CardRegion? {
        session.state.hoveredRegion
    }

    private var outputOptionBinding: Binding<ConfigurationOutputOption> {
        Binding(
            get: {
                session.selectedOutputOption
            },
            set: {
                session.selectedOutputOption = $0
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

private enum CenterInsertableModule:
    String,
    CaseIterable,
    Identifiable {

    case subjectNickname
    case smartTime
    case captureDate
    case cameraModel
    case captureSummary
    case location

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .subjectNickname:
            return "对象昵称"
        case .smartTime:
            return "智能时间"
        case .captureDate:
            return "拍摄日期"
        case .cameraModel:
            return "设备型号"
        case .captureSummary:
            return "参数概要"
        case .location:
            return "位置"
        }
    }

    var previewValue: String {
        switch self {
        case .subjectNickname:
            return "Tutu"
        case .smartTime:
            return "11个月28天"
        case .captureDate:
            return "2026.05.24"
        case .cameraModel:
            return "iPhone 17 Pro Max"
        case .captureSummary:
            return "20mm f/1.9 1/117s ISO80"
        case .location:
            return "河南 · 商丘"
        }
    }

    var systemImage: String {
        switch self {
        case .subjectNickname:
            return "person.fill"
        case .smartTime:
            return "sparkles"
        case .captureDate:
            return "calendar"
        case .cameraModel:
            return "camera.fill"
        case .captureSummary:
            return "camera.metering.center.weighted"
        case .location:
            return "location.fill"
        }
    }
}

private enum BottomCardTextStyle {
    case headline
    case secondary
    case memory

    var primaryFont: Font {
        switch self {
        case .headline:
            return .system(size: 20, weight: .bold)
        case .secondary:
            return .system(size: 16, weight: .medium)
        case .memory:
            return .system(size: 16, weight: .semibold)
        }
    }

    var secondaryFont: Font {
        switch self {
        case .headline:
            return .system(size: 15, weight: .medium)
        case .secondary,
             .memory:
            return .system(size: 14, weight: .regular)
        }
    }

    var primaryColor: Color {
        switch self {
        case .headline:
            return Color.primary
        case .secondary:
            return Color.secondary
        case .memory:
            return Color.primary.opacity(0.82)
        }
    }

    var primaryLineLimit: Int {
        switch self {
        case .headline:
            return 2
        case .secondary,
             .memory:
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
