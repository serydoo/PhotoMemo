# ADR-010: Presentation Artifact Media Parity

Status: Accepted

Date: 2026-08-22

## Context

The Minimal Live Photo path previously allowed a renderer-specific, per-frame
video implementation. On a physical iPhone 17 Pro Max it expanded a 1920 ×
1080 source into a 4032 × 2268 canvas while converting every frame through
AVAssetReader, Core Image, CGImage, CGContext, and AVAssetWriter. The task
exceeded the background processing budget and was terminated before pair save.

The same implementation also allowed Minimal's visual geometry to diverge
between preview, static output, Live Photo still, and paired motion. Footer
names and placement branches made a future renderer likely to require changes
inside the media pipeline.

## Decision

1. A renderer produces a renderer-neutral `PresentationArtifact` containing
   canvas geometry, photo frame, ordered visual layers, layer opacity, and
   canvas background policy.
2. Layout Engine owns the canonical geometry and performs encoder-safe even
   pixel normalization once. Still and video composers validate and consume
   the immutable result; they do not recompute layout.
3. Still and paired-video composition use the same artifact and the same
   canonical geometry. Background policy, layer order, opacity, source-video
   transform, duration, frame cadence, and audio remain media concerns, not
   renderer concerns.
4. Generic video composition and Live Photo paired-video composition have
   distinct contracts. The paired API requires a non-optional
   `LivePhotoPairingIdentityPlan` and fails closed when identity is absent.
5. Live Photo routing is determined by source resources and output policy, not
   by a concrete renderer style. Missing paired resources or pairing identity
   cannot silently downgrade the result to a static photo.
6. A `RecordCardPresentationPlanner` is the registration boundary between
   presentation style and renderer view/size. Export and media services must
   not add `if style == ...` branches for new renderers.

## Consequences

- Minimal is implemented as full source photo plus an opaque appended bottom
  area, matching the approved PDR.
- Existing footer-named compatibility APIs may remain temporarily at migration
  boundaries, but new code must use artifact layers and background policy.
- The old Minimal floating/per-frame encoder path is not a supported fallback.
- Physical Apple Photos round-trip evidence is still required before any
  production-certification claim.

## Verification

- Renderer-neutral artifact contracts verify arbitrary layers, geometry
  replacement, background policy, and style-free media services.
- Pair composition tests verify one geometry resolution and one required
  pairing identity for both still and motion.
- Physical-device QA must confirm `.photoLive` readback, paired resources,
  long-press playback, audio, orientation, and original-photo preservation.
