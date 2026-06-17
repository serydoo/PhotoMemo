import Foundation

struct CardTextBlock: Identifiable, Hashable {

    let id: UUID

    var title: String

    var value: String

    var area: String

    init(
        id: UUID = UUID(),
        title: String,
        value: String,
        area: String
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.area = area
    }
}
