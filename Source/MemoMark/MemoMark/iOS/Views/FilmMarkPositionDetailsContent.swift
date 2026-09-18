#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct FilmMarkPositionDetailsContent: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var configuration: FilmMarkConfiguration
    let onChange: () -> Void
    var showsHeader: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsHeader {
                Text(filmMarkLocalized("filmMark.configuration.position.title", fallback: "位置"))
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal, CompactInformationRowMetrics.horizontalPadding)
                    .padding(.top, 4)
                Text(filmMarkLocalized("filmMark.configuration.position.help", fallback: "选择文字在照片中的位置，并微调。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, CompactInformationRowMetrics.horizontalPadding)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
            }
            anchorRow
            nudgeRow
        }
    }

    private var anchorRow: some View {
        detailRow(title: "filmMark.configuration.anchor.title", subtitle: "filmMark.configuration.anchor.help") {
            Picker(
                filmMarkLocalized("filmMark.configuration.anchor.accessibility", fallback: "起始位置"),
                selection: Binding(
                    get: { configuration.placement.anchor },
                    set: { anchor in update { $0.placement.anchor = anchor } }
                )
            ) {
                ForEach(FilmMarkPlacementAnchor.allCases, id: \.self) { anchor in
                    Text(anchor.displayTitle).tag(anchor)
                }
            }
            .pickerStyle(.segmented)
            .tint(.accentColor)
            .accessibilityLabel(filmMarkLocalized("filmMark.configuration.anchor.accessibility", fallback: "胶片标记起始位置"))
        }
    }

    private var nudgeRow: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    nudgeDescription
                    resetButton
                    nudgeControls
                }
            } else {
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        nudgeDescription
                        resetButton.frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                    nudgeControls
                }
            }
        }
        .padding(.horizontal, CompactInformationRowMetrics.horizontalPadding)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
    }

    private var resetButton: some View {
        Button {
            update { $0.placement = FilmMarkPlacementDraft(anchor: $0.placement.anchor) }
        } label: {
            Text(filmMarkLocalized("filmMark.configuration.reset", fallback: "复位"))
                .font(.caption.weight(.semibold))
                .frame(width: 88, height: 28)
                .background(Capsule().fill(ConfigurationUI.controlBackground))
                .overlay { Capsule().stroke(ConfigurationUI.faintHairline) }
                .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
        .accessibilityLabel(filmMarkLocalized("filmMark.configuration.reset.accessibility", fallback: "复位胶片时间标记位置"))
    }

    private var nudgeControls: some View {
        HStack(spacing: 4) {
            nudgeButton(direction: .left, systemImage: "arrow.left")
            VStack(spacing: 4) {
                nudgeButton(direction: .up, systemImage: "arrow.up")
                nudgeButton(direction: .down, systemImage: "arrow.down")
            }
            nudgeButton(direction: .right, systemImage: "arrow.right")
        }
    }

    private var nudgeDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(filmMarkLocalized("filmMark.configuration.nudge.title", fallback: "精细调整位置"))
                .font(.headline.weight(.semibold))
            Text(filmMarkLocalized("filmMark.configuration.nudge.help", fallback: "每次移动照片尺寸的 0.5%，轻调到合适的位置。"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func detailRow<Trailing: View>(title: String, subtitle: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ConfigurationFieldHeading(title: title, subtitle: subtitle)
            trailing()
        }
        .padding(.horizontal, CompactInformationRowMetrics.horizontalPadding)
        .padding(.vertical, 8)
    }

    private func nudgeButton(direction: FilmMarkPlacementDirection, systemImage: String) -> some View {
        Button {
            update { $0.placement = FilmMarkLayoutSpecification.nudged($0.placement, direction: direction) }
        } label: {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(Circle().fill(ConfigurationUI.controlBackground))
                .frame(width: ConfigurationUI.minimumInteractiveHeight, height: ConfigurationUI.minimumInteractiveHeight)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction.accessibilityLabel)
        .accessibilityHint(filmMarkLocalized("filmMark.configuration.nudge.accessibility_hint", fallback: "微调胶片时间标记在照片上的位置"))
    }

    private func update(_ mutation: (inout FilmMarkConfiguration) -> Void) {
        var next = configuration
        mutation(&next)
        configuration = next
        onChange()
    }
}
#endif
