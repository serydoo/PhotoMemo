# Media Geometry Foundation Checklist

## Status

MGF-0 Foundation Freeze: Completed
MGF-1 Geometry Core Implementation: Completed
MGF-2A Geometry Adoption Completion: Completed

Closed milestones:

- MGF-0 Foundation Freeze
- MGF-1 Geometry Core Implementation
- MGF-2A Geometry Adoption Completion

Current milestone:

```text
MGF-2B: Runtime Validation
```

Mission:

```text
Prove Media Geometry Foundation holds in the iOS Photos Runtime.
```

Architecture guardrails:

```text
Live Photo Composer consumes CanonicalGeometry. It never derives geometry.

Live Photo Composer never observes media. It only observes composition inputs.
```

MGF-2 may migrate Live Photo internals, but it must not change user-visible V1
static-image behavior or the current output UI.

MGF-2A completion rule:

```text
A Foundation is not proven by its implementation. It is proven by the first
consumer that no longer owns the same domain logic.
```

MGF-2B runtime validation principle:

```text
Runtime Validation validates runtime behavior. It never redesigns Foundation.
```

MGF-2B is a Runtime Sprint, not a refactor sprint. Do not optimize or reshape
implementation code unless a runtime failure has first been reproduced and
classified.

Runtime quality discipline:

```text
One runtime failure, one root cause.
```

Investigate one failing runtime scenario at a time. Do not bundle portrait,
landscape, metadata, footer, animation, and playback changes into one fix.

Required first question for every runtime finding:

```text
Is Truth wrong, or is the Consumer wrong?
```

Foundation change burden:

```text
Do not ask whether Foundation should change. Prove CanonicalGeometry is wrong.
```

If that proof is missing, the finding must remain Runtime or Composition.

## Phase A: Foundation

### MGF-0: Foundation Freeze

- [x] RFC frozen:
  `Docs/02_Architecture/RFC-002-Media-Geometry-Foundation.md`
- [x] ADR accepted:
  `Docs/ADR/ADR-008-MediaGeometryFoundation.md`
- [x] Constitution frozen:
  `Docs/Foundations/MediaGeometry/GeometryConstitution.md`
- [x] Manifest added:
  `Docs/Foundations/MediaGeometry/Manifest.md`

### MGF-1: Geometry Core Implementation

Only these core components should be implemented first:

- [x] `CanonicalGeometry`
- [x] `MediaGeometryResolver`
- [x] `GeometrySnapshotSerializer`
- [x] `GeometryLinter`

Core boundaries:

- [x] `GeometrySnapshotSerializer` serializes only `CanonicalGeometry`.
- [x] `GeometrySnapshotSerializer` does not accept `UIImage`, `CGImage`,
  `AVAsset`, or renderer output.
- [x] `GeometryLinter` accepts only `CanonicalGeometry`.
- [x] `GeometryLinter` returns `[GeometryIssue]`.
- [x] `GeometryLinter` does not inspect `UIImage`, `CGImage`, `AVAsset`, or
  renderer output.
- [x] MGF-1 does not introduce Overlay adoption.
- [x] MGF-1 does not modify Live Photo Composer.
- [x] MGF-1 does not modify Renderer.
- [x] MGF-1 does not modify Exporter.

Exit Criteria:

- [x] Portrait JPEG snapshot is stable.
- [x] Landscape JPEG snapshot is stable.
- [x] Portrait HEIC can produce `CanonicalGeometry`.
- [x] Landscape HEIC can produce `CanonicalGeometry`.
- [x] Orientation Right can produce `CanonicalGeometry`.
- [x] Orientation Left can produce `CanonicalGeometry`.
- [x] Each result can be serialized to stable JSON snapshot output.
- [x] Geometry Linter reports zero errors for accepted snapshots.
- [x] Snapshot regression is enabled in the focused test suite.
- [x] Geometry Core dependency guard prevents UI, renderer, export, and video
  composition imports.

Pure geometry pipeline:

```text
Media
    |
    v
Resolver
    |
    v
CanonicalGeometry
    |
    v
Linter
    |
    v
Snapshot
    |
    v
PASS
```

### Geometry Models

- [x] Add `MediaGeometryFacts`.
- [x] Add `CanvasGeometry`.
- [x] Add immutable `CanonicalGeometry`.
- [ ] Add `OverlayRegion`.
- [ ] Add `NormalizedRect`.

Acceptance:

- [x] Models are value types.
- [x] `CanonicalGeometry` is read-only after construction.
- [x] Focused tests prove equality-relevant geometry values and JSON encoding.

### Geometry Resolver

- [ ] Add Still Geometry Resolver.
- [ ] Add Video Geometry Resolver.
- [ ] Add Geometry Normalizer.
- [ ] Resolve media facts separately from canvas geometry.

Acceptance:

