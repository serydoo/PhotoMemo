# Classic White Portrait Layout and Preview Stack Study

Date: 2026-09-24
Status: implementation candidate; automated geometry matrix is in place, with physical-device visual acceptance still pending.

## Product loop and observed problem

The owner's iPhone captures show that the Classic White portrait information
bar feels unbalanced: a wide empty region remains between the divider and
short right-side copy, while the left context and the complete right cluster do
not read as two balanced groups. A separate preview concern is
that the current alternate-orientation card peek is too subtle and one-sided.
The new reference image suggests borrowing a clearer layered-card hierarchy
and restrained side peeks, not reproducing its gallery, content, or controls.

## Current source evidence

- `ClassicWhiteRenderer.Layout` and `MemoryCardPreviewSurface` currently resolve
  portrait columns through fixed width/origin ratios. The preview positions the
  text, logo, divider, and right text as separate elements.
- The iOS preview already keeps the alternate orientation card behind the
  active card, while stable glass arrow buttons switch orientations. This
  interaction model remains; this study changes only the visual depth and
  reveals more intentional, balanced edges of the existing alternate card.
- The current left inset is `.045`; historical June 30 source recorded logo
  center `.490` and divider center `.540`. These are a useful balanced-state
  visual reference, not universal coordinates for content of every length.
- Existing renderer text compression/truncation behavior remains the fallback
  for content that does not fit the bounded layout.

## Latest owner decision

This confirms the right-cluster interpretation; it supersedes the later
incomplete correction that moved the avatar and divider into the left group.

- The left-side context rows form one group. Measure the wider of its two rows
  and retain stable inner padding; do not include the avatar/logo or divider in
  this group.
- The avatar/logo, divider, and both right-side output rows form one right
  cluster. Measure the wider of the two right rows with stable inner padding;
  keep logo size and the logo-divider-text gaps stable as the cluster moves.
  Anchor the cluster's outer text edge to the right inset. The left context's
  outer edge and the right cluster's outer edge retain equal minimum canvas
  insets (`.045` of canvas width).
- Both right-side output rows remain leading-aligned. Keep the historical
  divider-edge-to-text gap (`.026` canvas width) and logo-slot-to-divider gap
  (`.015` canvas width) fixed. The preview and output use the same measured
  right text origin, divider bounds, and trailing-aligned logo slot.
- The divider is part of the right cluster, not the boundary separating the
  avatar from the right-side copy. Keep the right cluster's outer text edge
  anchored. Derive its logo and divider positions from the measured wider row
  plus the fixed logo/gap geometry; the cluster's left edge and its separation
  from the left context therefore adapt within bounds derived from both groups'
  required widths and equal outer insets. Neither group may infinitely
  compress or push the other off canvas.
- When both groups are short, use the June arrangement as the balanced visual
  reference. Asymmetrically longer content may move the right cluster's logo
  and divider leftward from that reference, but only as far as the measured
  minimum inter-group spacing allows. Historical `.490` logo / `.540` divider
  values in the first draft were not the pre-change production geometry and
  are superseded. The pre-change compact preview used `.473` / `.523` centers;
  the actual footer's fixed slot/gap geometry resolves approximately `.4695` /
  `.5212` at the full-width baseline. The shared resolver now follows those
  actual footer edge gaps rather than hard-coding the preview-only centers.
- Existing single-line scale/truncation behavior applies after available
  width is resolved. Do not add a new copy rule or alter user-authored text.
- Preview and actual Classic White export must consume the same Layout Engine
  resolved measurement and placement result. Renderer draws that result; it
  does not choose coordinates. This changes rendered Classic White geometry,
  not preset contents, time anchors, or durable configuration.
- Landscape layout, output aspect ratio, source photo pixels, metadata, and
  all non-Classic-White render geometry remain unchanged.

## Geometry bounds and validation

The implementation uses the current measured maximum columns as caps (`.364`
left and `.406` right), `.045` equal outer insets, and `.014` minimum space
between the left text and right cluster. The right cluster is trailing
anchored; its measured width moves its logo-slot/divider/text group as one
unit, preserving the `.015` slot-to-divider and `.026` divider-edge-to-text
gaps. These are normalized Layout Engine inputs, not preset/configuration
values.
Automated tests now cover the historical maximum-width state, short right copy,
asymmetric long copy, mixed Chinese/English, and maximum-length rows. They also
check that both outer bounds and the minimum group separation survive adaptive
placement. Preview and output call the same resolver contract.

This remains a candidate until the paired iPhone 17 Pro Max review confirms
that the short-copy right cluster does not feel over-dispersed and that the
historical balanced state remains comfortable. Physical review must also
confirm the actual output matches the preview.

If device review reveals over-dispersion or content collision, revise the
bounded ratios from the full matrix rather than tuning one screenshot. If there
is no feasible space for a case, keep structural gaps and outer insets intact
and apply existing text scale/truncation behavior.

## Preview stack visual direction

- Keep exactly the two supported orientations and the existing left/right
  glass arrow controls; do not add a gallery, extra content, or a second
  switching gesture.
- Keep both actual orientation previews as the stack's front/back surfaces.
  Improve depth with a stable, restrained offset/scale and a visible but quiet
  side reveal, using matching corner radius, edge treatment, and lighting.
- Switching should exchange front/back roles smoothly without changing the
  preview viewport contract or causing the configuration content below to
  jump. Respect Reduce Motion; use no bounce or attention-grabbing oscillation.
- Keep zoom control clear of rendered output content and preserve the current
  local-only preview preferences.

## Implementation and verification boundary

Product Loop, P2. Scope is Classic White portrait Layout Engine measurement,
Renderer and preview consumption, the existing preview stack presentation,
focused tests, and this research record. No preset/schema/persistence migration
is allowed. Do not touch media ingestion, PhotoKit, Export save-back behavior,
or landscape geometry.

Required evidence: focused geometry tests across the matrix, renderer/preview
contract tests, a clean MemoMark build, review of the actual output and preview
on the paired iPhone 17 Pro Max, and explicit reporting of any remaining manual
acceptance. UI implementation is not complete based on build or installation
alone.
