#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit

enum ShareExtensionViewState {
    case confirming
    case processing
    case received
    case failed(title: String, message: String, suggestion: String)
    case handoffFailed
}

struct ShareExtensionViewStateInput {
    let state: ShareExtensionViewState
    let photoCount: Int
    let configurationIsReady: Bool
    let maximumPhotoCount: Int
}

struct ShareExtensionViewStateUpdate {
    let state: ShareExtensionViewState
    let animatesActivity: Bool
    let hidesPreview: Bool
    let hidesSummary: Bool
    let resetsContentPresentation: Bool
    let title: String
    let subtitle: String
    let statusTitle: String
    let statusMessage: String
    let statusColor: UIColor
    let showsProcessingChecklist: Bool
    let footer: String
    let buttonTitle: String
    let buttonIsEnabled: Bool
    let accessibilityAnnouncement: String?
}

struct ShareExtensionViewStateBindings {
    let contentStack: UIStackView
    let activityIndicator: UIActivityIndicatorView
    let previewSectionView: UIView?
    let summarySectionView: UIView?
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let statusTitleLabel: UILabel
    let statusMessageLabel: UILabel
    let footerLabel: UILabel
    let primaryButton: UIButton
}

@MainActor
final class ShareExtensionViewStateRenderer {

    func apply(
        _ update: ShareExtensionViewStateUpdate,
        to bindings: ShareExtensionViewStateBindings
    ) {
        if update.animatesActivity {
            bindings.activityIndicator.startAnimating()
        } else {
            bindings.activityIndicator.stopAnimating()
        }
        bindings.previewSectionView?.isHidden = update.hidesPreview
        bindings.summarySectionView?.isHidden = update.hidesSummary
        if update.resetsContentPresentation {
            bindings.contentStack.alpha = 1
            bindings.contentStack.transform = .identity
        }
        bindings.titleLabel.text = update.title
        bindings.subtitleLabel.text = update.subtitle
        bindings.statusTitleLabel.text = update.statusTitle
        bindings.statusMessageLabel.textColor = update.statusColor
        if update.showsProcessingChecklist {
            bindings.statusMessageLabel.attributedText =
                processingChecklistAttributedText()
        } else {
            bindings.statusMessageLabel.attributedText = nil
            bindings.statusMessageLabel.text = update.statusMessage
        }
        bindings.footerLabel.text = update.footer
        bindings.primaryButton.isEnabled = update.buttonIsEnabled
        bindings.primaryButton.configuration?.title = update.buttonTitle
        bindings.primaryButton.accessibilityLabel = update.buttonTitle
        if let announcement = update.accessibilityAnnouncement {
            UIAccessibility.post(
                notification: .announcement,
                argument: announcement
            )
        }
    }

