#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCard: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                cardSurface
                regionStrip
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 36)
            .padding(.vertical, 34)
        }
        .background(Color.clear)
    }

    private var cardSurface: some View {
        VStack(spacing: 0) {
            decorationPanel
            slotPanel
        }
        .frame(width: 430, height: 610)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.035), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.045),
            radius: 14,
            y: 7
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

    private var decorationPanel: some View {
        VStack(spacing: 18) {
            cardRegionButton(
                .badge,
                accessibilityValue: selectedBadgeTitle
            ) {
                VStack(spacing: 8) {
                    Image(systemName: selectedBadgeName)
                        .font(.system(size: 22, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)

                    Text(selectedBadgeTitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            cardRegionButton(
                .icon,
                accessibilityValue: selectedIconTitle
            ) {
                VStack(spacing: 8) {
                    Image(systemName: selectedIconName)
                        .font(.system(size: 44, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.primary)

                    Text(subjectName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 210)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var slotPanel: some View {
        VStack(spacing: 0) {
            horizontalRegionSeparator

            slotRegion(
                .slotA,
                role: "Recorder",
                value: "Shot on iPhone 17 Pro Max",
                prominence: .secondary
            )

            horizontalRegionSeparator

            slotRegion(
                .slotB,
                role: "Timeline",
                value: "2026.06.18",
                prominence: .secondary
            )

            horizontalRegionSeparator

            HStack(spacing: 0) {
                slotRegion(
                    .slotC,
                    role: "Location",
                    value: "河南 · 商丘",
                    prominence: .compact
                )

                verticalRegionSeparator

                slotRegion(
                    .slotD,
                    role: "Memory",
                    value: memoryExpression,
                    prominence: .primary
                )
            }
            .frame(minHeight: 132)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }

    private var horizontalRegionSeparator: some View {
        Rectangle()
            .fill(Color.black.opacity(0.045))
            .frame(height: 1)
    }

    private var verticalRegionSeparator: some View {
        Rectangle()
            .fill(Color.black.opacity(0.045))
            .frame(width: 1)
    }

    private func slotRegion(
        _ region: CardRegion,
        role: String,
        value: String,
        prominence: SlotProminence
    ) -> some View {
        cardRegionButton(
            region,
            accessibilityValue: "\(role), \(value)"
        ) {
            VStack(spacing: prominence == .primary ? 8 : 5) {
                Text(value)
                    .font(prominence.valueFont)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(prominence.lineLimit)
                    .fixedSize(horizontal: false, vertical: true)

                Text(role)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity, minHeight: prominence.minimumHeight)
            .padding(.horizontal, prominence.horizontalPadding)
            .padding(.vertical, prominence.verticalPadding)
        }
    }

    private var regionStrip: some View {
        HStack(spacing: 0) {
            regionStripButton(
                .slotA,
                title: "Recorder",
                systemImage: "camera.fill"
            )

            regionStripButton(
                .slotB,
                title: "Timeline",
                systemImage: "calendar"
            )

            regionStripButton(
                .slotC,
                title: "Location",
                systemImage: "location.fill"
            )

            regionStripButton(
                .slotD,
                title: "Memory",
                systemImage: "text.quote"
            )
        }
        .padding(4)
        .frame(width: 430)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.08))
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
            VStack(spacing: 4) {
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
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        region == selectedRegion
                        ? Color.accentColor.opacity(0.10)
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

    private var subjectName: String {
        selectedSubject?.identity.displayName ?? "Memory Subject"
    }

    private var memoryExpression: String {
        selectedSubject?
            .behavior.memoryExpression.displayText
        ?? "Memory expression"
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
            .title ?? "Icon"
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
            .title ?? "Badge"
    }
}

private enum SlotProminence {
    case primary
    case secondary
    case compact

    var valueFont: Font {
        switch self {
        case .primary:
            return .headline.weight(.semibold)
        case .secondary:
            return .subheadline.weight(.semibold)
        case .compact:
            return .subheadline.weight(.medium)
        }
    }

    var minimumHeight: CGFloat {
        switch self {
        case .primary:
            return 124
        case .secondary:
            return 92
        case .compact:
            return 124
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .primary:
            return 18
        case .secondary:
            return 30
        case .compact:
            return 14
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .primary:
            return 16
        case .secondary:
            return 14
        case .compact:
            return 14
        }
    }

    var lineLimit: Int {
        switch self {
        case .primary:
            return 3
        case .secondary,
             .compact:
            return 2
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
            return 0
        default:
            return 8
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.065)
        }

        if isHovered {
            return Color.black.opacity(0.018)
        }

        return Color.clear
    }

    private var strokeColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.28)
        }

        if isHovered {
            return Color.black.opacity(0.11)
        }

        return Color.clear
    }

    private var strokeWidth: CGFloat {
        isSelected ? 1 : 0.75
    }
}
#endif
