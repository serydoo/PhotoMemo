#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCard: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                cardSurface
                cardCaption
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 36)
            .padding(.vertical, 34)
        }
        .background(Color.gray.opacity(0.045))
    }

    private var cardSurface: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 18)

            cardBody

            Spacer(minLength: 22)

            bottomPanel
        }
        .frame(width: 430, height: 610)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 18,
            y: 10
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

    private var cardBody: some View {
        VStack(spacing: 20) {
            cardRegionButton(
                .icon,
                accessibilityValue: selectedIconTitle
            ) {
                Image(systemName: selectedIconName)
                    .font(.system(size: 48, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.primary)
                    .frame(width: 82, height: 82)
            }

            cardRegionButton(
                .subject,
                accessibilityValue: subjectName
            ) {
                VStack(spacing: 5) {
                    Text(subjectName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    Text(selectedSubject?.relationship.label ?? "Memory Subject")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            cardRegionButton(
                .badge,
                accessibilityValue: selectedBadgeTitle
            ) {
                Image(systemName: selectedBadgeName)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(height: 18)
            }

            VStack(spacing: 6) {
                cardRegionButton(
                    .slotA,
                    accessibilityValue: "Shot on iPhone 17 Pro Max"
                ) {
                    Text("Shot on iPhone 17 Pro Max")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                cardRegionButton(
                    .slotB,
                    accessibilityValue: "2026.06.18"
                ) {
                    Text("2026.06.18")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.86))
                }

                cardRegionButton(
                    .slotC,
                    accessibilityValue: "河南 · 商丘"
                ) {
                    Label("河南 · 商丘", systemImage: "location.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            cardRegionButton(
                .slotD,
                accessibilityValue: memoryExpression
            ) {
                Text(memoryExpression)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 330)
            }
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 36)
        .padding(.top, 26)
        .padding(.bottom, 30)
        .background(Color.gray.opacity(0.055))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var cardCaption: some View {
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
        .frame(maxWidth: 430)
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
                .padding(.horizontal, region == .slotD ? 12 : 8)
                .padding(.vertical, region == .slotD ? 8 : 5)
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
        region == .slotD ? 10 : 8
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.10)
        }

        if isHovered {
            return Color.accentColor.opacity(0.055)
        }

        return Color.clear
    }

    private var strokeColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.42)
        }

        if isHovered {
            return Color.accentColor.opacity(0.20)
        }

        return Color.clear
    }

    private var strokeWidth: CGFloat {
        isSelected ? 1 : 0.75
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
                    InlineMemoryToken(
                        block: block,
                        isSelected: block.id == selectedBlockID
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct InlineMemoryToken: View {

    let block: MemoryBlock
    let isSelected: Bool

    var body: some View {
        Text(block.value)
            .font(
                block.type == .text
                ? .caption
                : .caption.weight(.semibold)
            )
            .foregroundStyle(
                block.type == .text
                ? Color.secondary
                : Color.accentColor
            )
            .padding(
                .horizontal,
                block.type == .text ? 0 : 8
            )
            .padding(
                .vertical,
                block.type == .text ? 0 : 4
            )
            .background(
                Group {
                    if block.type == .text {
                        Color.clear
                    } else {
                        Capsule()
                            .fill(Color.accentColor.opacity(0.10))
                    }
                }
            )
            .overlay(
                Group {
                    if isSelected, block.type != .text {
                        Capsule()
                            .stroke(Color.accentColor.opacity(0.55))
                    }
                }
            )
    }
}
#endif