- [ ] Still resolver reads facts but does not calculate final canvas geometry.
- [ ] Normalizer calculates canvas geometry.
- [ ] Resolver/normalizer tests cover portrait, landscape, square, and rotated
  stills before Live Photo migration.

### Geometry Linter

- [x] Add `GeometryIssue`.
- [x] Add `GeometryIssueSeverity`.
- [x] Add stable issue codes.
- [x] Add linter checks for display size, canvas bounds, and
  invalid frames.
- [ ] Add overlay bounds linting after Overlay adoption begins.

Acceptance:

- [x] Linter returns machine-readable results.
- [x] No linter path returns only `Bool`.

### Geometry Snapshot

- [x] Add JSON snapshot writer.
- [ ] Add JSON snapshot reader if a real consumer requires it.
- [x] Add ordinary portrait JPEG/HEIC geometry snapshot.
- [x] Add ordinary landscape JPEG/HEIC geometry snapshot.

Acceptance:

- [x] Geometry Resolver's first consumer is Geometry Snapshot.
- [x] No Live Photo Composer migration happens before ordinary still snapshots
  are stable.

## Phase B: Adoption

### JPEG / HEIC Still Adoption

- [ ] Route ordinary JPEG geometry through `CanonicalGeometry`.
- [ ] Route ordinary HEIC geometry through `CanonicalGeometry`.
- [ ] Add portrait still geometry snapshot.
- [ ] Add landscape still geometry snapshot.

Acceptance:

- [ ] Ordinary still-image geometry snapshots are stable.
- [ ] Existing V1 still-image output behavior remains unchanged.

### MGF-2: Live Photo Geometry Adoption

Mission:

```text
Adopt Geometry Truth through the first real production consumer.
```

Architecture guardrails:

```text
Live Photo Composer consumes CanonicalGeometry. It never derives geometry.

Live Photo Composer never observes media. It only observes composition inputs.
```

Always:

- [x] Resolve still-image geometry before composer entry.
- [x] Pass `CanonicalGeometry` into still composition.
- [x] Pass `CanonicalGeometry` into video composition.
- [x] Keep footer/canvas placement in display space.
- [ ] Keep V1 renderer/footer content visually consistent with existing V1
  output.
- [ ] Preserve existing static-image routing unless the input is a Live Photo.

Never:

- [x] Composer must not read EXIF orientation.
- [x] Composer must not inspect `CGImageSource` or raw image properties.
- [x] Composer must not inspect `PHAsset`.
- [x] Composer must not inspect `AVAsset`.
- [x] Composer must not inspect `AVAssetTrack`.
- [x] Composer must not infer from `naturalSize`.
- [x] Composer must not infer from `preferredTransform`.
- [x] Composer must not swap width/height as a local fix.
- [x] Composer must not introduce a second geometry truth.

Implementation order:

- [x] Add a Live Photo geometry request/contract that carries
  `CanonicalGeometry`.
- [x] Migrate still composition to consume `CanonicalGeometry`.
- [x] Migrate video composition to consume `CanonicalGeometry`.
- [x] Add a dependency/architecture guard proving composers no longer parse
  media geometry.
- [x] Run focused Live Photo composer tests.
- [ ] Run simulator smoke only for UI/static routing regressions.
- [ ] Run iPhone Photos acceptance for final Live Photo behavior.

MGF-2A Exit Criteria:

- [x] Still composition and video composition consume the same
  `CanonicalGeometry`.
- [x] Footer placement is derived from `geometry.canvas.footerFrame`.
- [x] Composer code contains no geometry parsing or transform inference.
- [x] Focused tests pass.
- [x] Debug build passes.

Dependency Acceptance:

- [x] Composer has no direct `ImageIO` dependency.
- [x] Composer has no direct `PhotoKit` dependency.
- [x] Composer has no direct media-observation use of `AVFoundation`.
- [x] Composer receives prepared composition inputs rather than source media
  objects.

Geometry Consistency Acceptance:

- [x] Debug/test path proves Resolver output equals Composer input.
- [x] No code path reconstructs a second `CanonicalGeometry` between Resolver
  and Composer.
- [x] Composer request keeps `CanonicalGeometry` immutable and read-only.

Adoption Review Checklist:

- [x] Consumer no longer derives Truth.
- [x] Consumer receives Truth.
- [x] Consumer actually consumes Truth.
- [x] Consumer does not recreate Truth.
- [x] Consumer removes legacy media-observation logic.

### MGF-2B: Runtime Validation

Mission:

```text
Prove Media Geometry Foundation holds in the iOS Photos Runtime.
```

RuntimeValidationChecklist:

