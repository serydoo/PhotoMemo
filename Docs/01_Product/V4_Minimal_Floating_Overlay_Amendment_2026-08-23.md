# V4 Minimal Same-Canvas Floating Overlay Amendment

Status: Accepted by project owner on 2026-08-23

## Decision

The Minimal expression style is a same-canvas floating presentation. The
source photo keeps its original pixel dimensions and aspect ratio. Minimal does
not append a white or colored information area outside the source photo.

The single information capsule is rendered inside the source photo near the
bottom-right edge. Its position is owned by the Layout Engine and is shared by
the static still, Live Photo still, and every paired-video frame.

## Why this amends the earlier PDR

The 2026-08-19 Minimal PDR described an appended opaque bottom area. Device
evidence on 2026-08-23 showed that this contract does not match the accepted
visual intent: static output placed the capsule outside the photo and Live
Photo output degraded into black/gray bands. The accepted intent is the
floating capsule visible in the original photo surface.

This amendment supersedes only the Minimal canvas/placement portion of the
earlier PDR. It does not change Memory Engine ownership, Logo semantics,
metadata preservation, local-first behavior, or Live Photo pairing rules.

## Canonical geometry

```text
canvasSize = sourcePhotoSize
photoFrame = full canvas
overlay    = transparent same-canvas artifact
placement  = floating
```

The overlay artifact may use a full-canvas transparent layer to preserve one
coordinate system across SwiftUI, Core Graphics, and AVFoundation. The visible
content remains only the capsule and Logo/text pixels; transparent pixels do
not obscure the motion frame.

## Media parity

Static export composes the original still image with the same overlay artifact.
Live Photo still and paired video consume that artifact directly. Live Photo
processing must not export a temporary appended-footer JPEG and crop it back
into an overlay.

## Capsule/avatar silhouette refinement

The Minimal capsule keeps the object avatar as the leading visual identity, but
the avatar must sit inside the measured capsule silhouette rather than overlap
or cover the capsule stroke. The visible capsule height is therefore owned by
`capsuleHeightToBarHeight` directly; vertical padding is not used to inflate the
drawn background after layout.

The current measured renderer rules are:

- landscape capsule height: `0.90 x barHeight`
- portrait capsule height: `0.92 x barHeight`
- avatar image size: `0.78 x barHeight`
- avatar leading inset: `0.08 x barHeight`
- avatar area width: `0.92 x barHeight`
- avatar/text spacing: `0.20 x barHeight`
- capsule vertical padding: `0`

This keeps the avatar's circular appearance while preventing the left rounded
edge and the avatar crop from creating a double border or rough join. The right
side remains a single continuous capsule edge around the text region.

## Configuration Center preview

The Configuration Center Minimal preview is a compact explanatory image slice,
not a miniature output card with an appended border area. It must show only the
sample photo surface and the bottom-right floating capsule. Top/bottom blank
bands are not part of the preview contract because they imply the old appended
footer model.

The preview uses `imageSliceHeightToWidth = 0.20625` as its visible height and
reuses the same capsule/avatar measured silhouette listed above. Its purpose is
to communicate placement and rhythm, not to simulate the full exported photo.

## Acceptance criteria

- Minimal static output has the same width and height as the source photo.
- The capsule is inside the source photo, anchored near the bottom-right.
- The capsule has one continuous rounded silhouette; the avatar sits inside its
  measured left-side area and does not overrun the stroke.
- Configuration Center Minimal preview shows the floating capsule over a sample
  image slice without top or bottom blank preview bands.
- Minimal Live Photo still and paired video use the same overlay coordinates.
- No black/gray/white band is introduced solely by Minimal composition.
- Static input remains static; Live Photo input remains a paired Live Photo.
- Classic White retains its existing appended-area contract.
- A future renderer registers its artifact/layout plan without a media-pipeline
  renderer branch.
