#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemoryTextBlock:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    var text: String

    init(
        id: UUID = UUID(),
        text: String
    ) {
        self.id = id
        self.text = text
    }
}

struct MemoryTokenBlock:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    var category: TokenCategory
    var title: String
    var value: String
    var isReserved: Bool

    init(
        id: UUID = UUID(),
        category: TokenCategory,
        title: String,
        value: String,
        isReserved: Bool = false
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.value = value
        self.isReserved = isReserved
    }

    var type: MemoryBlockType {
        category.blockType
    }
}

enum MemoryBlock:
    Identifiable,
    Codable,
    Hashable {

    case textBlock(MemoryTextBlock)
    case tokenBlock(MemoryTokenBlock)

    var id: UUID {
        switch self {
        case .textBlock(let block):
            return block.id
        case .tokenBlock(let block):
            return block.id
        }
    }

    var type: MemoryBlockType {
        switch self {
        case .textBlock:
            return .text
        case .tokenBlock(let block):
            return block.type
        }
    }

    var title: String {
        switch self {
        case .textBlock:
            return "文本"
        case .tokenBlock(let block):
            return block.title
        }
    }

    var value: String {
        switch self {
        case .textBlock(let block):
            return block.text
        case .tokenBlock(let block):
            return block.value
        }
    }

    var isReserved: Bool {
        switch self {
        case .textBlock:
            return false
        case .tokenBlock(let block):
            return block.isReserved
        }
    }

    init(
        id: UUID = UUID(),
        type: MemoryBlockType,
        title: String,
        value: String,
        isReserved: Bool = false
    ) {
        if let category = TokenCategory(blockType: type) {
            self = .tokenBlock(
                MemoryTokenBlock(
                    id: id,
                    category: category,
                    title: title,
                    value: value,
                    isReserved: isReserved
                )
            )
        } else {
            self = .textBlock(
                MemoryTextBlock(
                    id: id,
                    text: value
                )
            )
        }
    }

    static func text(
        _ value: String
    ) -> MemoryBlock {
        .textBlock(
            MemoryTextBlock(
                text: value
            )
        )
    }
}
#endif
