#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct ConfigurationActionToolbar: View {

    @State
    private var showsResetConfigurationConfirmation = false

    @State
    private var showsDeleteConfigurationConfirmation = false

    let configurationStatus: ConfigurationPersistenceStatus
    let isSavingConfiguration: Bool
    let isSelectedProcessingDefault: Bool
    let onSaveCurrentConfiguration: () -> Void
    let onSetAsProcessingDefault: () -> Void
    let onCreateConfiguration: () -> Void
    let onResetConfiguration: () -> Void
    let onDeleteConfiguration: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            moreActionsMenu

            Button(action: onSaveCurrentConfiguration) {
                Label(saveActionTitle, systemImage: saveActionSystemImage)
            }
            .disabled(isSavingConfiguration || configurationStatus == .saved)
        }
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

    private var moreActionsMenu: some View {
        Menu {
            if !isSelectedProcessingDefault {
                Button { onSetAsProcessingDefault() } label: {
                    Label(
                        localized(
                            "将已保存配置设为下次处理默认",
                            fallback: "将已保存配置设为下次处理默认"
                        ),
                        systemImage: "checkmark.seal"
                    )
                }
                .disabled(
                    isSavingConfiguration
                    || configurationStatus != .saved
                )
            }
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

    private var saveActionSystemImage: String {
        if isSavingConfiguration { return "hourglass" }
        switch configurationStatus {
        case .saved: return "checkmark.circle.fill"
        case .failure: return "arrow.clockwise.circle.fill"
        default: return "tray.and.arrow.down"
        }
    }

    private func localized(_ key: String, fallback: String? = nil) -> String {
        MemoMarkLanguage.interfaceStored.localized(key: key, fallback: fallback ?? key)
    }
}
#endif
