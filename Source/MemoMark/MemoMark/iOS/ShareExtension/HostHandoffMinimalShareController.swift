#if os(iOS) && DEBUG && MEMOMARK_HOST_HANDOFF_MINIMAL && MEMOMARK_SHARE_EXTENSION
import UIKit

/// Same extension entry point, isolated by a build condition. Never loads provider data.
final class MemoMarkShareExtensionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let button = UIButton(type: .system)
        button.setTitle("开始记录", for: .normal)
        button.accessibilityIdentifier = "host-handoff-isolated-submit"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(submit), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func submit() {
        guard #available(iOS 26.0, *) else { return }
        let count = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .reduce(0) { $0 + ($1.attachments?.count ?? 0) }
        Task { @MainActor in
            _ = await HostHandoffMinimalProbe.submitFromExtension(itemCount: count)
            HostHandoffMinimalProbe.recordDismissal()
            extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
#endif
