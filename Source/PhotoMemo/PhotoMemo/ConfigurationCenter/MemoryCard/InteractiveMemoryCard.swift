#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCard: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 18) {
                cardSurface
            }
            .frame(maxWidth: .infinity)
            .padding(28)
        }
        .background(Color.gray.opacity(0.06))
    }

    private var cardSurface: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            Divider()

            regionGrid

            Divider()

            expressionStrip
        }
        .padding(22)
        .frame(maxWidth: 620)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.10))
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 10,
            y: 4
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

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            regionButton(
                .icon,
                title: selectedIconTitle,
                symbol: selectedIconName
            )

            Button {
                session.select(
                    CardRegionBehavior(region: .subject)
                )
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        selectedSubject?
                            .identity.displayName
                        ?? "Subject"
                    )
                    .font(.title3.weight(.semibold))

                    Text(
                        selectedSubject?
                            .behavior.primaryAnchor
                        ?? "Primary Anchor"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(
                    CardRegionChrome(
                        region: .subject,
                        selectedRegion: selectedRegion,
                        hoveredRegion: hoveredRegion
                    )
                )
            }
            .buttonStyle(.plain)
            .onHover {
                session.hoverRegion($0 ? .subject : nil)
            }
            .accessibilityIdentifier(
                CardRegion.subject.accessibilityIdentifier
            )
            .accessibilityLabel(
                CardRegion.subject.accessibilityLabel
            )

            regionButton(
                .badge,
                title: selectedBadgeTitle,
                symbol: selectedBadgeName
            )
        }
    }

    private var regionGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            memoryRegionButton(
                .slotA,
                value: "Recorder"
            )
            memoryRegionButton(
                .slotB,
                value: "Capture Summary"
            )
            memoryRegionButton(
                .slotC,
                value: "记录于 · 拍摄日期"
            )
            memoryRegionButton(
                .slotD,
                value:
                    selectedSubject?
                    .behavior.memoryExpression.displayText
                    ?? ""
            )
        }
    }

    private var expressionStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Memory Expression")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            MemoryBlockFlow(
                blocks:
                    selectedSubject?
                    .behavior.memoryExpression.blocks
                    ?? [],
                selectedBlockID:
                    session.state.selectedBlockID,
                onSelect: {
                    session.selectBlock($0)
                }
            )
        }
    }

    private func memoryRegionButton(
        _ region: CardRegion,
        value: String
    ) -> some View {
        Button {
            session.select(
                CardRegionBehavior(region: region)
            )
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(region.semanticTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 42,
                        alignment: .topLeading
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
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
    }

    private func regionButton(
        _ region: CardRegion,
        title: String,
        symbol: String
    ) -> some View {
        Button {
            session.select(
                CardRegionBehavior(region: region)
            )
        } label: {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))

                Text(title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundStyle(
                region == selectedRegion
                ? Color.accentColor
                : Color.primary
            )
            .frame(width: 64, height: 58)
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

    private var selectedIconName: String {
        selectedSubject?
            .decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "sparkles"
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
            .systemSymbolName ?? "seal"
    }

    private var selectedBadgeTitle: String {
        selectedSubject?
            .decorations
            .first(where: { $0.kind == .badge })?
            .title ?? "Badge"
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        strokeColor,
                        lineWidth: strokeWidth
                    )
            )
            .contentShape(
                RoundedRectangle(cornerRadius: 8)
            )
    }

    private var isSelected: Bool {
        region == selectedRegion
    }

    private var isHovered: Bool {
        region == hoveredRegion
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.10)
        }

        if isHovered {
            return Color.accentColor.opacity(0.06)
        }

        return Color.gray.opacity(0.06)
    }

    private var strokeColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.55)
        }

        if isHovered {
            return Color.accentColor.opacity(0.24)
        }

        return Color.black.opacity(0.08)
    }

    private var strokeWidth: CGFloat {
        isSelected ? 1.25 : 1
    }
}

private struct MemoryBlockFlow: View {

    let blocks: [MemoryBlock]
    let selectedBlockID: MemoryBlock.ID?
    let onSelect: (MemoryBlock) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(blocks) { block in
                Button {
                    onSelect(block)
                } label: {
                    Text(block.value)
                        .font(
                            block.type == .text
                            ? .body
                            : .caption.weight(.semibold)
                        )
                        .foregroundStyle(
                            block.type == .text
                            ? Color.primary
                            : Color.accentColor
                        )
                        .padding(
                            .horizontal,
                            block.type == .text ? 0 : 9
                        )
                        .padding(
                            .vertical,
                            block.type == .text ? 0 : 5
                        )
                        .background(
                            Group {
                                if block.type == .text {
                                    Color.clear
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            Color.accentColor
                                                .opacity(0.10)
                                        )
                                }
                            }
                        )
                        .overlay(
                            Group {
                                if block.id == selectedBlockID,
                                   block.type != .text {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.accentColor)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
