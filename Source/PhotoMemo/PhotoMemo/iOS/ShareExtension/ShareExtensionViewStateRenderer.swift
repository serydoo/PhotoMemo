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
    let statusStageTitle: String
    let statusSymbolName: String?
    let statusMessage: String
    let statusColor: UIColor
    let showsProcessingChecklist: Bool
    let footer: String
    let buttonTitle: String
    let buttonSystemImage: String
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
    let statusStageLabel: UILabel
    let statusSymbolView: UIImageView
    let statusMessageLabel: UILabel
    let statusChecklistStack: UIStackView
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
        bindings.statusSymbolView.isHidden =
            update.animatesActivity
            || update.statusSymbolName == nil
        bindings.statusSymbolView.image =
            update.statusSymbolName.flatMap {
                UIImage(systemName: $0)
            }
        bindings.statusSymbolView.tintColor = update.statusColor
        bindings.previewSectionView?.isHidden = update.hidesPreview
        bindings.summarySectionView?.isHidden = update.hidesSummary
        if update.resetsContentPresentation {
            bindings.contentStack.alpha = 1
            bindings.contentStack.transform = .identity
        }
        bindings.titleLabel.text = update.title
        bindings.subtitleLabel.text = update.subtitle
        bindings.statusTitleLabel.text = update.statusTitle
        bindings.statusStageLabel.text = update.statusStageTitle
        bindings.statusStageLabel.textColor = update.statusColor
        bindings.statusMessageLabel.textColor = update.statusColor
        bindings.statusChecklistStack.isHidden =
            !update.showsProcessingChecklist
        bindings.statusMessageLabel.isHidden =
            update.showsProcessingChecklist
        bindings.statusMessageLabel.attributedText = nil
        bindings.statusMessageLabel.text = update.statusMessage
        bindings.footerLabel.text = update.footer
        bindings.primaryButton.isEnabled = update.buttonIsEnabled
        bindings.primaryButton.configuration?.title = update.buttonTitle
        bindings.primaryButton.configuration?.image =
            UIImage(systemName: update.buttonSystemImage)
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
                title: normalTitle(input),
                subtitle: normalSubtitle(input),
                statusTitle: localized("处理状态", english: "Processing Status"),
                statusStageTitle: localized("正在接收照片", english: "Receiving Photos"),
                statusSymbolName: nil,
                statusMessage: "",
                statusColor: .secondaryLabel,
                showsProcessingChecklist: true,
                footer: "",
                buttonTitle: localized("正在提交", english: "Submitting"),
                buttonSystemImage: "hourglass",
                buttonIsEnabled: false,
                accessibilityAnnouncement:
                    localized(
                        "正在接收照片并准备后台处理",
                        english: "Receiving photos and preparing background processing"
                    )
            )
        case .received:
            return .init(
                state: .received,
                animatesActivity: false,
                hidesPreview: true,
                hidesSummary: input.photoCount == 0,
                resetsContentPresentation: false,
                title: normalTitle(input),
                subtitle: normalSubtitle(input),
                statusTitle: localized("处理状态", english: "Processing Status"),
                statusStageTitle: localized("已加入后台处理", english: "Submitted"),
                statusSymbolName: "checkmark.circle.fill",
                statusMessage: "",
                statusColor: .secondaryLabel,
                showsProcessingChecklist: true,
                footer: "",
                buttonTitle: localized("已提交", english: "Submitted"),
                buttonSystemImage: "checkmark",
                buttonIsEnabled: false,
                accessibilityAnnouncement:
                    localized(
                        "已加入后台处理",
                        english: "Submitted for background processing"
                    )
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
                statusTitle: localized("处理状态", english: "Processing Status"),
                statusStageTitle: title,
                statusSymbolName: "exclamationmark.circle.fill",
                statusMessage: message,
                statusColor: .systemOrange,
                showsProcessingChecklist: false,
                footer: suggestion,
                buttonTitle: localized("重新尝试", english: "Try Again"),
                buttonSystemImage: "arrow.clockwise",
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
                statusTitle: localized("处理状态", english: "Processing Status"),
                statusStageTitle: localized("需要重新交接", english: "Handoff Required"),
                statusSymbolName: "arrow.clockwise.circle.fill",
                statusMessage: localized("请点下面按钮再试一次；如果仍失败，请直接打开时光记，它会继续检查待处理照片。", english: "Tap below to try again. If it still fails, open MemoMark to check pending photos."),
                statusColor: .secondaryLabel,
                showsProcessingChecklist: false,
                footer: localized("原图已经接收，原始照片不会被修改。", english: "The originals were received and will not be modified."),
                buttonTitle: localized("重新交给时光记", english: "Hand Off to MemoMark Again"),
                buttonSystemImage: "arrow.clockwise",
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
            bindings.statusStageLabel.text =
                localized("正在读取 iCloud 原图", english: "Reading iCloud Original")
            bindings.primaryButton.configuration?.title =
                localized("正在提交", english: "Submitting")
        case .sourceReady:
            bindings.statusStageLabel.text =
                localized("正在接收照片", english: "Receiving Photos")
            bindings.primaryButton.configuration?.title =
                localized("正在提交", english: "Submitting")
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

    private func confirmingUpdate(
        _ input: ShareExtensionViewStateInput
    ) -> ShareExtensionViewStateUpdate {
        let isNormalConfirmation =
            input.configurationIsReady
            && input.photoCount > 0
            && input.maximumPhotoCount > 0
            && input.photoCount <= input.maximumPhotoCount

        let statusStageTitle: String
        let statusSymbolName: String
        let statusMessage: String
        let footer: String
        let buttonTitle: String
        let buttonSystemImage: String
        if !input.configurationIsReady {
            statusStageTitle = localized("需要先完成配置", english: "Configuration Required")
            statusSymbolName = "exclamationmark.circle.fill"
            statusMessage = localized("请先打开时光记，在配置中心保存当前记忆对象的配置。输出部分默认可不改；如果你改了输出设置，保存后也会并入当前配置。", english: "Open MemoMark and save the current memory configuration in Configuration Center. Output settings can stay as they are unless you want to change them.")
            footer = localized("配置保存完成后，再回到 Apple Photos 重新分享这批照片。", english: "Return to Apple Photos and share these photos again after saving.")
            buttonTitle = localized("打开时光记去配置", english: "Open MemoMark to Configure")
            buttonSystemImage = "arrow.up.forward.app"
        } else if input.maximumPhotoCount == 0 {
            statusStageTitle = localized("免费成长记录已完成", english: "Free Records Completed")
            statusSymbolName = "checkmark.circle.fill"
            statusMessage = localized("请打开时光记了解 MemoMark+，继续记录未来的时光。", english: "Open MemoMark to learn about MemoMark+ and keep recording future memories.")
            footer = localized("已经生成的照片和配置不会受到影响。", english: "Existing photos and configurations are not affected.")
            buttonTitle = localized("打开时光记", english: "Open MemoMark")
            buttonSystemImage = "arrow.up.forward.app"
        } else if input.photoCount
                    > input.maximumPhotoCount {
            statusStageTitle = localized("这次的照片有点多", english: "This Batch Is Too Large")
            statusSymbolName = "exclamationmark.circle.fill"
            statusMessage = MemoMarkLanguage.interfaceStored == .english
                ? "Good memories are easier to organize in smaller batches. You can share up to \(input.maximumPhotoCount) photos at a time."
                : "美好的记忆适合慢慢整理。当前最多分享 \(input.maximumPhotoCount) 张，可以分几次完成。"
            footer = localized("少量分批处理，也能让每一张照片更稳定地回到 Apple Photos。", english: "Smaller batches help each photo return to Apple Photos reliably.")
            buttonTitle = localized("返回分批分享", english: "Share in Smaller Batches")
            buttonSystemImage = "arrow.uturn.backward"
        } else if input.photoCount > 0 {
            statusStageTitle = localized("等待开始", english: "Waiting")
            statusSymbolName = "circle"
            statusMessage = ""
            footer = ""
            buttonTitle = localized("生成时光记录", english: "Create Memory Record")
            buttonSystemImage = "sparkles"
        } else {
            statusStageTitle = localized("暂不支持这类内容", english: "This Content Is Not Supported")
            statusSymbolName = "xmark.circle.fill"
            statusMessage = PhotoMemoShareExtensionError.noSupportedImages
                .errorDescription ?? localized("没有可处理的照片。", english: "There are no processable photos.")
            footer = PhotoMemoShareExtensionError.noSupportedImages
                .recoverySuggestion
            buttonTitle = localized("关闭", english: "Close")
            buttonSystemImage = "xmark"
        }

        return .init(
            state: .confirming,
            animatesActivity: false,
            hidesPreview: true,
            hidesSummary: input.photoCount == 0,
            resetsContentPresentation: false,
            title: normalTitle(input),
            subtitle: normalSubtitle(input),
            statusTitle: localized("处理状态", english: "Processing Status"),
            statusStageTitle: statusStageTitle,
            statusSymbolName: statusSymbolName,
            statusMessage: statusMessage,
            statusColor: .secondaryLabel,
            showsProcessingChecklist: isNormalConfirmation,
            footer: footer,
            buttonTitle: buttonTitle,
            buttonSystemImage: buttonSystemImage,
            buttonIsEnabled: true,
            accessibilityAnnouncement: nil
        )
    }

    private func normalTitle(
        _ input: ShareExtensionViewStateInput
    ) -> String {
        input.photoCount > 0
            ? localized("已准备好", english: "Ready")
            : localized(
                "这次分享里没有可处理照片",
                english: "No Processable Photos"
            )
    }

    private func normalSubtitle(
        _ input: ShareExtensionViewStateInput
    ) -> String {
        guard input.configurationIsReady else {
            return localized(
                "首次处理前，需要先在时光记里保存一个配置。",
                english: "Save a configuration in MemoMark before processing for the first time."
            )
        }
        guard input.photoCount > 0 else {
            return localized(
                "当前内容里没有可直接处理的照片。",
                english: "There are no photos ready to process."
            )
        }
        return MemoMarkLanguage.interfaceStored.localized(
            key: "share.ready.subtitle",
            fallback: "准备记录这段时光"
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
