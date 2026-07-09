# Geometry Constitution

## Status

Frozen

## Date

2026-07-08

## Constitution

### Rule 1: Geometry Belongs To Media

Geometry is a property of media. It does not belong to Renderer, Composer, or
Exporter.

### Rule 2: Resolved Once, Consumed Everywhere

Geometry is resolved once and consumed everywhere.

Downstream modules may read geometry. They may not mutate geometry or derive a
second geometry truth.

### Rule 3: CanonicalGeometry Is Immutable

`CanonicalGeometry` is the only geometry truth allowed to cross module
boundaries, and it is an immutable value object.

Any geometry change requires rerunning the resolver and normalizer.

### Rule 4: Facts Can Be Read; Canvas Can Be Calculated

`MediaGeometryFacts` records objective source-media facts.

`CanvasGeometry` records calculated display and canvas decisions.

### Rule 5: Composer Is A Consumer

Composer must not parse media, read EXIF orientation, inspect AV tracks, inspect
`naturalSize`, inspect `preferredTransform`, swap width and height, or guess
rotation.

### Rule 6: Renderer Works In Display Space

Renderer consumes canonical display/canvas geometry.

Renderer must not infer layout from raw pixel size, `UIImage.size`,
orientation metadata, `naturalSize`, or `preferredTransform`.

### Rule 7: Exporter Does Not Correct Geometry

Exporter writes output from already-resolved geometry and metadata policy.

Exporter must not repair orientation or rederive canvas decisions.

### Rule 8: Overlay Is A Pipeline Capability

Footer, logo, decoration, and future watermark-like assets are overlays.

Overlay regions use normalized frames. Absolute pixel frames are derived from
canonical geometry.

### Rule 9: Geometry Validation Is Machine-Readable

Geometry validation must produce linter issues with severity, code, message,
and location.

Validation must not be reduced to a Boolean result.

### Rule 10: Geometry Snapshots Are JSON

Geometry snapshots serialize `CanonicalGeometry` to JSON.

Image snapshots may support visual QA, but they are not the primary geometry
contract.
