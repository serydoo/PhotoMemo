#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Displays MemoMark's local-data and original-photo guarantees without
/// owning preferences, Photos permission, or any persistence behavior.
struct DataSafetySupportContent: View {

    let language: MemoMarkLanguage

    var body: some View {
        VStack(spacing: 0) {
            SettingsPrivacyRow(
                title: localized("settings.privacy.local_processing.title", fallback: "本地完成处理"),
                detail: localized("settings.privacy.local_processing.detail", fallback: "不会上传照片。"),
                systemImage: "iphone",
                tint: .cyan,
                showsDivider: true
            )
            SettingsPrivacyRow(
                title: localized("settings.privacy.original.title", fallback: "不修改原图"),
                detail: localized("settings.privacy.original.detail", fallback: "始终生成新的照片。"),
                systemImage: MemoMarkSymbol.originalPhoto.name,
                tint: .green,
                showsDivider: true
            )
            SettingsPrivacyRow(
                title: localized("settings.privacy.local_configuration.title", fallback: "配置保存在本机"),
                detail: localized("settings.privacy.local_configuration.detail", fallback: "记忆对象、时间锚点与任务记录保存在应用容器中。"),
                systemImage: MemoMarkSymbol.localStorage.name,
                tint: .purple,
                showsDivider: true
            )
            SettingsPrivacyRow(
                title: localized("settings.privacy.delete_app.title", fallback: "删除应用"),
                detail: localized("settings.privacy.delete_app.detail", fallback: "未单独备份的本地配置与记录会一起删除。"),
                systemImage: MemoMarkSymbol.information.name,
                tint: .secondary,
                showsDivider: false
            )
        }
        .background(Color.clear)
    }

    private func localized(_ key: String, fallback: String) -> String {
        language.localized(key: key, fallback: fallback)
    }
}
#endif
