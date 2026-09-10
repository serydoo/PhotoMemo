# MemoMark macOS Native Parity Plan

Date: 2026-09-10
Primary loop: Product Loop with an Engineering Loop verification gate
Scope: macOS Configuration Center shell and its iOS-parity editing surface

## Decision

MemoMark macOS should be a native large-canvas Configuration Center, not an
iOS layout enlarged to fill a Mac window and not a new batch workbench.

The selected interaction model is:

`summary cards -> popover selection -> persistent preview -> trailing Inspector`

with a modal Sheet reserved for a complete Memory Object edit or another
focused flow that must temporarily own the parent window. The preview remains
the real Memory Card and remains visible while the lower configuration area is
edited. The iOS surface keeps its compact, gesture-first presentation; iPadOS
uses a split-capable surface; macOS uses the available width, keyboard, menu,
popover, and Inspector capabilities.

This decision follows Apple's macOS guidance to use large displays for more
content with fewer nested levels, use the menu bar and standard shortcuts, and
support resizable windows and focused keyboard work. It also follows the
documented distinction that a popover is transient, a macOS Sheet is modal,
and a trailing Inspector is appropriate for repeated detail editing while the
main content remains available.

## Evidence and pattern comparison

| Reference | Useful observed pattern | MemoMark application | Not copied |
| --- | --- | --- | --- |
| Apple Photos for Mac | A persistent viewer/editor relationship, an Info window, shortcut-driven editing, and context menus for item actions | Keep the real card preview visible, expose contextual module actions, and make the editor keyboard reachable | Photos' library and photo-editing IA; MemoMark remains a local-first memory presentation tool |
| Apple macOS system surfaces | Sidebars and split views are for peer navigation; inspectors and panels are for detail; toolbars and menus are stable command locations | Keep Configuration Center as the root, use explicit routes, and use a trailing Inspector for repeated Card Content and Time & Place edits | A deep sidebar hierarchy or a separate document browser that would change the frozen IA-002 product boundary |
| Things for Mac and iPad | The same task semantics adapt to Mac and iPad; the Mac surface adds keyboard shortcuts, sidebar visibility, navigation popovers, and type-to-find | Share domain/draft semantics while adding Mac commands and pointer affordances progressively | Things' task model, tagging, sync, and navigation hierarchy |

Sources used for the pattern review:

