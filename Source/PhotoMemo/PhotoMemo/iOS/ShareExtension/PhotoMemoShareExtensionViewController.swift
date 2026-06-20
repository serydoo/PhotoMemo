#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit

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

    private let successDisplayNanoseconds:
        UInt64 = 650_000_000

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

    private let currentConfigurationValueLabel =
        UILabel()

    private let outputValueLabel =
        UILabel()

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
            "这次会使用"

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
                title: "当前风格",
                valueLabel:
                    currentConfigurationValueLabel
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

        sharedCountValueLabel.text =
            sharedPhotoCount > 0
            ? "\(sharedPhotoCount) 张"
            : "未识别到可处理照片"
    }

    @MainActor
    func applyWorkflowSummary() {

        let snapshot =
            snapshotService.loadSnapshot()
        let summary =
            workflowSummaryBuilder.build(
                from: snapshot
            )

        currentConfigurationValueLabel.text =
            summary.configurationTitle
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
            ? "PhotoMemo 会按当前风格继续处理。确认后就会进入下一步。"
            : "当前内容看起来不像可直接处理的原始照片。"

        if sharedPhotoCount > 0 {
            statusTitleLabel.text =
                "继续后会发生什么"
            statusMessageLabel.text =
                "PhotoMemo 会先接收这次分享，再按当前风格继续处理，完成后写回系统相册。"
            footerLabel.text =
                "如果想更换风格，请先回到 PhotoMemo 主 App 调整，再重新分享。"
            applyPrimaryButton(
                title:
                    "按当前风格继续"
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
            "正在接收这次分享"
        subtitleLabel.text =
            "PhotoMemo 正在记录这次分享，并准备按当前风格继续处理。"
        statusTitleLabel.text =
            "正在交给 PhotoMemo"
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.text =
            "这一步完成后，后续处理会继续进行。"
        footerLabel.text =
            "请稍等片刻，不需要再次设置。"

        primaryButton.isEnabled =
            false
        primaryButton.configuration?.title =
            "正在继续"
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
        }
    }

    @MainActor
    func persistIncomingItems() async {

        guard !inputItems.isEmpty else {
            PhotoMemoShareIntakeLog.error(
                "persistIncomingItems failed before intake: inputItems was empty."
            )
            applyFailureState(
                title:
                    "无法读取这次分享",
                message:
                    "PhotoMemo 没有收到这次分享的原始内容。",
                suggestion:
                    "请返回系统相册重新分享；如果重复出现，请打开 PhotoMemo 检查当前风格后再试。"
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

            statusTitleLabel.text =
                "已经交给 PhotoMemo"
            statusMessageLabel.textColor =
                .secondaryLabel
            statusMessageLabel.text =
                successMessage(
                    for: result
                )
            footerLabel.text =
                "当前分享页会关闭，PhotoMemo 会继续按当前风格处理这批照片。"
            primaryButton.isEnabled =
                false
            primaryButton.configuration?.title =
                "即将完成"
            activityIndicator.stopAnimating()

            try? await Task.sleep(
                nanoseconds:
                    successDisplayNanoseconds
            )

            PhotoMemoShareIntakeLog.notice(
                "Share extension completion request will be sent."
            )

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
                applyFailureState(
                    title:
                        "这次分享没有完成",
                    message:
                        (error as? LocalizedError)?
                        .errorDescription
                        ?? "无法把内容交给 PhotoMemo。",
                    suggestion:
                        "请先返回系统相册重新分享；如果仍失败，请打开 PhotoMemo 检查当前风格和系统相册权限。"
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

            return "\(summaryParts.joined(separator: "，"))。后续处理完成后会写回系统相册。"
        }

        return "已接收 \(result.requestedCount) 张。后续处理完成后会写回系统相册。"
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
