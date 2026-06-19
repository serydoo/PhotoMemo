import SwiftUI

struct MainStatusPillView: View {

    let title: String

    let value: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 3
        ) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                MinimalPalette.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
    }
}

private struct MainPreviewHeaderView: View {

    var body: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("实时预览")
                    .font(.title3.weight(.semibold))

                Text("按当前配置、时间点与 EXIF 数据即时生成")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct MainPreviewCanvasView: View {

    let previewImage: Image

    let card: RecordCard

    let previewWidth: CGFloat

    var body: some View {

        RecordCardRenderer(
            image: previewImage,
            card: card
        )
        .frame(
            maxWidth: previewWidth
        )
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
            .fill(
                MinimalPalette.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 24,
            y: 12
        )
    }
}

private struct MainPreviewSummaryView: View {

    let templateName: String

    let anchorSummaryText: String?

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Live Context")
                .font(.headline)

            Text("当前配置内容：\(templateName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let anchorSummaryText {

                Text(anchorSummaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                MinimalPalette.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
        .frame(
            maxWidth: 900,
            alignment: .leading
        )
    }
}

struct MainPreviewDetailView: View {

    let previewImage: Image

    let card: RecordCard

    let previewWidth: CGFloat

    var body: some View {

        VStack(
            alignment: .center,
            spacing: 22
        ) {

            VStack(
                alignment: .leading,
                spacing: 22
            ) {

                MainPreviewHeaderView()

                MainPreviewCanvasView(
                    previewImage: previewImage,
                    card: card,
                    previewWidth: previewWidth
                )

                MainPreviewSummaryView(
                    templateName: card.template.name,
                    anchorSummaryText:
                        card.anchorResult?
                        .summaryText
                )
            }
            .frame(
                maxWidth: previewWidth,
                alignment: .leading
            )
        }
        .frame(maxWidth: .infinity)
    }
}
