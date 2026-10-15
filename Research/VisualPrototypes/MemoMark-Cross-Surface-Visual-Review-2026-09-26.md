# MemoMark Cross-Surface Visual Review — 2026-09-26

Status: active Product Loop review; two evidence-backed preview parity
corrections are implemented. Cross-surface physical-device acceptance remains
open.

## Objective

Bring the recent Home preset, Configuration Center preview, Classic White
portrait, and FilmMark overflow work into one review baseline. Establish a
coherent hierarchy across MemoMark surfaces while preserving the existing
product architecture and recent owner decisions.

The visual test is: the photograph and its memory presentation remain the
visual center; time and subject information explain the memory; controls and
containers stay quiet and predictable.

## Product And Engineering Decision Gate

- Primary UI loop: Product Loop, bounded refinement of existing surfaces.
- Related reliability work: Engineering Loop, the existing P1 FilmMark
  overflow feedback slice.
- Owners: Home owns the preset-row projection; Configuration Center owns
  preview interaction and temporary inspection state; Layout Engine owns
  Classic White geometry; FilmMark resolver/layout own overflow truth.
- Source of truth: current production source, `MemoMarkDesignTokens`,
  `ConfigurationCenterWindowSpecification.md`, the 2026-09-24 preview-arrow
  decision, the Classic White portrait study, and the current 2026-09-26
  implementation record.
- Risk: P1 for FilmMark overflow feedback; P2 for bounded Home, preview,
  accessibility, and Classic White fidelity refinements.
- Apple capability: retain native SwiftUI controls, system materials,
  accessibility traits, Dynamic Type, and Reduce Motion behavior. No new
  framework, dependency, permission, or persisted product field is needed.

## Unified Current Baseline

The following recent work is included in this pass rather than treated as
separate visual guesses:

1. **Home preset row (2026-09-26):** the current local changes put the memory
   subject before the preset descriptor, restore each preset's localized saved
   time, remove the visible “in use” phrase, preserve that state in the
   accessible label, and add a blue selected-row fill/border alongside the
   trailing checkmark. The interaction and configuration selection owner stay
   in `HomePageSurface`.
2. **Configuration preview (2026-09-26):** production orientation switching
   uses left/right edge buttons; horizontal swipes do not switch orientation.
   Vertical dragging is reserved for portrait inspection expansion. Orientation
   is an app-local viewing preference; expansion is temporary view state.
   Reduced Motion disables the transition.
3. **Classic White portrait (2026-09-26):** the left context and right output
   cluster use shared, measured Layout Engine geometry consumed by preview and
   output. The right cluster is trailing anchored and retains its bounded
   internal gaps.
4. **FilmMark overflow:** the local implementation now projects Layout-owned
   overflow into localized preview guidance and a dedicated pre-render
   production diagnostic. The implementation record remains the detailed
   source for tests and build evidence.

The earlier 2026-09-24 production-preview integration note describes the
previous swipe interaction. The 2026-09-24 arrow-switching decision and the
2026-09-26 production code/status are the current interaction contract.
Historical notes remain intact until the research specification is stable.

## Confirmed Source Findings

| Priority | Surface | Evidence | Direction |
|---|---|---|---|
| P1 | FilmMark preview and processing | Layout already resolves safe-area overflow; the current local slice displays that state and maps it to a specific processing failure. | Implemented in the current tree. Suite run: 26 passed; one existing viewport-ratio assertion remains failed. Keep physical-device acceptance open; do not truncate authored content or change Renderer ownership. |
| P2 | FilmMark full-photo calibration preview | `FilmMarkPreviewSurface.photoPreviewBackground` darkened the supplied photo with a vertical gradient that is not part of FilmMark output. | Resolved in the current tree by removing only that preview overlay; the regression assertion passed in the 27-test FilmMark suite. |
| P2 | Classic White portrait geometry | `ClassicWhitePortraitLayoutSpecification.measureTextWidth` previously used Core Text Bold traits while the corresponding output rows render in Semibold. | Resolved in the current tree using platform system Regular/Semibold fonts. All 11 `ClassicWhiteRendererLayoutTests` passed, including the width-parity and adaptive-geometry cases. |
| P2 | Home preset selection | Current row combines tinted fill, a 1.5pt accent border, and a selected checkmark. Shared selection surfaces use quieter token-based selection styling. | Keep the recent subject/date/accessibility decisions in scope. Compare the whole preset group before changing emphasis; do not revert the recent appearance without device evidence. |
| P2 | Preview VoiceOver | The preview canvas exposes a switch-orientation accessibility action while both visible edge buttons also expose the same switch action. | Verify traversal and action duplication with VoiceOver before simplifying the accessible route. |
| P2 | Home preset VoiceOver | The row ignores child accessibility elements. Its row-level label previously included subject, descriptor, saved time, and selection but omitted the visible logo identity. | Resolved in source by including the logo-mark type in the row label and all four localized formats. Physical VoiceOver review remains open. |

## Cross-Surface Review Scope

The review inventory covers the active iOS entry tabs and their related
surfaces:

- Home and the recent preset-row changes;
- Configuration Center preview, Library, Interactive Memory Card, and Object
  Inspector;
- Output configuration and its save/destination actions;
- Processing status and recent results;
- Settings, help, and support sheets;
- Memory Subject and Time Anchor editing sheets;
- Share Extension confirmation and processing states;
- macOS Configuration Center's wide workspace and inspector.