    func update(
        for input: ShareExtensionViewStateInput
    ) -> ShareExtensionViewStateUpdate {
        switch input.state {
        case .confirming:
            return confirmingUpdate(input)
        case .processing:
            return .init(
                state: .processing,
                animatesActivity: true,
                hidesPreview: true,
                hidesSummary: input.photoCount == 0,
                resetsContentPresentation: false,
                title: localized("正在准备照片", english: "Preparing Photos"),
                subtitle: localized("这次分享会在后台继续处理。", english: "This share will continue in the background."),
                statusTitle: localized("正在接收照片", english: "Receiving Photos"),
                statusMessage: localized("原图不会被修改。", english: "The original photo will not be modified."),
                statusColor: .secondaryLabel,
                showsProcessingChecklist: false,
                footer: localized("完成后会发送通知。", english: "You will receive a notification when it is complete."),
                buttonTitle: localized("正在处理", english: "Processing"),
                buttonIsEnabled: false,
                accessibilityAnnouncement: "正在接收照片并准备后台处理"
            )
        case .received:
            return .init(
                state: .received,
                animatesActivity: false,
                hidesPreview: true,
                hidesSummary: input.photoCount == 0,
                resetsContentPresentation: false,
                title: localized("已开始处理", english: "Processing Started"),
                subtitle: localized("时光记会在后台继续处理这次分享。", english: "MemoMark will continue processing this share in the background."),
                statusTitle: localized("可以返回照片", english: "You Can Return to Photos"),
                statusMessage: localized("你可以继续分享下一批。", english: "You can share another batch."),
                statusColor: .secondaryLabel,
                showsProcessingChecklist: false,
                footer: localized("完成后会发送通知。", english: "You will receive a notification when it is complete."),
                buttonTitle: localized("已开始处理", english: "Processing Started"),
                buttonIsEnabled: false,
                accessibilityAnnouncement: "已开始处理"
            )
        case .failed(let title, let message, let suggestion):
            return .init(
                state: input.state,
                animatesActivity: false,
                hidesPreview: true,
                hidesSummary: input.photoCount == 0,
                resetsContentPresentation: false,
                title: localized("这次交接没有完成", english: "Handoff Did Not Finish"),
                subtitle: localized("可以直接重试；如果仍失败，再回到时光记查看。", english: "Retry now. If it still fails, open MemoMark to check the handoff."),
                statusTitle: title,
                statusMessage: message,
                statusColor: .systemOrange,
                showsProcessingChecklist: false,
                footer: suggestion,
                buttonTitle: localized("重新尝试", english: "Try Again"),
                buttonIsEnabled: true,
                accessibilityAnnouncement: "\(title)。\(message)"
            )
        case .handoffFailed:
            return .init(
                state: .handoffFailed,
                animatesActivity: false,
                hidesPreview: true,
                hidesSummary: input.photoCount == 0,
                resetsContentPresentation: true,
                title: localized("照片已经接收", english: "Photos Received"),
                subtitle: localized("但这次没有顺利继续交给时光记。", english: "This batch was not handed off to MemoMark successfully."),
                statusTitle: localized("重新交给时光记", english: "Hand Off to MemoMark Again"),
                statusMessage: localized("请点下面按钮再试一次；如果仍失败，请直接打开时光记，它会继续检查待处理照片。", english: "Tap below to try again. If it still fails, open MemoMark to check pending photos."),
                statusColor: .secondaryLabel,
                showsProcessingChecklist: false,
                footer: localized("原图已经接收，原始照片不会被修改。", english: "The originals were received and will not be modified."),
                buttonTitle: localized("重新交给时光记", english: "Hand Off to MemoMark Again"),
                buttonIsEnabled: true,
                accessibilityAnnouncement: nil
            )
        }
    }

    func apply(
        _ update: ShareExtensionIntakeDiagnosticUpdate,
        to bindings: ShareExtensionViewStateBindings
    ) {
        switch update {
        case .preparingSource:
            bindings.titleLabel.text =
                localized("正在准备原图", english: "Preparing Original")
            bindings.subtitleLabel.text =
                localized("系统正在把 iCloud 原图准备到本地。", english: "iCloud is preparing the original locally.")
            bindings.statusTitleLabel.text =
                localized("正在读取 iCloud 原图", english: "Reading iCloud Original")
            bindings.statusMessageLabel.attributedText = nil
            bindings.statusMessageLabel.text =
                localized("原图准备好后会继续后台处理。", english: "Background processing will continue when the original is ready.")
            bindings.primaryButton.configuration?.title =
                localized("正在准备", english: "Preparing")
        case .sourceReady:
            bindings.titleLabel.text =
                localized("原图已可读取", english: "Original is Ready")
            bindings.subtitleLabel.text =
                localized("正在准备后台处理。", english: "Preparing background processing.")
            bindings.statusTitleLabel.text =
                localized("正在继续处理", english: "Continuing Processing")
            bindings.statusMessageLabel.attributedText = nil
            bindings.statusMessageLabel.text =
                localized("照片已经可处理，完成后会发送通知。", english: "The photo is ready to process. You will receive a notification when it is complete.")
            bindings.primaryButton.configuration?.title =
                localized("正在处理", english: "Processing")
        }
    }

