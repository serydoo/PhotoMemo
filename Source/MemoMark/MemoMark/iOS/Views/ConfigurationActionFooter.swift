#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct ConfigurationActionFooter: View {

    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    @State
    private var showsResetConfigurationConfirmation = false

    @State
    private var showsDeleteConfigurationConfirmation = false

    let configurationStatus: ConfigurationPersistenceStatus
    let isSavingConfiguration: Bool
    let onSaveCurrentConfiguration: () -> Void
    let onCreateConfiguration: () -> Void
    let onResetConfiguration: () -> Void
    let onDeleteConfiguration: () -> Void

    var body: some View {
        configurationActionRow
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .alert(isPresented: $showsResetConfigurationConfirmation) {
                Alert(
                    title: Text(localized("configuration.action.reset.title", fallback: "恢复默认配置？")),
                    message: Text(localized("当前未保存的修改会被默认内容替换。此操作无法撤销。")),
                    primaryButton: .cancel(Text(localized("取消"))),
                    secondaryButton: .destructive(
                        Text(localized("恢复默认")),
                        action: onResetConfiguration
                    )
                )
            }
            .alert(isPresented: $showsDeleteConfigurationConfirmation) {
                Alert(
                    title: Text(localized("configuration.action.delete.title", fallback: "删除当前配置？")),
                    message: Text(localized("本地配置库中的备份会保留。此操作无法撤销。")),
                    primaryButton: .cancel(Text(localized("取消"))),
                    secondaryButton: .destructive(
                        Text(localized("删除配置")),
                        action: onDeleteConfiguration
                    )
                )
            }
    }

    private var configurationActionRow: some View {
        ZStack(alignment: .bottom) {
            HStack {
                Spacer(minLength: 0)
                moreActionsMenu
            }
            centeredPrimaryAction
        }
        .padding(.horizontal, MemoMarkDesignTokens.Layout.compactActionClusterHorizontalPadding)
        .padding(.vertical, MemoMarkDesignTokens.Layout.compactActionClusterVerticalPadding)
        .frame(maxWidth: MemoMarkDesignTokens.Layout.compactActionClusterMaxWidth)
        .background {
            if reduceTransparency {
                RoundedRectangle(
                    cornerRadius: MemoMarkDesignTokens.Layout.compactActionClusterCornerRadius,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            } else {
                RoundedRectangle(
                    cornerRadius: MemoMarkDesignTokens.Layout.compactActionClusterCornerRadius,
                    style: .continuous
                )
                .fill(.regularMaterial)
            }
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: MemoMarkDesignTokens.Layout.compactActionClusterCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        }
    }

    private var centeredPrimaryAction: some View {
        Button(action: onSaveCurrentConfiguration) {
            Label(saveActionTitle, systemImage: saveActionSystemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .buttonStyle(saveActionButtonStyle)
        .disabled(isSavingConfiguration || configurationStatus == .saved)
    }

    private var saveActionButtonStyle: ConfigurationSaveButtonStyle {
        ConfigurationSaveButtonStyle(isRestrained: configurationStatus == .saved)
    }

    private var moreActionsMenu: some View {
        Menu {
            Button { onCreateConfiguration() } label: {
                Label(localized("另存为新配置"), systemImage: "plus.square")
            }
            Button { showsResetConfigurationConfirmation = true } label: {
                Label(localized("恢复默认"), systemImage: "arrow.counterclockwise")
            }
            Button(role: .destructive) { showsDeleteConfigurationConfirmation = true } label: {
                Label(localized("删除当前配置"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(localized("更多配置操作"))
    }

    private var saveActionTitle: String {
        if isSavingConfiguration { return localized("output.save.saving") }
        switch configurationStatus {
        case .saved: return localized("output.save.saved")
        case .failure: return localized("output.save.retry")
        default: return localized("configuration.editor.save")
        }
    }

    private func localized(_ key: String, fallback: String? = nil) -> String {
        MemoMarkLanguage.interfaceStored.localized(key: key, fallback: fallback ?? key)
    }

    private var saveActionSystemImage: String {
        if isSavingConfiguration { return "hourglass" }
        switch configurationStatus {
        case .saved: return "checkmark.circle.fill"
        case .failure: return "arrow.clockwise.circle.fill"
        default: return "tray.and.arrow.down"
        }
    }
}

private struct ConfigurationSaveButtonStyle: ButtonStyle {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.isEnabled)
    private var isEnabled

    let isRestrained: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isRestrained ? Color.primary.opacity(0.58) : MemoMarkDesignTokens.Semantic.onAccent)
            .padding(.horizontal, 14)
            .frame(width: CompactBottomActionMetrics.width, height: CompactBottomActionMetrics.height)
            .background(
                RoundedRectangle(cornerRadius: CompactBottomActionMetrics.cornerRadius, style: .continuous)
                    .fill(isRestrained ? ConfigurationUI.controlBackground : Color.accentColor.opacity(MemoMarkDesignTokens.Layout.compactPrimaryActionTintOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CompactBottomActionMetrics.cornerRadius, style: .continuous)
                    .stroke(isRestrained ? ConfigurationUI.faintHairline : Color.clear)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : (isRestrained ? 1 : 0.56))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .shadow(
                color: isRestrained ? Color.clear : Color.accentColor.opacity(MemoMarkDesignTokens.Layout.compactPrimaryActionShadowOpacity),
                radius: MemoMarkDesignTokens.Layout.compactPrimaryActionShadowRadius,
                y: MemoMarkDesignTokens.Layout.compactPrimaryActionShadowOffsetY
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ConfigurationActionButtonStyle: ButtonStyle {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.56)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
#endif
