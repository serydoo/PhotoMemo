#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit
import UniformTypeIdentifiers
import ImageIO

final class PhotoMemoShareExtensionViewController:
    UIViewController {

    private enum ViewState {

        case confirming

        case processing

        case failed(
            title: String,
            message: String,
            suggestion: String
        )

        case handoffFailed
    }

    private let intakeService =
        PhotoMemoShareExtensionIntakeService()

    private let snapshotService =
        SharedBatchConfigurationSnapshotService()

    private lazy var workflowSummaryBuilder =
        PhotoMemoShareWorkflowSummaryBuilder {
            [snapshotService] identifier in
            snapshotService.resolvedAlbumTitle(
                for: identifier
            )
        }

    private var pendingHandoffRequestID: UUID?

    private let contentStack =
        UIStackView()

    private let brandLabel =
        UILabel()

    private let titleLabel =
        UILabel()

    private let subtitleLabel =
        UILabel()

    private let sharedCountValueLabel =
        UILabel()

    private let currentStyleValueLabel =
        UILabel()

    private let outputValueLabel =
        UILabel()

    private let previewScrollView =
        UIScrollView()

    private let previewCardStack =
        UIStackView()

    private let previewCaptionLabel =
        UILabel()

    private var previewSectionView:
        UIView?

    private let activityIndicator =
        UIActivityIndicatorView(style: .medium)

    private let statusTitleLabel =
        UILabel()

    private let statusMessageLabel =
        UILabel()

    private let footerLabel =
        UILabel()

    private let primaryButton =
        UIButton(type: .system)

    private var inputItems:
        [NSExtensionItem] = []

    private var sharedPhotoCount = 0

    private var firstPreviewTask:
        Task<Void, Never>?

    private var previewCardViews:
        [UIView] = []

    private var previewImageViews:
        [UIImageView] = []

    private var selectedPreviewIndex = 0

    private var viewState: ViewState = .confirming

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        loadInputItems()
        applyWorkflowSummary()
        applyConfirmingState()
    }
}

private extension PhotoMemoShareExtensionViewController {