    func successMessage(
        for result: PhotoMemoShareExtensionImportResult
    ) -> String {
        if MemoMarkLanguage.interfaceStored == .english {
            if result.hasWarnings {
                var summaryParts = [
                    "Received \(result.importedCount) of \(result.requestedCount)"
                ]
                if result.skippedCount > 0 {
                    summaryParts.append("\(result.skippedCount) skipped")
                }
                if result.failedCount > 0 {
                    summaryParts.append("\(result.failedCount) not received")
                }
                if result.livePhotoStaticFallbackCount > 0 {
                    summaryParts.append(
                        "\(result.livePhotoStaticFallbackCount) Live Photos received as still images"
                    )
                }
                return "\(summaryParts.joined(separator: ", ")). MemoMark will explain any remaining items."
            }
            return "Received \(result.requestedCount) photos. Processing in the background."
        }

        if result.hasWarnings {
            var summaryParts = [
                "已接收 \(result.importedCount) / \(result.requestedCount) 张"
            ]
            if result.skippedCount > 0 {
                summaryParts.append("跳过 \(result.skippedCount) 张")
            }
            if result.failedCount > 0 {
                summaryParts.append("未接收 \(result.failedCount) 张")
            }
            if result.livePhotoStaticFallbackCount > 0 {
                summaryParts.append(
                    "\(result.livePhotoStaticFallbackCount) 张 Live Photo 已按静态照片接收"
                )
            }
            return "\(summaryParts.joined(separator: "，"))，其余情况会在时光记中继续说明。"
        }
        return "已接收 \(result.requestedCount) 张，正在后台处理。"
    }

    private func processingChecklistAttributedText() -> NSAttributedString {
        let items = [
            ("photo.stack.fill", localized("原图保持不变", english: "Original stays unchanged")),
            ("doc.badge.gearshape", localized("保留拍摄信息", english: "Capture information preserved")),
            ("bell.fill", localized("完成后发送通知", english: "Notification when complete")),
            ("arrow.right.circle.fill", localized("可以继续分享下一批", english: "You can share another batch"))
        ]
        let font =
            MemoMarkDesignTokens
            .Typography
            .detail
            .uiFont()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraphStyle
        ]
        let result = NSMutableAttributedString(string: "")

        let symbolConfiguration =
            UIImage.SymbolConfiguration(
                hierarchicalColor: .secondaryLabel
            )

        for (symbolName, title) in items {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(
                systemName: symbolName,
                withConfiguration: symbolConfiguration
            )
            attachment.bounds = CGRect(
                x: 0,
                y: -2,
                width: 16,
                height: 16
            )
            result.append(
                NSAttributedString(
                    attachment: attachment
                )
            )
            result.append(
                NSAttributedString(
                    string: "  \(title)\n",
                    attributes: textAttributes
                )
            )
        }

        if result.length > 0 {
            result.deleteCharacters(
                in: NSRange(
                    location: result.length - 1,
                    length: 1
                )
            )
        }

