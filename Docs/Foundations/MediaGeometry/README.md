# Media Geometry Foundation

## Status

Foundation Freeze

## Date

2026-07-08

## Purpose

Media Geometry Foundation establishes one canonical geometry truth for the
MemoMark media pipeline.

From this freeze forward, geometry no longer belongs to Live Photo. Geometry
belongs to the whole media pipeline.

Any future work involving orientation, dimensions, canvas, overlay regions,
render space, still composition, video composition, or export geometry must
follow this foundation.

## Design Declaration

Media Geometry Foundation does not solve Live Photo. It removes geometry
reasoning from the entire rendering pipeline.

## Start Here

Read in this order:

1. `Manifest.md`
2. `GeometryConstitution.md`
3. `FoundationChecklist.md`
4. `Docs/02_Architecture/RFC-002-Media-Geometry-Foundation.md`
5. `Docs/ADR/ADR-008-MediaGeometryFoundation.md`

## Canonical Truth

```text
CanonicalGeometry
```

`CanonicalGeometry` is the only geometry truth allowed to cross module
boundaries. It is immutable.

## Architecture Line

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

## Foundation Checklist

```text
Media Geometry Foundation

[x] RFC Frozen
[x] ADR Accepted
[x] Constitution Frozen
[ ] Geometry Models
[ ] Geometry Resolver
[ ] Geometry Linter
[ ] Geometry Snapshot
[ ] Composer Migration
[ ] Live Photo Validation
```

## Implementation Rule

The first consumer of Geometry Resolver must be Geometry Snapshot, not Live
Photo Composer.

Ordinary still-image geometry should become stable first. Live Photo should
only migrate after JPEG/HEIC still geometry can produce reviewable
`CanonicalGeometry` JSON snapshots.

## Source Documents

- `Docs/Foundations/README.md`
- `Docs/Foundations/MediaGeometry/Manifest.md`
- `Docs/02_Architecture/RFC-002-Media-Geometry-Foundation.md`
- `Docs/ADR/ADR-008-MediaGeometryFoundation.md`
- `Docs/Foundations/MediaGeometry/GeometryConstitution.md`
- `Docs/Foundations/MediaGeometry/FoundationChecklist.md`
