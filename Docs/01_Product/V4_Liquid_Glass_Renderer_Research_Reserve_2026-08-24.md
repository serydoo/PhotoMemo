# V4 Liquid Glass Renderer Research Reserve
Status: Research reserve only

Date: 2026-08-24

Product stage: V4 Expression Style System / V4.0 Research And Product Definition

Implementation status: Not authorized

This document records a bounded research result for a possible future MemoMark
Expression Style. It does not authorize a Renderer change, a persistence change,
a new Shortcut integration, a Live Photo pipeline rewrite, or a production
claim.

## 1. Research question

Can the supplied iOS 26 Shortcut and its output samples provide reusable,
measurable design and rendering rules for a future MemoMark Renderer?

Research inputs:

- Shortcut: `/Users/rui/Downloads/苹果水印液态玻璃版.shortcut`
- Original landscape: `/Users/rui/Downloads/IMG_3536.jpg`
- Watermarked landscape: `/Users/rui/Downloads/Watermark-1787564851.JPG`
- Original portrait: `/Users/rui/Downloads/IMG_3538.jpg`
- Watermarked portrait: `/Users/rui/Downloads/Watermark-1787564852.JPG`

The private image and Shortcut files remain outside the repository and must not
be committed as research fixtures.

## 2. Executive conclusion

The sample is not a normal text watermark and is not a complete visual
specification contained in the Shortcut file. It is a same-canvas, bottom
overlay information surface with an adaptive glass treatment. The Shortcut is
primarily an orchestration layer; the core visual operation is delegated to a
third-party App Intent:

```text
OMLiquidGlassWatermarkIntent
```

The most reusable MemoMark ideas are:

1. A low-interference bottom information surface instead of a corner stamp.
2. Four semantic information slots with stable roles.
3. A glass background that samples the photo behind the surface.
4. A short-side-aware geometry model for portrait and landscape output.
5. A separation between metadata-derived facts, user overrides, and rendered
   pixels.
6. A renderer that preserves the original canvas and creates a new output.

The Shortcut implementation itself is not suitable as a MemoMark foundation.
It has a third-party App Intent dependency, a likely Live Photo output-reference
problem, generic completion feedback, questionable missing-value conditions,
and no file-level proof of metadata or Live Photo fidelity.

## 3. Evidence classification

### Directly measured or parsed

- The original and output pairs have identical pixel dimensions.
- All four files are JPEG and report Display P3 through `sips`.
- The visible effect is localized to the bottom region of each output.
- Interior glass samples become brighter and lower in high-frequency detail.
- The original files contain camera, time, exposure, focal-length, ISO, and GPS
  metadata.
- The output files retain only limited basic metadata and do not retain the
  original camera, capture-time, exposure, lens, or GPS fields.
- The displayed text matches the source metadata, including 35mm-equivalent
  focal length and DMS GPS formatting.
- The Shortcut is an AEA/Apple Archive signed container with one
  `Shortcut.wflow` payload and 108 actions.
- The main rendering and location operations are third-party App Intents from
  `com.lian.omnishortcuts`.

### Strong visual inference

- The glass treatment contains at least a blur/detail-reduction pass, a light
  adaptive tint, and a border/highlight pass.
- The visible grass distortion indicates a refraction or displacement component
  in addition to ordinary blur.
- Layout is likely composed from left and right anchored groups with a flexible
  brand/divider area rather than three fixed image-wide columns.

### Still unproven

- Whether the third-party action uses SwiftUI Liquid Glass, Core Image, Metal,
  Core Graphics, or another implementation.
- Whether the third-party action is fully local or performs network work inside
  the opaque App Intent.
- Whether the Shortcut successfully preserves Live Photo pairing.
- Whether its `preserveCaptureMetadata` option has consistent behavior across
  all source formats.
- Exact font family, font sizes, blur radius, displacement map, tint alpha,
  border width, and corner-radius values.

## 4. Measured output observations

### Canvas behavior

| Property | Landscape pair | Portrait pair |
| --- | ---: | ---: |
| Canvas | 8064 x 4536 | 3213 x 5712 |
| Aspect ratio | 16:9 | 9:16 |
| Output canvas changed | No | No |
| Output profile | Display P3 | Display P3 |
| Output model/time EXIF | Removed | Removed |
| Output GPS EXIF | Removed | Removed |

The effect overlays the existing image. It does not append a footer canvas,
crop the photo, or resize the source.

### Difference-band evidence

The following is an 8x sampled difference analysis. The bounds describe a
strongly changed pixel band, not the final geometric specification of the
glass shape.

| Pair | Strong difference band | Normalized observation |
| --- | --- | --- |
| Landscape | y 3880-4471 | begins around 85.5% of image height; bottom safety gap remains |
| Portrait | y 5248-5559 | begins around 91.9% of image height; effect remains bottom-local |