- [ ] Photos recognizes the output as a Live Photo.
- [ ] Still image and MOV pairing identity remains intact.
- [ ] Long-press playback works.
- [ ] Still-to-motion transition is visually stable.
- [ ] Portrait Live Photo output remains portrait.
- [ ] Portrait Live Photo output is not stretched.
- [ ] Landscape Live Photo output remains landscape.
- [ ] Footer remains fixed and visually consistent with V1 renderer output.
- [ ] Static JPEG/HEIC output behavior remains unchanged.
- [ ] Simulator smoke covers only UI/static routing regressions.
- [ ] Final acceptance runs on connected iPhone Photos runtime.

Runtime Regression Matrix:

| Validation | Portrait | Landscape |
|---|---|---|
| Recognized by Photos | [ ] | [ ] |
| Long press playback | [ ] | [ ] |
| Still-to-motion transition | [ ] | [ ] |
| Footer fixed and aligned | [ ] | [ ] |
| No stretch | [ ] | [ ] |
| Static export unchanged | [ ] | [ ] |

Fixed device validation order:

1. Import Live Photo.
2. Export Live Photo.
3. Verify Photos recognition.
4. Verify long-press playback.
5. Verify still-to-motion transition.
6. Verify footer geometry.
7. Verify portrait output.
8. Verify landscape output.

Stop on the first failed runtime pipeline step. For example, if Photos does not
recognize the output as a Live Photo, do not continue to long-press playback,
transition, footer, portrait, or landscape validation.

Runtime Report format:

```text
Runtime Validation

[ ] Live Photo Recognized
[ ] Asset Identifier Match
[ ] Long Press Playback
[ ] Still-to-Video Transition
[ ] Geometry Hash Match
[ ] Footer Bounds Match
[ ] Portrait OK
[ ] Landscape OK

Issue:
Classification:
Code:
Layer:
Root Cause:
Decision:
Foundation Changed: No
```

MGF-2B Stop Rule:

```text
MGF-2B ends when all runtime failures can be classified without changing
Foundation.
```

MGF-2B Exit Gates:

- Gate 1: Foundation is not modified for runtime-only failures.
- Gate 2: Every issue is classified as Runtime, Composition, or Foundation.
- Gate 3: Runtime Regression Matrix passes for the accepted validation scope.
- Gate 4: Runtime behavior is stable on the connected iPhone Photos runtime.

Runtime Evidence:

- Runtime reports live under `RuntimeReports/`.
- Private `.heic`, `.mov`, screenshots, and screen recordings must not be
  committed.
- Store private evidence outside the repository and record only safe paths,
  hashes, dimensions, and conclusions.

Suggested daily scope:

- Day 1: Portrait Runtime.
- Day 2: Landscape Runtime.
- Day 3: Playback Transition.
- Day 4: Runtime Metadata Validation.

MGF-2B issue triage order:

1. Runtime bug:
   Photos recognition, pairing identity, MOV pairing, long-press playback,
   export/import, or runtime metadata behavior.
2. Composition bug:
   Footer, overlay, canvas, crop, stretch, or transition geometry after
   `CanonicalGeometry` has already been consumed.
3. Foundation bug:
   Only when evidence proves `CanonicalGeometry`, the resolver, or the linter
   produced incorrect truth.

Issue classification:

| Area | Code | Meaning |
|---|---|---|
| Runtime | R001 | Pairing |
| Runtime | R002 | Photos Recognition |
| Runtime | R003 | Playback |
| Runtime | R004 | Transition |
| Runtime | R005 | Export / Import |
| Runtime | R006 | Runtime Metadata |
| Composition | C001 | Footer |
| Composition | C002 | Overlay |
| Composition | C003 | Canvas |
| Composition | C004 | Crop / Stretch |
| Foundation | F001 | Canonical Geometry |
| Foundation | F002 | Resolver |
| Foundation | F003 | Linter |

Runtime validation boundary:

- [ ] Do not add new geometry abstractions only for Live Photo runtime fixes.
- [ ] Treat rendered overlay inputs as Composition Facts, not Media Facts.
- [ ] Do not split `MediaGeometryResolver` until a second non-Live-Photo
  consumer proves the abstraction is needed.

Out of scope:

- [ ] Output format UI redesign.
- [ ] Metadata policy redesign.
- [ ] RAW/HDR/ProRAW adoption.
- [ ] General video export support.
- [ ] Renderer visual polish unrelated to geometry.

### Live Photo Runtime Validation Backlog

- [ ] Portrait Live Photo remains portrait.
- [ ] Output is not stretched.
- [ ] Footer matches V1 renderer content.
- [ ] Static-image output still follows V1 behavior.
- [ ] Ordinary still-image inputs remain unchanged.

### Future Media Adoption

- [ ] RAW
- [ ] HDR Photo
- [ ] ProRAW
- [ ] Spatial Photo
- [ ] Video
- [ ] Burst

## Stop Rule

Do not apply another Live Photo-specific geometry fix until the model, linter,
snapshot, and ordinary still-image resolver path are in place.

Foundation rhythm:

```text
Freeze -> Truth -> Consumer -> Adoption
```
