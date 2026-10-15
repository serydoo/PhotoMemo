# Configuration Preview Arrow Switching — 2026-09-24

## UI change record

- **Loop:** Product Loop, based on the 2026-09-24 iPhone screen recording and
  the owner's follow-up that horizontal switching remains unsettled.
- **Observed behavior:** Horizontal orientation changes depend on a drag
  gesture that competes with the preview's vertical expand/collapse drag. The
  outer preview viewport already changes aspect ratio with orientation, and
  the configuration content below naturally reflows with it.
- **Intended outcome:** Replace horizontal swipe switching with two quiet,
  translucent, large-chevron buttons over the left and right edges of the
  preview. Keep the current orientation-dependent viewport sizing and natural
  downstream reflow; do not lock the viewport to a fixed height. Preserve
  vertical expand/collapse behavior, card content, orientation persistence,
  presets, and renderer/export behavior.
- **Scope owner:** `MemoryCardPreviewSection` owns the local interaction and
  preview-only orientation preference. Renderer, Layout Engine, preset state,
  and output content are out of scope.
- **Risk:** P2, bounded UI interaction refinement.
- **Acceptance:** Both arrows switch deterministically to the opposite
  orientation with VoiceOver labels; horizontal drag no longer switches the
  preview; vertical expansion/collapse remains available; orientation changes
  still resize the viewport and allow the content below to reflow; card
  content and output configuration remain unchanged; focused source-contract
  tests and an iOS build pass. Physical iPhone review remains with the owner.

## 2026-09-24 visual refinement addendum

- **Observed:** Owner-provided iPhone captures show the 52×68 material capsules
  dominate the photo. The 44pt expand control at bottom-trailing overlaps
  FilmMark's bottom output line.
- **Intended:** Use native SwiftUI Liquid Glass circular controls on iOS 26+
  (including iOS 27), with a restrained translucent fallback on the app's
  supported iOS 18 deployment target. Keep 44pt hit areas and smaller
  chevrons. Move expand/fit to the preview's top-trailing corner so bottom
  output remains inspectable. Preserve the existing orientation switch,
  expand gesture, viewport aspect-ratio changes, preview persistence, and
  natural configuration reflow.
- **Risk:** Product Loop, P2. UI-only control presentation; no output/config
  content change. Classic White alignment is specified in the companion record.
- **Acceptance:** Focused tests and iOS build pass. Physical iPhone visual
  acceptance remains pending owner review; this change is not installed on the
  device as part of this pass.
