# High-Resolution Media Intake Foundation

Date: 2026-07-05

Status: Frozen Sprint Baseline

## Mission

Establish a unified, file-first, memory-safe high-resolution media intake
foundation for RAW, high-resolution HEIC, TIFF, DNG, and future Live Photo still
derivatives.

The goal of this sprint is not to optimize rendering quality. The goal is to
establish a canonical, memory-safe, file-first media intake pipeline for
high-resolution assets.

## Architecture Principle

High-resolution media complexity must terminate before entering the rendering
pipeline.

Renderer code must not branch on source media formats such as RAW, DNG, HEIC,
TIFF, or future Live Photo still derivatives. Format-specific decisions belong
in media intake, representation, and decode boundaries.

## Scope Freeze

- Do not refactor Renderer.
- Do not optimize final export image quality.
- Do not add Live Photo output support.
- Do not add filter, GPU, or image-enhancement paths.
- Do not modify the Memory Pipeline.
- Do not change renderer-facing APIs unless required by media representation
  convergence.

## Non-Goals

- This sprint does not improve final export quality.
- This sprint does not shorten renderer execution time.
- This sprint does not change `RecordCard` generation logic.
- This sprint does not modify the metadata pipeline.
- This sprint does not support Live Photo output.
- This sprint does not change the export contract.

## Architecture Decisions

### Single Media Intake Policy

All media entry points must rely on `PhotoProcessingInputPolicy` for supported
formats, size limits, RAW detection, Live Photo rejection or future still
derivative handling, and diagnostic rejection reasons.

### File-First Import

High-resolution media and RAW assets should enter the pipeline as file
references by default. `Data` loading is allowed only as a fallback when a file
representation is unavailable.

### Canonical Media Representation

Introduce only the thin first-version model required by this sprint:

```text
MediaAsset
-> MediaRepresentation
-> DecodePurpose
```

`MediaAsset` describes the original media source. It may include file URL,
content type, pixel size, metadata, RAW status, Live Photo status, and source
identifier. It does not decode image pixels.

`MediaRepresentation` describes an image representation already prepared for a
pipeline purpose, such as thumbnail, preview, processing, or export source. It
does not care whether the original media was RAW, DNG, HEIC, TIFF, or JPEG.

`DecodePurpose` expresses why decoding is needed, such as preview, processing,
or export. It does not decide how decoding is implemented.

Do not introduce `DecodeStrategy` in the first sprint version. Add it only when
multiple real decode implementations need to be selected explicitly.

### Single Decode Entry

File-to-image decode work must converge into one media decode layer. Business
code should not scatter direct `CGImageSource`, `CIImage`, `UIImage`, `NSImage`,
or equivalent platform-image decode decisions across unrelated services.

### Renderer Isolation

Renderer code should consume prepared image representations and existing render
models. It should not know whether the original source was RAW, DNG, HEIC, TIFF,
JPEG, or a future Live Photo still derivative.

### Memory-Aware Queue Policy

The batch queue should account for media cost, including pixel count, RAW
status, and estimated memory pressure. High-cost assets should automatically
use lower decode, render, and export concurrency.

### Diagnostics-First

Import and rejection outcomes should record enough information to explain what
happened without reproducing the original private image. Diagnostics should
capture format, content type, pixel size, RAW status, representation choice,
downsample behavior, and failure reason.

## Deliverables

1. Media Intake Convergence
2. File-first Import
3. `MediaAsset`, `MediaRepresentation`, and `DecodePurpose`
4. Preview Downsample Representation
5. Memory Budget and Queue Policy
6. Import Diagnostics

## Success Criteria

- Main App, PhotosPicker, File Import, Share Extension, and V1 Quick Action use
  `PhotoProcessingInputPolicy` for intake decisions.
- Large images and RAW assets use file-first import by default instead of using
  `Data` as the primary import path.
- Preview uses a downsample representation by default.
- Export preserves original media source semantics where the current export
  contract allows.
- Renderer code does not need to identify RAW, DNG, HEIC, TIFF, or JPEG source
  formats.
- The project has one unified decode entry for file-to-image representation
  preparation.
- All import failures expose a clear diagnostic reason.

## Implementation Order

1. Converge all intake format checks on `PhotoProcessingInputPolicy`.
2. Add the thin media model: `MediaAsset`, `MediaRepresentation`, and
   `DecodePurpose`.
3. Move PhotosPicker and file import paths toward file-first intake.
4. Route preview loading through a downsample media representation.
5. Add media cost classification and queue policy adjustments.
6. Add import diagnostics and tests for supported, rejected, RAW, and oversized
   assets.

## Review Boundary

This sprint should be reviewed as a media intake convergence project, not as a
renderer, export-quality, metadata, Memory Engine, or Live Photo project.

Future complete Live Photo, HDR, or advanced RAW decode support should build on
this foundation in separate reviewed sprints.
