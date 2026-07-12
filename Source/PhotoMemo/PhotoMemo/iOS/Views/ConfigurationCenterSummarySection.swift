#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct ConfigurationCenterSummarySection: View {

    let subject: MemorySubject?
    let selectedRegion: CardRegion
    let currentBorderStyleName: String
    let locationPresentation:
        LocationDisplayInspectorPresentation
    let selectedLocationValue: String
    let locationDetail: String
    let isLocationSelectable: Bool
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
        .padding(10)
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(
            color: ConfigurationUI.cardShadow.opacity(0.18),
            radius: 10,
            y: 4
        )
        .overlay(alignment: .topLeading) {
            Text("当前生效配置")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.88))
                )
                .padding(.leading, 12)
                .padding(.top, -10)
        }
    }

    private var summaryIntro: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(Color.accentColor.opacity(0.10))
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: MemoMarkSymbol.configuration.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("摘要面板")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("先确认对象、锚点与展示方式，再进入下方区域继续细化。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            groupedRowsPanel
        }
    }

    private var groupedRowsPanel: some View {
        VStack(spacing: 0) {
            summaryRow(
                title: "记忆对象",
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
                            ?? "记忆对象"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                        Text(
                            subject?.relationship.label
                            ?? "未选择对象"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } trailing: {
                summaryDisclosureButton(
                    title: subjectAnchorCountTitle,
                    subtitle: "对象详情",
                    action: onOpenSubject
                )
            }

            summaryDivider

            summaryRow(
                title: "当前生效锚点",
                systemImage: MemoMarkSymbol.timeAnchor.name,
                detail: timeAnchorDetail
            ) {
                Text(
                    subject?.primaryTimeAnchor?.title
                    ?? "未选择锚点"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
            } trailing: {
                if availableTimeAnchors.isEmpty {
                    Text("暂无")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Picker(
                        "时间锚点",
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
                    .accessibilityLabel("选择当前时间锚点")
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
                .disabled(isLocationSelectable == false)
                .accessibilityLabel("选择位置显示方式")
            }

            summaryDivider

            summaryRow(
                title: "记忆显示",
                systemImage: MemoMarkSymbol.memoryContent.name,
                detail: memoryDisplayDetail
            ) {
                Text(memoryDisplayValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } trailing: {
                if availableMemoryDisplayStyles.isEmpty {
                    Text("暂无")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Picker(
                        "记忆显示",
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
                    .accessibilityLabel("选择记忆显示方式")
                }
            }

            summaryDivider

            summaryRow(
                title: "边框样式",
                systemImage: MemoMarkSymbol.configuration.name,
                detail: "当前先锁定 1 种样式，后续再扩展。"
            ) {
                Text(currentBorderStyleName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
            } trailing: {
                summaryStatusBadge("当前锁定")
            }

            summaryDivider

            summaryRow(
                title: "四个区域",
                systemImage: MemoMarkSymbol.module.name,
                detail: "点击对应区域，直接跳到当前生效配置的编辑位置。"
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
                                            : Color.white.opacity(0.86)
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
        .background(Color.white.opacity(0.94))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var subjectIdentityDetail: String {
        let anchorCount =
            subject?.timeAnchors.count ?? 0
        return "当前记忆对象已配置 \(anchorCount) 个时间锚点，可继续进入对象页维护头像、名称与关系。"
    }

    private var subjectAnchorCountTitle: String {
        let anchorCount =
            subject?.timeAnchors.count ?? 0
        return "\(anchorCount) 个锚点"
    }

    private var timeAnchorDetail: String {
        guard let subject else {
            return "先选择一个记忆对象，再切换当前生效锚点。"
        }

        let count = subject.timeAnchors.count
        let note =
            subject.primaryTimeAnchor?.note
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let note, !note.isEmpty {
            return "当前记忆对象共有 \(count) 个锚点，当前说明：\(note)"
        }

        return "当前记忆对象共有 \(count) 个锚点，可直接在这里切换当前生效锚点。"
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
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.86))
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }

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
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 6)
        }
        .buttonStyle(.plain)
    }

    private func summaryStatusBadge(
        _ title: String
    ) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(ConfigurationUI.controlBackground.opacity(0.88))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ConfigurationUI.faintHairline)
            )
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(height: 0.5)
            .padding(.leading, 66)
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
                Image(systemName: "person.crop.circle.fill")
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
