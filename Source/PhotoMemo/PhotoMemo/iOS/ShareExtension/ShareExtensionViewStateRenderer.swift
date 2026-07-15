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
        bindings.statusMessageLabel.text = update.statusMessage
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
                title: "正在交给时光记",
                subtitle: "正在安全接收这次分享。",
                statusTitle: "正在准备继续处理",
                statusMessage: "会先接收原图，再交给时光记主程序继续处理。",
                statusColor: .secondaryLabel,
                footer: "原始照片不会被修改。",
                buttonTitle: "正在接收",
                buttonIsEnabled: false,
                accessibilityAnnouncement: "正在安全接收照片并交给时光记"
            )
        case .received:
            return .init(
                state: .received,
                animatesActivity: false,
                hidesPreview: true,
                hidesSummary: input.photoCount == 0,
                resetsContentPresentation: false,
                title: "已交给时光记",
                subtitle: "时光记会继续处理，并把结果写回系统相册。",
                statusTitle: "后续进度会在时光记中显示",
                statusMessage: "如果系统没有自动切换，可手动打开时光记查看处理状态。",
                statusColor: .secondaryLabel,
                footer: "处理完成后会发送系统通知。现在可以关闭这个窗口。",
                buttonTitle: "关闭",
                buttonIsEnabled: true,
                accessibilityAnnouncement: nil
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
                footer: "原图已经接收，原始照片不会被修改。",
                buttonTitle: "重新交给时光记",
                buttonIsEnabled: true,
                accessibilityAnnouncement: nil
            )
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
        return "已接收 \(result.requestedCount) 张，正在交给时光记继续处理。"
    }

    func detailedFailureMessage(
        for error: PhotoMemoShareExtensionError
    ) -> String {
        if let diagnosticSummary = error.diagnosticSummaryLine {
            return "\(error.errorDescription ?? "这次分享没有完成。")\n\n\(diagnosticSummary)"
        }
        return error.errorDescription ?? "这次分享没有完成。"
    }

    func detailedSuggestion(
        for error: PhotoMemoShareExtensionError
    ) -> String {
        if let errorSummary = error.resolvedFailureContext?.errorSummary {
            return "\(error.recoverySuggestion)\n\nNSError: \(errorSummary.domain) / \(errorSummary.code)"
        }
        return error.recoverySuggestion
    }

    private func confirmingUpdate(
        _ input: ShareExtensionViewStateInput
    ) -> ShareExtensionViewStateUpdate {
        let title = input.photoCount > 0
            ? "检测到 \(input.photoCount) 张可处理照片"
            : "这次分享里没有可处理照片"
        let subtitle = input.configurationIsReady
            ? (input.photoCount > 0
                ? "时光记会按当前配置继续处理，并把结果写回系统相册。"
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
            statusTitle = "准备交给时光记"
            statusMessage = "点击后会继续交给主程序，进度可在时光记或锁屏中查看。"
            footer = "处理完成后会发送系统通知。你不需要停留在这里。"
            buttonTitle = "交给时光记处理 \(input.photoCount) 张"
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
            footer: footer,
            buttonTitle: buttonTitle,
            buttonIsEnabled: true,
            accessibilityAnnouncement: nil
        )
    }
}
#endif
