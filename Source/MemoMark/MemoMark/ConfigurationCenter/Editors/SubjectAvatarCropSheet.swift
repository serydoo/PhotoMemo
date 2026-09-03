#if canImport(UIKit) && !MEMOMARK_SHARE_EXTENSION
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
        ZStack {
            ConfigurationUI.appBackground
                .ignoresSafeArea()

            NavigationStack {
                VStack(alignment: .leading, spacing: 18) {
                    Text(
                        MemoMarkLanguage.interfaceStored.localized(
                            key: "avatar.crop.instructions",
                            fallback: "拖动照片调整位置，双指缩放。完成后会用于对象头像和卡片预览。"
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    cropCanvas

                    zoomControl

                    Button(
                        MemoMarkLanguage.interfaceStored.localized(
                            key: "avatar.crop.reset",
                            fallback: "恢复默认位置"
                        )
                    ) {
                        committedZoomScale = 1
                        interactiveZoomScale = 1
                        committedTranslation = .zero
                        interactiveTranslation = .zero
                    }
                    .buttonStyle(.borderless)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ConfigurationUI.appBackground.ignoresSafeArea())
                .navigationTitle(
                    MemoMarkLanguage.interfaceStored.localized(
                        key: "avatar.crop.title",
                        fallback: "调整对象头像"
                    )
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(ConfigurationUI.appBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(
                            MemoMarkLanguage.interfaceStored.localized(
                                key: "common.cancel",
                                fallback: "取消"
                            ),
                            action: onCancel
                        )
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button(
                            MemoMarkLanguage.interfaceStored.localized(
                                key: "avatar.crop.done",
                                fallback: "完成"
                            )
                        ) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ConfigurationUI.appBackground.ignoresSafeArea())
        .presentationBackground(ConfigurationUI.appBackground)
    }

    private var cropCanvas: some View {
        // Establish the square canvas before GeometryReader measures its
        // contents. A bare GeometryReader inside the vertical editor can
        // otherwise consume the remaining height, making a portrait image
        // and the circular crop guide appear vertically misaligned.
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let canvasSize = proxy.size
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
                        Color.black

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
                    .frame(
                        width: canvasSize.width,
                        height: canvasSize.height
                    )
                    .clipped()
                    .onAppear {
                        latestCanvasSize = canvasSize
                    }
                    .onChange(of: canvasSize) { _, newSize in
                        latestCanvasSize = newSize
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                interactiveTranslation = value.translation
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
                            }
                    )
                    .simultaneousGesture(
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
                    .accessibilityIdentifier(
                        "subject-avatar-crop-canvas"
                    )
                }
            }
            .clipped()
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

    private var zoomControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(
                value:
                    Binding(
                        get: { committedZoomScale },
                        set: { value in
                            committedZoomScale =
                                SubjectAvatarCropConfiguration
                                .clampedZoomScale(value)
                            interactiveZoomScale = 1
                            committedTranslation =
                                clampedTranslation(
                                    proposed: committedTranslation,
                                    canvasSize: latestCanvasSize,
                                    zoomScale: committedZoomScale
                                )
                        }
                    ),
                in: avatarZoomRange
            )
            .accessibilityLabel(Text(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "accessibility.avatar_zoom",
                    fallback: "Avatar zoom"
                )
            ))
            .accessibilityValue("\(Int(committedZoomScale * 100))%")

            Image(systemName: "photo.fill")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var avatarZoomRange: ClosedRange<CGFloat> {
        return (
            SubjectAvatarCropConfiguration.minimumZoomScale
            ... SubjectAvatarCropConfiguration.maximumZoomScale
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

}
#endif
