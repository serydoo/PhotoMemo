# Configuration Preview Production Integration

Date: 2026-09-24
Status: implemented in the bounded iOS Configuration Center preview; Baguette visual review performed; paired physical-device acceptance remains open.

## Decision and observation

At approval time, the shared Mid-Autumn pair and landscape/portrait review
appeared only through the opt-in DEBUG route; the actual Configuration Center
editor still rendered the prior compact preview and retained no viewing
preferences. The owner authorized integrating the configured behavior into
the real MemoMark code and validating it through the local Baguette simulator.

## Scope

- Primary loop: Product Loop; bounded refinement of the existing iOS
  Configuration Center calibration surface, not a new expression-style or
  output capability.
- Affected owner: `MemoryCardPreviewSection` and its existing real
  `MemoryCardPreviewSurface` / style-specific preview composition.
- Risk: P1 because this is a primary configuration and calibration surface;
  output configuration, preset schemas, durable configuration, renderer,
  layout, export, PhotoKit, and original-photo behavior remain out of scope.
- Validation target: iPhone 17 Pro, iOS 26.5 in the owner-designated local
  Baguette panel at `http://127.0.0.1:8421/simulators`. This is supporting
  visual evidence, not physical-device acceptance.
- The first integrated slice is the iOS configuration editor preview used by
  Baguette. The separate macOS compact-preview composition and the small
  top-summary region preview are not redesigned in this slice.

## Accepted behavior

1. Classic White, Minimal, and FilmMark use the same owner-provided landscape
   or portrait Mid-Autumn preview asset for a given orientation. Each keeps its
   existing output/content semantics and photo-relative composition. Classic
   White keeps the complete information bar; Minimal and FilmMark show their
   actual output layers over the photograph.
2. One active orientation is shown at a time. A quieter, offset preview of the
   alternate orientation sits behind it. Horizontal swipes exchange the two
   orientations; there are no landscape/portrait buttons. VoiceOver receives
   an equivalent named accessibility action.
3. The landscape fit view remains width-bounded and shows the complete source
   photo. The portrait fit view reveals the lower half of its full photo canvas
   so the output placement is visible without occupying the whole page. A
   subtle top-edge continuation cue indicates that more photo is above.
4. A single corner control toggles between fit and full-canvas inspection.
   The portrait can also be expanded with a downward drag and collapsed with
   an upward drag on the preview. The preview's height change naturally moves
   the configuration controls below it; motion is restrained, interruptible,
   and respects Reduce Motion.
5. Orientation and fit/full-canvas mode are local interface preferences in
   `UserDefaults.standard` only. They are not part of a preset, configuration
   aggregate, FilmMark payload, Renderer input, export, or app-group handoff.
   The same values are shared across the three style previews so switching a
   style does not unexpectedly reset the viewing context.
6. FilmMark's existing font and position controls remain FilmMark-only. This
   preview slice does not add those calibration controls to Classic White or
   Minimal.

## Implementation and verification plan

1. Add tested, pure preview geometry/preference contracts first: common asset
   selection, orientation aspect ratios, portrait lower-half fit viewport, and
   landscape scale-to-fit sizing.
2. Wire app-local persisted preview state into the real editor preview while
   keeping configuration and export inputs unchanged.
3. Add native orientation layering, swipe/vertical expand gestures, the corner
   fit/full control, accessibility semantics, and Reduce Motion handling.
4. Run focused Swift Testing, relevant configuration contract tests, iOS
   Simulator build for the explicitly requested Baguette check, generic iOS
   build, `git diff --check`, asset JSON validation, and localization parity.
5. In Baguette, open the normal app route and inspect all three styles in both
   orientations, the portrait fit/full transition, preference restoration,
   and unchanged configuration controls. Do not use the DEBUG fixture screen
   as the sole integration check.
6. Keep paired physical iPhone 17 Pro Max acceptance separate and report it as
   not verified unless the exact current build is installed and manually
   reviewed there.

## Explicit non-goals

- No preset/configuration schema or saved user-content migration.
- No changes to Renderer, Layout Engine, export transactions, metadata,
  PhotoKit, Share, Live Photo, or save-back.
- No new background upload, remote service, or third-party simulator account.
- No redesign of the macOS preview or the independent top-summary region
  preview in this increment.

## Implementation result

- Preview orientation and fit/full-canvas preferences use shared standard
  `UserDefaults` keys and survived app termination plus in-place simulator
  app update. They do not enter a preset or output configuration.
- The production editor now uses the shared source photos in all three styles.
  In Baguette on iPhone 17 Pro / iOS 26.5, horizontal swipes changed orientation;
  the portrait fit state exposed the bottom half with a continuation cue, and
  the expand control revealed the full portrait while moving the editor below.
  Classic White, Minimal, and FilmMark each retained their own real output
  composition over the shared images.
- Focused `FilmMarkPresentationSpecificationTests`,
  `CrossTargetLocalizationTests`, and `ConfigurationOptionListContractTests`
  pass. `MemoMarkiOS` iOS Simulator Debug build passes. Both owner-provided
  PNG assets remain byte-identical to their input files.
- This Baguette pass is preliminary visual evidence only. VoiceOver, Reduce
  Motion, Dynamic Type, prolonged gesture interaction, and paired iPhone 17 Pro
  Max acceptance remain for manual review.

## Owner feedback refinement — 2026-09-24

The first Baguette pass exposed two issues that were not sufficiently clear in
static geometry checks: orientation changed mostly on gesture release, making
the preview feel like a page jump; and portrait fit occupied the full viewport
width, causing the alternate card to be clipped instead of reading as a stack.
The Classic White composition also needed an explicit distinction between the
photo's source ratio and the complete photo-plus-information-bar ratio.

Accepted correction:

- While dragging horizontally, the active and alternate orientation canvases
  move continuously with the gesture. On release, the incoming canvas settles
  into the active position along that trajectory; an incomplete swipe returns
  to the existing orientation. The completed orientation alone is persisted.
- The fit canvas is width-inset in both orientations so the offset alternate
  canvas remains visible as a second card; portrait still exposes the lower
  half of its full-height canvas. Full-canvas inspection continues to use the
  full available width. The outer viewport animates with orientation and fit
  state so the editor below follows its changing height.
- Classic White now composes the orientation-matched photograph and complete
  information bar as adjacent vertical regions. The photo region uses the
  original 16:9 or 9:16 aspect ratio without a fill crop; the appended bar uses
  the matching `CompactInformationBarSpec.barHeightToWidth`. The total canvas
  ratio is derived from those two regions, and is used by the viewport sizing.

Focused `FilmMarkPresentationSpecificationTests` pass (25 tests), covering
the composed Classic White ratio, both orientation canvases, preview fit
geometry, and existing presentation contracts. The iOS `MemoMarkiOS` Debug
build passed for the owner-designated Baguette iPhone 17 Pro / iOS 26.5 target;
the app was overwrite-installed without clearing simulator data and launched
in the normal Configuration Center. The final Baguette view showed the
orientation card edge at rest, the cropped-to-lower-half portrait fit, and the
Classic White landscape photo plus appended bar. Paired iPhone 17 Pro Max,
VoiceOver, Reduce Motion, Dynamic Type, and sustained gesture acceptance remain
open. This is still a preview-only UI change: no preset, output configuration,
renderer, layout, export, or media-pipeline contract changed.
