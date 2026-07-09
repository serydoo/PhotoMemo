# Media Geometry Foundation Manifest

## Mission

Establish MemoMark's single Geometry Truth so every media type can share one
geometry pipeline.

Geometry should be resolved once, validated once, snapshotted once, and then
consumed read-only by Renderer, Composer, and Exporter.

## Why It Exists

MemoMark now processes more than ordinary still images. Live Photo revealed the
same foundation problem that RAW, HDR, ProRAW, Spatial Photo, Video, and future
media types will also face:

```text
multiple modules were allowed to infer geometry independently
```

Media Geometry Foundation exists to remove geometry reasoning from downstream
modules and replace it with one immutable canonical model.

## Goals

- Geometry Facts
- Geometry Normalization
- Canonical Geometry
- Geometry Validation
- Geometry Snapshot

## Non-Goals

Media Geometry Foundation does not own:

- Renderer design
- Composer implementation
- Export behavior
- Live Photo feature behavior
- Visual style
- Metadata policy

## Core Principles

- Geometry is a media property.
- Geometry is resolved once.
- `CanonicalGeometry` is immutable.
- Consumers never infer geometry.
- Geometry validation is machine-readable.
- Geometry snapshots are JSON.

## Canonical Truth

```text
CanonicalGeometry
```

`CanonicalGeometry` is the only geometry truth allowed to cross module
boundaries.

## Stop Rule

Do not apply Live Photo-specific geometry fixes before Geometry Models,
Geometry Resolver, Geometry Linter, and Geometry Snapshot exist.
