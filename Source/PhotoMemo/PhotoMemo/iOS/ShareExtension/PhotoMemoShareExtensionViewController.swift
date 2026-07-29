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

    private let statusIndicatorContainer =
        UIView()

    private let statusSymbolView =
        UIImageView()

    private let statusTitleLabel =
        UILabel()

    private let statusStageLabel =
        UILabel()

    private let statusMessageLabel =
        UILabel()

    private let processingChecklistStack =
        UIStackView()

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
        makeProcessingChecklistStack()
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
            makeTitledCardContainer(
                title: "本次分享",
                contentView:
                    makeInnerCardContainer(
                        contentView: makeSummaryStack()
                    )
            )
        summarySectionView =
            summaryCard

        let statusCard =
            makeTitledCardContainer(
                headerView: statusTitleLabel,
                contentView:
                    makeInnerCardContainer(
                        contentView: makeStatusStack()
                    )
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
                    constant:
                        MemoMarkDesignTokens.Share.contentTopInset
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
                    constant:
                        -MemoMarkDesignTokens.Share.contentActionSpacing
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
                    greaterThanOrEqualTo:
                        view.safeAreaLayoutGuide.leadingAnchor,
                    constant: 16
                ),
            bottomActionStack.trailingAnchor
                .constraint(
                    lessThanOrEqualTo:
                        view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -16
                ),
            bottomActionStack.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor
            ),
            bottomActionStack.widthAnchor.constraint(
                equalToConstant:
                    MemoMarkDesignTokens.Layout.compactPrimaryActionWidth
            ),
            bottomActionStack.bottomAnchor
                .constraint(
                    equalTo:
                        view.safeAreaLayoutGuide
                        .bottomAnchor,
                    constant:
                        -MemoMarkDesignTokens.Share.bottomActionInset
                ),
            primaryButton.heightAnchor
                .constraint(
                    equalToConstant:
                        MemoMarkDesignTokens.Share.primaryActionHitTarget
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
        contentStack.spacing =
            MemoMarkDesignTokens.Share.contentActionSpacing
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
        brandLabel.accessibilityTraits =
            .staticText

        titleLabel.font =
            MemoMarkDesignTokens.Typography.hero.uiFont()
        titleLabel.adjustsFontForContentSizeCategory =
            true
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits =
            .header

        subtitleLabel.font =
            MemoMarkDesignTokens.Typography.heroSubtitle.uiFont()
        subtitleLabel.textColor =
            .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true
    }

    func configureStatusLabels() {

        statusIndicatorContainer.translatesAutoresizingMaskIntoConstraints =
            false
        statusIndicatorContainer.accessibilityElementsHidden =
            true

        activityIndicator.translatesAutoresizingMaskIntoConstraints =
            false
        activityIndicator.hidesWhenStopped =
            true

        statusSymbolView.translatesAutoresizingMaskIntoConstraints =
            false
        statusSymbolView.contentMode =
            .scaleAspectFit
        statusSymbolView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 16,
                weight: .semibold
            )
        statusSymbolView.tintColor =
            .secondaryLabel

        statusTitleLabel.font =
            MemoMarkDesignTokens.Typography.moduleTitle.uiFont()
        statusTitleLabel.numberOfLines = 0
        statusTitleLabel.adjustsFontForContentSizeCategory = true
        statusTitleLabel.accessibilityTraits = .header
        statusTitleLabel.text =
            "处理状态"

        statusStageLabel.font =
            UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(
                for: UIFont.systemFont(
                    ofSize:
                        MemoMarkDesignTokens
                        .Typography
                        .detail
                        .size,
                    weight: .semibold
                )
            )
        statusStageLabel.numberOfLines = 0
        statusStageLabel.adjustsFontForContentSizeCategory = true

        statusMessageLabel.font =
            MemoMarkDesignTokens.Typography.detail.uiFont()
        statusMessageLabel.textColor =
            .secondaryLabel
        statusMessageLabel.numberOfLines = 0
        statusMessageLabel.adjustsFontForContentSizeCategory = true
        statusMessageLabel.isHidden = true
    }

    func makeProcessingChecklistStack() {

        processingChecklistStack.translatesAutoresizingMaskIntoConstraints =
            false
        processingChecklistStack.axis = .vertical
        processingChecklistStack.alignment = .fill
        processingChecklistStack.spacing =
            MemoMarkDesignTokens.Share.checklistRowSpacing
        processingChecklistStack.addArrangedSubview(
            makeProcessingChecklistRow(
                symbolName: "photo.stack.fill",
                title: MemoMarkLanguage.interfaceStored.localized(
                    key: "原图保持不变",
                    fallback: "Original stays unchanged"
                )
            )
        )
        processingChecklistStack.addArrangedSubview(
            makeProcessingChecklistRow(
                symbolName: "doc.badge.gearshape",
                title: MemoMarkLanguage.interfaceStored.localized(
                    key: "保留拍摄信息",
                    fallback: "Capture information preserved"
                )
            )
        )
        processingChecklistStack.addArrangedSubview(
            makeProcessingChecklistRow(
                symbolName: "arrow.right.circle.fill",
                title: MemoMarkLanguage.interfaceStored.localized(
                    key: "后台继续处理",
                    fallback: "Continues in the background"
                )
            )
        )
        processingChecklistStack.addArrangedSubview(
            makeProcessingChecklistRow(
                symbolName: "bell.fill",
                title: MemoMarkLanguage.interfaceStored.localized(
                    key: "完成后发送通知",
                    fallback: "Notification when complete"
                )
            )
        )
    }

    func makeProcessingChecklistRow(
        symbolName: String,
        title: String
    ) -> UIStackView {

        let iconView = UIImageView(
            image: UIImage(
                systemName: symbolName,
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize:
                        MemoMarkDesignTokens.Share.checklistIconSize,
                    weight: .semibold
                )
            )
        )
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel
        iconView.accessibilityElementsHidden = true

        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        let label = UILabel()
        label.font = MemoMarkDesignTokens.Typography.detail.uiFont()
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.text = title

        let row = UIStackView(
            arrangedSubviews: [
                iconContainer,
                label
            ]
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = MemoMarkDesignTokens.Spacing.small

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(
                equalToConstant:
                    MemoMarkDesignTokens.Share.checklistIconContainerWidth
            ),
            iconContainer.heightAnchor.constraint(
                equalToConstant:
                    MemoMarkDesignTokens.Share.checklistIconContainerWidth
            ),
            iconView.centerXAnchor.constraint(
                equalTo: iconContainer.centerXAnchor
            ),
            iconView.centerYAnchor.constraint(
                equalTo: iconContainer.centerYAnchor
            ),
            iconView.widthAnchor.constraint(
                equalToConstant:
                    MemoMarkDesignTokens.Share.checklistIconSize
            ),
            iconView.heightAnchor.constraint(
                equalToConstant:
                    MemoMarkDesignTokens.Share.checklistIconSize
            )
        ])

        return row
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
            MemoMarkLanguage.interfaceStored == .english
            ? "The receiving status for each photo appears here."
            : "每张照片的接收状态会显示在这里。"
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
        let systemTint =
            view.tintColor ?? UIColor.tintColor
        primaryButton.configuration?.baseBackgroundColor =
            systemTint.withAlphaComponent(
                CGFloat(
                    MemoMarkDesignTokens
                        .Layout
                        .compactPrimaryActionTintOpacity
                )
            )
        primaryButton.configuration?.baseForegroundColor =
            .white
        primaryButton.configuration?.image =
            UIImage(systemName: "sparkles")
        primaryButton.configuration?.imagePlacement =
            .leading
        primaryButton.configuration?.imagePadding =
            8
        primaryButton.configuration?.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(
                pointSize: 15,
                weight: .semibold
            )
        primaryButton.configuration?.cornerStyle =
            .fixed
        primaryButton.layer.cornerRadius =
            MemoMarkDesignTokens.Layout.compactPrimaryActionCornerRadius
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
        stack.alignment = .fill
        stack.spacing = 12
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
        stack.alignment = .fill
        stack.spacing = 10
        stack.addArrangedSubview(
            makeStatusStageStack()
        )
        stack.addArrangedSubview(
            statusMessageLabel
        )
        stack.addArrangedSubview(
            processingChecklistStack
        )

        return stack
    }

    func makeStatusStageStack() -> UIStackView {

        let stack =
            UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints =
            false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10

        statusIndicatorContainer.addSubview(
            statusSymbolView
        )
        statusIndicatorContainer.addSubview(
            activityIndicator
        )

        NSLayoutConstraint.activate([
            statusIndicatorContainer.widthAnchor.constraint(
                equalToConstant: 20
            ),
            statusIndicatorContainer.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 20
            ),
            statusSymbolView.centerXAnchor.constraint(
                equalTo: statusIndicatorContainer.centerXAnchor
            ),
            statusSymbolView.centerYAnchor.constraint(
                equalTo: statusIndicatorContainer.centerYAnchor
            ),
            statusSymbolView.widthAnchor.constraint(
                equalToConstant: 18
            ),
            statusSymbolView.heightAnchor.constraint(
                equalToConstant: 18
            ),
            activityIndicator.centerXAnchor.constraint(
                equalTo: statusIndicatorContainer.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: statusIndicatorContainer.centerYAnchor
            )
        ])

        stack.addArrangedSubview(
            statusIndicatorContainer
        )
        stack.addArrangedSubview(
            statusStageLabel
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
            stack.addArrangedSubview(
                makeInsetDivider()
            )
        }

        return stack
    }

    func makeInsetDivider() -> UIView {

        let container =
            UIView()
        container.translatesAutoresizingMaskIntoConstraints =
            false

        let divider =
            UIView()
        divider.translatesAutoresizingMaskIntoConstraints =
            false
        divider.backgroundColor =
            .separator
        container.addSubview(divider)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: container.topAnchor),
            divider.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant: MemoMarkDesignTokens.Layout.dividerInset
            ),
            divider.trailingAnchor.constraint(
                equalTo: container.trailingAnchor,
                constant: -MemoMarkDesignTokens.Layout.dividerInset
            ),
            divider.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            divider.heightAnchor.constraint(
                equalToConstant: 1 / UIScreen.main.scale
            )
        ])

        return container
    }

    func makeTitledCardContainer(
        title: String,
        contentView: UIView
    ) -> UIView {

        let titleLabel =
            UILabel()
        titleLabel.font =
            MemoMarkDesignTokens.Typography.moduleTitle.uiFont()
        titleLabel.adjustsFontForContentSizeCategory =
            true
        titleLabel.numberOfLines =
            0
        titleLabel.text =
            title
        titleLabel.accessibilityTraits =
            .header

        return makeTitledCardContainer(
            headerView: titleLabel,
            contentView: contentView
        )
    }

    func makeTitledCardContainer(
        headerView: UIView,
        contentView: UIView
    ) -> UIView {

        let stack =
            UIStackView(
                arrangedSubviews: [
                    headerView,
                    contentView
                ]
            )
        stack.translatesAutoresizingMaskIntoConstraints =
            false
        stack.axis =
            .vertical
        stack.alignment =
            .fill
        stack.spacing =
            12

        return makeCardContainer(
            contentView: stack,
            padding:
                MemoMarkDesignTokens
                .Layout
                .compactCardPadding
        )
    }

    func makeInnerCardContainer(
        contentView: UIView
    ) -> UIView {

        let container =
            UIView()
        container.translatesAutoresizingMaskIntoConstraints =
            false
        container.backgroundColor =
            .systemBackground
        container.layer.cornerRadius =
            MemoMarkDesignTokens
            .Layout
            .compactInnerCardCornerRadius
        container.layer.cornerCurve =
            .continuous
        container.layer.borderColor =
            UIColor.separator.withAlphaComponent(0.35).cgColor
        container.layer.borderWidth =
            1 / UIScreen.main.scale
        container.addSubview(
            contentView
        )

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(
                equalTo: container.topAnchor,
                constant:
                    MemoMarkDesignTokens
                    .Layout
                    .compactInnerCardPadding
            ),
            contentView.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant:
                    MemoMarkDesignTokens
                    .Layout
                    .compactInnerCardPadding
            ),
            contentView.trailingAnchor.constraint(
                equalTo: container.trailingAnchor,
                constant:
                    -MemoMarkDesignTokens
                    .Layout
                    .compactInnerCardPadding
            ),
            contentView.bottomAnchor.constraint(
                equalTo: container.bottomAnchor,
                constant:
                    -MemoMarkDesignTokens
                    .Layout
                    .compactInnerCardPadding
            )
        ])

        return container
    }

    func makeCardContainer(
        contentView: UIView,
        padding: CGFloat =
            MemoMarkDesignTokens.Layout.compactCardPadding
    ) -> UIView {

        let container =
            UIView()
        container.translatesAutoresizingMaskIntoConstraints =
            false
        container.backgroundColor =
            .secondarySystemBackground
        container.layer.cornerRadius =
            MemoMarkDesignTokens.Layout.compactCardCornerRadius
        container.layer.cornerCurve = .continuous
        container.addSubview(
            contentView
        )

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(
                equalTo:
                    container.topAnchor,
                constant: padding
            ),
            contentView.leadingAnchor.constraint(
                equalTo:
                    container.leadingAnchor,
                constant: padding
            ),
            contentView.trailingAnchor.constraint(
                equalTo:
                    container.trailingAnchor,
                constant: -padding
            ),
            contentView.bottomAnchor.constraint(
                equalTo:
                    container.bottomAnchor,
                constant: -padding
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
                configurationIsReady: configurationReadiness.isReady,
                maximumPhotoCount:
                    intakeService
                    .maxSupportedPhotoCount
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
            statusStageLabel: statusStageLabel,
            statusSymbolView: statusSymbolView,
            statusMessageLabel: statusMessageLabel,
            statusChecklistStack: processingChecklistStack,
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
                    intakeService
                    .maxSupportedPhotoCount,
                  intakeService
                    .maxSupportedPhotoCount > 0
            else {
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionInputTooManyPhotos,
                    message:
                        "supportedPhotos=\(sharedPhotoCount), max=\(intakeService.maxSupportedPhotoCount)"
                )
                cancelExtension(
                    message:
                        intakeService.maxSupportedPhotoCount == 0
                        ? "免费成长记录已完成，请打开时光记了解 MemoMark+。"
                        : "一次最多处理 \(intakeService.maxSupportedPhotoCount) 张照片。请回到 Apple Photos 分批分享。"
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

                if result.hasWarnings {
                    statusMessageLabel.attributedText =
                        nil
                    statusMessageLabel.textColor =
                        .secondaryLabel
                    statusMessageLabel.text =
                        viewStateRenderer.successMessage(
                            for: result
                        )
                    footerLabel.text =
                        "其余情况会在时光记中继续说明。"
                }
            }
        )

        switch result {
        case .received(let importResult):
            pendingHandoffPhotoCount =
                importResult.importedCount
            applyViewState(
                .received,
                photoCount: sharedPhotoCount
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
