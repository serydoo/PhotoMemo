#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import UIKit

/// Stateless UIKit surface construction for the Share Extension. Lifecycle,
/// intake, state rendering, and accessibility value updates remain owned by
/// the view controller and its focused collaborators.
enum ShareExtensionSurfaceFactory {

    static func makeInsetDivider() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .separator
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

    static func makeTitledCardContainer(
        title: String,
        contentView: UIView
    ) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = MemoMarkDesignTokens.Typography.moduleTitle.uiFont()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        titleLabel.accessibilityTraits = .header
        return makeTitledCardContainer(
            headerView: titleLabel,
            contentView: contentView
        )
    }

    static func makeTitledSectionContainer(
        title: String,
        contentView: UIView
    ) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = MemoMarkDesignTokens.Typography.moduleTitle.uiFont()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        titleLabel.accessibilityTraits = .header
        return makeTitledSectionContainer(
            headerView: titleLabel,
            contentView: contentView
        )
    }

    static func makeTitledSectionContainer(
        headerView: UIView,
        contentView: UIView
    ) -> UIView {
        let stack = UIStackView(arrangedSubviews: [headerView, contentView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        return stack
    }

    static func makeTitledCardContainer(
        headerView: UIView,
        contentView: UIView
    ) -> UIView {
        let stack = UIStackView(arrangedSubviews: [headerView, contentView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        return makeCardContainer(
            contentView: stack,
            padding: MemoMarkDesignTokens.Layout.compactCardPadding
        )
    }

    static func makeInnerCardContainer(
        contentView: UIView
    ) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius =
            MemoMarkDesignTokens.Layout.compactInnerCardCornerRadius
        container.layer.cornerCurve = .continuous
        container.layer.borderColor =
            UIColor.separator.withAlphaComponent(0.35).cgColor
        container.layer.borderWidth = 1 / UIScreen.main.scale
        container.addSubview(contentView)

        let padding = MemoMarkDesignTokens.Layout.compactInnerCardPadding
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(
                equalTo: container.topAnchor,
                constant: padding
            ),
            contentView.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant: padding
            ),
            contentView.trailingAnchor.constraint(
                equalTo: container.trailingAnchor,
                constant: -padding
            ),
            contentView.bottomAnchor.constraint(
                equalTo: container.bottomAnchor,
                constant: -padding
            )
        ])
        return container
    }

    static func makeCardContainer(
        contentView: UIView,
        padding: CGFloat = MemoMarkDesignTokens.Layout.compactCardPadding
    ) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius =
            MemoMarkDesignTokens.Layout.compactCardCornerRadius
        container.layer.cornerCurve = .continuous
        container.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(
                equalTo: container.topAnchor,
                constant: padding
            ),
            contentView.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant: padding
            ),
            contentView.trailingAnchor.constraint(
                equalTo: container.trailingAnchor,
                constant: -padding
            ),
            contentView.bottomAnchor.constraint(
                equalTo: container.bottomAnchor,
                constant: -padding
            )
        ])
        return container
    }
}
#endif
