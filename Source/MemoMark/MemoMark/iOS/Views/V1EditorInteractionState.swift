#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Owns only transient editor interaction state.
///
/// This value never becomes a configuration, draft, preview, or persistence
/// source of truth. The command buses retain their existing reference identity
/// so each TextKit region keeps its command routing across SwiftUI updates.
@MainActor
struct V1EditorInteractionState {
    var activeModuleRegion: CardRegion?
    var focusedEditorRegion: CardRegion?
    var activeTextItemIDs: [CardRegion: UUID]
    var recentInsertionRegion: CardRegion?
    var recentInsertionItemID: UUID?

    let slotATextKitCommandBus: V1TextKitCommandBus
    let slotBTextKitCommandBus: V1TextKitCommandBus
    let slotCTextKitCommandBus: V1TextKitCommandBus
    let slotDTextKitCommandBus: V1TextKitCommandBus

    init() {
        activeModuleRegion = nil
        focusedEditorRegion = nil
        activeTextItemIDs = [:]
        recentInsertionRegion = nil
        recentInsertionItemID = nil
        slotATextKitCommandBus = V1TextKitCommandBus()
        slotBTextKitCommandBus = V1TextKitCommandBus()
        slotCTextKitCommandBus = V1TextKitCommandBus()
        slotDTextKitCommandBus = V1TextKitCommandBus()
    }

    mutating func clearInsertionContext() {
        recentInsertionRegion = nil
        recentInsertionItemID = nil
    }
}
#endif
