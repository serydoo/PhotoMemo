#if os(iOS) && MEMOMARK_SHARE_EXTENSION
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
                statusTitle: localized("share.status.title", fallback: "Processing Status"),
                statusStageTitle: localized("share.status.stage.receiving", fallback: "Receiving Photos"),
                statusSymbolName: nil,
                statusMessage: "",
                statusColor: .label,
                showsProcessingChecklist: true,
                footer: "",
                buttonTitle: localized("share.status.button.submitting", fallback: "Submitting"),
                buttonSystemImage: "hourglass",
                buttonIsEnabled: false,
                accessibilityAnnouncement:
                    localized(
                        "share.status.stage.receiving",
                        fallback: "Receiving photos and preparing background processing"
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
                statusTitle: localized("share.status.title", fallback: "Processing Status"),
                statusStageTitle: localized("share.status.stage.submitted", fallback: "Submitted"),
                statusSymbolName: "checkmark.circle.fill",
                statusMessage: "",
                statusColor: .label,
                showsProcessingChecklist: true,
                footer: "",
                buttonTitle: localized("share.status.button.submitted", fallback: "Submitted"),
                buttonSystemImage: "checkmark",
                buttonIsEnabled: false,
                accessibilityAnnouncement:
                    localized(
                        "share.status.stage.submitted",
                        fallback: "Submitted for background processing"
                    )
            )
        case .failed(let title, let message, let suggestion):
            return .init(
                state: input.state,
                animatesActivity: false,
                hidesPreview: true,
                hidesSummary: input.photoCount == 0,
                resetsContentPresentation: false,
                title: localized("share.error.handoff.title", fallback: "Handoff Did Not Finish"),
                subtitle: localized("share.error.handoff.recovery", fallback: "Retry now. If it still fails, open MemoMark to check the handoff."),
                statusTitle: localized("share.status.title", fallback: "Processing Status"),
                statusStageTitle: title,
                statusSymbolName: "exclamationmark.circle.fill",
                statusMessage: message,
                statusColor: .systemOrange,
                showsProcessingChecklist: false,
                footer: suggestion,
                buttonTitle: localized("share.status.button.try_again", fallback: "Try Again"),
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
                title: localized(
                    "share.error.handoff.title",
                    fallback: "照片已经接收"
                ),
                subtitle: localized(
                    "share.error.handoff.recovery",
                    fallback: "后台处理还没有开始。"
                ),
                statusTitle: localized(
                    "share.status.title",
                    fallback: "处理状态"
                ),
                statusStageTitle: localized(
                    "share.status.stage.continuing",
                    fallback: "需要重新交接"
                ),
                statusSymbolName: "arrow.clockwise.circle.fill",
                statusMessage: localized(
                    "share.error.handoff.message",
                    fallback: "照片已经接收，需要打开时光记继续处理。"
                ),
                statusColor: .secondaryLabel,
                showsProcessingChecklist: false,
                footer: localized(
                    "share.error.handoff.recovery",
                    fallback: "原图已经接收，原始照片不会被修改。"
                ),
                buttonTitle: localized(
                    "share.status.button.open_app",
                    fallback: "重新交给时光记"
                ),
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
                localized("share.reading_icloud_original", fallback: "Reading iCloud Original")
            bindings.primaryButton.configuration?.title =
                localized("share.status.button.submitting", fallback: "Submitting")
        case .sourceReady:
            bindings.statusStageLabel.text =
                localized("share.status.stage.receiving", fallback: "Receiving Photos")
            bindings.primaryButton.configuration?.title =
                localized("share.status.button.submitting", fallback: "Submitting")
        }
    }

    func successMessage(
        for result: MemoMarkShareExtensionImportResult
    ) -> String {
        guard result.hasWarnings else {
            return formatted(
                "share.success.completed_format",
                fallback: "Received %lld photos. Processing in the background.",
                Int64(result.requestedCount)
            )
        }

        var summaryParts = [
            formatted(
                "share.success.received_format",
                fallback: "Received %lld of %lld photos",
                Int64(result.importedCount),
                Int64(result.requestedCount)
            )
        ]
        if result.skippedCount > 0 {
            summaryParts.append(
                formatted(
                    "share.success.skipped_format",
                    fallback: "%lld skipped",
                    Int64(result.skippedCount)
                )
            )
        }
        if result.failedCount > 0 {
            summaryParts.append(
                formatted(
                    "share.success.failed_format",
                    fallback: "%lld not received",
                    Int64(result.failedCount)
                )
            )
        }
        if result.livePhotoStaticFallbackCount > 0 {
            summaryParts.append(
                formatted(
                    "share.success.live_photo_still_format",
                    fallback: "%lld Live Photos received as still images",
                    Int64(result.livePhotoStaticFallbackCount)
                )
            )
        }
        return formatted(
            "share.success.warning_format",
            fallback: "%@. %@",
            summaryParts.joined(
                separator: localized(
                    "share.success.separator",
                    fallback: ", "
                )
            ),
            localized(
                "share.success.remaining_note",
                fallback: "MemoMark will explain any remaining items."
            )
        )
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
            statusStageTitle = localized("share.status.stage.configuration_required", fallback: "Configuration Required")
            statusSymbolName = "exclamationmark.circle.fill"
            statusMessage = localized("share.status.message.configuration_required", fallback: "Open MemoMark and save the current memory configuration in Configuration Center.")
            footer = localized("share.status.footer.configuration_required", fallback: "Return to Apple Photos and share these photos again after saving.")
            buttonTitle = localized("share.status.button.configure", fallback: "Open MemoMark to Configure")
            buttonSystemImage = "arrow.up.forward.app"
        } else if input.maximumPhotoCount == 0 {
            statusStageTitle = localized("share.status.stage.free_records_completed", fallback: "Free Records Completed")
            statusSymbolName = "checkmark.circle.fill"
            statusMessage = localized("share.status.message.free_records_completed", fallback: "Open MemoMark to learn about MemoMark+ and keep recording future memories.")
            footer = localized("share.status.footer.free_records_completed", fallback: "Existing photos and configurations are not affected.")
            buttonTitle = localized("share.status.button.open_app", fallback: "Open MemoMark")
            buttonSystemImage = "arrow.up.forward.app"
        } else if input.photoCount
                    > input.maximumPhotoCount {
            statusStageTitle = localized("share.status.stage.batch_too_large", fallback: "This Batch Is Too Large")
            statusSymbolName = "exclamationmark.circle.fill"
            statusMessage = formatted(
                "share.status.message.batch_too_large",
                fallback: "Good memories are easier to organize in smaller batches. You can share up to %lld photos at a time.",
                Int64(input.maximumPhotoCount)
            )
            footer = localized("share.status.footer.batch_too_large", fallback: "Smaller batches help each photo return to Apple Photos reliably.")
            buttonTitle = localized("share.status.button.share_smaller_batches", fallback: "Share in Smaller Batches")
            buttonSystemImage = "arrow.uturn.backward"
        } else if input.photoCount > 0 {
            statusStageTitle = localized("share.status.stage.waiting", fallback: "Waiting")
            statusSymbolName = "circle"
            statusMessage = ""
            footer = ""
            buttonTitle = localized("share.status.button.create_record", fallback: "Start Recording")
            buttonSystemImage = "sparkles"
        } else {
            statusStageTitle = localized("share.status.stage.unsupported", fallback: "This Content Is Not Supported")
            statusSymbolName = "xmark.circle.fill"
            statusMessage = MemoMarkShareExtensionError.noSupportedImages
                .localizedDescription(for: .interfaceStored)
            footer = MemoMarkShareExtensionError.noSupportedImages
                .localizedRecoverySuggestion(for: .interfaceStored)
            buttonTitle = localized("share.status.button.close", fallback: "Close")
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
            statusTitle: localized("share.status.title", fallback: "Processing Status"),
            statusStageTitle: statusStageTitle,
            statusSymbolName: statusSymbolName,
            statusMessage: statusMessage,
            statusColor: isNormalConfirmation
                ? .label
                : .secondaryLabel,
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
            ? localized("share.title.ready", fallback: "Ready")
            : localized("share.title.no_photos", fallback: "No Processable Photos")
    }

    private func normalSubtitle(
        _ input: ShareExtensionViewStateInput
    ) -> String {
        guard input.configurationIsReady else {
            return localized(
                "share.no_configuration.subtitle",
                fallback: "Save a configuration in MemoMark before processing for the first time."
            )
        }
        guard input.photoCount > 0 else {
            return localized(
                "share.subtitle.no_photos",
                fallback: "There are no photos ready to process."
            )
        }
        return MemoMarkLanguage.interfaceStored.localized(
            key: "share.ready.subtitle",
            fallback: "准备记录这段时光"
        )
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: key,
            fallback: fallback
        )
    }

    private func formatted(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: localized(key, fallback: fallback),
            locale: MemoMarkLanguage.interfaceStored.locale,
            arguments: arguments
        )
    }
}
#endif
