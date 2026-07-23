#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1EditorDraft: Hashable {
    var items: [V1ContentItem]

    var modules: [V1ContentItem] {
        items.filter { $0.kind != .text }
    }

    var singleLineText: String {
        InlineContentTextComposer.compose(
            items.map { item in
                InlineContentTextComposer.Piece(
                    kind: item.kind.inlineComposerKind,
                    value: item.displayValue
                )
            }
        )
    }

    var singleLineTemplateText: String {
        InlineContentTextComposer.compose(
            items.map { item in
                InlineContentTextComposer.Piece(
                    kind: item.kind.inlineComposerKind,
                    value: item.templateValue
                )
            }
        )
    }

    mutating func updateTextItem(
        _ item: V1ContentItem,
        text: String
    ) {
        guard let index =
            items.firstIndex(where: { $0.id == item.id })
        else {
            return
        }

        items[index].value = text
        items[index].savedValue = text
    }

    @discardableResult
    mutating func prependText(_ text: String) -> UUID? {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return nil
        }

        let item = V1ContentItem.text(text)
        items.insert(item, at: 0)
        return item.id
    }

    @discardableResult
    mutating func appendText(_ text: String) -> UUID? {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return nil
        }

        let item = V1ContentItem.text(text)
        items.append(item)
        return item.id
    }

    mutating func appendComposedItem(
        _ item: V1ContentItem
    ) {
        if let last = items.last,
           last.kind == .text,
           last.value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            items.insert(
                item,
                at: max(items.count - 1, 0)
            )
        } else {
            items.append(item)
        }

        normalizeTrailingTextInput()
    }

    mutating func insertComposedItem(
        _ item: V1ContentItem,
        after anchorID: UUID?
    ) {
        guard let anchorID,
              let anchorIndex =
                items.firstIndex(where: { $0.id == anchorID })
        else {
            appendComposedItem(item)
            return
        }

        let anchor = items[anchorIndex]
        let insertionIndex: Int

        if anchor.kind == .text,
           anchor.value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            insertionIndex = anchorIndex
        } else {
            insertionIndex = min(anchorIndex + 1, items.count)
        }

        items.insert(item, at: insertionIndex)
        normalizeTrailingTextInput()
    }

    mutating func normalizeTrailingTextInput() {
        while items.count > 1,
              let last = items.last,
              let previous = items.dropLast().last,
              last.kind == .text,
              previous.kind == .text,
              last.value
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty {
            items.removeLast()
        }

        if let last = items.last,
           last.kind != .text {
            items.append(.text(""))
        }
    }
}

struct V1ContentItem: Identifiable, Hashable {

    enum Kind: Hashable {
        case text
        case token
        case separator
        case lineBreak
    }

    let id: UUID
    let kind: Kind
    var title: String
    var value: String
    var savedValue: String
    var systemImage: String

    var displayValue: String {
        switch kind {
        case .text, .token, .separator:
            return value
        case .lineBreak:
            return " "
        }
    }

    var templateValue: String {
        switch kind {
        case .text, .separator:
            return value
        case .token:
            return savedValue
        case .lineBreak:
            return " "
        }
    }

    static func text(_ value: String) -> V1ContentItem {
        V1ContentItem(
            id: UUID(),
            kind: .text,
            title: "文字",
            value: value,
            savedValue: value,
            systemImage: MemoMarkSymbol.expressionFormula.name
        )
    }

    static func token(
        _ title: String,
        value: String,
        templateValue: String,
        systemImage: String
    ) -> V1ContentItem {
        V1ContentItem(
            id: UUID(),
            kind: .token,
            title: title,
            value: value,
            savedValue: templateValue,
            systemImage: systemImage
        )
    }

    static func separator(_ value: String) -> V1ContentItem {
        V1ContentItem(
            id: UUID(),
            kind: .separator,
            title: "分隔符",
            value: value,
            savedValue: value,
            systemImage: "circle.fill"
        )
    }
}

private extension V1ContentItem.Kind {

    var inlineComposerKind: InlineContentTextComposer.PieceKind {
        switch self {
        case .text:
            return .text
        case .token:
            return .token
        case .separator:
            return .separator
        case .lineBreak:
            return .lineBreak
        }
    }
}
#endif
