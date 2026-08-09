# V4 UI Language And Guidance Refinement — 2026-08-09

## Decision Gate

- Primary loop: Product Loop
- Risk: P2
- Observation: the current iPhone 17 Pro Max build is visually coherent, but
  the Card Content editor gives its most important novice guidance the weakest
  visual hierarchy. Several adjacent surfaces also expose internal vocabulary,
  repeat titles, or describe future options instead of the current decision.
- Source of truth: `README.md`, `README_EN.md`,
  `Docs/Guidelines/PRODUCT_LANGUAGE_GUIDE.md`, `Docs/DesignSystem.md`, and the
  current Configuration Center implementation.
- Apple-native reuse: existing SwiftUI navigation titles, confirmation toolbar
  actions, Dynamic Type branches, semantic section headers, and system
  typography remain the UI foundation.

## Intended Outcome

1. Card Content explains, at the point of use, that all four regions combine
   the user's words, photo information, and memory expressions.
2. The lower-right region gives Apple Photos description/search behavior a
   readable two-line hierarchy instead of a trailing caption.
3. The expression section distinguishes the outer decision, the style control,
   and the example without repeating the same title.
4. Time and location settings describe their current purpose and make no
   roadmap promise.
5. Memory Subject and Settings guidance prefer human language over internal
   model vocabulary while preserving accepted domain ownership.
6. The expression guide begins with a real before/today/after scenario and
   places the implementation formula in a secondary explanation.

## Scope

- Configuration Center headings, subtitles, accessibility labels, and example
  typography.
- Card Content editor guidance and lower-right description presentation.
- Time/location sheet naming and subtitles.
- Memory Subject overview/editor copy and explicit modal completion where the
  current surface lacks a visible exit.
- Settings getting-started and expression-guide copy.
- Closely related Chinese/English localization and source contracts.

## Explicitly Out Of Scope

- Memory Engine calculations and anchor semantics.
- TextKit draft ownership, insertion, deletion, focus, or candidate-panel
  behavior.
- Renderer, Layout Engine, Export, Share Extension, PhotoKit, commerce,
  persistence, or version/build numbers.
- A new navigation architecture or a return to Workspace, Dashboard, Import
  Flow, or batch workbench concepts.

## Verification

1. Source contracts cover the accepted headings and novice guidance.
2. Focused Swift tests pass.
3. Chinese and English string tables pass `plutil -lint`.
4. `git diff --check` passes.
5. Generic iOS Debug build passes without code signing.
6. A signed Debug build is installed over the existing app on the specified
   iPhone 17 Pro Max without uninstalling or clearing local data.
7. The main edited surfaces are reopened through iPhone Mirroring and reviewed
   for compact width, keyboard state, Dynamic Type-safe wrapping, and clear
   completion controls.
