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
        bottomCardPreview
            .frame(width: 560, height: 205)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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

    private var bottomCardPreview: some View {
        HStack(spacing: 0) {
            leftSlotColumn
                .frame(maxWidth: .infinity, alignment: .leading)

            decorationDivider

            rightSlotColumn
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 26)
    }

    private var leftSlotColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            textRegion(
                .slotA,
                primary: "\(subjectName)手持iPhone 17 Pro Max拍摄",
                secondary: nil,
                style: .headline
            )

            textRegion(
                .slotB,
                primary: "2026.05.24 14:33:13记录",
                secondary: nil,
                style: .secondary
            )
        }
    }

    private var rightSlotColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            textRegion(
                .slotC,
                primary: "20mm f/1.9 1/117s ISO80",
                secondary: "河南 · 商丘",
                style: .headline
            )

            textRegion(
                .slotD,
                primary: memoryExpression,
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
                Image(systemName: "apple.logo")
                    .font(.system(size: 42, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.secondary)
                    .frame(width: 58, height: 72)
            }

            Rectangle()
                .fill(Color.black.opacity(0.10))
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
        .frame(width: 560)
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
        case .secondary,
             .memory:
            return Color.secondary
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
