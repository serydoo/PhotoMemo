#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1DraftMutationItem: Identifiable, Hashable {

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

    nonisolated init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        value: String,
        savedValue: String? = nil,
        systemImage: String
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.value = value
        self.savedValue = savedValue ?? value
        self.systemImage = systemImage
    }

    nonisolated static func text(
        _ value: String,
        id: UUID = UUID()
    ) -> V1DraftMutationItem {
        V1DraftMutationItem(
            id: id,
            kind: .text,
            title: "文字",
            value: value,
            systemImage: "textformat"
        )
    }

    nonisolated static func token(
        title: String = "模块",
        value: String,
        templateValue: String,
        systemImage: String = "tag",
        id: UUID = UUID()
    ) -> V1DraftMutationItem {
        V1DraftMutationItem(
            id: id,
            kind: .token,
            title: title,
            value: value,
            savedValue: templateValue,
            systemImage: systemImage
        )
    }
}

struct V1DraftMutationDraft: Hashable {
    var items: [V1DraftMutationItem]

    mutating func updateTextItem(
        id: UUID,
        text: String
    ) {
        guard let index =
            items.firstIndex(where: { $0.id == id })
        else {
            return
        }

        items[index].value = text
        items[index].savedValue = text
    }

    @discardableResult
    mutating func prependText(
        _ text: String
    ) -> UUID? {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return nil
        }

        let item = V1DraftMutationItem.text(text)
        items.insert(item, at: 0)
        return item.id
    }

    @discardableResult
    mutating func appendText(
        _ text: String
    ) -> UUID? {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return nil
        }

        let item = V1DraftMutationItem.text(text)
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
        return item.id
    }

    mutating func appendComposedItem(
        _ item: V1DraftMutationItem
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
        _ item: V1DraftMutationItem,
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
              previous.value
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty,
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

struct V1DraftMutationCoordinator {

    struct State: Hashable {
        var regionDrafts: [CardRegion: V1DraftMutationDraft] = [:]
        var activeTextItemIDs: [CardRegion: UUID] = [:]
        var activeConfigurationMessage = ""
    }

    struct Update: Hashable {
        var state: State
        var dirtyRegions: Set<CardRegion>
    }

    static let dirtyStateMessage = "有未保存修改"

    static func draft(
        for region: CardRegion,
        state: State,
        makeDefaultDraft: (CardRegion) -> V1DraftMutationDraft
    ) -> V1DraftMutationDraft {
        state.regionDrafts[region]
        ?? makeDefaultDraft(region)
    }

    static func setActiveTextItem(
        _ itemID: UUID?,
        for region: CardRegion,
        in state: State
    ) -> State {
        var nextState = state
        nextState.activeTextItemIDs[region] = itemID
        return nextState
    }

    static func updateDraft(
        for region: CardRegion,
        in state: State,
        makeDefaultDraft: (CardRegion) -> V1DraftMutationDraft,
        transform: (inout V1DraftMutationDraft) -> Void
    ) -> Update {
        var nextState = state
        var draft =
            draft(
                for: region,
                state: state,
                makeDefaultDraft: makeDefaultDraft
            )
        transform(&draft)
        nextState.regionDrafts[region] = draft
        nextState.activeConfigurationMessage =
            dirtyStateMessage
        return Update(
            state: nextState,
            dirtyRegions: [region]
        )
    }

    static func updateTextItem(
        id: UUID,
        text: String,
        for region: CardRegion,
        in state: State,
        makeDefaultDraft: (CardRegion) -> V1DraftMutationDraft
    ) -> Update {
        var nextState = state
        nextState.activeTextItemIDs[region] = id
        return updateDraft(
            for: region,
            in: nextState,
            makeDefaultDraft: makeDefaultDraft
        ) { draft in
            draft.updateTextItem(
                id: id,
                text: text
            )
            draft.normalizeTrailingTextInput()
        }
    }

    static func prependText(
        _ text: String,
        for region: CardRegion,
        in state: State,
        makeDefaultDraft: (CardRegion) -> V1DraftMutationDraft
    ) -> Update {
        var insertedID: UUID?
        let update =
            updateDraft(
                for: region,
                in: state,
                makeDefaultDraft: makeDefaultDraft
            ) { draft in
                insertedID = draft.prependText(text)
                draft.normalizeTrailingTextInput()
            }

        guard let insertedID else {
            return update
        }

        var nextState = update.state
        nextState.activeTextItemIDs[region] = insertedID
        return Update(
            state: nextState,
            dirtyRegions: update.dirtyRegions
        )
    }

    static func appendText(
        _ text: String,
        for region: CardRegion,
        in state: State,
        makeDefaultDraft: (CardRegion) -> V1DraftMutationDraft
    ) -> Update {
        var insertedID: UUID?
        let update =
            updateDraft(
                for: region,
                in: state,
                makeDefaultDraft: makeDefaultDraft
            ) { draft in
                insertedID = draft.appendText(text)
                draft.normalizeTrailingTextInput()
            }

        guard let insertedID else {
            return update
        }

        var nextState = update.state
        nextState.activeTextItemIDs[region] = insertedID
        return Update(
            state: nextState,
            dirtyRegions: update.dirtyRegions
        )
    }

    static func removeItem(
        id: UUID,
        from region: CardRegion,
        in state: State,
        makeDefaultDraft: (CardRegion) -> V1DraftMutationDraft
    ) -> Update {
        updateDraft(
            for: region,
            in: state,
            makeDefaultDraft: makeDefaultDraft
        ) { draft in
            draft.items.removeAll { $0.id == id }
            draft.normalizeTrailingTextInput()
            if draft.items.count > 1,
               let last = draft.items.last,
               let previous =
                draft.items.dropLast().last,
               last.kind == .text,
               previous.kind == .text,
               last.value
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty {
                draft.items.removeLast()
            }
        }
    }

    static func insert(
        _ item: V1DraftMutationItem,
        into region: CardRegion,
        in state: State,
        makeDefaultDraft: (CardRegion) -> V1DraftMutationDraft
    ) -> Update {
        updateDraft(
            for: region,
            in: state,
            makeDefaultDraft: makeDefaultDraft
        ) { draft in
            draft.insertComposedItem(
                item,
                after: state.activeTextItemIDs[region]
            )
        }
    }
}
#endif
