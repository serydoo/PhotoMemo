#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Presents Settings' read-only About content and delegates release-note
/// presentation to the page that owns its sheet state.
struct AboutSettingsContent: View {
    let language: MemoMarkLanguage
    let compactVersion: String
    let onShowReleaseNotes: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 0) {
                SettingsVersionRow(
                    title: localized("settings.version.row_title", fallback: "版本"),
                    compactVersion: compactVersion
                )
                Button(action: onShowReleaseNotes) {
                    SettingsActionRow(
                        title: localized("settings.version.release_notes", fallback: "更新日志"),
                        detail: localized("settings.version.release_notes_detail", fallback: "看看时光记最近有哪些变化。"),
                        systemImage: "doc.text.fill",
                        tint: .blue,
                        showsDivider: false
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Color.clear)

            Text(localized("settings.version.copyright", fallback: "© 2026 MemoMark"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func localized(_ key: String, fallback: String) -> String {
        language.localized(key: key, fallback: fallback)
    }
}

/// Displays the narrative shown by the existing About MemoMark sheet.
struct AboutMemoMarkNarrativeContent: View {
    let language: MemoMarkLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localized("settings.overview.headline", fallback: "让照片记得，它在人生里的位置。"))
                .font(.headline.weight(.semibold))
            ForEach(paragraphs, id: \.self) { paragraph in
                Text(paragraph).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(localized("settings.overview.closing", fallback: "愿大家都能享受这些被时间标记的记忆。"))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var paragraphs: [String] {
        [
            localized("settings.overview.paragraph_one", fallback: "陪伴孩子长大的过程中，我们留下了很多照片。时光记最初只想回答一个问题：打开照片时，能不能马上知道那一天，孩子多大？"),
            localized("settings.overview.paragraph_two", fallback: "从孩子出生的那一天开始，生日、纪念日和未来的重要日期都可以成为时间锚点。照片因此不只记录拍摄时间，也能呈现年龄、倒数，以及它位于一段人生的什么位置。"),
            localized("settings.overview.paragraph_three", fallback: "时光记不是给照片添加水印，而是把时间关系变成更容易读懂的回忆。照片只在你的设备上整理，原图始终保持不变。")
        ]
    }

    private func localized(_ key: String, fallback: String) -> String { language.localized(key: key, fallback: fallback) }
}
#endif
