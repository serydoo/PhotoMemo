import Foundation

struct AnchorResult: Hashable {

    let title: String

    let primaryText: String

    let secondaryText: String

    init(
        title: String,
        primaryText: String,
        secondaryText: String
    ) {
        self.title = title
        self.primaryText = primaryText
        self.secondaryText = secondaryText
    }
}
