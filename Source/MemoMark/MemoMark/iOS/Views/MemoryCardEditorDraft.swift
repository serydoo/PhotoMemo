#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct MemoryCardEditorDraft: Hashable {
    var items: [MemoryCardContentItem]

    var modules: [MemoryCardContentItem] {
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
        _ item: MemoryCardContentItem,
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

        let item = MemoryCardContentItem.text(text)
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

        let item = MemoryCardContentItem.text(text)
        items.append(item)
        return item.id
    }

    mutating func appendComposedItem(
        _ item: MemoryCardContentItem
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
        _ item: MemoryCardContentItem,
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

struct MemoryCardContentItem: Identifiable, Hashable, Codable {

    enum Kind: Hashable, Codable {
        case text
        case token
        case separator
        case lineBreak
    }

    let id: UUID
    let sourceItemID: UUID?
    let kind: Kind
    var title: String
    var value: String
    var savedValue: String
    var systemImage: String

    nonisolated init(
        id: UUID,
        sourceItemID: UUID? = nil,
        kind: Kind,
        title: String,
        value: String,
        savedValue: String,
        systemImage: String
    ) {
        self.id = id
        self.sourceItemID = sourceItemID
        self.kind = kind
        self.title = title
        self.value = value
        self.savedValue = savedValue
        self.systemImage = systemImage
    }

    var displayValue: String {
        switch kind {
        case .text, .token, .separator:
            return value
        case .lineBreak:
            return "\n"
        }
    }

    var templateValue: String {
        switch kind {
        case .text, .separator:
            return value
        case .token:
            return savedValue
        case .lineBreak:
            return "\n"
        }
    }

    static func text(_ value: String) -> MemoryCardContentItem {
        MemoryCardContentItem(
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
    ) -> MemoryCardContentItem {
        MemoryCardContentItem(
            id: UUID(),
            kind: .token,
            title: title,
            value: value,
            savedValue: templateValue,
            systemImage: systemImage
        )
    }

    static func separator(_ value: String) -> MemoryCardContentItem {
        MemoryCardContentItem(
            id: UUID(),
            kind: .separator,
            title: "分隔符",
            value: value,
            savedValue: value,
            systemImage: "circle.fill"
        )
    }

    /// The persisted expression is the module's stable identity. The title,
    /// value, and icon remain presentation projections and may be refreshed
    /// when interface language or resolver data changes.
    var canonicalModuleExpression: String? {
        guard kind == .token else { return nil }
        let expression = savedValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return expression.isEmpty ? nil : expression
    }

    /// Unknown token expressions remain editable objects instead of silently
    /// collapsing into plain text or an empty attachment.
    var isUnresolvedModule: Bool {
        guard kind == .token else { return false }
        guard let expression = canonicalModuleExpression else {
            return true
        }
        return MemoryCardTemplateTokenCatalog.module(
            matching: expression
        ) == nil
    }

    var editorModuleTitle: String {
        let title = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !title.isEmpty {
            return title
        }

        if let expression = canonicalModuleExpression,
           let tokenName = MemoryCardTemplateTokenCatalog.tokenName(
            from: expression
           ),
           !tokenName.isEmpty {
            return tokenName
        }

        return isUnresolvedModule ? "模块不可用" : "模块"
    }

    var editorModuleSystemImage: String {
        isUnresolvedModule
            ? "exclamationmark.triangle"
            : systemImage
    }

    var editorModuleAccessibilityLabel: String {
        if isUnresolvedModule {
            let expression = canonicalModuleExpression ?? "未知表达式"
            return "模块不可用，\(expression)"
        }
        return "\(editorModuleTitle)，\(value)"
    }

    /// Pasted modules receive new local identities so a paste never aliases
    /// the source item's UUID or source-region relationship.
    var copyingForInsertion: MemoryCardContentItem {
        MemoryCardContentItem(
            id: UUID(),
            sourceItemID: nil,
            kind: kind,
            title: title,
            value: value,
            savedValue: savedValue,
            systemImage: systemImage
        )
    }
}

struct MemoryCardEditorClipboardPayload: Codable, Hashable {
    static let schemaVersion = 1

    let schema: Int
    let items: [MemoryCardContentItem]

    init(
        items: [MemoryCardContentItem],
        schema: Int = MemoryCardEditorClipboardPayload.schemaVersion
    ) {
        self.schema = schema
        self.items = items
    }

    var displayText: String {
        MemoryCardEditorDraft(items: items).singleLineText
    }
}

enum MemoryCardEditorClipboardCodec {
    static func encode(
        _ payload: MemoryCardEditorClipboardPayload
    ) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(payload)
    }

    static func decode(
        _ data: Data
    ) -> MemoryCardEditorClipboardPayload? {
        guard let payload = try? JSONDecoder().decode(
            MemoryCardEditorClipboardPayload.self,
            from: data
        ),
        payload.schema == MemoryCardEditorClipboardPayload.schemaVersion,
        !payload.items.isEmpty else {
            return nil
        }
        return payload
    }
}

private extension MemoryCardContentItem.Kind {

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
