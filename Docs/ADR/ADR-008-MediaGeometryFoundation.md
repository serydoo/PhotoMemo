# Media Geometry Foundation

## Status

Accepted

## Date

2026-07-08

## Context

MemoMark is extending its media pipeline beyond ordinary still-image export.
Live Photo internal testing exposed a portrait-orientation regression where
still rendering, still composition, and video composition could each derive
geometry from different facts and coordinate systems.

The observed symptom was a portrait Live Photo becoming horizontal and
stretched. The underlying architecture issue is broader: the pipeline allowed
multiple Geometry Truths to exist inside one production task.

Future support for Live Photo, RAW, HDR Photo, ProRAW, Spatial Photo, Video,
and Burst-style media requires geometry to become a first-class foundation
instead of being rediscovered by Renderer, Composer, or Exporter.

## Decision

MemoMark adopts Media Geometry Foundation as a permanent media-pipeline
boundary.

The decision is:

1. Geometry is a property of media. It does not belong to Renderer, Composer,
   or Exporter.
2. Geometry is resolved once, consumed everywhere.
3. `CanonicalGeometry` is the only Geometry Truth allowed to cross module
   boundaries, and it is an immutable value object.
4. Geometry verification happens through Geometry Linter and JSON Geometry
   Snapshot, not through downstream runtime correction.
5. A Foundation is not proven by its implementation. It is proven by the first
   consumer that no longer owns the same domain logic.
6. Runtime Validation validates runtime behavior. It never redesigns
   Foundation.
7. One runtime failure gets one root cause. Foundation changes require proof
   that `CanonicalGeometry`, resolver, or linter output is wrong.

The canonical lifecycle is:

```text
Media Asset
     |
     v
Still / Video Resolver
     |
     v
Media Geometry Facts
     |
     v
Geometry Normalizer
     |
     v
Canonical Geometry (Immutable)
     |          |          |
     v          v          v
Renderer   Composer   Exporter
        (Read Only Consumers)
```

## Boundary Rules

- `MediaGeometryFacts` records objective facts read from source media.
- Renderer output, footer extraction, theme-derived overlay placement, logo,
  decoration, and other product-composition inputs are Composition Facts, not
  Media Geometry Facts.
- `CanvasGeometry` records calculated display/canvas geometry.
- `CanonicalGeometry` carries facts and canvas as one immutable value object.
- Renderer consumes canonical display/canvas geometry and does not infer
  orientation from raw pixels, `UIImage.size`, or media transforms.
- Composer consumes canonical geometry and does not parse media, read EXIF,
  read AV tracks, inspect `naturalSize`, inspect `preferredTransform`, swap
  width and height, or guess rotation.
- Exporter consumes canonical geometry and metadata policy without repairing
  geometry.
- Overlay is a media-pipeline capability that uses normalized frames. Footer is
  one overlay, not a special geometry model.
- Runtime validation issues are triaged as Runtime first, Composition second,
  and Foundation only when evidence proves `CanonicalGeometry`, resolver, or
  linter output is wrong.
- Runtime validation evidence is recorded as reports, classifications, hashes,
  dimensions, and conclusions. Private media evidence stays outside the
  repository.

## Alternatives Considered

### Keep Geometry Inside Live Photo Composer

Rejected.

This would fix one visible Live Photo symptom while preserving the broader
architecture problem. Still and video paths would remain free to derive
different geometry truths.

### Let Renderer Own Display Geometry

Rejected.

Renderer should draw resolved presentation instructions. If renderer owns media
geometry, future RAW, HDR, Live Photo, and video paths would all need renderer
specific orientation and transform logic.

### Let Each Media Type Implement Its Own Geometry Rules

Rejected.

This would make every future media type a special case. The project needs one
shared geometry foundation, not separate orientation and coordinate systems for
Live Photo, RAW, HDR, and Video.

### Validate Only By Final Image Snapshot

Rejected.

Final image snapshots are useful for visual QA, but geometry mistakes are more
stable and reviewable as JSON snapshots of canonical geometry. The pipeline
needs machine-readable geometry linter results and snapshot diffs.

## Consequences

### Positive

- Geometry has one owner and one lifecycle.
- Renderer, Composer, and Exporter become read-only consumers of geometry.
- Portrait/landscape, EXIF orientation, video transforms, canvas size, and
  overlay frames can be tested before rendering.
- Live Photo fixes become foundation work reusable by RAW, HDR, ProRAW,
  Spatial Photo, Video, and future media types.
- JSON Geometry Snapshots provide stable review artifacts for future PRs.
- The first production consumer proves the foundation only after it deletes its
  duplicated geometry logic and accepts `CanonicalGeometry` as the authority.

### Negative

- The media pipeline gains a new foundation layer before Live Photo work can
  continue safely.
- Existing Live Photo composer code must be migrated away from direct media
  parsing.
- Some renderer/export seams may need adapter work before they can consume
  canonical geometry cleanly.

### Risks

- The foundation could become too broad if it attempts to solve every future
  media type at once.
- The first implementation must stay focused on geometry facts, canonical
  canvas geometry, linter output, snapshots, and Live Photo migration.
- Composition Facts must not be allowed to blur into Media Geometry Facts, or
  the foundation will slowly become renderer-specific.
- Visual renderer redesign is explicitly out of scope for this ADR.
- Runtime validation must not reopen foundation design for Photos pairing,
  playback, import/export, or device-only runtime failures.
- If the team cannot prove `CanonicalGeometry` is wrong, the issue remains a
  Runtime or Composition finding.

## Follow-up Work

- Implement `MediaGeometryFacts`, `CanvasGeometry`, and immutable
  `CanonicalGeometry`.
- Implement Geometry Linter with machine-readable issue codes.
- Implement JSON Geometry Snapshot tests.
- Implement still and video geometry resolvers.
- Implement Geometry Normalizer.
- Migrate Live Photo still/video composers to consume canonical geometry.
- Add portrait Live Photo fixture coverage before attempting another device
  fix.
