#if canImport(UIKit) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct SubjectAvatarCropDraft: Identifiable {

    let id = UUID()
    let data: Data
    let image: UIImage
}

struct SubjectAvatarCropSheet: View {

    let image: UIImage
    let onCancel: () -> Void
    let onConfirm: (SubjectAvatarCropConfiguration) -> Void

    @State
    private var committedZoomScale: CGFloat = 1

    @State
    private var interactiveZoomScale: CGFloat = 1

    @State
    private var committedTranslation: CGSize = .zero

    @State
    private var interactiveTranslation: CGSize = .zero

    @State
    private var latestCanvasSize =
        CGSize(width: 320, height: 320)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("拖动头像位置，双指缩放画面。确认后会同步生成头像、标识和预览资源。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                cropCanvas

                HStack(spacing: 10) {
                    statPill(
                        title: "缩放",
                        value: "\(Int(effectiveZoomScale * 100))%"
                    )
                    statPill(
                        title: "模式",
                        value: "圆形裁切"
                    )
                }

                Button("恢复默认位置") {
                    committedZoomScale = 1
                    interactiveZoomScale = 1
                    committedTranslation = .zero
                    interactiveTranslation = .zero
                }
                .buttonStyle(.borderless)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("调整对象头像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消", action: onCancel)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("应用") {
                        onConfirm(
                            SubjectAvatarCropConfiguration(
                                zoomScale: effectiveZoomScale,
                                normalizedOffset:
                                    currentNormalizedOffset
                            )
                        )
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var cropCanvas: some View {
        GeometryReader { proxy in
            let side =
                min(proxy.size.width, proxy.size.height)
            let canvasSize =
                CGSize(width: side, height: side)
            let drawRect =
                SubjectAvatarCropSupport
                .resolvedDrawRect(
                    sourceSize: image.size,
                    canvasSize: canvasSize,
                    safeInsetRatio:
                        SubjectAvatarAssetOptimizationService
                        .safeInsetRatio,
                    configuration:
                        SubjectAvatarCropConfiguration(
                            zoomScale: effectiveZoomScale,
                            normalizedOffset:
                                normalizedOffset(
                                    in: canvasSize
                                )
                        )
                )

            ZStack {
                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.black.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(
                        width: drawRect.width,
                        height: drawRect.height
                    )
                    .position(
                        x: drawRect.midX,
                        y: drawRect.midY
                    )

                avatarCropMask
            }
            .frame(width: side, height: side)
            .onAppear {
                latestCanvasSize = canvasSize
            }
            .onChange(of: side) { _, _ in
                latestCanvasSize = canvasSize
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
                    .stroke(
                        Color.black.opacity(0.07),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            interactiveTranslation =
                                value.translation
                        }
                        .onEnded { value in
                            committedTranslation =
                                clampedTranslation(
                                    proposed:
                                        CGSize(
                                            width:
                                                committedTranslation.width
                                                + value.translation.width,
                                            height:
                                                committedTranslation.height
                                                + value.translation.height
                                        ),
                                    canvasSize: canvasSize,
                                    zoomScale: effectiveZoomScale
                                )
                            interactiveTranslation = .zero
                        },
                    MagnificationGesture()
                        .onChanged { value in
                            interactiveZoomScale = value
                        }
                        .onEnded { value in
                            committedZoomScale =
                                SubjectAvatarCropConfiguration
                                .clampedZoomScale(
                                    committedZoomScale * value
                                )
                            interactiveZoomScale = 1
                            committedTranslation =
                                clampedTranslation(
                                    proposed: currentTranslation,
                                    canvasSize: canvasSize,
                                    zoomScale: committedZoomScale
                                )
                        }
                )
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var avatarCropMask: some View {
        GeometryReader { proxy in
            let rect =
                CGRect(
                    origin: .zero,
                    size: proxy.size
                )
            let circleInset =
                proxy.size.width
                * SubjectAvatarAssetOptimizationService
                    .safeInsetRatio

            ZStack {
                Path { path in
                    path.addRect(rect)
                    path.addEllipse(
                        in: rect.insetBy(
                            dx: circleInset,
                            dy: circleInset
                        )
                    )
                }
                .fill(
                    Color.black.opacity(0.28),
                    style: FillStyle(eoFill: true)
                )

                Circle()
                    .inset(by: circleInset)
                    .strokeBorder(
                        Color.white.opacity(0.92),
                        lineWidth: 2
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private var effectiveZoomScale: CGFloat {
        SubjectAvatarCropConfiguration
            .clampedZoomScale(
                committedZoomScale * interactiveZoomScale
            )
    }

    private var currentTranslation: CGSize {
        CGSize(
            width:
                committedTranslation.width
                + interactiveTranslation.width,
            height:
                committedTranslation.height
                + interactiveTranslation.height
        )
    }

    private var currentNormalizedOffset: CGSize {
        normalizedOffset(
            in: latestCanvasSize
        )
    }

    private func normalizedOffset(
        in canvasSize: CGSize
    ) -> CGSize {
        SubjectAvatarCropSupport
            .normalizedOffset(
                for:
                    clampedTranslation(
                        proposed: currentTranslation,
                        canvasSize: canvasSize,
                        zoomScale: effectiveZoomScale
                    ),
                sourceSize: image.size,
                canvasSize: canvasSize,
                safeInsetRatio:
                    SubjectAvatarAssetOptimizationService
                    .safeInsetRatio,
                zoomScale: effectiveZoomScale
            )
    }

    private func clampedTranslation(
        proposed: CGSize,
        canvasSize: CGSize,
        zoomScale: CGFloat
    ) -> CGSize {
        SubjectAvatarCropSupport
            .clampedTranslation(
                proposed,
                sourceSize: image.size,
                canvasSize: canvasSize,
                safeInsetRatio:
                    SubjectAvatarAssetOptimizationService
                    .safeInsetRatio,
                zoomScale: zoomScale
            )
    }

    private func statPill(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.black.opacity(0.08))
        )
    }
}
#endif
