#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterTopPreviewSection<
    ProfilePresetControl: View
>: View {

    @ObservedObject
    var session: ConfigurationSession

    let currentBorderStyleName: String

    @Binding
    var isRenamingProfile: Bool

    let profileTitle: Binding<String>
    let onDismissKeyboard: () -> Void
    let onBeginRename: () -> Void
    let onResetPreset: () -> Void
    let onApplyPreset: () -> Void
    let onRegionSelection: (CardRegion) -> Void
    let profilePresetControl: ProfilePresetControl

    init(
        session: ConfigurationSession,
        currentBorderStyleName: String,
        isRenamingProfile: Binding<Bool>,
        profileTitle: Binding<String>,
        onDismissKeyboard: @escaping () -> Void,
        onBeginRename: @escaping () -> Void,
        onResetPreset: @escaping () -> Void,
        onApplyPreset: @escaping () -> Void,
        onRegionSelection: @escaping (CardRegion) -> Void,
        @ViewBuilder profilePresetControl: () -> ProfilePresetControl
    ) {
        self.session = session
        self.currentBorderStyleName = currentBorderStyleName
        _isRenamingProfile = isRenamingProfile
        self.profileTitle = profileTitle
        self.onDismissKeyboard = onDismissKeyboard
        self.onBeginRename = onBeginRename
        self.onResetPreset = onResetPreset
        self.onApplyPreset = onApplyPreset
        self.onRegionSelection = onRegionSelection
        self.profilePresetControl = profilePresetControl()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            profilePanel
            compactCardPreview
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background(ConfigurationUI.panelBackground)
        .overlay(
            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(height: 0.5),
            alignment: .bottom
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onDismissKeyboard()
                }
        )
    }

    private var profilePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Label("总体配置", systemImage: "rectangle.stack.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .labelStyle(.iconOnly)

                profilePresetControl
                    .frame(
                        minWidth: 118,
                        idealWidth: 146,
                        maxWidth: 168,
                        alignment: .leading
                    )

                Button(action: onBeginRename) {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("重命名")

                Button(action: onResetPreset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption.weight(.semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("重置")

                Spacer(minLength: 0)

                Button(action: onApplyPreset) {
                    Label(
                        session.selectedMemoryPresetIsApplied
                        ? "已生效"
                        : "保存并生效",
                        systemImage:
                            session.selectedMemoryPresetIsApplied
                            ? "checkmark.circle.fill"
                            : "checkmark.circle"
                    )
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .font(.caption.weight(.semibold))

            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 1) {
                    Text("边框样式")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(currentBorderStyleName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 0)

                Text("当前锁定规范")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 1) {
                    Text("自动输出")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.currentConfigurationLabel)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.86))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 0)

                Text(session.currentMemoryPresetSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            if isRenamingProfile {
                TextField(
                    "配置名称",
                    text: profileTitle
                )
                .textFieldStyle(.plain)
                .font(.caption)
                .configurationFieldChrome(isActive: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(ConfigurationUI.controlBackground.opacity(0.62))
        .clipShape(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
                .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var compactCardPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("当前配置预览")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            IOSMacStyleMemoryCardPreview(
                session: session,
                onPreviewInteraction: onDismissKeyboard
            )

            regionStrip
        }
        .padding(12)
        .configurationPanelChrome()
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
                title: "拍摄参数",
                systemImage: "scope"
            )

            regionStripButton(
                .slotD,
                title: "记忆",
                systemImage: "text.quote"
            )
        }
        .padding(4)
        .background(Color.white.opacity(0.88))
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
            onRegionSelection(region)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(
                region == session.state.selectedRegion
                ? Color.accentColor
                : Color.secondary
            )
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        region == session.state.selectedRegion
                        ? ConfigurationUI.selectedBackground
                        : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
#endif