Only the Home row, Configuration Center preview, Classic White portrait,
FilmMark preview/overflow, and directly related accessibility semantics have
confirmed source changes in this slice. Other surfaces are inspected for clear
hierarchy, excessive nested chrome, repeated trailing geometry, localization,
and device-fit evidence; no broad rewrite follows from the inventory alone.

## Existing Design System And Boundaries

- Reuse `MemoMarkDesignTokens`, `ConfigurationUI`,
  `ConfigurationOptionRowLayout`, and
  `ConfigurationCenterWindowSpecification.md`. Do not add a parallel global
  `MemoMarkVisualMetrics` type.
- Align comparable configuration rows through the existing adaptive layout;
  do not force toggles, navigation links, destructive actions, and buttons into
  one fixed accessory shape.
- Reduce containers only where the observed hierarchy shows redundant nested
  surfaces. Cards are not removed as a blanket rule.
- Keep the frozen architecture:
  `Library -> Interactive Memory Card -> Object Inspector`.
- Preserve configuration and preview-state ownership. Preview preferences do
  not enter durable Presets, processing snapshots, FilmMark payloads, or
  exports.
- Do not change the Apple Photos lifecycle, original assets, Share Extension
  processing boundary, metadata, or Live Photo behavior.
- Do not treat high-resolution memory concerns or the macOS 26 geocoder
  deprecation as visual tasks. They remain separate measurement/maintenance
  items.

## Implementation Plan

### Slice A — Preview fidelity

- **Implemented:** removed only the full-photo calibration background's
  preview-only dark gradient. FilmMark's authored text/substrate composition
  and the separate compact review surface remain unchanged.
- The source-contract regression ran and passed as part of the 27-test
  `FilmMarkPresentationSpecificationTests` suite.

### Slice B — Classic White typography measurement

- **Implemented:** measure primary rows with platform system Semibold and
  secondary rows with system Regular, matching the corresponding SwiftUI
  output weights. The Layout Engine still owns the measured shared geometry.
- Added direct width parity against the native system Semibold font. All 11
  `ClassicWhiteRendererLayoutTests` passed, including Chinese, mixed-script,
  short-content, and constrained long-content geometry cases.
- The Renderer still consumes resolved layout and gained no layout decisions.

### Slice C — Home row and cross-surface review

- Keep the current local Home row changes as the baseline: subject first,
  localized saved time, no visible active-state sentence, and accessible
  selection state.
- Inspect its selected treatment as one composed group against existing
  semantic selection tokens before changing the border/fill/checkmark balance.
- Include the visible logo-mark type in the parent row's VoiceOver label,
  because the row intentionally ignores its child accessibility elements.
  This change and its four-language format test are implemented; manual
  VoiceOver confirmation is pending.
- Verify the preview's orientation custom action alongside its two visible
  edge buttons before changing the available VoiceOver routes.
- Review the remaining listed surfaces for concrete evidence and add them to a
  later bounded slice only when a verified issue warrants code changes.

### Slice D — Acceptance and record

- Focused layout suite: 11 passed / 0 failed.
- Home-row contract and localization suites: 14 passed / 0 failed.
- Focused FilmMark suite: 26 passed / 1 existing viewport-ratio failure. The
  new full-photo regression passed; `productionPreviewsSelectSharedAssetsAndCanvasRatios`
  remains the sole failure (`1.2784` absolute difference).
- Generic iOS Debug build of the current working tree passed after the three
  source slices. Physical-device review remains open.
- Install the exact signed build on the paired iPhone 17 Pro Max when available.
- Review Home, Configuration Center preview in all three styles and both
  orientations, FilmMark overflow, and Classic White portrait output.
- Check VoiceOver, supported Dynamic Type sizes, light/dark appearance,
  Increased Contrast, Reduce Motion, and four supported interface languages.
- Update this review and `Docs/CURRENT_STATUS.md` with evidence by category.

## Verification Commands

Preferred unsigned build:

```bash
xcodebuild -project $REPO_ROOT/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMarkiOS -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/MemoMarkVisualClosure CODE_SIGNING_ALLOWED=NO -quiet build
```

Run the focused `MemoMarkTests` cases for FilmMark preview contracts,
Classic White portrait geometry, Home preset row semantics, and localization.
Keep test execution, build, signed installation/launch, and manual device
acceptance as separate evidence.

## Open Acceptance Gap

The paired iPhone 17 Pro Max is currently showing its Lock Screen. No device
unlock or app navigation was attempted. Static source and prior status records
support this initial audit; current whole-screen visual balance, touch feel,
VoiceOver traversal, Dynamic Type, contrast, and the combined recent Home-row
appearance remain `NOT VERIFIED` until the app can be reviewed on the device.

## Implementation Record

- Preview-only gradient removal: implemented in
  `FilmMarkPreviewSurface.photoPreviewBackground`.
- Classic White typography parity: implemented in
  `ClassicWhitePortraitLayoutSpecification`, with production and preview
  call-sites distinguishing Semibold from Regular.
- Suite-level test filters were used after identifying that individual-method
  Swift Testing filters returned a zero-test `unknown` result. No zero-test
  invocation is counted as verification.
- Home-row appearance and VoiceOver decisions remain unchanged pending
  paired-device review except for the added logo-mark description. No device
  was unlocked or navigated during this pass.
