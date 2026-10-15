# Shared Mid-Autumn Preview Backgrounds

Date: 2026-09-24
Status: DEBUG-native visual review update; no production output or preset behavior change.

## Decision and scope

The two product-owner-supplied Mid-Autumn images are one shared preview-photo
pair for all three presentation styles:

- landscape: 1672 × 941 PNG;
- portrait: 941 × 1672 PNG.

The review harness must show the same selected source image for Classic White,
Minimal, and FilmMark. Each style composes its own existing information/output
layer over that image. Classic White therefore gains a photo-backed review
composition only in this visual-review route; its existing production preview
and output configuration remain unchanged pending owner review.

The original bytes are retained without conversion:

- landscape SHA-256: `c532b9c078cebe2eac0a0531ecd3efe90065d02b3f50119407384814c22251d6`;
- portrait SHA-256: `2b5c084c6846ab7f70ac6aca602a1e4f15220ad5a29dc3942c7518b103a42798`.

## Ownership and boundaries

- Primary loop: Product Loop, V4.0 research and product definition.
- Source of truth for overlay semantics remains each style's existing preview,
  Layout Engine specification, resolver, and Renderer contract.
- The supplied image files are copied byte-for-byte into app assets. They are
  preview fixtures only; they do not enter presets, output configuration,
  Renderer inputs, export, PhotoKit, or user photo storage.
- Orientation is local preview state only. It selects the landscape or portrait
  review scenario and does not mutate the selected preset or output settings.
- Existing user work and unrelated dirty files remain untouched.

## Acceptance

- All three style selections resolve the same landscape asset and the same
  portrait asset, respectively.
- Classic White shows its complete information layer over the shared photo in
  the DEBUG review route.
- Minimal and FilmMark continue to use their current style-specific layout and
  content ownership over those shared images.
- Asset source SHA-256 values match the two user-provided originals exactly.
- Focused asset-selection/presentation tests and an iOS Debug build pass.
- Physical iPhone visual review remains a separate required UI acceptance step;
  the DEBUG review route is not production acceptance.
