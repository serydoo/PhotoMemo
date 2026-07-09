# RFC-002: Media Geometry Foundation

## Status

Accepted

## Date

2026-07-08

## Authors

- MemoMark project
- Codex collaboration session

## Project Convention

This RFC follows the MemoMark V2 convention:

- One RFC, One Architectural Fact
- Never solve two architectural facts in one RFC

## Foundation Sprint

```text
Foundation Sprint: Media Geometry Foundation
```

This sprint is not a Live Photo sprint. It is a foundation sprint at the same
architecture level as Production Media Pipeline Integration.

## Design Declaration

Media Geometry Foundation does not solve Live Photo. It removes geometry
reasoning from the entire rendering pipeline.

Media Geometry Foundation 的目标不是解决 Live Photo，而是将几何推导从整
个渲染流水线中剥离出来，形成唯一、可验证、可复用的 Geometry Truth。

## Frozen Principles

1. Geometry is a property of media. It does not belong to Renderer, Composer,
   or Exporter.
2. Geometry is resolved once, consumed everywhere.
3. `CanonicalGeometry` is the only Geometry Truth allowed to cross module
   boundaries, and it is an immutable value object.
4. Geometry verification must happen through Geometry Linter and Geometry
   Snapshot, not through downstream runtime correction.

## Foundation Freeze

```text
Foundation Freeze
Media Geometry Foundation
Status: Frozen
```

From this freeze forward, geometry no longer belongs to Live Photo. Geometry
belongs to the whole media pipeline.

Any future work involving orientation, dimensions, canvas, overlay regions, or
render space must obey this foundation before changing Renderer, Composer, or
Exporter behavior.

Foundation entry:

- `Docs/Foundations/MediaGeometry/Manifest.md`
- `Docs/Foundations/MediaGeometry/README.md`
- `Docs/Foundations/MediaGeometry/GeometryConstitution.md`
- `Docs/Foundations/MediaGeometry/FoundationChecklist.md`

## Problem Statement

The current media pipeline allows multiple modules to derive geometry
independently. Still Renderer, Still Composer, and Video Composer can each
interpret orientation, pixel size, display size, transforms, and render space
from their own local context.

This creates multiple Geometry Truths inside one production task. A portrait
Live Photo can be interpreted as portrait by the still path and landscape by
the video path when raw HEIC pixels, EXIF orientation, `UIImage` orientation,
`AVAssetTrack.naturalSize`, `AVAssetTrack.preferredTransform`, renderer canvas
size, and AVVideoComposition render space are not normalized into a single
contract.

The immediate device symptom is portrait Live Photo output becoming horizontal
or stretched. The architectural problem is broader: Live Photo, RAW, HDR
Photo, ProRAW, Spatial Photo, Video, and future Burst-style media all require a
single shared geometry foundation before Renderer, Composer, and Exporter
consume media.

## Architectural Principles

### Geometry Belongs To Media

Geometry is a media-domain fact and derivation boundary. Renderer, Composer,
and Exporter are consumers. They must not rediscover, reinterpret, or repair
geometry.

### Resolved Once, Consumed Everywhere

Geometry follows the same architecture philosophy as Configuration Snapshot:

```text
Configuration -> Snapshot -> Everybody Reads
Media -> Geometry -> Everybody Reads
```

Once resolved, `CanonicalGeometry` becomes immutable. Downstream modules may
read it, but they may not mutate it. Any geometry change requires rerunning the
resolver and normalizer.

### Facts Can Be Read; Canvas Can Be Calculated

The foundation separates media facts from canvas decisions:

- `MediaGeometryFacts` stores objective media facts read from the original
  resource.
- `CanvasGeometry` stores normalized layout geometry derived from facts and
  output policy.
- `CanonicalGeometry` carries both as one immutable value object.

### Overlay Is A Pipeline Capability

Overlay is not owned by Geometry and is not limited to footer rendering.
Footer, logo, decoration, and future watermark-like elements are all overlay
regions that use normalized frames. Geometry is responsible for mapping those
normalized frames into concrete display and render spaces.

