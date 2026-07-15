#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit

final class PhotoMemoShareExtensionViewController:
    UIViewController {

    private let intakeService =
        PhotoMemoShareExtensionIntakeService()

    private let snapshotService =
        SharedBatchConfigurationSnapshotService()

    private let batchSnapshotService =
        SharedBatchQueueSnapshotService()

    private let previewController =
        ShareExtensionPreviewController()

    private let viewStateRenderer =
        ShareExtensionViewStateRenderer()

    private lazy var handoffCoordinator =
        ShareExtensionHandoffCoordinator(
            extensionContext: { [weak self] in
                self?.extensionContext
            },
            firstResponder: { [weak self] in
                self
            }
        )

    private lazy var progressObserver =
        ShareExtensionProgressObserver(
            batchSnapshotService: batchSnapshotService,
            enqueuedJobID: { [weak self] requestID in
                self?.handoffCoordinator.enqueuedJobID(
                    for: requestID
                )
            }
        )

    private lazy var workflowSummaryBuilder =
        PhotoMemoShareWorkflowSummaryBuilder {
            [snapshotService] identifier in
            snapshotService.resolvedAlbumTitle(
                for: identifier
            )
        }

    private var pendingHandoffRequestID: UUID?

    private let scrollView =
        UIScrollView()

    private let contentStack =
        UIStackView()

    private let bottomActionStack =
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

    private var summarySectionView:
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

    private var configurationReadiness =
        V1SavedConfigurationReadiness(
            isReady: false,
            presetTitle: nil
        )

    private var firstPreviewTask:
        Task<Void, Never>?

    private var pendingHandoffPhotoCount = 0

    private var viewState: ShareExtensionViewState = .confirming

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize =
            CGSize(
                width: 0,
                height: 680
            )
        configureView()
        loadInputItems()
        applyWorkflowSummary()
        applyConfirmingState()
    }

    override func viewDidDisappear(_ animated: Bool) {
        firstPreviewTask?.cancel()
        progressObserver.stopIntakeDiagnosticMonitoring()
        super.viewDidDisappear(animated)
    }
}

private extension PhotoMemoShareExtensionViewController {

