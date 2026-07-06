#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterSidebarItem:
    Identifiable,
    Hashable {

    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    static func == (
        lhs: ConfigurationCenterSidebarItem,
        rhs: ConfigurationCenterSidebarItem
    ) -> Bool {
        lhs.id == rhs.id
    }

    func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(id)
    }
}

struct ConfigurationCenterSidebarSubjectGroup:
    Identifiable,
    Hashable {

    let id = UUID()
    let title: String
    let addTitle: String
    let items: [ConfigurationCenterSidebarItem]
    let addAction: () -> Void

    static func == (
        lhs: ConfigurationCenterSidebarSubjectGroup,
        rhs: ConfigurationCenterSidebarSubjectGroup
    ) -> Bool {
        lhs.id == rhs.id
    }

    func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(id)
    }
}

struct ConfigurationCenterSidebarView: View {

    let subjectGroups:
        [ConfigurationCenterSidebarSubjectGroup]
    let cardItems:
        [ConfigurationCenterSidebarItem]
    let memoryModuleItems:
        [ConfigurationCenterSidebarItem]
    let outputItems:
        [ConfigurationCenterSidebarItem]
    let guideItems:
        [ConfigurationCenterSidebarItem]
    let onBackgroundTap: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sidebarHeader

                ForEach(subjectGroups) { group in
                    sidebarSubjectSection(group)
                }

                sidebarSection(
                    "卡片区域",
                    items: cardItems
                )

                sidebarSection(
                    "智能模块",
                    items: memoryModuleItems
                )

                sidebarSection(
                    "输出内容",
                    items: outputItems
                )

                sidebarSection(
                    "说明",
                    items: guideItems
                )

                sidebarFooter
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ConfigurationUI.appBackground)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onBackgroundTap()
                }
        )
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("配置资料")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text("记忆对象、卡片区域与智能写入")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    private func sidebarSubjectSection(
        _ group: ConfigurationCenterSidebarSubjectGroup
    ) -> some View {
        sidebarSection(
            group.title,
            items: group.items
        ) {
            sidebarAddAction(
                title: group.addTitle,
                action: group.addAction
            )
        }
    }

    private func sidebarSection<Footer: View>(
        _ title: String,
        items: [ConfigurationCenterSidebarItem],
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 10)

            VStack(spacing: 3) {
                if items.isEmpty {
                    Text("暂无内容")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                } else {
                    ForEach(items) { item in
                        sidebarAction(item)
                    }
                }

                footer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sidebarSection(
        _ title: String,
        items: [ConfigurationCenterSidebarItem]
    ) -> some View {
        sidebarSection(title, items: items) {
            EmptyView()
        }
    }

    private func sidebarAddAction(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: 17)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func sidebarAction(
        _ item: ConfigurationCenterSidebarItem
    ) -> some View {
        Button(action: item.action) {
            HStack(spacing: 10) {
                Image(systemName: item.systemImage)
                    .font(.subheadline.weight(.medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        item.isSelected
                        ? Color.accentColor
                        : Color.secondary
                    )
                    .frame(width: 19)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
                    .fill(
                        item.isSelected
                        ? ConfigurationUI.selectedBackground
                        : Color.clear
                    )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .opacity(0.28)

            VStack(alignment: .leading, spacing: 4) {
                Text("当前生效锚点")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text("不同记忆对象拥有不同锚点，也拥有不同的回忆角度。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("记忆对象")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text("PhotoMemo 用锚点帮助你阅读回忆，而不只是保存照片。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
    }
}
#endif
