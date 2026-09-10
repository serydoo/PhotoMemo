#if os(macOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct MacConfigurationCenterHeader: View {

    @ObservedObject
    var session: ConfigurationSession

    @ObservedObject
    var commerceStore: MemoMarkCommerceStore

    let onOpenSubject: () -> Void
    let onOpenPreset: () -> Void

    init(
        session: ConfigurationSession,
        commerceStore: MemoMarkCommerceStore,
        onOpenSubject: @escaping () -> Void = {},
        onOpenPreset: @escaping () -> Void = {}
    ) {
        self.session = session
        self.commerceStore = commerceStore
        self.onOpenSubject = onOpenSubject
        self.onOpenPreset = onOpenPreset
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            productIdentityRow

            SubjectPresetSummaryLayout {
                subjectSummaryCard
                presetSummaryCard
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var productIdentityRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("MemoMark")
                    .font(.title2.weight(.semibold))

                Text("让照片记得，它在人生里的位置。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("本地优先")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.tertiary)

                Image(systemName: "photo.on.rectangle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Apple Photos")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("本地优先，Apple Photos")

            entitlementStatus
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .configurationPanelChrome()
        .overlay(
            RoundedRectangle(cornerRadius: MacConfigurationCenterStyle.regionCornerRadius, style: .continuous)
                .stroke(
                    MacConfigurationCenterStyle.regionBorder,
                    lineWidth: MacConfigurationCenterStyle.regionBorderWidth
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mac.configurationCenter.productIdentity")
    }

    private var entitlementStatus: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(entitlementColor)
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 1) {
                Text(entitlementTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(entitlementDetail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(entitlementColor.opacity(0.10))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("购买状态")
        .accessibilityValue("\(entitlementTitle)，\(entitlementDetail)")
    }

    private var subjectSummaryCard: some View {
        Button(action: onOpenSubject) {
            MacConfigurationSummaryCard(
                title: "记忆对象",
                systemImage: "person.crop.circle",
                accent: .blue
            ) {
                Text(selectedSubjectName)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Text(selectedSubjectRelationship)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Divider()

                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.caption2.weight(.semibold))

                    Text(selectedAnchorDescription)
                        .font(.callout)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .foregroundStyle(Color.accentColor)
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .help("切换记忆对象")
        .accessibilityIdentifier("mac.configurationCenter.memorySubjectSummary")
        .accessibilityHint("打开记忆对象列表")
    }

    private var presetSummaryCard: some View {
        Button(action: onOpenPreset) {
            MacConfigurationSummaryCard(
                title: "当前预设",
                systemImage: "rectangle.stack.fill",
                accent: .orange
            ) {
                Text(session.currentMemoryPresetTitle)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Text(session.currentMemoryPresetSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                HStack(spacing: 6) {
                    Image(systemName: presetStatusSymbol)
                        .font(.caption2.weight(.semibold))

                    Text(presetStatusTitle)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
                .foregroundStyle(presetStatusColor)
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .help("切换当前预设")
        .accessibilityIdentifier("mac.configurationCenter.currentPresetSummary")
        .accessibilityHint("打开预设列表")
    }

    private var selectedSubjectName: String {
        session.state.selectedSubject?.identity.displayName ?? "记忆对象"
    }

    private var selectedSubjectRelationship: String {
        session.state.selectedSubject?.relationship.label ?? "尚未选择对象"
    }

    private var selectedAnchorDescription: String {
        guard let anchor = session.state.selectedSubject?.primaryTimeAnchor else {
            return "尚未设置时间锚点"
        }

        return "\(anchor.title) · \(anchor.date.formatted(date: .abbreviated, time: .omitted))"
    }

    private var presetStatusTitle: String {
        if session.selectedMemoryPresetIsApplied,
           session.selectedMemoryPresetIsDurable {
            return "已保存并生效"
        }

        if session.selectedMemoryPresetIsApplied {
            return "当前草稿"
        }

        return "有未应用更改"
    }

    private var presetStatusSymbol: String {
        session.selectedMemoryPresetIsApplied
            ? "checkmark.circle.fill"
            : "circle.dotted"
    }

    private var presetStatusColor: Color {
        session.selectedMemoryPresetIsApplied
            ? .green
            : .orange
    }

    private var entitlementTitle: String {
        if commerceStore.isTestFlightExperienceActive {
            return "TestFlight 体验"
        }

        if commerceStore.hasActiveSubscription {
            return "MemoMark+ 订阅有效"
        }

        if commerceStore.hasFounderLifetimeEntitlement {
            return "首批记录者"
        }

        if commerceStore.isPlus {
            return "MemoMark+ 已解锁"
        }

        return "免费体验"
    }

    private var entitlementDetail: String {
        if commerceStore.isPlus {
            return "无限记录"
        }

        if let remainingRecords = commerceStore.remainingRecords {
            return "免费剩余 \(remainingRecords) 张"
        }

        return "权益待确认"
    }

    private var entitlementColor: Color {
        commerceStore.isPlus ? .green : .secondary
    }
}

private struct MacConfigurationSummaryCard<Content: View>: View {

    let title: String
    let systemImage: String
    let accent: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 156, alignment: .topLeading)
        .configurationPanelChrome()
        .overlay(
            RoundedRectangle(cornerRadius: MacConfigurationCenterStyle.regionCornerRadius, style: .continuous)
                .stroke(
                    MacConfigurationCenterStyle.regionBorder,
                    lineWidth: MacConfigurationCenterStyle.regionBorderWidth
                )
        )
        .accessibilityElement(children: .contain)
    }
}

private struct SubjectPresetSummaryLayout: Layout {

    static let subjectPresetWideLayoutBreakpoint: CGFloat = 732
    static let subjectPresetCardMinimumWidth: CGFloat = 360
    static let cardSpacing: CGFloat = 12

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard subviews.count == 2 else {
            return .zero
        }

        let proposedWidth = proposal.width ??
            (Self.subjectPresetCardMinimumWidth * 2 + Self.cardSpacing)
        if proposedWidth >= Self.subjectPresetWideLayoutBreakpoint {
            let cardWidth = max(
                Self.subjectPresetCardMinimumWidth,
                (proposedWidth - Self.cardSpacing) / 2
            )
            let sizes = subviews.map {
                $0.sizeThatFits(
                    ProposedViewSize(width: cardWidth, height: nil)
                )
            }
            return CGSize(
                width: max(proposedWidth, cardWidth * 2 + Self.cardSpacing),
                height: sizes.map(\.height).max() ?? 0
            )
        }

        let sizes = subviews.map {
            $0.sizeThatFits(ProposedViewSize(width: proposedWidth, height: nil))
        }
        return CGSize(
            width: proposedWidth,
            height: sizes.reduce(0) { $0 + $1.height }
                + Self.cardSpacing
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard subviews.count == 2 else {
            return
        }

        let isWide = bounds.width >= Self.subjectPresetWideLayoutBreakpoint
        if isWide {
            let cardWidth = max(
                Self.subjectPresetCardMinimumWidth,
                (bounds.width - Self.cardSpacing) / 2
            )
            let height = bounds.height
            for (index, subview) in subviews.enumerated() {
                subview.place(
                    at: CGPoint(
                        x: bounds.minX
                            + CGFloat(index) * (cardWidth + Self.cardSpacing),
                        y: bounds.minY
                    ),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: cardWidth, height: height)
                )
            }
            return
        }

        var y = bounds.minY
        for subview in subviews {
            let size = subview.sizeThatFits(
                ProposedViewSize(width: bounds.width, height: nil)
            )
            subview.place(
                at: CGPoint(x: bounds.minX, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: size.height)
            )
            y += size.height + Self.cardSpacing
        }
    }
}

#Preview {
    MacConfigurationCenterHeader(
        session: ConfigurationSession(),
        commerceStore: MemoMarkCommerceStore()
    )
    .padding()
    .frame(width: 640)
}
#endif
