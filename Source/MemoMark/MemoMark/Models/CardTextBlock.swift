import Foundation

enum CardTextArea: String, Hashable {

    case leftTop

    case leftBottom

    case rightTop

    case rightBottom

    case badge
}

struct CardTextBlock: Identifiable, Hashable {

    let id: UUID

    var title: String

    var value: String

    var area: CardTextArea

    init(
        id: UUID = UUID(),
        title: String,
        value: String,
        area: CardTextArea
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.area = area
    }
}
