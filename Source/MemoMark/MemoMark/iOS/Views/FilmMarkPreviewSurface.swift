import SwiftUI

/// A calibration view for the authored FilmMark presentation.
///
/// The preview intentionally uses a stable wide canvas so placement and
/// typography can be compared while editing. It is not the export canvas:
/// export resolves the same presentation against the source photo's actual
/// pixel dimensions.
struct FilmMarkPreviewSurface: View {

    let content: FilmMarkContentProjection
    let configuration: FilmMarkConfiguration
    var showsPlacementGuide: Bool = false

    private let canvasSize = CGSize(width: 1_200, height: 600)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "filmMark.preview.calibration_note",
                    fallback: "样式与位置校准示意，实际输出会根据照片比例自适应。"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isStaticText)

            previewCanvas
        }
    }

    private var previewCanvas: some View {
        let presentation = FilmMarkPresentationResolver.resolve(
            content: content,
            configuration: configuration,
            canvasSize: canvasSize
        )

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.24, blue: 0.26),
                        Color(red: 0.83, green: 0.54, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color.white.opacity(0.56))
                    .frame(width: geometry.size.height * 0.22)
                    .position(
                        x: geometry.size.width * 0.76,
                        y: geometry.size.height * 0.27
                    )
                Rectangle()
                    .fill(Color.black.opacity(0.10))
                FilmMarkTextLayer(
                    presentation: presentation,
                    displaySize: geometry.size
                )
                if showsPlacementGuide {
                    FilmMarkPreviewPlacementGuide(
                        configuration: configuration,
                        size: geometry.size
                    )
                }
                if presentation.content.primaryOutput.isEmpty {
                    Text(
                        MemoMarkLanguage.interfaceStored.localized(
                            key: "filmMark.preview.empty",
                            fallback: "暂无胶片内容"
                        )
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.28), in: Capsule())
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center
                    )
                    .allowsHitTesting(false)
                }
            }
        }
        .aspectRatio(canvasSize.width / canvasSize.height, contentMode: .fit)
        .clipped()
    }
}

private struct FilmMarkPreviewPlacementGuide: View {

    let configuration: FilmMarkConfiguration
    let size: CGSize

    var body: some View {
        let inset = min(size.width, size.height) * 0.065
        let guideRect = CGRect(
            x: inset,
            y: inset,
            width: max(0, size.width - inset * 2),
            height: max(0, size.height - inset * 2)
        )

        ZStack {
            RoundedRectangle(cornerRadius: max(8, size.height * 0.04))
                .stroke(
                    Color.white.opacity(0.28),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                )
                .frame(width: guideRect.width, height: guideRect.height)

            Circle()
                .fill(Color.white.opacity(0.82))
                .frame(width: max(6, size.height * 0.026))
                .overlay {
                    Circle().stroke(Color.black.opacity(0.32), lineWidth: 1)
                }
                .position(anchorPoint(in: guideRect))
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func anchorPoint(in rect: CGRect) -> CGPoint {
        switch configuration.placement.anchor {
        case .bottomLeft:
            CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:
            CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
}