Outside the bottom region, the row-level mean channel difference remains close
to JPEG recompression noise. The bottom quarter carries the meaningful output
change.

### Interior glass measurements

The following ROIs were selected inside the glass background and away from the
main text as far as the sample allowed. They are evidence of material behavior,
not final production tokens.

| Measurement | Landscape ROI | Portrait ROI |
| --- | ---: | ---: |
| Original mean RGB | 105.9 / 100.3 / 85.2 | 83.3 / 99.6 / 28.7 |
| Output mean RGB | 136.7 / 130.7 / 114.7 | 108.6 / 127.7 / 49.4 |
| Horizontal detail gradient | 0.42 -> 0.16 | 8.91 -> 1.91 |
| Interpretation | light tint plus detail reduction | stronger detail reduction on grass |

The portrait grass ROI also shows a large reduction in per-channel standard
deviation. The effect is therefore more than a white alpha fill: it lowers
local detail while preserving the broad environmental color.

## 5. Candidate visual specification

This is a provisional R0.1 research specification. Values are ranges or
relationships until more samples are measured. They must not be copied into a
Renderer as unowned constants.

### Surface geometry

```text
canvas                  = original oriented pixel canvas
surface                 = bottom same-canvas overlay
horizontal inset        = approximately 1% - 2% of image width
bottom inset            = approximately 1% - 2% of short side
height basis            = short side, not a fixed output pixel value
corner radius           = approximately half the surface height
```

The surface is a continuous pill with a fine border. It is not a rectangular
footer, a white frame, or a second canvas region.

### Information layout

```text
[ left information ]        [ brand mark | divider | right information ]
```

Left information is a two-line group:

```text
device model
capture date and time
```

Right information is a two-line group:

```text
camera parameters
location or coordinate
```

The brand mark and divider form the visual anchor between the left and right
groups. The horizontal arrangement should adapt to the actual text widths.
Long text needs an explicit truncation or fallback rule before implementation.

### Typography direction

- Use Apple system typography or a carefully measured equivalent.
- Use a stronger primary row and a lighter secondary row.
- Use white foreground without heavy black outlines.
- Keep line spacing compact and baselines aligned across left and right groups.
- Keep numeric data legible and stable; do not allow accidental wrapping.
- Treat the brand mark as an optional, policy-reviewed asset rather than a
  generic decoration.

### Material direction

The candidate rendering passes are:

```text
1. Resolve the surface geometry from the Layout Engine.
2. Sample the original image behind the surface.
3. Reduce local detail with bounded blur.
4. Apply bounded displacement/refraction.
5. Apply a light, background-aware tint.
6. Draw a fine border and restrained top-edge highlight.
7. Draw text and icon content above the material.
8. Export in the input color space when supported.
```

Refraction must have a content-sensitive ceiling. The grass sample shows that
high-frequency backgrounds can become visibly wavy when displacement is too
strong.

## 6. Metadata and content boundary

The sample validates a useful data mapping but also demonstrates a key risk:
rendered text is not equivalent to retained metadata.

### Validated mappings

- Device model: `iPhone 17 Pro Max`.
- Capture time: source `DateTimeOriginal` formatted as
  `yyyy.MM.dd HH:mm:ss`.
- Focal length: 35mm-equivalent value, not physical lens focal length.
- Aperture: `f/2.2` and `f/1.78`.
- Shutter: `1/121s` and `1/60s`.
- ISO: `ISO40` and `ISO250`.
- GPS: decimal metadata converted to degree-minute-second notation.

MemoMark should continue to use `PhotoMetadataReader` as the fact source. The
Renderer must receive resolved display values; it must not become an EXIF
reader or invent fallback facts.

Recommended slot model for a future style specification:

```text
SlotValue
├─ displayValue
├─ source: EXIF | PhotoKit | MemoryEngine | UserOverride | Unknown
├─ rawValue
├─ privacyClass
├─ missingStrategy
└─ formattingVersion
```

When a fact is missing, the future MemoMark style should prefer omission or an
explicit unavailable state. It must not silently use sample values such as a
specific iPhone model, camera setting, or location.

## 7. Shortcut implementation lessons

### Reusable ideas

- Share Sheet / Action Extension as the entry surface.
- Multiple image and Live Photo input types.
- A single per-item rendering action rather than many image-editing actions.
- Original image is not edited in place.
- Four semantic slots are passed to the renderer.
- Still and Live Photo rendering share the same conceptual content contract.

### Do not adopt as MemoMark architecture

