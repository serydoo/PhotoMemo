#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit
import UniformTypeIdentifiers

struct ShareExtensionPreviewRequest {
    let inputItems: [NSExtensionItem]
    let limit: Int
}

@MainActor
final class ShareExtensionPreviewController: NSObject {

    private weak var scrollView: UIScrollView?
    private weak var cardStack: UIStackView?
    private weak var captionLabel: UILabel?
    private weak var listHeightConstraint: NSLayoutConstraint?
    private var cardViews: [UIView] = []
    private var imageViews: [UIImageView] = []
    private var statusBadgeViews: [UIImageView] = []
    private var statusTitleLabels: [UILabel] = []
    private var statusDetailLabels: [UILabel] = []
    private var cardSizeConstraints:
        [UIView: (width: NSLayoutConstraint, height: NSLayoutConstraint)] = [:]

    func attach(
        scrollView: UIScrollView,
        cardStack: UIStackView,
        captionLabel: UILabel,
        listHeightConstraint: NSLayoutConstraint
    ) {
        self.scrollView = scrollView
        self.cardStack = cardStack
        self.captionLabel = captionLabel
        self.listHeightConstraint = listHeightConstraint
    }

    func supportedProviders(
        for request: ShareExtensionPreviewRequest
    ) -> [NSItemProvider] {
        Array(
            request.inputItems
                .flatMap { $0.attachments ?? [] }
                .filter(isSupportedPreviewProvider)
                .prefix(max(request.limit, 1))
        )
    }

    func loadImages(
        from providers: [NSItemProvider]
    ) async -> [UIImage?] {
        var images: [UIImage?] = []
        images.reserveCapacity(providers.count)
        for provider in providers {
            if Task.isCancelled {
                break
            }
            images.append(await loadPreviewImage(from: provider))
        }
        return images
    }

    func loadPreviews(
        for request: ShareExtensionPreviewRequest,
        sharedPhotoCount: Int,
        showsProcessingLegend:
            @MainActor () -> Bool
    ) async {
        let providers = supportedProviders(
            for: request
        )

        guard !providers.isEmpty else {
            setCaption(
                sharedPhotoCount > 0
                ? "这次会按相同风格处理 \(sharedPhotoCount) 张照片。"
                : "未识别到可处理照片。"
            )
            resetCards()
            return
        }

        configurePlaceholders(count: providers.count)
        let images = await loadImages(
            from: providers
        )

        guard !Task.isCancelled else {
            return
        }

        applyImages(images)

        if showsProcessingLegend() {
            setCaption(Self.processingLegendText)
        } else if sharedPhotoCount > 1 {
            setCaption(
                "左右滑动查看待处理照片，所有照片会使用相同风格处理。"
            )
        } else {
            setCaption(
                "将按当前默认风格处理这张照片。"
            )
        }
    }

    func setCaption(_ text: String) {
        captionLabel?.text = text
    }

