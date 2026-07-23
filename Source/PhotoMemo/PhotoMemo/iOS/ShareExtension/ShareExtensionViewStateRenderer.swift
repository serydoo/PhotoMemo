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
                title: "正在准备照片",
                subtitle: "这次分享会在后台继续处理。",
                statusTitle: "正在接收照片",
                statusMessage: "原图不会被修改。",
                statusColor: .secondaryLabel,
                showsProcessingChecklist: false,
                footer: "完成后会发送通知。",
                buttonTitle: "正在处理",
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
                title: "已开始处理",
                subtitle: "时光记会在后台继续处理这次分享。",
                statusTitle: "可以返回照片",
                statusMessage: "你可以继续分享下一批。",
                statusColor: .secondaryLabel,
                showsProcessingChecklist: false,
                footer: "完成后会发送通知。",
                buttonTitle: "已开始处理",
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
                title: "这次交接没有完成",
                subtitle: "可以直接重试；如果仍失败，再回到时光记查看。",
                statusTitle: title,
                statusMessage: message,
                statusColor: .systemOrange,
                showsProcessingChecklist: false,
                footer: suggestion,
                buttonTitle: "重新尝试",
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
                title: "照片已经接收",
                subtitle: "但这次没有顺利继续交给时光记。",
                statusTitle: "重新交给时光记",
                statusMessage: "请点下面按钮再试一次；如果仍失败，请直接打开时光记，它会继续检查待处理照片。",
                statusColor: .secondaryLabel,
                showsProcessingChecklist: false,
                footer: "原图已经接收，原始照片不会被修改。",
                buttonTitle: "重新交给时光记",
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
                "正在准备原图"
            bindings.subtitleLabel.text =
                "系统正在把 iCloud 原图准备到本地。"
            bindings.statusTitleLabel.text =
                "正在读取 iCloud 原图"
            bindings.statusMessageLabel.attributedText = nil
            bindings.statusMessageLabel.text =
                "原图准备好后会继续后台处理。"
            bindings.primaryButton.configuration?.title =
                "正在准备"
        case .sourceReady:
            bindings.titleLabel.text =
                "原图已可读取"
            bindings.subtitleLabel.text =
                "正在准备后台处理。"
            bindings.statusTitleLabel.text =
                "正在继续处理"
            bindings.statusMessageLabel.attributedText = nil
            bindings.statusMessageLabel.text =
                "照片已经可处理，完成后会发送通知。"
            bindings.primaryButton.configuration?.title =
                "正在处理"
        }
    }

    func successMessage(
        for result: PhotoMemoShareExtensionImportResult
    ) -> String {
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
            ("photo.stack.fill", "原图保持不变"),
            ("doc.badge.gearshape", "保留拍摄信息"),
            ("bell.fill", "完成后发送通知"),
            ("arrow.right.circle.fill", "可以继续分享下一批")
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
            ? "已准备好"
            : "这次分享里没有可处理照片"
        let subtitle = input.configurationIsReady
            ? (input.photoCount > 0
                ? "\(input.photoCount) 张照片准备开始记录"
                : "当前内容里没有可直接处理的照片。")
            : "首次处理前，需要先在时光记里保存一个配置。"

        let statusTitle: String
        let statusMessage: String
        let footer: String
        let buttonTitle: String
        if !input.configurationIsReady {
            statusTitle = "需要先完成配置"
            statusMessage = "请先打开时光记，在配置中心保存当前记忆对象的配置。输出部分默认可不改；如果你改了输出设置，保存后也会并入当前配置。"
            footer = "配置保存完成后，再回到 Apple Photos 重新分享这批照片。"
            buttonTitle = "打开时光记去配置"
        } else if input.photoCount
                    > PhotoMemoShareExtensionIntakeService.maxSupportedPhotoCount {
            statusTitle = "这次的照片有点多"
            statusMessage = "美好的记忆适合慢慢整理。每次最多分享 \(PhotoMemoShareExtensionIntakeService.maxSupportedPhotoCount) 张，可以分几次完成。"
            footer = "少量分批处理，也能让每一张照片更稳定地回到 Apple Photos。"
            buttonTitle = "返回分批分享"
        } else if input.photoCount > 0 {
            statusTitle = "后台处理"
            statusMessage = "原图保持不变\n保留拍摄信息\n完成后发送通知\n可以继续分享下一批"
            footer = ""
            buttonTitle = "生成时光记录"
        } else {
            statusTitle = "暂不支持这类内容"
            statusMessage = PhotoMemoShareExtensionError.noSupportedImages
                .errorDescription ?? "没有可处理的照片。"
            footer = PhotoMemoShareExtensionError.noSupportedImages
                .recoverySuggestion
            buttonTitle = "关闭"
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
                && input.photoCount <=
                    PhotoMemoShareExtensionIntakeService
                    .maxSupportedPhotoCount,
            footer: footer,
            buttonTitle: buttonTitle,
            buttonIsEnabled: true,
            accessibilityAnnouncement: nil
        )
    }
}
#endif