    @MainActor
    func configureView() {

        view.backgroundColor =
            .systemBackground

        configureContentStack()
        configureHeaderLabels()
        configureStatusLabels()
        configureFooterLabel()
        configurePrimaryButton()
        configurePreviewViews()

        let previewCard =
            makeCardContainer(
                contentView:
                    makePreviewStack()
            )
        previewSectionView =
            previewCard

        let summaryCard =
            makeCardContainer(
                contentView:
                    makeSummaryStack()
            )

        let statusCard =
            makeCardContainer(
                contentView:
                    makeStatusStack()
            )

        contentStack.addArrangedSubview(
            brandLabel
        )
        contentStack.addArrangedSubview(
            titleLabel
        )
        contentStack.addArrangedSubview(
            subtitleLabel
        )
        contentStack.addArrangedSubview(
            previewCard
        )
        contentStack.addArrangedSubview(
            summaryCard
        )
        contentStack.addArrangedSubview(
            statusCard
        )
        contentStack.addArrangedSubview(
            footerLabel
        )
        contentStack.addArrangedSubview(
            primaryButton
        )

        view.addSubview(
            contentStack
        )

        NSLayoutConstraint.activate([
            contentStack.topAnchor
                .constraint(
                    greaterThanOrEqualTo:
                        view.safeAreaLayoutGuide
                        .topAnchor,
                    constant: 16
                ),
            contentStack.leadingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .leadingAnchor,
                    constant: 20
                ),
            contentStack.trailingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .trailingAnchor,
                    constant: -20
                ),
            contentStack.centerYAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .centerYAnchor
                ),
            contentStack.bottomAnchor
                .constraint(
                    lessThanOrEqualTo:
                        view.safeAreaLayoutGuide
                        .bottomAnchor,
                    constant: -16
                ),
            primaryButton.heightAnchor
                .constraint(
                    equalToConstant: 50
                )
        ])
    }

    func configureContentStack() {

        contentStack.translatesAutoresizingMaskIntoConstraints =
            false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
    }

    func configureHeaderLabels() {

        brandLabel.font =
            .preferredFont(
                forTextStyle: .caption1
            )
        brandLabel.textColor =
            .secondaryLabel
        brandLabel.text =
            "PhotoMemo"

        titleLabel.font =
            .preferredFont(
                forTextStyle: .title2
            )
        titleLabel.adjustsFontForContentSizeCategory =
            true
        titleLabel.numberOfLines = 0

        subtitleLabel.font =
            .preferredFont(
                forTextStyle: .body
            )
        subtitleLabel.textColor =
            .secondaryLabel
        subtitleLabel.numberOfLines = 0
    }

    func configureStatusLabels() {

        activityIndicator.translatesAutoresizingMaskIntoConstraints =
            false
        activityIndicator.hidesWhenStopped =
            true

        statusTitleLabel.font =
            .preferredFont(
                forTextStyle: .headline
            )
        statusTitleLabel.numberOfLines = 0

        statusMessageLabel.font =
            .preferredFont(
                forTextStyle: .subheadline
            )
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.numberOfLines = 0
    }

    func configurePreviewViews() {

        previewScrollView.translatesAutoresizingMaskIntoConstraints =
            false
        previewScrollView.alwaysBounceHorizontal =
            true
        previewScrollView.showsHorizontalScrollIndicator =
            false
        previewScrollView.decelerationRate =
            .fast
        previewScrollView.contentInset =
            UIEdgeInsets(
                top: 0,
                left: 4,
                bottom: 0,
                right: 4
            )

        previewCardStack.translatesAutoresizingMaskIntoConstraints =
            false
        previewCardStack.axis = .horizontal
        previewCardStack.alignment = .center
        previewCardStack.spacing = -14

        previewCaptionLabel.font =
            .preferredFont(
                forTextStyle: .caption1
            )
        previewCaptionLabel.textColor =
            .secondaryLabel
        previewCaptionLabel.numberOfLines = 0
        previewCaptionLabel.text =
            "正在准备这次分享的预览。"
    }

    func configureFooterLabel() {

        footerLabel.font =
            .preferredFont(
                forTextStyle: .footnote
            )
        footerLabel.textColor =
            .secondaryLabel
        footerLabel.numberOfLines = 0
    }

    func configurePrimaryButton() {

        primaryButton.configuration =
            .filled()
        primaryButton.configuration?.cornerStyle =
            .large
        primaryButton.configuration?.baseBackgroundColor =
            .label
        primaryButton.configuration?.baseForegroundColor =
            .systemBackground
        primaryButton.addTarget(
            self,
            action: #selector(handlePrimaryButtonTap),
            for: .touchUpInside
        )
    }

    func makePreviewStack() -> UIStackView {

        let stack =
            UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints =
            false
        stack.axis = .vertical
        stack.spacing = 12

        let headerLabel =
            UILabel()
        headerLabel.font =
            .preferredFont(
                forTextStyle: .headline
            )
        headerLabel.text =
            "这次会处理"

        let imageContainer =
            UIView()
        imageContainer.translatesAutoresizingMaskIntoConstraints =
            false
        imageContainer.addSubview(previewScrollView)
        previewScrollView.addSubview(previewCardStack)

        NSLayoutConstraint.activate([
            previewScrollView.topAnchor.constraint(
                equalTo:
                    imageContainer.topAnchor
            ),
            previewScrollView.leadingAnchor.constraint(
                equalTo:
                    imageContainer.leadingAnchor
            ),
            previewScrollView.trailingAnchor.constraint(
                equalTo:
                    imageContainer.trailingAnchor
            ),
            previewScrollView.bottomAnchor.constraint(
                equalTo:
                    imageContainer.bottomAnchor
            ),
            previewScrollView.heightAnchor.constraint(
                equalToConstant: 168
            ),
            previewCardStack.topAnchor.constraint(
                equalTo:
                    previewScrollView.contentLayoutGuide
                    .topAnchor
            ),
            previewCardStack.leadingAnchor.constraint(
                equalTo:
                    previewScrollView.contentLayoutGuide
                    .leadingAnchor
            ),
            previewCardStack.trailingAnchor.constraint(
                equalTo:
                    previewScrollView.contentLayoutGuide
                    .trailingAnchor
            ),
            previewCardStack.bottomAnchor.constraint(
                equalTo:
                    previewScrollView.contentLayoutGuide
                    .bottomAnchor
            ),
            previewCardStack.heightAnchor.constraint(
                equalTo:
                    previewScrollView.frameLayoutGuide
                    .heightAnchor
            )
        ])

        stack.addArrangedSubview(
            headerLabel
        )
        stack.addArrangedSubview(
            imageContainer
        )
        stack.addArrangedSubview(
            previewCaptionLabel
        )

        return stack
    }

    func makeSummaryStack() -> UIStackView {

        let stack =
            UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints =
            false
        stack.axis = .vertical
        stack.spacing = 12

        let headerLabel =
            UILabel()
        headerLabel.font =
            .preferredFont(
                forTextStyle: .headline
            )
        headerLabel.text =
            "这次会如何处理"

        stack.addArrangedSubview(
            headerLabel
        )
        stack.addArrangedSubview(
            makeSummaryRow(
                title: "照片",
                valueLabel:
                    sharedCountValueLabel
            )
        )
        stack.addArrangedSubview(
            makeSummaryRow(
                title: "默认风格",
                valueLabel:
                    currentStyleValueLabel
            )
        )
        stack.addArrangedSubview(
            makeSummaryRow(
                title: "结果去向",
                valueLabel:
                    outputValueLabel
            )
        )

        return stack
    }

    func makeStatusStack() -> UIStackView {

        let stack =
            UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints =
            false
        stack.axis = .vertical
        stack.spacing = 12

        let headerStack =
            UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 10
        headerStack.addArrangedSubview(
            activityIndicator
        )
        headerStack.addArrangedSubview(
            statusTitleLabel
        )

        stack.addArrangedSubview(
            headerStack
        )
        stack.addArrangedSubview(
            statusMessageLabel
        )

        return stack
    }

    func makeSummaryRow(
        title: String,
        valueLabel: UILabel
    ) -> UIStackView {

        let titleLabel =
            UILabel()
        titleLabel.font =
            .preferredFont(
                forTextStyle: .caption1
            )
        titleLabel.textColor =
            .secondaryLabel
        titleLabel.text =
            title

        valueLabel.font =
            .preferredFont(
                forTextStyle: .body
            )
        valueLabel.numberOfLines = 0

        let stack =
            UIStackView(
                arrangedSubviews: [
                    titleLabel,
                    valueLabel
                ]
            )
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    func makeCardContainer(
        contentView: UIView
    ) -> UIView {

        let container =
            UIView()
        container.translatesAutoresizingMaskIntoConstraints =
            false
        container.backgroundColor =
            .secondarySystemBackground
        container.layer.cornerRadius = 18
        container.layer.cornerCurve = .continuous
        container.addSubview(
            contentView
        )

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(
                equalTo:
                    container.topAnchor,
                constant: 16
            ),
            contentView.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant: 16
            ),
            contentView.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant: -16
            ),
            contentView.bottomAnchor.constraint(
                equalTo:
                    container.bottomAnchor,
                constant: -16
            )
        ])

        return container
    }

    func loadInputItems() {

        inputItems =
            extensionContext?
            .inputItems as? [NSExtensionItem]
            ?? []

        sharedPhotoCount =
            intakeService.supportedPhotoCount(
                in: inputItems
            )

        PhotoMemoShareDiagnostics.record(
            stage: "extension.input",
            message:
                "inputItems=\(inputItems.count), supportedPhotos=\(sharedPhotoCount)"
        )

        sharedCountValueLabel.text =
            sharedPhotoCount > 0
            ? "\(sharedPhotoCount) 张"
            : "未识别到可处理照片"

        previewSectionView?.isHidden =
            sharedPhotoCount <= 1

        if sharedPhotoCount > 1 {
            loadFirstPreviewIfNeeded()
        } else {
            firstPreviewTask?.cancel()
            resetPreviewCards()
        }
    }

    @MainActor
    func applyWorkflowSummary() {

        let snapshot =
            snapshotService.loadSnapshot()
        let summary =
            workflowSummaryBuilder.build(
                from: snapshot
            )

        currentStyleValueLabel.text =
            summary.styleTitle
        outputValueLabel.text =
            summary.outputTitle
    }

    @MainActor
    func applyConfirmingState() {

        viewState = .confirming
        activityIndicator.stopAnimating()
        statusMessageLabel.textColor =
            .secondaryLabel

        titleLabel.text =
            sharedPhotoCount > 0
            ? "确认这次分享"
            : "这次分享里没有可处理照片"

        subtitleLabel.text =
            sharedPhotoCount > 0
            ? "确认后，PhotoMemo 会直接生成新的记忆照片并保存。"
            : "当前内容看起来不像可直接处理的原始照片。"

        if sharedPhotoCount > 0 {
            statusTitleLabel.text =
                "接下来会发生什么"
            statusMessageLabel.text =
                "PhotoMemo 会使用当前默认风格处理这次分享，并按现在的保存位置写回系统相册。"
            footerLabel.text =
                "如果想改默认风格或保存位置，请先回到 PhotoMemo 调整，再重新分享。"
            applyPrimaryButton(
                title:
                    "开始生成"
            )
        } else {
            statusTitleLabel.text =
                "建议这样重试"
            statusMessageLabel.text =
                PhotoMemoShareExtensionError
                .noSupportedImages
                .errorDescription
            footerLabel.text =
                PhotoMemoShareExtensionError
                .noSupportedImages
                .recoverySuggestion
            applyPrimaryButton(
                title:
                    "关闭"
            )
        }
    }

    @MainActor
    func applyProcessingState() {

        viewState = .processing
        activityIndicator.startAnimating()
        titleLabel.text =
            "正在生成"
        subtitleLabel.text =
            "PhotoMemo 正在处理这次分享。"
        statusTitleLabel.text =
            "正在保存到系统相册"
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.text =
            "这一步完成后，后续处理会继续进行。"
        footerLabel.text =
            "请稍等片刻，不需要再次设置。"

        primaryButton.isEnabled =
            false
        primaryButton.configuration?.title =
            "处理中"
    }

    @MainActor
    func applyFailureState(
        title: String,
        message: String,
        suggestion: String
    ) {

        viewState = .failed(
            title: title,
            message: message,
            suggestion: suggestion
        )
        activityIndicator.stopAnimating()
        titleLabel.text =
            "这次分享没有完成"
        subtitleLabel.text =
            "可以直接重试；如果仍失败，再回到 PhotoMemo 或系统相册检查。"
        statusTitleLabel.text =
            title
        statusMessageLabel.textColor =
            .systemRed
        statusMessageLabel.text =
            message
        footerLabel.text =
            suggestion

        applyPrimaryButton(
            title:
                "重新尝试"
        )
    }

    func applyPrimaryButton(
        title: String
    ) {

        primaryButton.isEnabled =
            true
        primaryButton.configuration?.title =
            title
    }

    @objc
    func handlePrimaryButtonTap() {

        PhotoMemoShareIntakeLog.notice(
            "Share confirmation button tapped. state=\(String(describing: viewState)) sharedPhotoCount=\(sharedPhotoCount)"
        )

        switch viewState {

        case .confirming:
            guard sharedPhotoCount > 0 else {
                cancelExtension(
                    message:
                        PhotoMemoShareExtensionError
                        .noSupportedImages
                        .errorDescription
                        ?? "没有可处理的照片。"
                )
                return
            }

            Task { @MainActor in
                await persistIncomingItems()
            }

        case .processing:
            return

        case .failed:
            Task { @MainActor in
                await persistIncomingItems()
            }

        case .handoffFailed:
            Task { @MainActor in
                let opened =
                    await requestMainAppRefresh(
                        requestID:
                            pendingHandoffRequestID
                    )

                if opened {
                    extensionContext?
                        .completeRequest(
                            returningItems: nil
                        )
                } else {
                    applyHandoffFailureState()
                }
            }
        }
    }

    @MainActor
    func persistIncomingItems() async {

        PhotoMemoShareDiagnostics.reset(
            reason: "Share confirmation started"
        )

        guard !inputItems.isEmpty else {
            PhotoMemoShareIntakeLog.error(
                "persistIncomingItems failed before intake: inputItems was empty."
            )
            PhotoMemoShareDiagnostics.record(
                stage: "extension.input.empty",
                message: "No NSExtensionItem was available."
            )
            applyFailureState(
                title:
                    "无法读取这次分享",
                message:
                    "PhotoMemo 没有收到这次分享的原始内容。",
                suggestion:
                    "请返回系统相册重新分享；如果重复出现，请打开 PhotoMemo 检查默认风格后再试。"
            )
            return
        }

        applyProcessingState()

        do {
            let result =
                try await intakeService
                .persistSharedItems(
                    inputItems
                )
            pendingHandoffRequestID =
                result.requestID

            PhotoMemoShareDiagnostics.record(
                stage: "extension.persisted",
                message:
                    "imported=\(result.importedCount), requested=\(result.requestedCount), skipped=\(result.skippedCount), failed=\(result.failedCount)"
            )

            statusTitleLabel.text =
                "已经开始处理"
            statusMessageLabel.textColor =
                .secondaryLabel
            statusMessageLabel.text =
                successMessage(
                    for: result
                )
            footerLabel.text =
                "接下来会回到 PhotoMemo，继续完成生成和保存。"
            primaryButton.isEnabled =
                false
            primaryButton.configuration?.title =
                "即将完成"
            activityIndicator.stopAnimating()

            PhotoMemoShareIntakeLog.notice(
                "Share extension will request main-app handoff before completion."
            )

            let opened =
                await requestMainAppRefresh(
                    requestID:
                        result.requestID
                )

            if !opened {
                PhotoMemoShareIntakeLog.notice(
                    "Share extension persisted intake, but main-app handoff was not confirmed before timeout."
                )
                PhotoMemoShareDiagnostics.record(
                    stage: "extension.handoff.deferred",
                    message:
                        "Intake is safely persisted; host app will process it when it next drains shared requests.",
                    requestID:
                        result.requestID
                )
            } else {
                PhotoMemoShareDiagnostics.record(
                    stage: "extension.handoff.accepted",
                    message: "Main app handoff reported success."
                )
            }

            await playCompletionTransition()

            extensionContext?
                .completeRequest(
                    returningItems: nil
                )
        } catch {
            if let shareError =
                error as? PhotoMemoShareExtensionError {
                PhotoMemoShareIntakeLog.error(
                    "Share extension caught PhotoMemoShareExtensionError.\n\(shareError.diagnosticsDescription ?? "no diagnostics")"
                )
                PhotoMemoShareDiagnostics.record(
                    stage: "extension.error",
                    message:
                        shareError.errorDescription
                        ?? shareError.failureTitle
                )
                applyFailureState(
                    title:
                        shareError.failureTitle,
                    message:
                        detailedFailureMessage(
                            for: shareError
                        ),
                    suggestion:
                        detailedSuggestion(
                            for: shareError
                        )
                )
            } else {
                let nsError =
                    error as NSError
                PhotoMemoShareIntakeLog.error(
                    """
                    Share extension caught unexpected error.
                    localizedDescription: \(nsError.localizedDescription)
                    domain: \(nsError.domain)
                    code: \(nsError.code)
                    underlyingError: \(((nsError.userInfo[NSUnderlyingErrorKey] as? NSError)?.localizedDescription) ?? "nil")
                    """
                )
                PhotoMemoShareDiagnostics.record(
                    stage: "extension.error.unexpected",
                    message:
                        "\(nsError.domain) / \(nsError.code): \(nsError.localizedDescription)"
                )
                applyFailureState(
                    title:
                        "这次分享没有完成",
                    message:
                        (error as? LocalizedError)?
                        .errorDescription
                        ?? "无法把内容交给 PhotoMemo。",
                    suggestion:
                        "请先返回系统相册重新分享；如果仍失败，请打开 PhotoMemo 检查默认风格和系统相册权限。"
                )
            }
        }
    }

    func cancelExtension(
        message: String
    ) {

        let error =
            NSError(
                domain: "PhotoMemoShareExtension",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        message
                ]
            )

        extensionContext?
            .cancelRequest(
                withError: error
            )
    }

    func successMessage(
        for result:
            PhotoMemoShareExtensionImportResult
    ) -> String {

        if result.hasWarnings {
            var summaryParts = [
                "已接收 \(result.importedCount) / \(result.requestedCount) 张"
            ]

            if result.skippedCount > 0 {
                summaryParts.append(
                    "跳过 \(result.skippedCount) 张"
                )
            }

            if result.failedCount > 0 {
                summaryParts.append(
                    "未接收 \(result.failedCount) 张"
                )
            }

            return "\(summaryParts.joined(separator: "，"))。处理完成后会写回系统相册。"
        }

        return "已接收 \(result.requestedCount) 张。处理完成后会写回系统相册。"
    }

    @MainActor
    func applyHandoffFailureState() {

        viewState = .handoffFailed
        contentStack.alpha = 1
        contentStack.transform = .identity
        activityIndicator.stopAnimating()

        titleLabel.text =
            "照片已经接收"
        subtitleLabel.text =
            "但系统这次没有把处理交给 PhotoMemo。"
        statusTitleLabel.text =
            "需要重新交给 PhotoMemo"
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.text =
            "请点下面按钮再试一次；如果仍失败，请直接打开 PhotoMemo MVP，它会继续检查待处理照片。"
        footerLabel.text =
            "这通常和应用唤起或系统分享状态有关，原始照片不会被修改。"

        applyPrimaryButton(
            title:
                "重新交给 PhotoMemo"
        )
    }

    @MainActor
    func playCompletionTransition() async {

        UIImpactFeedbackGenerator(
            style: .soft
        )
        .impactOccurred()

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<Void, Never>
            ) in

            UIView.animate(
                withDuration: 0.46,
                delay: 0.08,
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0.18,
                options: [
                    .curveEaseInOut,
                    .beginFromCurrentState
                ]
            ) {
                self.contentStack.transform =
                    CGAffineTransform(
                        translationX: 0,
                        y: -self.view.bounds.height * 0.36
                    )
                    .scaledBy(
                        x: 0.62,
                        y: 0.62
                    )
                self.contentStack.alpha = 0.08
            } completion: { _ in
                continuation.resume()
            }
        }
    }

    func requestMainAppRefresh(
        requestID: UUID?
    ) async -> Bool {

        let deepLinkURL =
            PhotoMemoDeepLink.share.url

        let opened =
            await withCheckedContinuation {
                (
                    continuation:
                        CheckedContinuation<Bool, Never>
                ) in

                guard
                    let extensionContext
                else {
                    continuation.resume(
                        returning: false
                    )
                    return
                }

                extensionContext.open(
                    deepLinkURL
                ) { success in
                    continuation.resume(
                        returning: success
                    )
                }
            }

        PhotoMemoShareIntakeLog.notice(
            "Requested main-app refresh via deep link. success=\(opened)"
        )

        PhotoMemoShareDiagnostics.record(
            stage: "extension.handoff.primary",
            message: "extensionContext.open success=\(opened)"
        )

        if opened {
            return await waitForMainAppHandoffConfirmation(
                requestID: requestID,
                source: "primary"
            )
        }

        let fallbackOpened =
            requestMainAppRefreshThroughResponderChain(
                deepLinkURL
            )

        PhotoMemoShareIntakeLog.notice(
            "Requested main-app refresh through responder chain. success=\(fallbackOpened)"
        )

        PhotoMemoShareDiagnostics.record(
            stage: "extension.handoff.fallback",
            message: "responderChain success=\(fallbackOpened)"
        )

        guard fallbackOpened else {
            return false
        }

        return await waitForMainAppHandoffConfirmation(
            requestID: requestID,
            source: "fallback"
        )
    }

    @MainActor
    func requestMainAppRefreshThroughResponderChain(
        _ url: URL
    ) -> Bool {

        let selector =
            NSSelectorFromString(
                "openURL:"
            )
        var responder: UIResponder? =
            self

        while let currentResponder =
            responder {
            if currentResponder.responds(
                to: selector
            ) {
                currentResponder.perform(
                    selector,
                    with: url
                )
                return true
            }

            responder =
                currentResponder.next
        }

        return false
    }

    func waitForMainAppHandoffConfirmation(
        requestID: UUID?,
        source: String
    ) async -> Bool {

        guard let requestID else {
            PhotoMemoShareDiagnostics.record(
                stage: "extension.handoff.unconfirmed",
                message:
                    "\(source) opened, but no requestID was available."
            )
            return false
        }

        for _ in 0..<25 {
            if mainAppConsumedRequest(
                requestID
            ) {
                PhotoMemoShareDiagnostics.record(
                    stage: "extension.handoff.confirmed",
                    message:
                        "\(source) confirmed request consumption.",
                    requestID:
                        requestID
                )
                return true
            }

            try? await Task.sleep(
                nanoseconds: 200_000_000
            )
        }

        PhotoMemoShareDiagnostics.record(
            stage: "extension.handoff.unconfirmed",
            message:
                "\(source) did not produce app drain/enqueue within timeout.",
            requestID:
                requestID
        )
        return false
    }

    func mainAppConsumedRequest(
        _ requestID: UUID
    ) -> Bool {

        PhotoMemoShareDiagnostics
            .loadEvents()
            .contains { event in
                guard event.requestID == requestID else {
                    return false
                }

                switch event.stage {

                case "app.request.validated",
                     "app.enqueue.created",
                     "app.enqueue.failed",
                     "app.request.dropped":
                    return true

                default:
                    return false
                }
            }
    }

    func loadFirstPreviewIfNeeded() {

        firstPreviewTask?.cancel()

        let providers =
            supportedPreviewProviders(
                limit: 10
            )

        guard !providers.isEmpty else {
            previewCaptionLabel.text =
                sharedPhotoCount > 0
                ? "这次会按相同风格处理 \(sharedPhotoCount) 张照片。"
                : "未识别到可处理照片。"
            resetPreviewCards()
            return
        }

        configurePreviewPlaceholders(
            count: providers.count
        )

        firstPreviewTask = Task { @MainActor in
            let images =
                await loadPreviewImages(
                    from: providers
                )

            guard !Task.isCancelled else {
                return
            }

            applyPreviewImages(
                images
            )

            if sharedPhotoCount > 1 {
                previewCaptionLabel.text =
                    "左右滑动查看待处理照片，所有照片会使用相同风格处理。"
            } else {
                previewCaptionLabel.text =
                    "将按当前默认风格处理这张照片。"
            }
        }
    }

    func supportedPreviewProviders(
        limit: Int
    ) -> [NSItemProvider] {

        Array(
            inputItems
            .flatMap { item in
                item.attachments ?? []
            }
            .filter {
                isSupportedPreviewProvider($0)
            }
            .prefix(
                max(limit, 1)
            )
        )
    }

    @MainActor
    func resetPreviewCards() {

        previewCardViews.removeAll()
        previewImageViews.removeAll()
        selectedPreviewIndex = 0

        previewCardStack
            .arrangedSubviews
            .forEach { view in
                previewCardStack
                    .removeArrangedSubview(view)
                view.removeFromSuperview()
            }
    }

    @MainActor
    func configurePreviewPlaceholders(
        count: Int
    ) {

        resetPreviewCards()

        for index in 0..<count {
            let card =
                makePreviewCard(
                    index: index
                )
            previewCardStack
                .addArrangedSubview(card.container)
            previewCardViews
                .append(card.container)
            previewImageViews
                .append(card.imageView)
        }

        selectedPreviewIndex = 0
        updateSelectedPreviewCard(
            animated: false
        )
    }

    @MainActor
    func makePreviewCard(
        index: Int
    ) -> (
        container: UIView,
        imageView: UIImageView
    ) {

        let container =
            UIView()
        container.translatesAutoresizingMaskIntoConstraints =
            false
        container.backgroundColor =
            .clear
        container.layer.cornerRadius = 14
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 0
        container.clipsToBounds = false

        let imageView =
            UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints =
            false
        imageView.contentMode =
            .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 11
        imageView.layer.cornerCurve = .continuous
        imageView.backgroundColor =
            .tertiarySystemFill

        container.addSubview(imageView)

        let tap =
            UITapGestureRecognizer(
                target: self,
                action: #selector(
                    handlePreviewCardTap(_:)
                )
            )
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        container.tag = index

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(
                equalToConstant:
                    sharedPhotoCount > 1 ? 116 : 132
            ),
            container.heightAnchor.constraint(
                equalToConstant: 158
            ),
            imageView.topAnchor.constraint(
                equalTo:
                    container.topAnchor
            ),
            imageView.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor
            ),
            imageView.bottomAnchor.constraint(
                equalTo:
                    container.bottomAnchor
            )
        ])

        return (container, imageView)
    }

    @objc
    func handlePreviewCardTap(
        _ recognizer: UITapGestureRecognizer
    ) {

        guard let card =
            recognizer.view else {
            return
        }

        selectedPreviewIndex =
            max(
                min(
                    card.tag,
                    previewCardViews.count - 1
                ),
                0
            )
        updateSelectedPreviewCard(
            animated: true
        )

        let targetRect =
            card.convert(
                card.bounds,
                to: previewScrollView
            )
            .insetBy(
                dx: -18,
                dy: 0
            )

        previewScrollView.scrollRectToVisible(
            targetRect,
            animated: true
        )
    }

    @MainActor
    func updateSelectedPreviewCard(
        animated: Bool
    ) {

        let updates = {
            for (index, card) in
                self.previewCardViews.enumerated() {
                let isSelected =
                    index == self.selectedPreviewIndex
                card.transform =
                    isSelected
                    ? CGAffineTransform(
                        scaleX: 1.06,
                        y: 1.06
                    )
                    : .identity
                card.layer.zPosition =
                    isSelected ? 10 : CGFloat(index)
                card.alpha =
                    isSelected ? 1 : 0.82
            }
        }

        guard animated else {
            updates()
            return
        }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [
                .curveEaseOut,
                .beginFromCurrentState
            ],
            animations: updates
        )
    }

    @MainActor
    func applyPreviewImages(
        _ images: [UIImage?]
    ) {

        for (index, image) in
            images.enumerated() {
            guard previewImageViews
                .indices
                .contains(index) else {
                continue
            }

            previewImageViews[index].image =
                image
        }
    }

    func loadPreviewImages(
        from providers: [NSItemProvider]
    ) async -> [UIImage?] {

        var images: [UIImage?] = []
        images.reserveCapacity(
            providers.count
        )

        for provider in providers {
            if Task.isCancelled {
                break
            }

            images.append(
                await loadPreviewImage(
                    from: provider
                )
            )
        }

        return images
    }

    func loadPreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {

        if let systemPreview =
            await loadSystemPreviewImage(
                from: provider
            ) {
            return systemPreview
        }

        if let filePreview =
            await loadFilePreviewImage(
                from: provider
            ) {
            return filePreview
        }

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<UIImage?, Never>
            ) in

            provider.loadItem(
                forTypeIdentifier:
                    preferredPreviewTypeIdentifier(
                        from: provider
                    )
                    ?? UTType.image.identifier,
                options: nil
            ) { item, _ in

                if let url = item as? URL,
                   let image =
                    self.thumbnailImage(
                        from: url
                    ) {
                    continuation.resume(
                        returning: image
                    )
                    return
                }

                if let image = item as? UIImage {
                    continuation.resume(
                        returning: image
                    )
                    return
                }

                if let data = item as? Data,
                   let image = UIImage(data: data) {
                    continuation.resume(
                        returning: image
                    )
                    return
                }

                continuation.resume(
                    returning: nil
                )
            }
        }
    }

    func isSupportedPreviewProvider(
        _ provider: NSItemProvider
    ) -> Bool {

        if provider.hasItemConformingToTypeIdentifier(
            UTType.image.identifier
        ) {
            return true
        }

        return PhotoProcessingInputPolicy
            .supportedImageTypes
            .contains { type in
                provider
                    .hasItemConformingToTypeIdentifier(
                        type.identifier
                    )
            }
    }

    func preferredPreviewTypeIdentifier(
        from provider: NSItemProvider
    ) -> String? {

        provider
            .registeredTypeIdentifiers
            .compactMap(UTType.init)
            .first { candidate in
                PhotoProcessingInputPolicy
                    .supportedImageTypes
                    .contains { supportedType in
                        candidate.conforms(
                            to: supportedType
                        )
                        || candidate.identifier
                            == supportedType.identifier
                    }
                || candidate.conforms(to: .image)
            }?
            .identifier
    }

    func loadSystemPreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {

        await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<UIImage?, Never>
            ) in

            provider.loadPreviewImage(
                options: [
                    NSItemProviderPreferredImageSizeKey:
                        CGSize(width: 420, height: 420)
                ]
            ) { item, _ in
                continuation.resume(
                    returning:
                        item as? UIImage
                )
            }
        }
    }

    func loadFilePreviewImage(
        from provider: NSItemProvider
    ) async -> UIImage? {

        guard let typeIdentifier =
            preferredPreviewTypeIdentifier(
                from: provider
            )
            ?? PhotoProcessingInputPolicy
            .supportedImageTypes
            .first(where: {
                provider
                    .hasItemConformingToTypeIdentifier(
                        $0.identifier
                    )
            })?
            .identifier
        else {
            return nil
        }

        return await withCheckedContinuation {
            continuation in

            provider.loadFileRepresentation(
                forTypeIdentifier:
                    typeIdentifier
            ) { url, _ in
                guard let url,
                      let image =
                        self.thumbnailImage(
                            from: url
                        ) else {
                    continuation.resume(
                        returning: nil
                    )
                    return
                }

                continuation.resume(
                    returning: image
                )
            }
        }
    }

    nonisolated
    func thumbnailImage(
        from url: URL
    ) -> UIImage? {

        guard let source =
            CGImageSourceCreateWithURL(
                url as CFURL,
                [
                    kCGImageSourceShouldCache:
                        false
                ] as CFDictionary
            ) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent:
                true,
            kCGImageSourceCreateThumbnailWithTransform:
                true,
            kCGImageSourceShouldCacheImmediately:
                true,
            kCGImageSourceThumbnailMaxPixelSize:
                640
        ]

        guard let cgImage =
            CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                options as CFDictionary
            ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func detailedFailureMessage(
        for error:
            PhotoMemoShareExtensionError
    ) -> String {

        if let diagnosticSummary =
            error.diagnosticSummaryLine {
            return "\(error.errorDescription ?? "这次分享没有完成。")\n\n\(diagnosticSummary)"
        }

        return error.errorDescription
            ?? "这次分享没有完成。"
    }

    func detailedSuggestion(
        for error:
            PhotoMemoShareExtensionError
    ) -> String {

        if let failureContext =
            error.resolvedFailureContext,
           let errorSummary =
            failureContext.errorSummary {
            return "\(error.recoverySuggestion)\n\nNSError: \(errorSummary.domain) / \(errorSummary.code)"
        }

        return error.recoverySuggestion
    }
}
#endif