- Third-party `OMLiquidGlassWatermarkIntent` as a core dependency.
- Opaque location resolution without a local-first guarantee.
- Defaulting missing facts to realistic-looking values.
- Localized display-string matching to identify Live Photos.
- `Encode Media(metadata = false)` followed by an opaque Live Photo action.
- A save action that references only one branch of a conditional renderer.
- One generic completion notification for a multi-item operation.
- `Save to Camera Roll` without an asset receipt, idempotency, and readback.

### Static risks retained for future verification

1. The Live Photo branch output appears not to be referenced by the subsequent
   save action; the save action points to the static branch output. This is a
   code-derived risk, not an executed failure claim.
2. Missing-value prompts contain a suspicious `photos == 2` condition. One,
   two, and three-or-more input cases must be tested before relying on its
   behavior.
3. Some metadata checks use the whole input list before the per-item loop,
   while location resolution happens inside the loop.
4. The `Photo Type` Live Photo check uses localized display strings rather than
   stable resource types.
5. The generic final notification does not establish per-item save success.

## 8. V4 development direction

This candidate belongs under the V4 Expression Style System as:

```text
Liquid Glass Bottom Metadata Overlay
液态玻璃底部元数据覆盖层
```

It is a research label, not a committed user-facing name.

The product direction is:

```text
Preset
└─ Expression Style candidate
   └─ Same-canvas Liquid Glass metadata overlay
```

It must remain separate from Memory Behavior. The surface can carry MemoMark
memory information later, but the material, geometry, and metadata presentation
grammar are independent of whether the memory behavior is Baby, Journal,
Travel, or Timeline.

### Future ownership direction

```text
Configuration Snapshot
    -> Memory Engine results
    -> Expression Style Specification
    -> Layout Engine
    -> Renderer
    -> Export / metadata merge
    -> PhotoKit save receipt
```

The Layout Engine owns measurable geometry. The Renderer consumes resolved
layers and draws them. Export owns color and metadata policy. PhotoKit owns
asset creation and readback. Live Photo composition remains in the existing
paired-resource pipeline.

### Suggested implementation order when authorized

1. Freeze the visual specification from additional paired samples.
2. Build a static-image material spike with no user-facing style or persistence
   change.
3. Validate geometry and material against landscape, portrait, bright, dark,
   smooth, and high-frequency backgrounds.
4. Add typed metadata slots and metadata-preservation tests.
5. Connect the style to the real preview/export renderer path.
6. Add Live Photo still/video parity and paired-resource verification.
7. Add an owned App Intent/Shortcut adapter only after the core pipeline is
   reliable.

## 9. Acceptance criteria for a future implementation

### Visual

- Original pixel dimensions and aspect ratio are preserved.
- Preview and exported output use the same resolved geometry.
- Bottom surface remains within the measured safe area.
- Text remains legible for long device names and long locations.
- Blur and refraction do not turn grass, leaves, or architecture into harsh
  repeating artifacts.
- Display P3 input remains Display P3 when the output path supports it.

### Metadata

- Source capture date remains distinguishable from rendered text.
- 35mm-equivalent focal length is used deliberately and tested.
- Missing fields do not become fabricated facts.
- EXIF retention policy is explicit and read back from the output.
- GPS display and GPS retention are separate user-visible decisions.

### Live Photo and delivery

- Still image and paired video use one immutable layout result.
- Both resources retain one matching Live Photo content identifier.
- Static fallback is explicit if pairing cannot be preserved.
- Each item has a durable outcome and save receipt.
- A final notification reflects persisted results, not merely a completed loop.

### Platform and accessibility

- iOS 26 availability is gated where required.
- Reduce Transparency and Increase Contrast behavior is defined for UI
  surfaces; exported image behavior remains deterministic.
- Original Photos assets are not mutated.
- No network dependency is required for the core render path.

## 10. Deferred decisions

The following remain open and must not be silently decided by the next code
change:

- Exact system font and weight mapping.
- Whether the Apple logo is retained, replaced, or made configurable.
- Exact blur and displacement implementation.
- Whether the style is a standalone Expression Style or a Style Variant.
- Whether location is represented as coordinates, short address, or a MemoMark
  memory phrase.
- Whether the surface is always bottom-anchored or can become a subject-aware
  safe-zone overlay.
- Whether iOS 26 is the minimum platform for the style or only for a Shortcut
  adapter.

## 11. Current decision

Record this work as a V4 research reserve only.

Do not:

- modify the current Classic White renderer;
- modify the approved Minimal implementation from this document;
- add Liquid Glass persistence fields;
- add a third-party Shortcut dependency;
- claim Live Photo support from the Shortcut structure;
- claim EXIF preservation from the visible watermark text;
- claim production readiness or Apple Photos certification.

The next valid decision point is a dedicated Product Design Review and an
implementation verification plan based on additional paired image and Live
Photo evidence.
