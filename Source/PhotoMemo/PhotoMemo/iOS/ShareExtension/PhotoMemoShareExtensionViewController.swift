#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit

final class PhotoMemoShareExtensionViewController:
    UIViewController {

    private let intakeService =
        PhotoMemoShareExtensionIntakeService()

    private let activityIndicator =
        UIActivityIndicatorView(style: .large)

    private let messageLabel =
        UILabel()

    private var hasStarted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func viewDidAppear(
        _ animated: Bool
    ) {
        super.viewDidAppear(animated)

        guard !hasStarted else {
            return
        }

        hasStarted = true

        Task { @MainActor in
            await persistIncomingItems()
        }
    }
}

private extension PhotoMemoShareExtensionViewController {

    @MainActor
    func configureView() {

        view.backgroundColor =
            .systemBackground

        activityIndicator.translatesAutoresizingMaskIntoConstraints =
            false
        activityIndicator.startAnimating()

        messageLabel.translatesAutoresizingMaskIntoConstraints =
            false
        messageLabel.textAlignment =
            .center
        messageLabel.numberOfLines = 0
        messageLabel.font =
            .preferredFont(
                forTextStyle: .body
            )
        messageLabel.textColor =
            .secondaryLabel
        messageLabel.text =
            "正在交给 PhotoMemo 处理..."

        view.addSubview(
            activityIndicator
        )
        view.addSubview(
            messageLabel
        )

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor
                .constraint(
                    equalTo:
                        view.centerXAnchor
                ),
            activityIndicator.centerYAnchor
                .constraint(
                    equalTo:
                        view.centerYAnchor,
                    constant: -20
                ),
            messageLabel.topAnchor
                .constraint(
                    equalTo:
                        activityIndicator
                        .bottomAnchor,
                    constant: 16
                ),
            messageLabel.leadingAnchor
                .constraint(
                    equalTo:
                        view.leadingAnchor,
                    constant: 24
                ),
            messageLabel.trailingAnchor
                .constraint(
                    equalTo:
                        view.trailingAnchor,
                    constant: -24
                )
        ])
    }

    @MainActor
    func persistIncomingItems() async {

        guard
            let inputItems =
                extensionContext?
                .inputItems as? [NSExtensionItem]
        else {
            cancelExtension(
                message:
                    "无法读取这次分享的内容。"
            )
            return
        }

        do {
            let result =
                try await intakeService
                .persistSharedItems(
                    inputItems
                )

            messageLabel.text =
                successMessage(
                    for: result
                )

            extensionContext?
                .completeRequest(
                    returningItems: nil
                )
        } catch {
            cancelExtension(
                message:
                    (error as? LocalizedError)?
                    .errorDescription
                    ?? "无法把内容交给 PhotoMemo。"
            )
        }
    }

    func cancelExtension(
        message: String
    ) {

        messageLabel.text = message

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
                "成功 \(result.importedCount) 张"
            ]

            if result.skippedCount > 0 {
                summaryParts.append(
                    "跳过 \(result.skippedCount) 张"
                )
            }

            if result.failedCount > 0 {
                summaryParts.append(
                    "失败 \(result.failedCount) 张"
                )
            }

            return "已加入 PhotoMemo 收件箱（\(summaryParts.joined(separator: "，"))）。"
        }

        return "已加入 PhotoMemo 收件箱（\(result.importedCount) 张）。"
    }
}
#endif