    @MainActor
    func configureView() {

        view.backgroundColor =
            .systemBackground

        configureScrollView()
        configureContentStack()
        configureBottomActionStack()
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
        summarySectionView =
            summaryCard

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

        view.addSubview(
            scrollView
        )
        scrollView.addSubview(
            contentStack
        )
        view.addSubview(
            bottomActionStack
        )

        NSLayoutConstraint.activate([
            scrollView.topAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .topAnchor,
                    constant: 52
                ),
            scrollView.leadingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .leadingAnchor,
                    constant: 20
                ),
            scrollView.trailingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .trailingAnchor,
                    constant: -20
                ),
            scrollView.bottomAnchor
                .constraint(
                    equalTo:
                        bottomActionStack
                        .topAnchor,
                    constant: -18
                ),
            contentStack.topAnchor.constraint(
                equalTo:
                    scrollView.contentLayoutGuide
                    .topAnchor
            ),
            contentStack.leadingAnchor.constraint(
                equalTo:
                    scrollView.contentLayoutGuide
                    .leadingAnchor
            ),
            contentStack.trailingAnchor.constraint(
                equalTo:
                    scrollView.contentLayoutGuide
                    .trailingAnchor
            ),
            contentStack.bottomAnchor.constraint(
                equalTo:
                    scrollView.contentLayoutGuide
                    .bottomAnchor
            ),
            contentStack.widthAnchor.constraint(
                equalTo:
                    scrollView.frameLayoutGuide
                    .widthAnchor
            ),
            bottomActionStack.leadingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .leadingAnchor,
                    constant: 20
                ),
            bottomActionStack.trailingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .trailingAnchor,
                    constant: -20
                ),
            bottomActionStack.bottomAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .bottomAnchor,
                    constant: -24
                ),
            primaryButton.heightAnchor
                .constraint(
                    equalToConstant: 52
                )
        ])
    }

    func configureScrollView() {

        scrollView.translatesAutoresizingMaskIntoConstraints =
            false
        scrollView.alwaysBounceVertical =
            false
        scrollView.showsVerticalScrollIndicator =
            false
        scrollView.keyboardDismissMode =
            .interactive
    }

    func configureContentStack() {

        contentStack.translatesAutoresizingMaskIntoConstraints =
            false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
    }

    func configureBottomActionStack() {

        bottomActionStack.translatesAutoresizingMaskIntoConstraints =
            false
        bottomActionStack.axis =
            .vertical
        bottomActionStack.spacing =
            12
        bottomActionStack.alignment =
            .fill
        bottomActionStack.addArrangedSubview(
            footerLabel
        )
        bottomActionStack.addArrangedSubview(
            primaryButton
        )
    }

    func configureHeaderLabels() {

        brandLabel.font =
            .preferredFont(
                forTextStyle: .caption1
            )
        brandLabel.textColor =
            .secondaryLabel
        brandLabel.text =
            "时光记"
        brandLabel.adjustsFontForContentSizeCategory = true
        brandLabel.accessibilityTraits = .header

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
        subtitleLabel.adjustsFontForContentSizeCategory = true
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
        statusTitleLabel.adjustsFontForContentSizeCategory = true
        statusTitleLabel.accessibilityTraits = .header

        statusMessageLabel.font =
            .preferredFont(
                forTextStyle: .subheadline
            )
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.numberOfLines = 0
        statusMessageLabel.adjustsFontForContentSizeCategory = true
    }

    func configurePreviewViews() {

        previewScrollView.translatesAutoresizingMaskIntoConstraints =
            false
        previewScrollView.alwaysBounceHorizontal =
            false
        previewScrollView.alwaysBounceVertical =
            true
        previewScrollView.showsHorizontalScrollIndicator =
            false
        previewScrollView.showsVerticalScrollIndicator =
            false
        previewScrollView.decelerationRate =
            .fast
        previewScrollView.contentInset =
            UIEdgeInsets(
                top: 2,
                left: 0,
                bottom: 2,
                right: 0
            )

        previewCardStack.translatesAutoresizingMaskIntoConstraints =
            false
        previewCardStack.axis = .vertical
        previewCardStack.alignment = .fill
        previewCardStack.spacing = 8

        previewCaptionLabel.font =
            .preferredFont(
                forTextStyle: .caption1
            )
        previewCaptionLabel.textColor =
            .secondaryLabel
        previewCaptionLabel.numberOfLines = 0
        previewCaptionLabel.adjustsFontForContentSizeCategory = true
        previewCaptionLabel.text =
            "灰色等待，蓝色处理中，绿色完成，红色需要处理。"
    }

    func configureFooterLabel() {

        footerLabel.font =
            .preferredFont(
                forTextStyle: .footnote
            )
        footerLabel.textColor =
            .secondaryLabel
        footerLabel.numberOfLines = 0
        footerLabel.adjustsFontForContentSizeCategory = true
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
        primaryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        primaryButton.accessibilityTraits.insert(.button)
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
            "处理队列"

        let imageContainer =
            UIView()
        imageContainer.translatesAutoresizingMaskIntoConstraints =
            false
        imageContainer.addSubview(previewScrollView)
        previewScrollView.addSubview(previewCardStack)

        let previewHeight =
            previewScrollView.heightAnchor.constraint(
                equalToConstant: 62
            )
        previewController.attach(
            scrollView: previewScrollView,
            cardStack: previewCardStack,
            captionLabel: previewCaptionLabel,
            listHeightConstraint: previewHeight
        )

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
            previewHeight,
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
            previewCardStack.widthAnchor.constraint(
                equalTo:
                    previewScrollView.frameLayoutGuide
                    .widthAnchor
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
            stage: .extensionInput,
            message:
                "inputItems=\(inputItems.count), supportedPhotos=\(sharedPhotoCount)"
        )

        sharedCountValueLabel.text =
            sharedPhotoCount > 0
            ? "\(sharedPhotoCount) 张可处理照片"
            : "未识别到可处理照片"

        previewSectionView?.isHidden = true
        firstPreviewTask?.cancel()
        previewController.resetCards()
    }

    @MainActor
    func applyWorkflowSummary() {

        configurationReadiness =
            snapshotService
            .loadV1ConfigurationReadiness()

        let snapshot =
            snapshotService.loadSnapshot()
        let summary =
            workflowSummaryBuilder.build(
                from: snapshot
            )

        if configurationReadiness.isReady {
            currentStyleValueLabel.text =
                configurationReadiness
                .presetTitle
                ?? summary.styleTitle
            outputValueLabel.text =
                summary.outputTitle
        } else {
            currentStyleValueLabel.text =
                "需要先保存配置"
            outputValueLabel.text =
                "打开时光记，在配置中心保存后再回来分享"
        }
    }

    @MainActor
    func applyConfirmingState() {
        applyViewState(.confirming, photoCount: sharedPhotoCount)
    }

    @MainActor
    func applyProcessingState() {
        applyViewState(.processing, photoCount: sharedPhotoCount)
    }

    @MainActor
    func startIntakeDiagnosticMonitor() {
        progressObserver.startIntakeDiagnosticMonitoring {
            [weak self] update in
            self?.applyIntakeDiagnosticUpdate(update)
        }
    }

    @MainActor
    func stopIntakeDiagnosticMonitor() {
        progressObserver.stopIntakeDiagnosticMonitoring()
    }

    @MainActor
    func applyIntakeDiagnosticUpdate(
        _ update: ShareExtensionIntakeDiagnosticUpdate
    ) {
        guard case .processing = viewState else {
            return
        }
        switch update {
        case .preparingSource:
            titleLabel.text =
                "正在准备原图"
            subtitleLabel.text =
                "系统正在把 iCloud 原图准备到本地。"
            statusTitleLabel.text =
                "正在读取 iCloud 原图"
            statusMessageLabel.text =
                "原图可读取后会继续交给时光记处理。"
            primaryButton.configuration?.title =
                "正在准备"
        case .sourceReady:
            titleLabel.text =
            "原图已可读取"
            subtitleLabel.text =
            "正在安全交给时光记。"
            statusTitleLabel.text =
            "正在继续交给时光记"
            statusMessageLabel.text =
            "照片已经可处理，正在继续交给主程序。"
            primaryButton.configuration?.title =
            "正在交给时光记"
        }
    }

    @MainActor
    func applyFailureState(
        title: String,
        message: String,
        suggestion: String
    ) {
        applyViewState(
            .failed(
                title: title,
                message: message,
                suggestion: suggestion
            ),
            photoCount: sharedPhotoCount
        )
    }

    @MainActor
    func applyViewState(
        _ state: ShareExtensionViewState,
        photoCount: Int
    ) {
        let update = viewStateRenderer.update(
            for: .init(
                state: state,
                photoCount: photoCount,
                configurationIsReady: configurationReadiness.isReady
            )
        )
        viewState = update.state
        viewStateRenderer.apply(
            update,
            to: .init(
                contentStack: contentStack,
                activityIndicator: activityIndicator,
                previewSectionView: previewSectionView,
                summarySectionView: summarySectionView,
                titleLabel: titleLabel,
                subtitleLabel: subtitleLabel,
                statusTitleLabel: statusTitleLabel,
                statusMessageLabel: statusMessageLabel,
                footerLabel: footerLabel,
                primaryButton: primaryButton
            )
        )
    }

    func applyPrimaryButton(
        title: String
    ) {

        primaryButton.isEnabled =
            true
        primaryButton.configuration?.title =
            title
        primaryButton.accessibilityLabel = title
    }

    @objc
    func handlePrimaryButtonTap() {

        PhotoMemoShareIntakeLog.notice(
            "Share confirmation button tapped. state=\(String(describing: viewState)) sharedPhotoCount=\(sharedPhotoCount)"
        )

        switch viewState {

        case .confirming:
            guard configurationReadiness.isReady else {
                Task { @MainActor in
                    let opened = await handoffCoordinator
                        .requestMainAppRefresh(
                            .init(requestID: nil)
                        )
                        .opened

                    if opened {
                        extensionContext?
                            .completeRequest(
                                returningItems: nil
                            )
                    } else {
                        cancelExtension(
                            message:
                                "请先打开时光记保存当前配置，再重新分享照片。"
                        )
                    }
                }
                return
            }

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

            guard sharedPhotoCount <=
                    PhotoMemoShareExtensionIntakeService
                    .maxSupportedPhotoCount
            else {
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionInputTooManyPhotos,
                    message:
                        "supportedPhotos=\(sharedPhotoCount), max=\(PhotoMemoShareExtensionIntakeService.maxSupportedPhotoCount)"
                )
                cancelExtension(
                    message:
                        "一次最多处理 \(PhotoMemoShareExtensionIntakeService.maxSupportedPhotoCount) 张照片。请回到 Apple Photos 分批分享。"
                )
                return
            }

            Task { @MainActor in
                await persistIncomingItems()
            }

        case .processing:
            return

        case .received:
            extensionContext?
                .completeRequest(
                    returningItems: nil
                )

        case .failed:
            Task { @MainActor in
                await persistIncomingItems()
            }

        case .handoffFailed:
            Task { @MainActor in
                let opened = await handoffCoordinator
                    .requestMainAppRefresh(
                        .init(
                            requestID:
                                pendingHandoffRequestID
                        )
                    )
                    .opened

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
                stage: .extensionInputEmpty,
                message: "No NSExtensionItem was available."
            )
            applyFailureState(
                title:
                    "无法读取这次分享",
                message:
                    "时光记没有收到这次分享的原始内容。",
                suggestion:
                    "请返回系统相册重新分享；如果重复出现，请打开时光记检查默认风格后再试。"
            )
            return
        }

        applyProcessingState()
        startIntakeDiagnosticMonitor()
        defer {
            stopIntakeDiagnosticMonitor()
        }

        do {
            let result =
                try await intakeService
                .persistSharedItems(
                    inputItems
                )
            pendingHandoffRequestID =
                result.requestID
            pendingHandoffPhotoCount =
                result.importedCount

            PhotoMemoShareDiagnostics.record(
                stage: .extensionPersisted,
                message:
                    "imported=\(result.importedCount), requested=\(result.requestedCount), skipped=\(result.skippedCount), failed=\(result.failedCount), livePhotoStaticFallback=\(result.livePhotoStaticFallbackCount)"
            )

            statusTitleLabel.text =
                "正在打开时光记"
            statusMessageLabel.textColor =
                .secondaryLabel
            statusMessageLabel.text =
                viewStateRenderer.successMessage(
                    for: result
                )
            footerLabel.text =
                "处理进度会在时光记主程序中显示。"

            PhotoMemoShareDiagnostics.record(
                stage: .extensionHandoffRequested,
                message:
                    "Intake is safely persisted; requesting host app handoff.",
                requestID:
                    result.requestID
            )

            let opened = await handoffCoordinator
                .requestMainAppRefresh(
                    .init(requestID: result.requestID)
                )
                .opened

            if opened {
                applyViewState(
                    .received,
                    photoCount: pendingHandoffPhotoCount
                )
            } else {
                applyHandoffFailureState()
            }
        } catch {
            if let shareError =
                error as? PhotoMemoShareExtensionError {
                PhotoMemoShareIntakeLog.error(
                    "Share extension caught PhotoMemoShareExtensionError.\n\(shareError.diagnosticsDescription ?? "no diagnostics")"
                )
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionError,
                    message:
                        shareError.errorDescription
                        ?? shareError.failureTitle
                )
                applyFailureState(
                    title:
                        shareError.failureTitle,
                    message:
                        viewStateRenderer.detailedFailureMessage(
                            for: shareError
                        ),
                    suggestion:
                        viewStateRenderer.detailedSuggestion(
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
                    stage: .extensionErrorUnexpected,
                    message:
                        "\(nsError.domain) / \(nsError.code): \(nsError.localizedDescription)"
                )
                applyFailureState(
                    title:
                        "这次分享没有完成",
                    message:
                        (error as? LocalizedError)?
                        .errorDescription
                        ?? "无法把内容交给时光记。",
                    suggestion:
                        "请先返回系统相册重新分享；如果仍失败，请打开时光记检查默认风格和系统相册权限。"
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

    @MainActor
    func applyHandoffFailureState() {
        applyViewState(
            .handoffFailed,
            photoCount: pendingHandoffPhotoCount
        )
    }

    @MainActor
    func holdCompletionStateBeforeDismissal() async {

        UIImpactFeedbackGenerator(
            style: .soft
        )
        .impactOccurred()

        contentStack.transform = .identity
        contentStack.alpha = 1

        try? await Task.sleep(
            nanoseconds: 1_150_000_000
        )
    }

    @MainActor
    func applyWaitingForQueueState(
        fallbackPhotoCount: Int
    ) {

        activityIndicator.startAnimating()
        statusTitleLabel.text =
            "正在加入处理队列"
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.text =
            "已接收 \(fallbackPhotoCount) 张照片，正在等待时光记开始逐张处理。"
        previewController.setCaption(
            ShareExtensionPreviewController.processingLegendText
        )
        previewController.updateRows(
            phases:
                Array(
                    repeating: .queued,
                    count:
                        previewController.cardCount
                )
        )
    }

    @MainActor
    func applyWaitingForAppState(
        fallbackPhotoCount: Int
    ) {

        viewState = .handoffFailed
        activityIndicator.stopAnimating()
        titleLabel.text =
            "照片已经接收"
        subtitleLabel.text =
            "需要时光记主程序接手后才会开始处理。"
        statusTitleLabel.text =
            "等待时光记开始处理"
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.text =
            "iOS 不会因为 Share Extension 写入待处理请求就自动运行主程序。打开时光记后，队列会立即继续。"
        footerLabel.text =
            "原始照片已经安全暂存；点下面按钮打开时光记继续。"
        previewCaptionLabel.text =
            "队列已建立，等待时光记主程序接手。"
        previewController.updateRows(
            phases:
                Array(
                    repeating: .queued,
                    count:
                        max(
                            previewController.cardCount,
                            fallbackPhotoCount
                        )
                )
        )
        applyPrimaryButton(
            title:
                "打开时光记继续处理"
        )
    }

    @MainActor
    func applyProcessingSnapshot(
        _ snapshot: SharedBatchJobSnapshot
    ) {

        statusMessageLabel.textColor =
            .secondaryLabel
        previewController.setCaption(
            ShareExtensionPreviewController.processingLegendText
        )
        previewController.updateRows(
            tasks:
                snapshot.tasks
        )

        if snapshot.isTerminal {
            activityIndicator.stopAnimating()

            if snapshot.failedCount > 0 {
                statusTitleLabel.text =
                    "已完成 \(snapshot.completedCount) 张，\(snapshot.failedCount) 张需要处理"
                statusMessageLabel.text =
                    "失败项会保留记录，可回到时光记查看原因并重试。"
            } else {
                statusTitleLabel.text =
                    "已完成 \(snapshot.completedCount) 张照片"
                statusMessageLabel.text =
                    "结果已写入系统图库。"
            }
            return
        }

        activityIndicator.startAnimating()
        statusTitleLabel.text =
            "正在处理第 \(activeTaskNumber(in: snapshot)) / \(snapshot.totalCount) 张"
        statusMessageLabel.text =
            currentProgressMessage(
                for: snapshot
            )
    }

    func activeTaskNumber(
        in snapshot: SharedBatchJobSnapshot
    ) -> Int {

        guard let index =
            snapshot.firstActiveTaskIndex else {
            return snapshot.totalCount
        }

        return index + 1
    }

    func currentProgressMessage(
        for snapshot: SharedBatchJobSnapshot
    ) -> String {

        guard let index =
            snapshot.firstActiveTaskIndex,
              snapshot.tasks.indices
            .contains(index) else {
            return "时光记会继续处理，完成后发送系统通知。"
        }

        let task =
            snapshot.tasks[index]

        if !task.statusMessage
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            return task.statusMessage
        }

        return task.phase.displayTitle
    }

    func loadFirstPreviewIfNeeded() {

        firstPreviewTask?.cancel()

        let providers = previewController.supportedProviders(
            for: .init(
                inputItems: inputItems,
                limit: 10
            )
        )

        guard !providers.isEmpty else {
            previewCaptionLabel.text =
                sharedPhotoCount > 0
                ? "这次会按相同风格处理 \(sharedPhotoCount) 张照片。"
                : "未识别到可处理照片。"
            previewController.resetCards()
            return
        }

        previewController.configurePlaceholders(count: providers.count)

        firstPreviewTask = Task { @MainActor in
            let images = await previewController.loadImages(
                from: providers
            )

            guard !Task.isCancelled else {
                return
            }

            previewController.applyImages(images)

            guard shouldShowProcessingLegend else {
                if sharedPhotoCount > 1 {
                    previewCaptionLabel.text =
                        "左右滑动查看待处理照片，所有照片会使用相同风格处理。"
                } else {
                    previewCaptionLabel.text =
                        "将按当前默认风格处理这张照片。"
                }
                return
            }

            previewController.setCaption(
                ShareExtensionPreviewController.processingLegendText
            )
        }
    }

    var shouldShowProcessingLegend: Bool {

        switch viewState {

        case .processing,
             .received:
            return true

        case .confirming,
             .failed,
             .handoffFailed:
            return false
        }
    }

}
#endif
