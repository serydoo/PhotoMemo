#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import ImageIO
import SwiftUI
import UIKit

/// A local, non-Photos thumbnail presentation for task history and status.
///
/// `TaskPageSurface` owns queue projections and navigation decisions. This
/// view owns only its short-lived image state and bounded background decode of
/// the already-selected local file URL; it never changes a task, an output
/// receipt, or the Photo Library.
struct TaskLocalThumbnail: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    let sourceURL: URL?
    let symbolName: String
    let tint: MemoMarkiOSQueueDiagnosticsTint
    let size: CGSize
    let itemCount: Int

    @State
    private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if itemCount > 1 {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.color.opacity(0.12))
                    .frame(width: size.width - 8, height: size.height - 8)
                    .offset(x: 5, y: -4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(ConfigurationUI.faintHairline)
                            .offset(x: 5, y: -4)
                    )
            }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    tint.color.opacity(0.12)
                )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint.color)
            }

            if itemCount > 1 {
                Text("\(itemCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.68)))
                    .padding(5)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ConfigurationUI.faintHairline)
        )
        .task(id: sourceURL) {
            image =
                await loadThumbnail(
                    from: sourceURL,
                    maxPixelSize:
                        max(size.width, size.height) * 3
                )
        }
        .accessibilityLabel(
            itemCount > 1
                ? interfaceLanguage.localized(
                    key: "task.thumbnail.multiple",
                    fallback: "共 %@ 张照片，显示第一张已保存结果作为封面"
                ).replacingOccurrences(
                    of: "%@",
                    with: String(itemCount)
                )
                : interfaceLanguage.localized(
                    key: "task.thumbnail.single",
                    fallback: "照片缩略图"
                )
        )
    }

    private func loadThumbnail(
        from url: URL?,
        maxPixelSize: CGFloat
    ) async -> UIImage? {
        guard let url else {
            return nil
        }

        return await Task.detached(priority: .utility) {
            guard let source =
                CGImageSourceCreateWithURL(
                    url as CFURL,
                    nil
                )
            else {
                return UIImage(contentsOfFile: url.path)
            }

            let options:
                [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways:
                        true,
                    kCGImageSourceCreateThumbnailWithTransform:
                        true,
                    kCGImageSourceThumbnailMaxPixelSize:
                        Int(maxPixelSize)
                ]

            guard let cgImage =
                CGImageSourceCreateThumbnailAtIndex(
                    source,
                    0,
                    options as CFDictionary
                )
            else {
                return UIImage(contentsOfFile: url.path)
            }

            return UIImage(cgImage: cgImage)
        }
        .value
    }
}
#endif
