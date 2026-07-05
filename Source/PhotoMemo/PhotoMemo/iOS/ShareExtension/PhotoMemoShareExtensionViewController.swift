#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit
import UniformTypeIdentifiers

final class PhotoMemoShareExtensionViewController:
    UIViewController {

    private enum ViewState {

        case confirming

        case processing

        case received

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

    private let batchSnapshotService =
        SharedBatchQueueSnapshotService()

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

    private var firstPreviewTask:
        Task<Void, Never>?

    private var intakeDiagnosticTask:
        Task<Void, Never>?

    private var previewCardViews:
        [UIView] = []

    private var previewImageViews:
        [UIImageView] = []

    private var previewStatusBadgeViews:
        [UIImageView] = []

    private var previewStatusTitleLabels:
        [UILabel] = []

    private var previewStatusDetailLabels:
        [UILabel] = []

    private var previewCardSizeConstraints:
        [UIView: (
            width: NSLayoutConstraint,
            height: NSLayoutConstraint
        )] = [:]

    private var previewListHeightConstraint:
        NSLayoutConstraint?

    private var selectedPreviewIndex = 0

    private var pendingHandoffPhotoCount = 0

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
        previewListHeightConstraint =
            previewHeight

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
            ? "\(sharedPhotoCount) 张"
            : "未识别到可处理照片"

        previewSectionView?.isHidden = true
        firstPreviewTask?.cancel()
        resetPreviewCards()
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
        previewSectionView?.isHidden = true
        summarySectionView?.isHidden = true

        titleLabel.text =
            sharedPhotoCount > 0
            ? "检测到 \(sharedPhotoCount) 张照片"
            : "这次分享里没有可处理照片"

        subtitleLabel.text =
            sharedPhotoCount > 0
            ? "将按当前配置交给 PhotoMemo 主程序处理。"
            : "当前内容看起来不像可直接处理的原始照片。"

        if sharedPhotoCount > 0 {
            statusTitleLabel.text =
                "准备交给 PhotoMemo"
            statusMessageLabel.text =
                "点击后会打开 PhotoMemo，处理进度在主程序中查看。"
            footerLabel.text =
                "完成后结果会写回系统相册，并发送系统通知。"
            applyPrimaryButton(
                title:
                    "交给 PhotoMemo 处理 \(sharedPhotoCount) 张"
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
        summarySectionView?.isHidden = true
        previewSectionView?.isHidden = true
        titleLabel.text =
            "正在交给 PhotoMemo"
        subtitleLabel.text =
            "正在安全接收这次分享。"
        statusTitleLabel.text =
            "正在接收原图"
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.text =
            "会把照片暂存后打开 PhotoMemo 继续处理。"
        footerLabel.text =
            "原始照片不会被修改。"

        primaryButton.isEnabled =
            false
        primaryButton.configuration?.title =
            "正在接收"
    }

    @MainActor
    func startIntakeDiagnosticMonitor() {

        intakeDiagnosticTask?.cancel()
        intakeDiagnosticTask =
            Task { @MainActor [weak self] in
                for _ in 0..<40 {
                    guard let self,
                          !Task.isCancelled else {
                        return
                    }

                    self.applyLatestIntakeDiagnosticStatus()

                    try? await Task.sleep(
                        nanoseconds: 180_000_000
                    )
                }
            }
    }

    @MainActor
    func stopIntakeDiagnosticMonitor() {

        intakeDiagnosticTask?.cancel()
        intakeDiagnosticTask = nil
    }

    @MainActor
    func applyLatestIntakeDiagnosticStatus() {

        guard case .processing = viewState else {
            return
        }

        let events =
            PhotoMemoShareDiagnostics
            .loadEvents()

        if events.contains(where: {
            $0.stage == .extensionSourcePrepare
        }),
           !events.contains(where: {
               $0.stage == .extensionSourceReady
           }) {
            titleLabel.text =
                "正在准备原图"
            subtitleLabel.text =
                "系统正在把 iCloud 原图准备到本地。"
            statusTitleLabel.text =
                "正在读取 iCloud 原图"
            statusMessageLabel.text =
                "原图可读取后会继续交给 PhotoMemo。"
            primaryButton.configuration?.title =
                "正在准备"
            return
        }

        if events.contains(where: {
            $0.stage == .extensionSourceReady
        }) {
            titleLabel.text =
                "原图已可读取"
            subtitleLabel.text =
                "正在安全交给 PhotoMemo 主程序。"
            statusTitleLabel.text =
                "正在交给 PhotoMemo"
            statusMessageLabel.text =
                "照片可用，正在继续处理。"
            primaryButton.configuration?.title =
                "正在交给 PhotoMemo"
        }
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
                stage: .extensionInputEmpty,
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
                    "imported=\(result.importedCount), requested=\(result.requestedCount), skipped=\(result.skippedCount), failed=\(result.failedCount)"
            )

            statusTitleLabel.text =
                "正在打开 PhotoMemo"
            statusMessageLabel.textColor =
                .secondaryLabel
            statusMessageLabel.text =
                successMessage(
                    for: result
                )
            footerLabel.text =
                "处理进度会在 PhotoMemo 主程序中显示。"

            PhotoMemoShareDiagnostics.record(
                stage: .extensionHandoffRequested,
                message:
                    "Intake is safely persisted; requesting host app handoff.",
                requestID:
                    result.requestID
            )

            let opened =
                await requestMainAppRefresh(
                requestID:
                    result.requestID
            )

            if opened {
                titleLabel.text =
                    "已交给 PhotoMemo"
                subtitleLabel.text =
                    "主程序会继续处理并写回系统相册。"
                statusTitleLabel.text =
                    "处理进度请在 PhotoMemo 查看"
                statusMessageLabel.text =
                    "如果系统没有自动切换，请手动打开 PhotoMemo。"
                footerLabel.text =
                    "可以关闭这个窗口。"
                viewState = .received
                activityIndicator.stopAnimating()
                applyPrimaryButton(
                    title:
                        "关闭"
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

            return "\(summaryParts.joined(separator: "，"))，正在交给 PhotoMemo 主程序。"
        }

        return "已接收 \(result.requestedCount) 张，正在交给 PhotoMemo 主程序。"
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
            "请点下面按钮再试一次；如果仍失败，请直接打开 PhotoMemo V1.0，它会继续检查待处理照片。"
        footerLabel.text =
            "这通常和应用唤起或系统分享状态有关，原始照片不会被修改。"

        applyPrimaryButton(
            title:
                "重新交给 PhotoMemo"
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
            stage: .extensionHandoffPrimary,
            message: "extensionContext.open success=\(opened)"
        )

        if opened {
            return true
        }

        let fallbackOpened =
            requestMainAppRefreshThroughResponderChain(
                deepLinkURL
            )

        PhotoMemoShareIntakeLog.notice(
            "Requested main-app refresh through responder chain. success=\(fallbackOpened)"
        )

        PhotoMemoShareDiagnostics.record(
            stage: .extensionHandoffFallback,
            message: "responderChain success=\(fallbackOpened)"
        )

        guard fallbackOpened else {
            return false
        }

        return true
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
                stage: .extensionHandoffUnconfirmed,
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
                    stage: .extensionHandoffConfirmed,
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
            stage: .extensionHandoffUnconfirmed,
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

                case .appEnqueueCreated,
                     .appEnqueueFailed,
                     .appRequestDropped:
                    return true

                default:
                    return false
                }
            }
    }

    func enqueuedJobID(
        for requestID: UUID
    ) -> UUID? {

        PhotoMemoShareDiagnostics
            .loadEvents()
            .reversed()
            .first { event in
                event.requestID == requestID
                && event.stage == .appEnqueueCreated
            }?
            .jobID
    }

    @MainActor
    func observeProcessingProgress(
        requestID: UUID,
        fallbackPhotoCount: Int
    ) async {

        let startedAt =
            Date()
        var latestSnapshot:
            SharedBatchJobSnapshot?

        repeat {
            if let jobID =
                enqueuedJobID(
                    for: requestID
                ),
               let snapshot =
                batchSnapshotService
                .loadSnapshot(
                    for: jobID
                ) {
                latestSnapshot =
                    snapshot
                applyProcessingSnapshot(
                    snapshot
                )

                if snapshot.isTerminal {
                    break
                }
            } else {
                applyWaitingForQueueState(
                    fallbackPhotoCount:
                        fallbackPhotoCount
                )
            }

            try? await Task.sleep(
                nanoseconds: 250_000_000
            )
        } while Date()
            .timeIntervalSince(startedAt) < 3.5

        if let latestSnapshot {
            applyProcessingSnapshot(
                latestSnapshot
            )

            if !latestSnapshot.isTerminal {
                activityIndicator.stopAnimating()
                statusTitleLabel.text =
                    "处理已开始"
                statusMessageLabel.text =
                    currentProgressMessage(
                        for: latestSnapshot
                    )
            }
        } else {
            applyWaitingForAppState(
                fallbackPhotoCount:
                    fallbackPhotoCount
            )
            return
        }

        viewState = .received
        footerLabel.text =
            "可以关闭窗口，处理完成后会收到系统通知。"
        applyPrimaryButton(
            title:
                "关闭"
        )

        UIImpactFeedbackGenerator(
            style: .soft
        )
        .impactOccurred()
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
            "已接收 \(fallbackPhotoCount) 张照片，正在等待 PhotoMemo 开始逐张处理。"
        previewCaptionLabel.text =
            processingLegendText()
        updatePreviewRows(
            phases:
                Array(
                    repeating: .queued,
                    count:
                        previewStatusBadgeViews
                        .count
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
            "需要 PhotoMemo 主程序接手后才会开始处理。"
        statusTitleLabel.text =
            "等待 PhotoMemo 开始处理"
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.text =
            "iOS 不会因为 Share Extension 写入待处理请求就自动运行主程序。打开 PhotoMemo 后，队列会立即继续。"
        footerLabel.text =
            "原始照片已经安全暂存；点下面按钮打开 PhotoMemo 继续。"
        previewCaptionLabel.text =
            "队列已建立，等待 PhotoMemo 主程序接手。"
        updatePreviewRows(
            phases:
                Array(
                    repeating: .queued,
                    count:
                        max(
                            previewStatusBadgeViews.count,
                            fallbackPhotoCount
                        )
                )
        )
        applyPrimaryButton(
            title:
                "打开 PhotoMemo 继续处理"
        )
    }

    @MainActor
    func applyProcessingSnapshot(
        _ snapshot: SharedBatchJobSnapshot
    ) {

        statusMessageLabel.textColor =
            .secondaryLabel
        previewCaptionLabel.text =
            processingLegendText()
        updatePreviewRows(
            tasks:
                snapshot.tasks
        )

        if snapshot.isTerminal {
            activityIndicator.stopAnimating()

            if snapshot.failedCount > 0 {
                statusTitleLabel.text =
                    "已完成 \(snapshot.completedCount) 张，\(snapshot.failedCount) 张需要处理"
                statusMessageLabel.text =
                    "失败项会保留记录，可回到 PhotoMemo 查看原因并重试。"
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
            return "PhotoMemo 会继续处理，完成后发送系统通知。"
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

    func processingLegendText() -> String {

        "灰色等待，蓝色处理中，绿色完成，红色需要处理。"
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

            previewCaptionLabel.text =
                processingLegendText()
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
        previewStatusBadgeViews.removeAll()
        previewStatusTitleLabels.removeAll()
        previewStatusDetailLabels.removeAll()
        previewCardSizeConstraints.removeAll()
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
            previewCardViews
                .append(card.container)
            previewImageViews
                .append(card.imageView)
            previewStatusBadgeViews
                .append(card.statusBadgeView)
            previewStatusTitleLabels
                .append(card.titleLabel)
            previewStatusDetailLabels
                .append(card.detailLabel)
        }

        rebuildPreviewLayout(
            using: Array(
                repeating: nil,
                count: count
            )
        )
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
        imageView: UIImageView,
        statusBadgeView: UIImageView,
        titleLabel: UILabel,
        detailLabel: UILabel
    ) {

        let container =
            UIView()
        container.translatesAutoresizingMaskIntoConstraints =
            false
        container.backgroundColor =
            .tertiarySystemBackground
        container.layer.cornerRadius = 14
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 0
        container.clipsToBounds = false

        let imageView =
            UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints =
            false
        imageView.contentMode =
            .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.layer.cornerCurve = .continuous
        imageView.backgroundColor =
            .secondarySystemBackground

        container.addSubview(imageView)

        let titleLabel =
            UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints =
            false
        titleLabel.font =
            .preferredFont(
                forTextStyle: .subheadline
            )
        titleLabel.textColor =
            .label
        titleLabel.numberOfLines = 1
        titleLabel.text =
            "第 \(index + 1) 张照片"

        let detailLabel =
            UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints =
            false
        detailLabel.font =
            .preferredFont(
                forTextStyle: .caption1
            )
        detailLabel.textColor =
            .secondaryLabel
        detailLabel.numberOfLines = 1
        detailLabel.text =
            "等待 PhotoMemo 接手"

        let textStack =
            UIStackView(
                arrangedSubviews: [
                    titleLabel,
                    detailLabel
                ]
            )
        textStack.translatesAutoresizingMaskIntoConstraints =
            false
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 2
        container.addSubview(
            textStack
        )

        let statusBadgeView =
            UIImageView()
        statusBadgeView.translatesAutoresizingMaskIntoConstraints =
            false
        statusBadgeView.contentMode =
            .center
        statusBadgeView.backgroundColor =
            .clear
        statusBadgeView.layer.cornerRadius = 0
        statusBadgeView.layer.cornerCurve =
            .continuous
        statusBadgeView.layer.shadowOpacity = 0
        statusBadgeView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 17,
                weight: .semibold
            )
        container.addSubview(
            statusBadgeView
        )
        applyPreviewStatusBadge(
            statusBadgeView,
            phase: .queued
        )

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

        let widthConstraint =
            container.widthAnchor.constraint(
                equalTo:
                    previewCardStack
                    .widthAnchor
            )
        let heightConstraint =
            container.heightAnchor.constraint(
                equalToConstant: 54
            )
        previewCardSizeConstraints[container] =
            (
                widthConstraint,
                heightConstraint
            )

        NSLayoutConstraint.activate([
            widthConstraint,
            heightConstraint,
            imageView.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant: 8
            ),
            imageView.centerYAnchor.constraint(
                equalTo:
                    container.centerYAnchor
            ),
            imageView.widthAnchor.constraint(
                equalToConstant: 40
            ),
            imageView.heightAnchor.constraint(
                equalToConstant: 40
            ),
            textStack.leadingAnchor.constraint(
                equalTo:
                    imageView.trailingAnchor,
                constant: 10
            ),
            textStack.centerYAnchor.constraint(
                equalTo:
                    container.centerYAnchor
            ),
            textStack.trailingAnchor.constraint(
                lessThanOrEqualTo:
                    statusBadgeView.leadingAnchor,
                constant: -10
            ),
            statusBadgeView.widthAnchor.constraint(
                equalToConstant: 24
            ),
            statusBadgeView.heightAnchor.constraint(
                equalToConstant: 24
            ),
            statusBadgeView.centerYAnchor.constraint(
                equalTo:
                    container.centerYAnchor
            ),
            statusBadgeView.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant: -10
            )
        ])

        return (
            container,
            imageView,
            statusBadgeView,
            titleLabel,
            detailLabel
        )
    }

    @MainActor
    func updatePreviewRows(
        tasks: [SharedBatchTaskSnapshot]
    ) {

        for (index, badge) in
            previewStatusBadgeViews
            .enumerated() {
            let task =
                tasks.indices.contains(index)
                ? tasks[index]
                : nil
            let phase =
                task?.phase ?? .queued

            if previewStatusTitleLabels
                .indices
                .contains(index) {
                previewStatusTitleLabels[index]
                    .text =
                    "第 \(index + 1) 张照片"
            }
            if previewStatusDetailLabels
                .indices
                .contains(index) {
                previewStatusDetailLabels[index]
                    .text =
                    previewStatusDetailText(
                        task: task,
                        phase: phase
                    )
            }
            applyPreviewStatusBadge(
                badge,
                phase: phase
            )
        }
    }

    @MainActor
    func updatePreviewRows(
        phases: [BatchTaskPhase]
    ) {

        for (index, badge) in
            previewStatusBadgeViews
            .enumerated() {
            let phase =
                phases.indices.contains(index)
                ? phases[index]
                : .queued

            if previewStatusTitleLabels
                .indices
                .contains(index) {
                previewStatusTitleLabels[index]
                    .text =
                    "第 \(index + 1) 张照片"
            }
            if previewStatusDetailLabels
                .indices
                .contains(index) {
                previewStatusDetailLabels[index]
                    .text =
                    previewStatusDetailText(
                        task: nil,
                        phase: phase
                    )
            }
            applyPreviewStatusBadge(
                badge,
                phase: phase
            )
        }
    }

    func previewStatusDetailText(
        task: SharedBatchTaskSnapshot?,
        phase: BatchTaskPhase
    ) -> String {

        if let failureMessage =
            task?.failureMessage,
           !failureMessage
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            return failureMessage
        }

        if let statusMessage =
            task?.statusMessage,
           !statusMessage
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            return statusMessage
        }

        switch phase {

        case .queued:
            return "等待 PhotoMemo 接手"

        case .completed:
            return "已保存到系统图库"

        case .failed:
            return "需要回到 PhotoMemo 查看"

        case .cancelled:
            return "已取消"

        case .importing,
             .metadataReady,
             .previewReady,
             .waitingForExport,
             .exporting,
             .savingToPhotoLibrary:
            return phase.displayTitle
        }
    }

    @MainActor
    func applyPreviewStatusBadge(
        _ badge: UIImageView,
        phase: BatchTaskPhase
    ) {

        badge.isHidden = false
        badge.tintColor =
            previewStatusTintColor(
                for: phase
            )
        badge.image =
            UIImage(
                systemName:
                    previewStatusSystemImageName(
                        for: phase
                    )
            )
        badge.accessibilityLabel =
            previewStatusAccessibilityLabel(
                for: phase
            )
    }

    func previewStatusSystemImageName(
        for phase: BatchTaskPhase
    ) -> String {

        switch phase {

        case .queued:
            return "clock.fill"

        case .importing,
             .metadataReady,
             .previewReady,
             .waitingForExport,
             .exporting,
             .savingToPhotoLibrary:
            return "arrow.triangle.2.circlepath"

        case .completed:
            return "checkmark.circle.fill"

        case .failed:
            return "exclamationmark.circle.fill"

        case .cancelled:
            return "minus.circle.fill"
        }
    }

    func previewStatusTintColor(
        for phase: BatchTaskPhase
    ) -> UIColor {

        switch phase {

        case .queued,
             .cancelled:
            return .systemGray

        case .importing,
             .metadataReady,
             .previewReady,
             .waitingForExport,
             .exporting,
             .savingToPhotoLibrary:
            return .systemBlue

        case .completed:
            return .systemGreen

        case .failed:
            return .systemRed
        }
    }

    func previewStatusAccessibilityLabel(
        for phase: BatchTaskPhase
    ) -> String {

        switch phase {

        case .queued:
            return "等待处理"

        case .completed:
            return "处理完成"

        case .failed:
            return "处理失败"

        case .cancelled:
            return "已取消"

        case .importing,
             .metadataReady,
             .previewReady,
             .waitingForExport,
             .exporting,
             .savingToPhotoLibrary:
            return "正在处理"
        }
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
                card.transform = .identity
                card.layer.zPosition =
                    CGFloat(index)
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

        rebuildPreviewLayout(
            using: images
        )
    }

    @MainActor
    func rebuildPreviewLayout(
        using images: [UIImage?]
    ) {

        previewCardStack
            .arrangedSubviews
            .forEach { view in
                previewCardStack
                    .removeArrangedSubview(view)
                view.removeFromSuperview()
            }

        previewCardViews
            .forEach { card in
                card.removeFromSuperview()
                card.transform = .identity
            }

        let count =
            previewCardViews.count

        previewCardStack.axis = .vertical
        previewCardStack.alignment = .fill
        previewCardStack.spacing = 8
        previewListHeightConstraint?
            .constant =
            previewListHeight(
                rowCount: count
            )

        guard count > 0 else {
            return
        }

        for card in previewCardViews {
            previewCardStack
                .addArrangedSubview(card)
        }
    }

    func previewListHeight(
        rowCount: Int
    ) -> CGFloat {

        guard rowCount > 0 else {
            return 0
        }

        let rowHeight: CGFloat = 54
        let spacing: CGFloat = 8
        let visibleRows =
            min(
                rowCount,
                4
            )

        return CGFloat(visibleRows)
            * rowHeight
            + CGFloat(max(visibleRows - 1, 0))
            * spacing
            + 4
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
                   let image =
                    self.thumbnailImage(
                        from: data
                    ) {
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

        MediaDecodeService()
            .thumbnailImage(
                from: url,
                maxPixelDimension: 640
            )
    }

    nonisolated
    func thumbnailImage(
        from data: Data
    ) -> UIImage? {

        MediaDecodeService()
            .thumbnailImage(
                from: data,
                maxPixelDimension: 640
            )
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
