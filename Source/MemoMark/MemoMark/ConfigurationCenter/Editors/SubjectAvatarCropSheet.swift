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
    private var cropConfiguration = SubjectAvatarCropConfiguration()

    @State
    private var latestCanvasSize = CGSize(width: 320, height: 320)

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
                        cropConfiguration = .init()
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
                            onConfirm(cropConfiguration)
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
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let canvasSize = proxy.size

                    SubjectAvatarCropViewport(
                        image: image,
                        configuration: $cropConfiguration,
                        safeInsetRatio:
                            SubjectAvatarAssetOptimizationService.safeInsetRatio,
                        onCanvasSizeChange: { newSize in
                            latestCanvasSize = newSize
                        }
                    )
                    .overlay { avatarCropMask }
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .accessibilityIdentifier("subject-avatar-crop-canvas")
                    .accessibilityLabel(Text(
                        MemoMarkLanguage.interfaceStored.localized(
                            key: "accessibility.avatar_crop",
                            fallback: "头像裁切区域"
                        )
                    ))
                    .accessibilityValue(avatarCropAccessibilityValue)
                    .accessibilityAction(
                        named: Text(
                            MemoMarkLanguage.interfaceStored.localized(
                                key: "accessibility.avatar_move_left",
                                fallback: "向左移动照片"
                            )
                        )
                    ) {
                        adjustCropOffset(width: -0.1)
                    }
                    .accessibilityAction(
                        named: Text(
                            MemoMarkLanguage.interfaceStored.localized(
                                key: "accessibility.avatar_move_right",
                                fallback: "向右移动照片"
                            )
                        )
                    ) {
                        adjustCropOffset(width: 0.1)
                    }
                    .accessibilityAction(
                        named: Text(
                            MemoMarkLanguage.interfaceStored.localized(
                                key: "accessibility.avatar_move_up",
                                fallback: "向上移动照片"
                            )
                        )
                    ) {
                        adjustCropOffset(height: -0.1)
                    }
                    .accessibilityAction(
                        named: Text(
                            MemoMarkLanguage.interfaceStored.localized(
                                key: "accessibility.avatar_move_down",
                                fallback: "向下移动照片"
                            )
                        )
                    ) {
                        adjustCropOffset(height: 0.1)
                    }
                    .accessibilityAction(
                        named: Text(
                            MemoMarkLanguage.interfaceStored.localized(
                                key: "accessibility.avatar_center",
                                fallback: "居中照片"
                            )
                        )
                    ) {
                        cropConfiguration.normalizedOffset = .zero
                    }
                }
            }
            .clipped()
    }

    private var avatarCropMask: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let circleInset = proxy.size.width
                * SubjectAvatarAssetOptimizationService.safeInsetRatio

            ZStack {
                Path { path in
                    path.addRect(rect)
                    path.addEllipse(
                        in: rect.insetBy(dx: circleInset, dy: circleInset)
                    )
                }
                .fill(
                    Color.black.opacity(0.28),
                    style: FillStyle(eoFill: true)
                )

                Circle()
                    .inset(by: circleInset)
                    .strokeBorder(Color.white.opacity(0.92), lineWidth: 2)
            }
        }
        .allowsHitTesting(false)
    }

    private var zoomControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(
                value: Binding(
                    get: { cropConfiguration.zoomScale },
                    set: { value in
                        cropConfiguration = SubjectAvatarCropSupport
                            .configurationPreservingCropCenter(
                                cropConfiguration,
                                newZoomScale: value,
                                sourceSize: image.size,
                                canvasSize: latestCanvasSize,
                                safeInsetRatio:
                                    SubjectAvatarAssetOptimizationService.safeInsetRatio
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
            .accessibilityValue("\(Int(cropConfiguration.zoomScale * 100))%")

            Image(systemName: "photo.fill")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var avatarZoomRange: ClosedRange<CGFloat> {
        SubjectAvatarCropConfiguration.minimumZoomScale
            ... SubjectAvatarCropConfiguration.maximumZoomScale
    }

    private var avatarCropAccessibilityValue: String {
        let zoom = Int(cropConfiguration.zoomScale * 100)
        let x = Int(cropConfiguration.normalizedOffset.width * 100)
        let y = Int(cropConfiguration.normalizedOffset.height * 100)
        return "\(zoom)%, x \(x)%, y \(y)%"
    }

    private func adjustCropOffset(
        width: CGFloat = 0,
        height: CGFloat = 0
    ) {
        cropConfiguration.normalizedOffset =
            SubjectAvatarCropConfiguration.clampedNormalizedOffset(
                CGSize(
                    width: cropConfiguration.normalizedOffset.width + width,
                    height: cropConfiguration.normalizedOffset.height + height
                )
            )
    }
}

private struct SubjectAvatarCropViewport: UIViewRepresentable {

    let image: UIImage
    @Binding var configuration: SubjectAvatarCropConfiguration
    let safeInsetRatio: CGFloat
    let onCanvasSizeChange: (CGSize) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> SubjectAvatarCropScrollView {
        let scrollView = SubjectAvatarCropScrollView()
        scrollView.backgroundColor = .black
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = SubjectAvatarCropConfiguration.minimumZoomScale
        scrollView.maximumZoomScale = SubjectAvatarCropConfiguration.maximumZoomScale
        scrollView.bounces = true
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = .normal
        scrollView.delaysContentTouches = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.onLayout = { [weak coordinator = context.coordinator] view in
            coordinator?.layout(view)
        }

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.frame = .zero
        scrollView.imageView = imageView
        scrollView.addSubview(imageView)
        return scrollView
    }

    func updateUIView(
        _ scrollView: SubjectAvatarCropScrollView,
        context: Context
    ) {
        context.coordinator.parent = self
        if scrollView.imageView?.image !== image {
            scrollView.imageView?.image = image
            context.coordinator.invalidateBaseLayout()
        }
        context.coordinator.apply(configuration, to: scrollView, animated: false)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {

        var parent: SubjectAvatarCropViewport
        private var isApplying = false
        private var lastApplied: SubjectAvatarCropConfiguration?
        private var lastBaseCanvasSize: CGSize?
        private var lastBaseSourceSize: CGSize?

        init(_ parent: SubjectAvatarCropViewport) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            (scrollView as? SubjectAvatarCropScrollView)?.imageView
        }

        func invalidateBaseLayout() {
            lastBaseCanvasSize = nil
            lastBaseSourceSize = nil
            lastApplied = nil
        }

        func layout(_ scrollView: SubjectAvatarCropScrollView) {
            guard scrollView.bounds.width > 0,
                  scrollView.bounds.height > 0,
                  let imageView = scrollView.imageView
            else { return }

            let canvasSize = scrollView.bounds.size
            let needsBaseLayout = lastBaseCanvasSize != canvasSize
                || lastBaseSourceSize != parent.image.size
            guard !scrollView.isZooming || !needsBaseLayout else { return }
            let baseRect = SubjectAvatarCropSupport.aspectFillRect(
                sourceSize: parent.image.size,
                canvasSize: canvasSize,
                safeInsetRatio: parent.safeInsetRatio
            )
            if needsBaseLayout {
                let configurationToRestore = parent.configuration
                isApplying = true
                lastApplied = nil
                if scrollView.isDecelerating {
                    scrollView.setContentOffset(
                        scrollView.contentOffset,
                        animated: false
                    )
                }
                if scrollView.zoomScale != 1 {
                    scrollView.setZoomScale(1, animated: false)
                }
                setBaseImageViewFrame(imageView, size: baseRect.size)
                lastBaseCanvasSize = canvasSize
                lastBaseSourceSize = parent.image.size
                updateInsets(
                    scrollView,
                    preservingTranslation: .zero
                )
                isApplying = false
                parent.onCanvasSizeChange(canvasSize)
                apply(
                    configurationToRestore,
                    to: scrollView,
                    animated: false
                )
                return
            }
            updateInsets(
                scrollView,
                preservingTranslation: currentTranslation(in: scrollView)
            )
            parent.onCanvasSizeChange(canvasSize)
            apply(parent.configuration, to: scrollView, animated: false)
        }

        func apply(
            _ configuration: SubjectAvatarCropConfiguration,
            to scrollView: SubjectAvatarCropScrollView,
            animated: Bool
        ) {
            guard scrollView.bounds.width > 0,
                  scrollView.bounds.height > 0,
                  scrollView.imageView != nil,
                  !scrollView.isDragging,
                  !scrollView.isZooming
            else { return }

            let normalizedConfiguration = SubjectAvatarCropConfiguration(
                zoomScale: configuration.zoomScale,
                normalizedOffset: configuration.normalizedOffset
            )
            guard !isEquivalent(normalizedConfiguration, to: lastApplied)
            else { return }

            isApplying = true
            let canvasSize = scrollView.bounds.size
            // Explicit crop commands must take ownership from existing
            // scroll-view momentum before applying their new state.
            if scrollView.isDecelerating {
                scrollView.setContentOffset(
                    scrollView.contentOffset,
                    animated: false
                )
            }
            scrollView.setZoomScale(
                normalizedConfiguration.zoomScale,
                animated: animated
            )
            scrollView.layoutIfNeeded()
            updateInsets(
                scrollView,
                preservingTranslation: SubjectAvatarCropSupport.translation(
                    for: normalizedConfiguration,
                    sourceSize: parent.image.size,
                    canvasSize: canvasSize,
                    safeInsetRatio: parent.safeInsetRatio
                )
            )
            setContentOffset(for: normalizedConfiguration, in: scrollView)
            lastApplied = normalizedConfiguration
            isApplying = false
        }

        private func setBaseImageViewFrame(
            _ imageView: UIImageView,
            size: CGSize
        ) {
            imageView.frame = CGRect(
                origin: .zero,
                size: size
            )
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard !isApplying else { return }
            updateInsets(
                scrollView,
                preservingTranslation: currentTranslation(in: scrollView)
            )
            report(scrollView)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isApplying else { return }
            report(scrollView)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            report(scrollView)
        }

        func scrollViewDidEndZooming(
            _ scrollView: UIScrollView,
            with view: UIView?,
            atScale scale: CGFloat
        ) {
            report(scrollView)
        }

        private func report(_ scrollView: UIScrollView) {
            guard !isApplying,
                  scrollView.bounds.width > 0,
                  scrollView.bounds.height > 0
            else { return }
            let canvasSize = scrollView.bounds.size
            let zoomScale = SubjectAvatarCropConfiguration.clampedZoomScale(
                scrollView.zoomScale
            )
            let configuration = SubjectAvatarCropConfiguration(
                zoomScale: zoomScale,
                normalizedOffset: SubjectAvatarCropSupport.normalizedOffset(
                    for: currentTranslation(in: scrollView),
                    sourceSize: parent.image.size,
                    canvasSize: canvasSize,
                    safeInsetRatio: parent.safeInsetRatio,
                    zoomScale: zoomScale
                )
            )
            lastApplied = configuration
            parent.configuration = configuration
        }

        private func currentTranslation(
            in scrollView: UIScrollView
        ) -> CGSize {
            guard let subjectScrollView = scrollView as?
                    SubjectAvatarCropScrollView,
                  let imageView = subjectScrollView.imageView
            else { return .zero }
            let imageCenter = imageView.superview?.convert(
                imageView.center,
                to: subjectScrollView
            ) ?? imageView.center
            return CGSize(
                width: imageCenter.x - subjectScrollView.bounds.midX,
                height: imageCenter.y - subjectScrollView.bounds.midY
            )
        }

        private func updateInsets(
            _ scrollView: UIScrollView,
            preservingTranslation translation: CGSize
        ) {
            guard let subjectScrollView = scrollView as?
                    SubjectAvatarCropScrollView,
                  let imageView = subjectScrollView.imageView
            else { return }
            let scaledSize = CGSize(
                width: imageView.bounds.width * scrollView.zoomScale,
                height: imageView.bounds.height * scrollView.zoomScale
            )
            let cropInset = min(
                scrollView.bounds.width,
                scrollView.bounds.height
            ) * parent.safeInsetRatio
            scrollView.contentInset = UIEdgeInsets(
                top: cropInset,
                left: cropInset,
                bottom: cropInset,
                right: cropInset
            )
            scrollView.scrollIndicatorInsets = scrollView.contentInset
            // Keep the scroll content extent explicit. This makes the
            // contentOffset domain match the same circular crop aperture used
            // by SubjectAvatarCropSupport.maximumTranslation.
            scrollView.contentSize = scaledSize
            guard !scrollView.isDragging, !scrollView.isZooming else { return }
            let canvasSize = scrollView.bounds.size
            let scaledMidX = scaledSize.width / 2
            let scaledMidY = scaledSize.height / 2
            let canvasMidX = canvasSize.width / 2
            let canvasMidY = canvasSize.height / 2
            let offset = CGPoint(
                x: scaledMidX - canvasMidX - translation.width,
                y: scaledMidY - canvasMidY - translation.height
            )
            scrollView.setContentOffset(offset, animated: false)
        }

        private func setContentOffset(
            for configuration: SubjectAvatarCropConfiguration,
            in scrollView: SubjectAvatarCropScrollView
        ) {
            let translation = SubjectAvatarCropSupport.translation(
                for: configuration,
                sourceSize: parent.image.size,
                canvasSize: scrollView.bounds.size,
                safeInsetRatio: parent.safeInsetRatio
            )
            guard let imageView = scrollView.imageView else { return }
            let scaledSize = CGSize(
                width: imageView.bounds.width * scrollView.zoomScale,
                height: imageView.bounds.height * scrollView.zoomScale
            )
            scrollView.setContentOffset(
                CGPoint(
                    x: scaledSize.width / 2
                        - scrollView.bounds.width / 2 - translation.width,
                    y: scaledSize.height / 2
                        - scrollView.bounds.height / 2 - translation.height
                ),
                animated: false
            )
        }

        private func isEquivalent(
            _ lhs: SubjectAvatarCropConfiguration,
            to rhs: SubjectAvatarCropConfiguration?
        ) -> Bool {
            guard let rhs else { return false }
            return abs(lhs.zoomScale - rhs.zoomScale) < 0.0001
                && abs(lhs.normalizedOffset.width - rhs.normalizedOffset.width) < 0.0001
                && abs(lhs.normalizedOffset.height - rhs.normalizedOffset.height) < 0.0001
        }
    }
}

private final class SubjectAvatarCropScrollView: UIScrollView {

    var imageView: UIImageView?
    var onLayout: ((SubjectAvatarCropScrollView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(self)
    }
}
#endif