- [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos/)
- [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars)
- [Popovers](https://developer.apple.com/design/human-interface-guidelines/popovers)
- [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets)
- [Panels](https://developer.apple.com/design/human-interface-guidelines/panels)
- [Menus](https://developer.apple.com/design/human-interface-guidelines/menus)
- [Context menus](https://developer.apple.com/design/human-interface-guidelines/context-menus)
- [Undo and redo](https://developer.apple.com/design/human-interface-guidelines/undo-and-redo)
- [Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [SwiftUI Inspector](https://developer.apple.com/documentation/SwiftUI/View/inspector%28isPresented%3Acontent%3A%29)
- [SwiftUI inspector column width](https://developer.apple.com/documentation/swiftui/view/inspectorcolumnwidth%28min%3Aideal%3Amax%3A%29)
- [Things: Show and Hide Sidebar](https://culturedcode.com/things/support/articles/3238254/)
- [Things: Keyboard Shortcuts](https://culturedcode.com/things/support/articles/2785159/)
- [Photos for Mac: Keyboard Shortcuts and Gestures](https://support.apple.com/guide/photos/keyboard-shortcuts-and-gestures-pht9b4411b24/mac)

## Platform responsibility matrix

| Concern | iOS | iPadOS | macOS |
| --- | --- | --- | --- |
| Primary navigation | Compact root and gesture-first navigation | Split-capable navigation when width allows | Configuration Center window with explicit routes; do not add Home/Tasks/Output roots without a product decision |
| Memory Object / Preset | Full-width rows and sheets where appropriate | Sidebar or popover depending width | Equal-width summary cards; popover for browsing and selection; Sheet for complete object editing |
| Preview | Preview pinning during upward scroll | Persistent split/detail preview | Pinned real preview above scrolling configuration content; Inspector beside it for repeated edits |
| Card Content | UIKit/TextKit editor and module library | Same editor semantics with hardware keyboard support | Native macOS text fields, menus, context-menu removal, and trailing Inspector; draft and save transaction remain shared |
| Time and Place | Option rows and focused sheet | Split/detail or sheet | Option row opens trailing Inspector; values continue through the existing configuration coordinator |
| Temporary choices | Sheets/popovers according to size and task | Popovers when spacious, sheets when compact | Popovers for short selection; avoid using a popover as a hidden long-form editor |
| Persistence | Existing iOS configuration transaction | Shared configuration aggregate | Same aggregate save, dirty guard, reload projection, and failure status; no separate Mac persistence model |
| Undo and keyboard | System text editing and iPad keyboard conventions | System text editing and keyboard conventions | Command-Z/Shift-Command-Z and menu integration must cover structural draft edits before calling the editor complete |

## Current implementation status

Completed in the current bounded slice:

1. Memory Object and Preset are deterministic equal-width cards at the wide
   breakpoint, with full-row hit targets and accessibility identifiers.
2. Preview is the real shared Memory Card and is pinned while the lower
   configuration content scrolls.
3. Card Content is a four-region editor backed by `MemoryCardEditorDraft`.
   Text changes, module insertion, normalization, preview projection, dirty
   status, and aggregate save all remain on the existing ownership path.
4. Non-text module chips can be removed through a native macOS destructive
   context-menu action. The action normalizes the trailing text input and
   republishes the preview.
5. Card Content and Time & Place now use a resizable trailing SwiftUI
   Inspector. Memory Object and complete object editing continue to use the
   existing popover-to-Sheet transition.
6. The unsigned local macOS container fallback prevents a development build
   from confusing a missing App Group entitlement with a persistence failure;
   signed production behavior still prefers the App Group container.

## Next implementation order

### P1 — Finish the native editing contract

- Add undo registration for logical draft operations: text replacement,
  insertion, module removal, and preset-driven draft replacement. The undo
  boundary must be the draft/session, not the durable repository, so Cancel
  cannot write data and Save remains the only aggregate commit.
- Expose the same operations through the Mac Edit menu and standard
  Command-Z/Shift-Command-Z shortcuts. Labels should describe the operation,
  such as “撤销移除模块”.
- Add focus/reveal behavior when a region is opened from the preview or when a
  module is inserted. Do not create a second caret or a Renderer-owned input
  geometry path.

### P1 — Close accessibility and window behavior

- Verify the full keyboard loop through summary cards, option rows, text
  fields, menus, Inspector controls, Save, and Done.
- Verify VoiceOver labels for the four regions, module chips, destructive
  removal, dirty/saved/failure states, and the persistent preview.
- Add standard Show/Hide Inspector and Show/Hide Sidebar commands only where a
  real sidebar or Inspector exists; do not add decorative commands.
- Verify window resize, full-screen, Inspector resize/restore, and relaunch
  state on a real unlocked Mac.

### P1 — Persistence and recovery gate

- Exercise save, cancel, preset switching with dirty state, subject switching
  with dirty state, relaunch/reload, failed save, and retry.
- Confirm that preview-only projection never becomes a durable write without
  Save, and that original Photos assets remain untouched.
- Run the existing local configuration repository and aggregate reconciliation
  tests; add only focused regression coverage for new failure paths.

### Product decision required — Mac commerce

The shared Option List can mark paid expression styles, but the current
purchase view is iOS-only and the Mac and iOS bundles use different bundle
identifiers. Before implementing a Mac purchase sheet, decide whether Mac has
its own StoreKit product/entitlement surface or intentionally exposes a
different entitlement boundary. Until that decision is recorded, this is
`NOT VERIFIED`, not silently treated as parity.

### Engineering boundary — iOS stability

The macOS shell may reuse shared configuration and draft types, but changes to
shared persistence, Renderer, Layout Engine, PhotoKit, Share Extension, EXIF,
Live Photo, or original-photo protection require a separate scoped review and
paired iPhone 17 Pro Max evidence. A generic iOS build proves compilation only;
it does not prove iOS interaction or media acceptance.

## Acceptance definition

This plan is complete only when all of the following are evidenced:

- focused macOS tests and the relevant shared persistence tests pass;
- signed or unsigned local Mac build behavior is explicitly classified;
- generic `MemoMarkiOS` build passes after cross-platform changes;
- unlocked Mac CUA verifies the route, Inspector, keyboard, dirty/save/reload,
  accessibility identifiers, and resize behavior;
- paired iPhone 17 Pro Max verifies unchanged iOS behavior when shared code is
  touched;
- Photos permission, album output, original-photo protection, and any
  PhotoKit/Live Photo read-back claims are verified separately;
- no commit, push, sync, TestFlight, or App Store mutation is implied by this
  engineering plan.
