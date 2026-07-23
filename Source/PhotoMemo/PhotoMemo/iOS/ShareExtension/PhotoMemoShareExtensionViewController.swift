#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit

final class PhotoMemoShareExtensionViewController:
    UIViewController {

    private let intakeService =
        PhotoMemoShareExtensionIntakeService()

    private let snapshotService =
        SharedBatchConfigurationSnapshotService()

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
        ShareExtensionProgressObserver()

    private lazy var intakeCoordinator =
        ShareExtensionIntakeCoordinator(
            intakeService: intakeService,
            handoffCoordinator: handoffCoordinator
        )

    private lazy var workflowSummaryBuilder =
        PhotoMemoShareWorkflowSummaryBuilder {
            [snapshotService] identifier in
            snapshotService.resolvedAlbumTitle(
                for: identifier
            )
        }

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

    private var completionTask:
        Task<Void, Never>?

    private var pendingHandoffPhotoCount = 0

    private var viewState: ShareExtensionViewState = .confirming

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize =
            CGSize(
                width: 0,
                height: 440
            )
        configureView()
        loadInputItems()
        applyWorkflowSummary()
        applyConfirmingState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        preferredContentSize =
            CGSize(
                width: 0,
                height: 440
            )
    }

    override func viewDidDisappear(_ animated: Bool) {
        firstPreviewTask?.cancel()
        completionTask?.cancel()
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

        let statusStack =
            makeStatusStack()
        let statusCard =
            makeCardContainer(
                contentView: statusStack
            )

        let quoteStack =
            makeQuoteStack()

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
        contentStack.addArrangedSubview(statusCard)
        contentStack.addArrangedSubview(quoteStack)

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
                    constant: 36
                ),
            scrollView.leadingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .leadingAnchor,
                    constant: 16
                ),
            scrollView.trailingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .trailingAnchor,
                    constant: -16
                ),
            scrollView.bottomAnchor
                .constraint(
                    equalTo:
                        bottomActionStack
                        .topAnchor,
                    constant: -12
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
                    constant: 16
                ),
            bottomActionStack.trailingAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .trailingAnchor,
                    constant: -16
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
        contentStack.spacing = 12
        contentStack.alignment = .fill
    }

    func configureBottomActionStack() {

        bottomActionStack.translatesAutoresizingMaskIntoConstraints =
            false
        bottomActionStack.axis =
            .vertical
        bottomActionStack.spacing =
            8
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
            MemoMarkDesignTokens.Typography.brand.uiFont()
        brandLabel.textColor =
            .tertiaryLabel
        brandLabel.text =
            "时光记"
        brandLabel.textAlignment = .center
        brandLabel.adjustsFontForContentSizeCategory = true
        brandLabel.accessibilityTraits = .header

        titleLabel.font =
            MemoMarkDesignTokens.Typography.hero.uiFont()
        titleLabel.adjustsFontForContentSizeCategory =
            true
        titleLabel.numberOfLines = 0

        subtitleLabel.font =
            MemoMarkDesignTokens.Typography.heroSubtitle.uiFont()
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
            MemoMarkDesignTokens.Typography.moduleTitle.uiFont()
        statusTitleLabel.numberOfLines = 0
        statusTitleLabel.adjustsFontForContentSizeCategory = true
        statusTitleLabel.accessibilityTraits = .header

        statusMessageLabel.font =
            MemoMarkDesignTokens.Typography.detail.uiFont()
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
            MemoMarkDesignTokens.Typography.caption.uiFont()
        previewCaptionLabel.textColor =
            .secondaryLabel
        previewCaptionLabel.numberOfLines = 0
        previewCaptionLabel.adjustsFontForContentSizeCategory = true
        previewCaptionLabel.text =
            "灰色等待，蓝色处理中，绿色完成，红色需要处理。"
    }

    func configureFooterLabel() {

        footerLabel.font =
            MemoMarkDesignTokens.Typography.secondary.uiFont()
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
            .systemBlue
        primaryButton.configuration?.baseForegroundColor =
            .white
        primaryButton.configuration?.cornerStyle =
            .fixed
        primaryButton.layer.cornerRadius =
            MemoMarkDesignTokens.Layout.cardCornerRadius
        primaryButton.layer.cornerCurve =
            .continuous
        primaryButton.configuration?.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font =
                    MemoMarkDesignTokens
                    .Typography
                    .button
                    .uiFont()
                return outgoing
            }
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
        stack.spacing = 16

        let headerLabel =
            UILabel()
        headerLabel.font =
            MemoMarkDesignTokens.Typography.sectionTitle.uiFont()
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
            "本次分享"

        stack.addArrangedSubview(
            headerLabel
        )
        stack.addArrangedSubview(
            makeSummaryRow(
                title: "照片",
                valueLabel: sharedCountValueLabel,
                addsDivider: true
            )
        )
        stack.addArrangedSubview(
            makeSummaryRow(
                title: "配置",
                valueLabel: currentStyleValueLabel,
                addsDivider: true
            )
        )
        stack.addArrangedSubview(
            makeSummaryRow(
                title: "相册",
                valueLabel: outputValueLabel,
                addsDivider: false
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
        stack.spacing = 6

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

    func makeQuoteStack() -> UIStackView {

        let stack =
            UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints =
            false
        stack.axis = .vertical
        stack.alignment = .fill

        let quoteLabel =
            UILabel()
        quoteLabel.font =
            MemoMarkDesignTokens.Typography.brand.uiFont()
        quoteLabel.textColor =
            .secondaryLabel
        quoteLabel.textAlignment = .left
        quoteLabel.numberOfLines = 0
        quoteLabel.adjustsFontForContentSizeCategory = true
        let quoteParagraphStyle =
            NSMutableParagraphStyle()
        quoteParagraphStyle.lineSpacing =
            MemoMarkDesignTokens.Layout.brandLineSpacing
        quoteLabel.attributedText =
            NSAttributedString(
                string: "今天的照片，\n也是未来的回忆。",
                attributes: [
                    .font:
                        MemoMarkDesignTokens
                        .Typography
                        .brand
                        .uiFont(),
                    .foregroundColor: UIColor.secondaryLabel,
                    .paragraphStyle: quoteParagraphStyle
                ]
            )

        stack.addArrangedSubview(
            quoteLabel
        )

        return stack
    }

    func makeSummaryRow(
        title: String,
        valueLabel: UILabel,
        addsDivider: Bool
    ) -> UIStackView {

        let titleLabel =
            UILabel()
        titleLabel.font =
            MemoMarkDesignTokens.Typography.caption.uiFont()
        titleLabel.textColor =
            .secondaryLabel
        titleLabel.text =
            title

        valueLabel.font =
            MemoMarkDesignTokens.Typography.value.uiFont()
        valueLabel.numberOfLines = 0

        let stack =
            UIStackView(
                arrangedSubviews: [
                    titleLabel,
                    valueLabel
                ]
            )
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        valueLabel.textAlignment = .left

        if addsDivider {
            let divider = UIView()
            divider.translatesAutoresizingMaskIntoConstraints = false
            divider.backgroundColor = .separator
            stack.addArrangedSubview(divider)
            divider.leadingAnchor.constraint(
                equalTo: stack.leadingAnchor,
                constant: MemoMarkDesignTokens.Layout.dividerInset
            ).isActive = true
            divider.trailingAnchor.constraint(
                equalTo: stack.trailingAnchor,
                constant: -MemoMarkDesignTokens.Layout.dividerInset
            ).isActive = true
            divider.heightAnchor.constraint(
                equalToConstant: 1 / UIScreen.main.scale
            ).isActive = true
        }

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
        container.layer.cornerRadius =
            MemoMarkDesignTokens.Layout.cardCornerRadius
        container.layer.cornerCurve = .continuous
        container.addSubview(
            contentView
        )

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(
                equalTo:
                    container.topAnchor,
                constant:
                    MemoMarkDesignTokens.Layout.cardPadding
            ),
            contentView.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant:
                    MemoMarkDesignTokens.Layout.cardPadding
            ),
            contentView.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant:
                    -MemoMarkDesignTokens.Layout.cardPadding
            ),
            contentView.bottomAnchor.constraint(
                equalTo:
                    container.bottomAnchor,
                constant:
                    -MemoMarkDesignTokens.Layout.cardPadding
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
            ? "\(sharedPhotoCount) 张"
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
            let configurationTitle =
                configurationReadiness
                .presetTitle
                ?? summary.styleTitle
            currentStyleValueLabel.text =
                summary.memorySubjectTitle
                ?? configurationTitle
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
        viewStateRenderer.apply(
            update,
            to: viewStateBindings
        )
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
            to: viewStateBindings
        )
    }

    var viewStateBindings: ShareExtensionViewStateBindings {
        .init(
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
                        .requestMainAppRefresh()
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
                    .requestMainAppRefresh()
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
        defer {
            stopIntakeDiagnosticMonitor()
        }

        let result = await intakeCoordinator.persistIncomingItems(
            inputItems,
            onIntakeStarted: { [weak self] in
                self?.applyProcessingState()
                self?.startIntakeDiagnosticMonitor()
            },
            onPersisted: { [weak self] result in
                guard let self else {
                    return
                }

                pendingHandoffPhotoCount =
                    result.importedCount

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
            }
        )

        switch result {
        case .received(let importResult):
            pendingHandoffPhotoCount =
                importResult.importedCount
            applyViewState(
                .received,
                photoCount: importResult.importedCount
            )
            scheduleSuccessfulDismissal()
        case .handoffFailed(let importResult):
            pendingHandoffPhotoCount =
                importResult.importedCount
            applyHandoffFailureState()
        case .failed(let failure):
            applyFailureState(
                title: failure.title,
                message: failure.message,
                suggestion: failure.suggestion
            )
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
    func scheduleSuccessfulDismissal() {

        completionTask?.cancel()
        completionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(
                nanoseconds: 700_000_000
            )
            guard !Task.isCancelled,
                  let self else {
                return
            }
            self.extensionContext?
                .completeRequest(
                    returningItems: nil
                )
        }
    }

    func loadFirstPreviewIfNeeded() {

        firstPreviewTask?.cancel()
        firstPreviewTask = Task { @MainActor in
            await previewController.loadPreviews(
                for: .init(
                    inputItems: inputItems,
                    limit: 10
                ),
                sharedPhotoCount: sharedPhotoCount,
                showsProcessingLegend: {
                    shouldShowProcessingLegend
                }
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