        return result
    }

    private func confirmingUpdate(
        _ input: ShareExtensionViewStateInput
    ) -> ShareExtensionViewStateUpdate {
        let title = input.photoCount > 0
            ? localized("已准备好", english: "Ready")
            : localized("这次分享里没有可处理照片", english: "No Processable Photos")
        let subtitle = input.configurationIsReady
            ? (input.photoCount > 0
                ? (MemoMarkLanguage.interfaceStored == .english
                    ? "\(input.photoCount) photos are ready to process"
                    : "\(input.photoCount) 张照片准备开始记录")
                : localized("当前内容里没有可直接处理的照片。", english: "There are no photos ready to process."))
            : localized("首次处理前，需要先在时光记里保存一个配置。", english: "Save a configuration in MemoMark before processing for the first time.")

        let statusTitle: String
        let statusMessage: String
        let footer: String
        let buttonTitle: String
        if !input.configurationIsReady {
            statusTitle = localized("需要先完成配置", english: "Configuration Required")
            statusMessage = localized("请先打开时光记，在配置中心保存当前记忆对象的配置。输出部分默认可不改；如果你改了输出设置，保存后也会并入当前配置。", english: "Open MemoMark and save the current memory configuration in Configuration Center. Output settings can stay as they are unless you want to change them.")
            footer = localized("配置保存完成后，再回到 Apple Photos 重新分享这批照片。", english: "Return to Apple Photos and share these photos again after saving.")
            buttonTitle = localized("打开时光记去配置", english: "Open MemoMark to Configure")
        } else if input.maximumPhotoCount == 0 {
            statusTitle = localized("免费成长记录已完成", english: "Free Records Completed")
            statusMessage = localized("请打开时光记了解 MemoMark+，继续记录未来的时光。", english: "Open MemoMark to learn about MemoMark+ and keep recording future memories.")
            footer = localized("已经生成的照片和配置不会受到影响。", english: "Existing photos and configurations are not affected.")
            buttonTitle = localized("打开时光记", english: "Open MemoMark")
        } else if input.photoCount
                    > input.maximumPhotoCount {
            statusTitle = localized("这次的照片有点多", english: "This Batch Is Too Large")
            statusMessage = MemoMarkLanguage.interfaceStored == .english
                ? "Good memories are easier to organize in smaller batches. You can share up to \(input.maximumPhotoCount) photos at a time."
                : "美好的记忆适合慢慢整理。当前最多分享 \(input.maximumPhotoCount) 张，可以分几次完成。"
            footer = localized("少量分批处理，也能让每一张照片更稳定地回到 Apple Photos。", english: "Smaller batches help each photo return to Apple Photos reliably.")
            buttonTitle = localized("返回分批分享", english: "Share in Smaller Batches")
        } else if input.photoCount > 0 {
            statusTitle = localized("后台处理", english: "Background Processing")
            statusMessage = [
                localized("原图保持不变", english: "Original stays unchanged"),
                localized("保留拍摄信息", english: "Capture information preserved"),
                localized("完成后发送通知", english: "Notification when complete"),
                localized("可以继续分享下一批", english: "You can share another batch")
            ].joined(separator: "\n")
            footer = ""
            buttonTitle = localized("生成时光记录", english: "Create Memory Record")
        } else {
            statusTitle = localized("暂不支持这类内容", english: "This Content Is Not Supported")
            statusMessage = PhotoMemoShareExtensionError.noSupportedImages
                .errorDescription ?? localized("没有可处理的照片。", english: "There are no processable photos.")
            footer = PhotoMemoShareExtensionError.noSupportedImages
                .recoverySuggestion
            buttonTitle = localized("关闭", english: "Close")
        }

        return .init(
            state: .confirming,
            animatesActivity: false,
            hidesPreview: true,
            hidesSummary: input.photoCount == 0,
            resetsContentPresentation: false,
            title: title,
            subtitle: subtitle,
            statusTitle: statusTitle,
            statusMessage: statusMessage,
            statusColor: .secondaryLabel,
            showsProcessingChecklist:
                input.configurationIsReady
                && input.photoCount > 0
                && input.maximumPhotoCount > 0
                && input.photoCount <=
                    input.maximumPhotoCount,
            footer: footer,
            buttonTitle: buttonTitle,
            buttonIsEnabled: true,
            accessibilityAnnouncement: nil
        )
    }

    private func localized(
        _ simplifiedChinese: String,
        english: String
    ) -> String {
        MemoMarkLanguage.interfaceStored == .english
            ? english
            : simplifiedChinese
    }
}
#endif