### Composer Is Dumb

Composer applies already-resolved geometry. Composer must not parse media,
read orientation metadata, read AV tracks, decide render size, swap width and
height, or guess transforms.

### Renderer Works In Display Space

Renderer consumes display/canvas geometry. Renderer must not infer layout from
raw pixel size, EXIF orientation, `UIImage.size`, `naturalSize`, or
`preferredTransform`.

### Exporter Does Not Correct Geometry

Exporter writes output from already-resolved geometry and metadata policies. It
does not repair orientation or rederive canvas decisions.

## Canonical Geometry Model

### Lifecycle

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

### Proposed Types

```swift
struct CanonicalGeometry: Equatable, Codable, Sendable {
    let facts: MediaGeometryFacts
    let canvas: CanvasGeometry
}
```

`CanonicalGeometry` is immutable. Its fields are resolved before rendering,
composition, or export.

```swift
struct MediaGeometryFacts: Equatable, Codable, Sendable {
    let rawPixelSize: CGSize
    let displaySize: CGSize
    let orientation: CGImagePropertyOrientation?
    let preferredTransform: CGAffineTransform?
    let renderSize: CGSize?
}
```

`MediaGeometryFacts` is read from media resources. It records objective media
facts and does not make layout decisions.

```swift
struct CanvasGeometry: Equatable, Codable, Sendable {
    let canvasSize: CGSize
    let photoFrame: CGRect
    let overlayRegions: [OverlayRegion]
}
```

`CanvasGeometry` is derived by the normalizer from facts and output policy. It
owns display-space canvas decisions such as photo frame and overlay placement.

```swift
struct OverlayRegion: Equatable, Codable, Sendable {
    let id: String
    let type: OverlayType
    let normalizedFrame: NormalizedRect
    let zIndex: Int
}
```

Overlay regions use normalized coordinates. They do not store absolute pixel
frames as their canonical contract.

### Geometry Facts

Facts are read, not designed:

- raw pixel size
- display size after orientation or transform
- EXIF orientation for still resources
- QuickTime preferred transform for video resources
- video render size after transform
- mirror or rotation facts when available

### Canvas Geometry

Canvas is calculated:

- output canvas size
- photo display frame
- footer region
- additional overlay regions
- normalized-to-pixel mapping

### Overlay Descriptor

The current footer-only model should evolve from `FixedFooterOverlayDescriptor`
to a general overlay model:

```text
OverlayDescriptor
    id
    type
    normalizedFrame
    zIndex
    content
```

Footer is one overlay. Logo, decoration, and future watermark-like assets are
also overlays.

## Geometry Linter

Geometry validation should produce machine-readable issues instead of a
single Boolean result.

```swift
struct GeometryIssue: Equatable, Codable, Sendable {
    let severity: GeometryIssueSeverity
    let code: String
    let message: String
    let location: String?
}
```

Examples:

```text
ERROR G001 DisplaySizeMismatch
ERROR G007 OverlayOutsideCanvas
WARNING G011 FooterHeightTooSmall
```

The linter should run before Renderer, Composer, and Exporter consume
geometry. It should be strict for invalid geometry and descriptive for
debugging.

## Geometry Snapshot

Geometry snapshot tests should serialize `CanonicalGeometry` to JSON. They
should not rely on image snapshots as the primary geometry contract.

The first consumer of Geometry Resolver must be Geometry Snapshot, not Live
Photo Composer. Ordinary JPEG/HEIC still-image geometry should become stable
before Live Photo migrates onto the foundation.

Example:

```json
{
  "facts": {
    "rawPixelSize": [3024, 4032],
    "displaySize": [3024, 4032]
  },
  "canvas": {
    "canvasSize": [3024, 4380],
    "photoFrame": [0, 0, 3024, 4032],
    "overlayRegions": [
      {
        "id": "footer",
        "type": "footer",
        "normalizedFrame": [0, 0.9205, 1, 0.0795],
        "zIndex": 100
      }
    ]
  }
}
```

