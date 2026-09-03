#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Displays the read-only Apple Photos processing guarantees from values
/// resolved by Settings. It owns no media, commerce, or queue behavior.
struct PhotoProcessingSupportContent: View {

    let language: MemoMarkLanguage
    let batchLimit: Int

    var body: some View {
        VStack(spacing: 0) {
            SettingsInformationRow(
                title: localized(
                    "settings.support.metadata.title",
                    fallback: "原始拍摄信息"
                ),
                headline: localized(
                    "settings.support.metadata.headline",
                    fallback: "保留日期、地点与拍摄参数；缺失时不影响照片处理。"
                ),
                detail: nil,
                systemImage: MemoMarkSymbol.photoMetadata.name,
                tint: .blue,
                showsDivider: true
            )

            SettingsInformationRow(
                title: localized(
                    "settings.support.input.title",
                    fallback: "支持的照片"
                ),
                headline: localized(
                    "settings.support.input.headline",
                    fallback: "JPEG、HEIF、RAW / DNG 与 Live Photo"
                ),
                detail: nil,
                systemImage: MemoMarkSymbol.originalPhoto.name,
                tint: .pink,
                showsDivider: true
            )

            SettingsInformationRow(
                title: localized(
                    "settings.support.batch.title",
                    fallback: "一次分享"
                ),
                headline: String(
                    format: localized(
                        "settings.support.batch.headline_format",
                        fallback: "最多 %lld 张照片"
                    ),
                    locale: language.locale,
                    Int64(batchLimit)
                ),
                detail: localized(
                    "settings.support.batch.detail",
                    fallback: "更多照片请分次分享。"
                ),
                systemImage: MemoMarkSymbol.processing.name,
                tint: .orange,
                showsDivider: true
            )

            SettingsInformationRow(
                title: localized(
                    "settings.support.result.title",
                    fallback: "保存到 Apple Photos"
                ),
                headline: localized(
                    "settings.support.result.headline",
                    fallback: "生成一张新照片，原图保持不变"
                ),
                detail: nil,
                systemImage: MemoMarkSymbol.applePhotos.name,
                tint: .green,
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