    func resetCards() {
        cardViews.removeAll()
        imageViews.removeAll()
        statusBadgeViews.removeAll()
        statusTitleLabels.removeAll()
        statusDetailLabels.removeAll()
        cardSizeConstraints.removeAll()
        cardStack?.arrangedSubviews.forEach { view in
            cardStack?.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func configurePlaceholders(count: Int) {
        resetCards()
        guard let cardStack else { return }

        for index in 0..<count {
            let card = makePreviewCard(index: index, cardStack: cardStack)
            cardViews.append(card.container)
            imageViews.append(card.imageView)
            statusBadgeViews.append(card.statusBadgeView)
            statusTitleLabels.append(card.titleLabel)
            statusDetailLabels.append(card.detailLabel)
        }

        rebuildLayout()
        updateSelectedCards(animated: false)
    }

    func updateRows(tasks: [SharedBatchTaskSnapshot]) {
        for (index, badge) in statusBadgeViews.enumerated() {
            let task = tasks.indices.contains(index) ? tasks[index] : nil
            let phase = task?.phase ?? .queued
            if statusTitleLabels.indices.contains(index) {
                statusTitleLabels[index].text = "第 \(index + 1) 张照片"
            }
            if statusDetailLabels.indices.contains(index) {
                statusDetailLabels[index].text = statusDetailText(
                    task: task,
                    phase: phase
                )
            }
            applyStatusBadge(badge, phase: phase)
        }
    }

    func updateRows(phases: [BatchTaskPhase]) {
        for (index, badge) in statusBadgeViews.enumerated() {
            let phase = phases.indices.contains(index) ? phases[index] : .queued
            if statusTitleLabels.indices.contains(index) {
                statusTitleLabels[index].text = "第 \(index + 1) 张照片"
            }
            if statusDetailLabels.indices.contains(index) {
                statusDetailLabels[index].text = statusDetailText(
                    task: nil,
                    phase: phase
                )
            }
            applyStatusBadge(badge, phase: phase)
        }
    }

    func applyImages(_ images: [UIImage?]) {
        for (index, image) in images.enumerated()
        where imageViews.indices.contains(index) {
            imageViews[index].image = image
        }
        rebuildLayout()
    }

    static let processingLegendText =
        "灰色等待，蓝色处理中，绿色完成，红色需要处理。"

    var cardCount: Int { statusBadgeViews.count }

    private func makePreviewCard(
        index: Int,
        cardStack: UIStackView
    ) -> (
        container: UIView,
        imageView: UIImageView,
        statusBadgeView: UIImageView,
        titleLabel: UILabel,
        detailLabel: UILabel
    ) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .tertiarySystemBackground
        container.layer.cornerRadius = 14
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = false

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.layer.cornerCurve = .continuous
        imageView.backgroundColor = .secondarySystemBackground
        container.addSubview(imageView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.text = "第 \(index + 1) 张照片"

        let detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = .preferredFont(forTextStyle: .caption1)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 1
        detailLabel.text = "等待时光记接手"

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 2
        container.addSubview(textStack)

        let statusBadgeView = UIImageView()
        statusBadgeView.translatesAutoresizingMaskIntoConstraints = false
        statusBadgeView.contentMode = .center
        statusBadgeView.backgroundColor = .clear
        statusBadgeView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        container.addSubview(statusBadgeView)
        applyStatusBadge(statusBadgeView, phase: .queued)

        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleCardTap(_:))
        )
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        container.tag = index

        let widthConstraint = container.widthAnchor.constraint(
            equalTo: cardStack.widthAnchor
        )
        let heightConstraint = container.heightAnchor.constraint(
            equalToConstant: 54
        )
        cardSizeConstraints[container] = (widthConstraint, heightConstraint)

        NSLayoutConstraint.activate([
            widthConstraint,
            heightConstraint,
            imageView.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant: 8
            ),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            textStack.leadingAnchor.constraint(
                equalTo: imageView.trailingAnchor,
                constant: 10
            ),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textStack.trailingAnchor.constraint(
                lessThanOrEqualTo: statusBadgeView.leadingAnchor,
                constant: -10
            ),
            statusBadgeView.widthAnchor.constraint(equalToConstant: 24),
            statusBadgeView.heightAnchor.constraint(equalToConstant: 24),
            statusBadgeView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            statusBadgeView.trailingAnchor.constraint(
                equalTo: container.trailingAnchor,
                constant: -10
            )
        ])

