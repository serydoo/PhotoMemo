#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct ConfigurationCenterSummarySection: View {

    let language: MemoMarkLanguage
    let subject: MemorySubject?
    let selectedRegion: CardRegion
    let currentBorderStyleName: String
    let locationPresentation:
        LocationDisplayInspectorPresentation
    let selectedLocationValue: String
    let locationDetail: String
    let selectedLocationOptionID: Binding<String>
    let selectedMemoryDisplayStyle:
        Binding<MemoryAnchorExpressionStyle>
    let availableMemoryDisplayStyles:
        [MemoryAnchorExpressionStyle]
    let availableTimeAnchors:
        [MemorySubject.TimeAnchor]
    let selectedTimeAnchorID: Binding<UUID>
    let onOpenSubject: () -> Void
    let onSelectRegion: (CardRegion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            summaryIntro
        }
    }

    private var summaryIntro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized("configuration.summary.current", fallback: "当前生效配置"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(localized("configuration.summary.detail", fallback: "先确认对象、锚点与展示方式，再进入下方区域继续细化。"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            groupedRowsPanel
        }
    }

    private var groupedRowsPanel: some View {
        VStack(spacing: 0) {
            summaryRow(
                title: localized("configuration.summary.subject", fallback: "记忆对象"),
                systemImage: MemoMarkSymbol.memorySubject.name,
                detail: subjectIdentityDetail
            ) {
                HStack(spacing: 12) {
                    ConfigurationCenterSubjectAvatarView(
                        imagePath:
                            subject?.identity.avatarPreviewImagePath
                            ?? subject?.identity.avatarImagePath
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            subject?.identity.displayName
                            ?? localized("configuration.summary.unselected_subject", fallback: "未选择对象")
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                        Text(
                            subject?.relationship.label
                            ?? localized("configuration.summary.unselected_subject", fallback: "未选择对象")
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } trailing: {
                summaryDisclosureButton(
                    title: subjectAnchorCountTitle,
                    subtitle: localized("configuration.summary.object_detail", fallback: "对象详情"),
                    action: onOpenSubject
                )
            }

            summaryDivider

            summaryRow(
                title: localized("configuration.summary.current_anchor", fallback: "当前生效时间锚点"),
                systemImage: MemoMarkSymbol.timeAnchor.name,
                detail: timeAnchorDetail
            ) {
                Text(
                    subject?.primaryTimeAnchor?.title
                    ?? localized("configuration.summary.unselected_anchor", fallback: "未选择时间锚点")
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
            } trailing: {
                if availableTimeAnchors.isEmpty {
                    Text(localized("configuration.summary.no_content", fallback: "暂无"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Picker(
                        localized("configuration.preview.time_anchor", fallback: "时间锚点"),
                        selection: selectedTimeAnchorID
                    ) {
                        ForEach(availableTimeAnchors) { anchor in
                            Text(anchor.title)
                                .tag(anchor.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .controlSize(.small)
                    .accessibilityLabel(localized("configuration.summary.choose_anchor", fallback: "选择当前时间锚点"))
                }
            }

            summaryDivider

            summaryRow(
                title: locationPresentation.title,
                systemImage: locationPresentation.systemImage,
                detail: locationDetail
            ) {
                Text(selectedLocationValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } trailing: {
                Picker(
                    locationPresentation.title,
                    selection: selectedLocationOptionID
                ) {
                    ForEach(locationPresentation.options) { option in
                        Text(option.title)
                            .tag(option.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.small)
                .accessibilityLabel(localized("configuration.summary.choose_location", fallback: "选择位置显示方式"))
            }

            summaryDivider

            summaryRow(
                title: localized("configuration.summary.memory_expression", fallback: "表达方式"),
                systemImage: MemoMarkSymbol.memoryContent.name,
                detail: memoryDisplayDetail
            ) {
                Text(memoryDisplayValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } trailing: {
                if availableMemoryDisplayStyles.isEmpty {
                    Text(localized("configuration.summary.no_content", fallback: "暂无"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Picker(
                        localized("configuration.summary.memory_expression", fallback: "表达方式"),
                        selection: selectedMemoryDisplayStyle
                    ) {
                        ForEach(
                            availableMemoryDisplayStyles,
                            id: \.self
                        ) { style in
                            Text(style.displayTitle)
                                .tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .controlSize(.small)
                    .accessibilityLabel(localized("configuration.summary.choose_expression", fallback: "选择表达方式"))
                }
            }

            summaryDivider

            summaryRow(
                title: localized("configuration.summary.border_style", fallback: "卡片样式"),
                systemImage: MemoMarkSymbol.configuration.name,
                detail: localized("configuration.summary.border_detail", fallback: "当前使用的卡片样式。")
            ) {
                Text(currentBorderStyleName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } trailing: {
                Text(localized("configuration.summary.current_version", fallback: "当前版本"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            summaryDivider

            summaryRow(
                title: localized("configuration.summary.regions", fallback: "四个区域"),
                systemImage: MemoMarkSymbol.module.name,
                detail: localized("configuration.summary.regions_detail", fallback: "点击对应区域，直接跳到当前生效配置的编辑位置。")
            ) {
                HStack(spacing: 8) {
                    ForEach(CardRegion.memoryCardRegions, id: \.self) { region in
                        Button {
                            onSelectRegion(region)
                        } label: {
                            Text(regionChipTitle(region))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    selectedRegion == region
                                    ? Color.accentColor
                                    : Color.primary.opacity(0.82)
                                )
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(
                                            selectedRegion == region
                                            ? Color.accentColor.opacity(0.12)
                                            : ConfigurationUI.controlBackground
                                        )
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(
                                            selectedRegion == region
                                            ? Color.accentColor.opacity(0.24)
                                            : ConfigurationUI.faintHairline
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .groupedSurface()
    }

    private var subjectIdentityDetail: String {
        let anchorCount =
            subject?.timeAnchors.count ?? 0
        return formatted(
            "configuration.summary.subject_identity_format",
            fallback: "当前记忆对象已配置 %lld 个时间锚点，可继续进入对象页维护头像、名称与关系。",
            Int64(anchorCount)
        )
    }

    private var subjectAnchorCountTitle: String {
        let anchorCount =
            subject?.timeAnchors.count ?? 0
        return formatted(
            "configuration.summary.anchor_count_format",
            fallback: "%lld 个时间锚点",
            Int64(anchorCount)
        )
    }

    private var timeAnchorDetail: String {
        guard let subject else {
            return localized(
                "configuration.summary.choose_subject_first",
                fallback: "先选择一个记忆对象，再切换当前生效时间锚点。"
            )
        }

        let count = subject.timeAnchors.count
        let note =
            subject.primaryTimeAnchor?.note
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let note, !note.isEmpty {
            return formatted(
                "configuration.summary.anchor_note_format",
                fallback: "当前记忆对象共有 %lld 个时间锚点，当前说明：%@",
                Int64(count),
                note
            )
        }

        return formatted(
            "configuration.summary.anchor_switch_detail_format",
            fallback: "当前记忆对象共有 %lld 个时间锚点，可直接在这里切换当前生效时间锚点。",
            Int64(count)
        )
    }

    private func localized(_ key: String, fallback: String) -> String {
        language.localized(key: key, fallback: fallback)
    }

    private func formatted(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: localized(key, fallback: fallback),
            locale: language.locale,
            arguments: arguments
        )
    }

    private var memoryDisplayValue: String {
        ConfigurationCenterMemoryDisplaySupport
            .summaryValue(subject: subject)
    }

    private var memoryDisplayDetail: String {
        ConfigurationCenterMemoryDisplaySupport
            .summaryDetail(subject: subject)
    }

    private func regionChipTitle(
        _ region: CardRegion
    ) -> String {
        switch region {
        case .slotA:
            return "A"
        case .slotB:
            return "B"
        case .slotC:
            return "C"
        case .slotD:
            return "D"
        default:
            return region.semanticTitle
        }
    }

    @ViewBuilder
    private func summaryRow<Content: View, Trailing: View>(
        title: String,
        systemImage: String,
        detail: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits {
                HStack(alignment: .center, spacing: 12) {
                    summaryRowLead(
                        title: title,
                        systemImage: systemImage,
                        content: content
                    )

                    Spacer(minLength: 0)

                    trailing()
                }

                VStack(alignment: .leading, spacing: 10) {
                    summaryRowLead(
                        title: title,
                        systemImage: systemImage,
                        content: content
                    )

                    trailing()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func summaryRowLead<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                content()
            }
        }
    }

    private func summaryDisclosureButton(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.82))

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.leading, 6)
        }
        .buttonStyle(.plain)
    }

    private var summaryDivider: some View {
        HorizontalDivider(horizontalInset: 14)
    }
}

private struct ConfigurationCenterSubjectAvatarView: View {

    let imagePath: String?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.10))

            if let imagePath,
               let image = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: MemoMarkSymbol.memorySubject.name)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: 44, height: 44)
        .overlay(
            Circle()
                .stroke(ConfigurationUI.faintHairline)
        )
    }
}
#endif
