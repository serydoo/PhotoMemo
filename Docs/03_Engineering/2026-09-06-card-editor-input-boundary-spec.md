# Card Editor Input Boundary And System Entry Specification

## Decision gate

- Primary loop: Product Loop, with P1 interaction and accessibility risk.
- Observed scenario: the Memory Card editor currently estimates its upper edge
  from the host screen height. When the real preview changes height, the editor
  can overlap the preview or leave an arbitrary gap. TextKit inputs also need a
  bounded accessibility-size path and a safe boundary around IME composition.
- Source of truth: the real preview frame, the shared editor-input geometry
  standard, and the existing `MemoryCardTextKitEditorSession` ownership model.
- Apple-native capabilities evaluated: SwiftUI preference geometry,
  `DynamicTypeSize`, UIKit/TextKit marked-text state, native undo, paste, and
  accessibility labels.
- Risk level: P1. No persistence, renderer, export, PhotoKit, or memory-truth
  behavior is in scope.

## Accepted behavior

1. The card-content editor sheet begins below the measured real preview, with a
   small shared gap. A conservative legacy estimate remains only as a startup
   fallback before the first preview measurement arrives.
2. The preview remains visible and has the highest visual weight. The editor
   never changes preview construction or renderer output.
3. The four slot editors and module library remain compact at the default text
   size. Accessibility text sizes receive a bounded larger line/module surface;
   no screenshot-derived per-region offsets are introduced.
4. TextKit remains the owner of the caret, selection, IME, undo, and atomic
   module editing. Structured insertion, paste, and attachment deletion do not
   mutate the attributed document while marked text is active.
5. Visible slot titles and VoiceOver labels use the same localized semantic
   names. Existing custom text and module-capsule behavior is preserved.
6. The photo-description field keeps the native SwiftUI text-input path and
   exposes focus state without changing its persisted meaning.

## Verification plan

- Run the focused architecture/source contracts on macOS.
- Build the `MemoMarkiOS` scheme for the paired physical iPhone 17 Pro Max.
- Install and launch the signed build without erasing app data.
- On device, verify the editor boundary against the real preview, all four slot
  fields, module insertion, IME composition, pull dismissal, accessibility-size
  layout, and photo-description focus/save behavior.
- Treat device launch as deployment evidence; keep visual, VoiceOver, Apple
  Photos, and release certification as separate acceptance evidence.

## Explicit non-goals

- No Renderer/Layout Engine rewrite.
- No PhotoKit, Share Extension, persistence, or output-policy change.
- No new editor feature surface beyond the bounded input and layout contracts.