Geometry snapshot changes should be easy to review in pull requests.

## Geometry Fixtures

The fixture set should cover geometry categories, not only product scenarios.

Still fixtures:

- portrait HEIC
- landscape HEIC
- HEIC orientation right
- HEIC orientation left
- HEIC orientation down
- square
- ultra-wide

Video fixtures:

- portrait MOV
- landscape MOV
- rotated MOV
- mirrored MOV

Live Photo fixtures:

- portrait HEIC + MOV pair
- landscape HEIC + MOV pair
- still/video orientation mismatch cases

## Geometry Debug Overlay

Debug builds should be able to render a geometry overlay that visualizes:

- display space
- canvas size
- photo frame
- overlay regions
- footer frame
- orientation
- render size

This debug overlay is for development and diagnostics. It is not part of
release output.

## Migration Plan

### Phase 1: Foundation Documents

- Add this RFC.
- Add ADR-008 Media Geometry Foundation.
- Add the Media Geometry Foundation Manifest.
- Add the Foundation Checklist.
- Record the Live Photo portrait-stretch regression as the first observed
  geometry failure.

### Phase 2: Model And Linter

- Add `MediaGeometryFacts`.
- Add `CanvasGeometry`.
- Add `CanonicalGeometry`.
- Add `OverlayRegion` and normalized frame support.
- Add `GeometryIssue` and Geometry Linter.

### Phase 3: Snapshot Infrastructure

- Add JSON geometry snapshot helpers.
- Add portrait and landscape still fixture snapshots.
- Add portrait Live Photo geometry snapshot.
- Make ordinary still-image snapshots the first consumer of the resolver.

### Phase 4: Resolver And Normalizer

- Add Still Geometry Resolver.
- Add Video Geometry Resolver.
- Add Geometry Normalizer.
- Ensure `CanonicalGeometry` is immutable and treated as read-only downstream.
- Stabilize ordinary JPEG/HEIC geometry before migrating Live Photo Composer.

### Phase 5: Live Photo Composer Migration

- Replace footer-specific pixel descriptor usage with overlay regions.
- Refactor still composition to consume canonical geometry.
- Refactor video composition to consume canonical geometry.
- Remove media parsing and orientation decisions from composers.

### Phase 6: Renderer And Export Consumption

- Route renderer display decisions through canonical display/canvas geometry.
- Ensure exporter consumes geometry and metadata policy without rederiving
  orientation.

### Phase 7: Device Verification

- Re-run the portrait Live Photo acceptance path on iPhone.
- Verify portrait output remains portrait.
- Verify the image area is not stretched.
- Verify footer is stable and matches V1 renderer content.
- Verify static-image output still follows V1 behavior.
- Verify ordinary still-image inputs are unchanged.

## Non-Goals

- Redesigning the V1 renderer visual style.
- Changing output copy or user-facing output modes.
- Changing Apple Photos save-back semantics.
- Solving HDR, RAW, ProRAW, Spatial Photo, or Video export in this sprint.
- Creating a new production pipeline parallel to V1.

## Success Criteria

- Geometry has one canonical lifecycle from media facts to immutable
  canonical geometry.
- Renderer, Composer, and Exporter consume geometry read-only.
- Composer no longer parses media or guesses orientation.
- Geometry failures produce machine-readable linter issues.
- Geometry snapshots are JSON and reviewable.
- Portrait Live Photo no longer becomes landscape or stretched on device.

## Verification Strategy

- Run geometry model and linter unit tests.
- Run JSON snapshot tests for still and Live Photo geometry.
- Run focused Live Photo still/video composition tests.
- Run iOS build.
- Install internal build on device.
- Verify portrait Live Photo output in Apple Photos.

## Closing Checklist

- Architecture Fact: `Accepted`
- Success Criteria: `Pending Implementation`
- Verification: `Pending Implementation`