        return (container, imageView, statusBadgeView, titleLabel, detailLabel)
    }

    private func statusDetailText(
        task: SharedBatchTaskSnapshot?,
        phase: BatchTaskPhase
    ) -> String {
        if let failureMessage = task?.failureMessage,
           !failureMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return failureMessage
        }
        if let statusMessage = task?.statusMessage,
           !statusMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return statusMessage
        }
        switch phase {
        case .queued: return "等待时光记接手"
        case .completed: return "已保存到系统图库"
        case .failed: return "需要回到时光记查看"
        case .cancelled: return "已取消"
        case .importing, .metadataReady, .previewReady, .waitingForExport,
             .exporting, .savingToPhotoLibrary:
            return phase.displayTitle
        }
    }

    private func applyStatusBadge(
        _ badge: UIImageView,
        phase: BatchTaskPhase
    ) {
        badge.isHidden = false
        badge.tintColor = statusTintColor(for: phase)
        badge.image = UIImage(systemName: statusSystemImageName(for: phase))
        badge.accessibilityLabel = statusAccessibilityLabel(for: phase)
    }

    private func statusSystemImageName(for phase: BatchTaskPhase) -> String {
        switch phase {
        case .queued: return "clock.fill"
        case .importing, .metadataReady, .previewReady, .waitingForExport,
             .exporting, .savingToPhotoLibrary:
            return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }

    private func statusTintColor(for phase: BatchTaskPhase) -> UIColor {
        switch phase {
        case .queued, .cancelled: return .systemGray
        case .importing, .metadataReady, .previewReady, .waitingForExport,
             .exporting, .savingToPhotoLibrary:
            return .systemBlue
        case .completed: return .systemGreen
        case .failed: return .systemRed
        }
    }

    private func statusAccessibilityLabel(for phase: BatchTaskPhase) -> String {
        switch phase {
        case .queued: return "等待处理"
        case .completed: return "处理完成"
        case .failed: return "处理失败"
        case .cancelled: return "已取消"
        case .importing, .metadataReady, .previewReady, .waitingForExport,
             .exporting, .savingToPhotoLibrary:
            return "正在处理"
        }
    }

    @objc
    private func handleCardTap(_ recognizer: UITapGestureRecognizer) {
        guard let card = recognizer.view,
              !cardViews.isEmpty else { return }
        updateSelectedCards(animated: true)
        guard let scrollView else { return }
        let targetRect = card.convert(card.bounds, to: scrollView)
            .insetBy(dx: -18, dy: 0)
        scrollView.scrollRectToVisible(targetRect, animated: true)
    }

    private func updateSelectedCards(animated: Bool) {
        let updates = { [cardViews] in
            for (index, card) in cardViews.enumerated() {
                card.transform = .identity
                card.layer.zPosition = CGFloat(index)
                card.alpha = 1
            }
        }
        guard animated else {
            updates()
            return
        }
        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState],
            animations: updates
        )
    }

    private func rebuildLayout() {
        guard let cardStack else { return }
        cardStack.arrangedSubviews.forEach { view in
            cardStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        cardViews.forEach { card in
            card.removeFromSuperview()
            card.transform = .identity
        }
        cardStack.axis = .vertical
        cardStack.alignment = .fill
        cardStack.spacing = 8
        listHeightConstraint?.constant = Self.listHeight(rowCount: cardViews.count)
        cardViews.forEach(cardStack.addArrangedSubview)
    }

    private static func listHeight(rowCount: Int) -> CGFloat {
        guard rowCount > 0 else { return 0 }
        let visibleRows = min(rowCount, 4)
        return CGFloat(visibleRows) * 54
            + CGFloat(max(visibleRows - 1, 0)) * 8
            + 4
    }

    private func loadPreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {
        if let systemPreview = await loadSystemPreviewImage(from: provider) {
            return systemPreview
        }
        if let filePreview = await loadFilePreviewImage(from: provider) {
            return filePreview
        }
        return await withCheckedContinuation {
            (continuation: CheckedContinuation<UIImage?, Never>) in
            provider.loadItem(
                forTypeIdentifier:
                    preferredPreviewTypeIdentifier(from: provider)
                    ?? UTType.image.identifier,
                options: nil
            ) { item, _ in
                if let url = item as? URL,
                   let image = self.thumbnailImage(from: url) {
                    continuation.resume(returning: image)
                    return
                }
                if let image = item as? UIImage {
                    continuation.resume(returning: image)
                    return
                }
                if let data = item as? Data,
                   let image = self.thumbnailImage(from: data) {
                    continuation.resume(returning: image)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    private func isSupportedPreviewProvider(
        _ provider: NSItemProvider
    ) -> Bool {
        if provider.hasItemConformingToTypeIdentifier(
            UTType.image.identifier
        ) {
            return true
        }
        return PhotoProcessingInputPolicy.supportedImageTypes.contains {
            provider.hasItemConformingToTypeIdentifier($0.identifier)
        }
    }

    private func preferredPreviewTypeIdentifier(
        from provider: NSItemProvider
    ) -> String? {
        provider.registeredTypeIdentifiers
            .compactMap(UTType.init)
            .first { candidate in
                PhotoProcessingInputPolicy.supportedImageTypes.contains {
                    candidate.conforms(to: $0)
                        || candidate.identifier == $0.identifier
                }
                    || candidate.conforms(to: .image)
            }?
            .identifier
    }

    private func loadSystemPreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {
        await withCheckedContinuation {
            (continuation: CheckedContinuation<UIImage?, Never>) in
            provider.loadPreviewImage(
                options: [
                    NSItemProviderPreferredImageSizeKey:
                        CGSize(width: 420, height: 420)
                ]
            ) { item, _ in
                continuation.resume(returning: item as? UIImage)
            }
        }
    }

    private func loadFilePreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {
        guard let typeIdentifier =
            preferredPreviewTypeIdentifier(from: provider)
            ?? PhotoProcessingInputPolicy.supportedImageTypes
                .first(where: {
                    provider.hasItemConformingToTypeIdentifier($0.identifier)
                })?
                .identifier
        else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(
                forTypeIdentifier: typeIdentifier
            ) { url, _ in
                guard let url,
                      let image = self.thumbnailImage(from: url) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }

    nonisolated func thumbnailImage(from url: URL) -> UIImage? {
        MediaDecodeService().thumbnailImage(
            from: url,
            maxPixelDimension: 640
        )
    }

    nonisolated func thumbnailImage(from data: Data) -> UIImage? {
        MediaDecodeService().thumbnailImage(
            from: data,
            maxPixelDimension: 640
        )
    }
}
#endif
