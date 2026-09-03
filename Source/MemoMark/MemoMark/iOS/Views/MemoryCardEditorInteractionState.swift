#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Owns only transient editor interaction state.
///
/// This value never becomes a configuration, draft, preview, or persistence
/// source of truth. The command buses retain their existing reference identity
/// so each TextKit region keeps its command routing across SwiftUI updates.
@MainActor
struct MemoryCardEditorInteractionState {
    var activeModuleRegion: CardRegion?
    var focusedEditorRegion: CardRegion?
    var activeTextItemIDs: [CardRegion: UUID]
    var recentInsertionRegion: CardRegion?
    var recentInsertionItemID: UUID?

    let slotATextKitCommandBus: MemoryCardTextKitCommandBus
    let slotBTextKitCommandBus: MemoryCardTextKitCommandBus
    let slotCTextKitCommandBus: MemoryCardTextKitCommandBus
    let slotDTextKitCommandBus: MemoryCardTextKitCommandBus

    init() {
        activeModuleRegion = nil
        focusedEditorRegion = nil
        activeTextItemIDs = [:]
        recentInsertionRegion = nil
        recentInsertionItemID = nil
        slotATextKitCommandBus = MemoryCardTextKitCommandBus()
        slotBTextKitCommandBus = MemoryCardTextKitCommandBus()
        slotCTextKitCommandBus = MemoryCardTextKitCommandBus()
        slotDTextKitCommandBus = MemoryCardTextKitCommandBus()
    }

    mutating func clearInsertionContext() {
        recentInsertionRegion = nil
        recentInsertionItemID = nil
    }
}

#endif
