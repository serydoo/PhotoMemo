# Card Content Inspector And Preview UI Pass

Date: 2026-09-27
Status: implemented; physical launch and visual acceptance pending

## Decision gate

- **Primary loop:** Product Loop. The supplied iPhone captures show that the card-content overlay covers the content it claims to preview, both with and without the keyboard.
- **Risk:** P1 for the main content-customization workflow, focus, and accessibility. This pass changes presentation only; configuration truth, Renderer, Layout Engine, PhotoKit, and export remain with their current owners.
- **Source of truth:** the current local source, the two owner-supplied iPhone captures, the accepted editor-input geometry standard, and the 2026-09-26 cross-surface visual review. The older sheet-boundary specification describes the superseded overlay and remains historical evidence.
- **Apple-native capability:** retain the existing SwiftUI page/inspector layout, UIKit/TextKit editing, system keyboard, native buttons, Dynamic Type, and VoiceOver. No new framework or persisted setting is needed.
- **Ownership:** `ConfigurationSession` and the style-specific editor drafts own live content; `RootPresentationState` owns transient inspector presentation; the preview consumes that content without becoming a second draft or changing output geometry.

## Complete interaction change set

1. Opening **Card Content** replaces the configuration option inspector in the same Configuration Center page. The existing Memory Card preview remains above it on iPhone and beside it at regular width. The editor no longer paints a scrim over the preview.
2. The inspector keeps all current style-specific inputs: four Classic White/Minimal regions or FilmMark's single authored output, the active-region module library, and the existing TextKit focus, IME, insertion, undo, and draft behavior.
3. A clear Done action returns to configuration options. It dismisses the keyboard and transient module state without implicitly saving or activating a preset. Configuration save actions stay with the configuration-options state.
4. While text input is active, the preview uses a bounded content-oriented viewport that continues to show the *same composed Memory Card*. The full-canvas inspection control remains available and returns to the same editing context. Keyboard space must not reduce the editable field to an unusable sliver.
5. The sample photograph and preview orientation are calibration context only. The orientation preference remains app-local; inspector presentation and focus are temporary UI state. Photo-specific modules continue to resolve separately for each processed photo.
6. Recent preview orientation buttons, portrait fit/full behavior, Classic White shared geometry, and FilmMark overflow feedback remain visible and correct in the new editing context.
7. General usage help may be less prominent in the active editor, while the Apple Photos description consequence stays discoverable near the affected content.

## Implementation slices

1. Replace the obscuring overlay with an in-page Card Content inspector; preserve the preview instance and editor bindings.
2. Adapt the preview viewport to keyboard/focus and ensure the selected content is inspectable without a separate rendering truth.
3. Update focused source contracts and localization where the visible interaction changes. Remove only dead overlay helpers and metrics.
4. Verify governance, focused tests, iOS build, and signed install/launch on the paired iPhone 17 Pro Max. Physical visual, VoiceOver, Dynamic Type, and longer typing acceptance remain explicit until observed by the owner.

## Acceptance scenarios

- Open and close Card Content in Classic White, Minimal, and FilmMark without losing edits or changing the active preset.
- See live preview updates from text and module insertion in landscape and portrait; expansion and orientation controls remain reachable.
- With the Chinese keyboard open, keep the focused input above the keyboard and leave a readable view of the relevant card content. Dismissing the keyboard restores the broader preview.
- Keep the FilmMark overflow notice discoverable in the content editor and full preview.
- Preserve one native caret, marked-text composition, VoiceOver navigation, Reduce Motion, light/dark appearance, and localized control names.
- Confirm install and launch of the exact signed build on the paired physical iPhone 17 Pro Max without clearing app data. Manual visual acceptance is recorded separately.

## Implementation and evidence

- Replaced the card-content overlay with an in-page inspector. The existing preview stays mounted while only the editor column changes; the existing TextKit cluster and module library retain draft/focus ownership. The Done action dismisses transient focus and returns to configuration options without saving.
- Keyboard presentation narrows a viewport of the same card canvas. Classic White and Minimal keep the lower content area visible; FilmMark finds its current text position through `FilmMarkPresentationResolver` so an upward placement remains inspectable. The keyboard dismiss control and preview expansion remain available. The header reflows at accessibility text sizes.
- Removed dead overlay metrics and updated focused source contracts, including recent preview orientation/Classic White source changes. Four relevant test suites passed 104/104 on macOS. iPhoneOS signed Debug build, strict code-signature verification, governance validation, and `git diff --check` passed.
- Installed 2.3.3 (111) over the existing bundle on the paired iPhone 17 Pro Max; `devicectl device info apps` confirms the installed version. The launch command was rejected with system reason `Locked` after the phone relocked. No uninstall or data clearing occurred. The owner has been asked to unlock and keep the screen awake; launch must be retried before claiming startup success. Visual, VoiceOver, Dynamic Type, Chinese IME, and prolonged editing remain manual acceptance items.
