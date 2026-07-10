# MemoMark Production Audit v2.0 Module 4

Module: Media Pipeline Audit

Date: 2026-07-10

Baseline: `f74717f Add Production Audit v1.0 report`

## Scope

This module reviews:

- still image import/export
- metadata reading and preservation
- Renderer/build/export boundary
- Live Photo main picker path
- Share Extension media intake
- Photo Library save-back
- MediaPipelineVNext extensibility
- RAW/HDR/video/spatial photo readiness

No files were modified during this module review.

## Executive Assessment

Rating: **B for current still/main-picker scope, D for broad media claims**

The still-image pipeline and main-app picker Live Photo candidate have real
implementation and meaningful focused test coverage. The Share Extension Live
Photo path is not production-ready because the extension can receive flattened
still representations without a usable PhotoKit asset identity.

The core release principle is simple: MemoMark may ship a limited TestFlight
candidate for still images and main-app picker Live Photo, but it must not claim
Share Extension Live Photo, HDR/RAW preservation, video, or Spatial Photo
support.

## Evidence

Primary files reviewed:

- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift:27`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift:115`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:27`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:112`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift:192`
- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MediaProcessingRouter.swift:18`
- `Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift:150`

Relevant tests:

- `Tests/PhotoMemoTests/MetadataTests/PhotoMetadataReaderTests.swift:9`
- `Tests/PhotoMemoTests/ExportTests/PhotoImportServiceTests.swift:494`
- `Tests/PhotoMemoTests/ArchitectureTests/LivePhotoAssetWriterContractTests.swift:9`
- `Tests/PhotoMemoTests/BatchTests/LivePhotoBatchQueueExecutionTests.swift:11`

## Ratings

| Dimension | Rating | Rationale |
|---|---|---|
| Still Image Pipeline | B+ | Functional and tested, with metadata parity debt. |
| Main-Picker Live Photo | B | Stronger path because PhotoKit identity can survive. |
| Share Extension Live Photo | D+ | Cannot yet preserve real Live Photo identity/resources reliably. |
| Metadata Preservation | B- | Good intent, split policy implementation. |
| RAW/HDR/Video/Spatial Readiness | C- | Current model lacks first-class capability semantics. |
| Testability | B | Good contract tests; real-device Share Extension evidence missing. |
| Release Confidence | Conditional | Depends entirely on release messaging scope. |

## P0 Findings

No P0 for the current stated release scope if Live Photo support remains limited
to the main app picker.

Conditional P0:

If release messaging claims Share Extension Live Photo support, that becomes P0.
The Share Extension does not preserve a usable `PHAsset.localIdentifier` or real
paired still/video resource set in the reviewed path.

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift:645`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift:1454`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift:1530`

## P1 Findings

### P1-01: Live Photo route identity is not first-class in route contract

Evidence:

- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MediaProcessingRouter.swift:25`
- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MediaProcessingRoute.swift:11`
- `Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift:240`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:766`

Impact:

Routing can describe Live Photo media by content type/subtype, but the real
processor needs a PhotoKit asset identity. The contract cannot express the
difference between "looks like Live Photo" and "can be processed as Live Photo".

Immediate fix?

Recommended before broadening Live Photo beyond main picker.

### P1-02: Static export can preserve stale Live Photo pairing metadata

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:550`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:557`
- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MetadataPolicyPlan.swift:353`

Impact:

Static export copies `sourceProperties` wholesale and does not consistently
apply the VNext removal policy. A static output can retain stale Live Photo
pairing metadata even though it is no longer paired with motion.

Immediate fix?

Recommended before production release; acceptable as a known limitation in
limited internal TestFlight if scoped.

### P1-03: Capture-time truth can degrade to build/export time

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:173`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:181`

Impact:

Anchor calculations can use `Date()` when EXIF capture date is missing. This
violates the Capture-Time Principle.

Immediate fix?

Recommended before treating Share Extension or metadata-poor inputs as stable.

### P1-04: Static HEIC non-ASCII `UserComment` parity issue

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:582`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:649`
- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoStillImageCompositionInput.swift:308`

Impact:

Live Photo HEIC avoids writing non-ASCII text to EXIF `UserComment`, while
static HEIC still has a separate path. Metadata readback parity can differ.

Immediate fix?

Recommended before metadata preservation claims are broadened.

### P1-05: Runtime gate naming conflicts with production behavior

Evidence:

- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MediaPipelineRuntimeGate.swift:34`
- `Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift:76`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:82`

Impact:

`.v1Production` says writes are disabled, while the default processor uses an
`.internalTesting` gate with Photo Library writes enabled. The code may work,
but the release governance model is confusing.

Immediate fix?

Recommended before TestFlight notes and code gates are considered aligned.

## P2 Findings

### P2-01: EXIF timestamps without timezone rely on formatter defaults

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift:21`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift:347`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift:387`

Classification: long-term architecture.

### P2-02: Export memory pressure is modeled but not enforced

Evidence:

- `Source/PhotoMemo/PhotoMemo/Models/PhotoProcessingInputPolicy.swift:39`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:136`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:1065`

Classification: near-term maintenance.

### P2-03: Temporary file lifecycle is distributed

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift:61`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:76`
- `Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift:552`

Classification: future capability blocker for larger media.

## Architecture Debt

- Metadata policy is split between old still export and VNext policy types.
- Live Photo footer geometry still reaches into renderer/layout constants
  instead of a future Layout Engine output.
- Current media model lacks first-class HDR, color profile, bit depth,
  depth/disparity, spatial photo, video codec, or auxiliary resource semantics.

## Evolution Review

MemoMark can evolve into a stronger media pipeline, but it needs a
`MediaAssetCapabilities` concept before HDR, RAW, video, or spatial media are
seriously attempted.

Current `PhotoProcessingInputPolicy` intentionally supports still-focused input
types and excludes video/GIF/WebP/general Live by standard policy. That is a
reasonable V1 boundary.

## API Design Review

Good:

- Live Photo loading/writing protocols exist.
- Photo Library export is behind a protocol boundary.
- Still metadata writer abstractions exist.

Gap:

`MediaProcessingRoute` should carry source identity and media capability, not
only content type, URL, dimensions, and `isLivePhotoAsset`.

## Dependency Review

PhotoKit is mostly isolated in save/load services. The hard platform dependency
is that production Live Photo requires PhotoKit asset identity or paired still
and video resources to survive intake.

## Testability Review

Strong:

- Live Photo writer contracts
- pairing identity verifier
- metadata policy resolver tests
- routing tests

Missing:

- real-device Share Extension Live Photo identity smoke
- static HEIC non-ASCII readback parity
- stale MakerApple/Live Photo metadata removal from static output
- HDR/color profile round-trip fixtures
- spatial/depth auxiliary metadata fixtures

## Immediate Fixes

- Keep release language narrow: main-app picker Live Photo only.
- Replace `Date()` capture fallback with explicit missing behavior if Share
  Extension or metadata-poor input is part of the current validation story.
- Rename or rework runtime gates so production write behavior is clear.
- Treat static export metadata-policy parity as scoped hardening, not a broad
  export rewrite under the current IA-003 boundary.
- Keep stale Live pairing metadata removal as a near-term release-quality patch
  only if it can be implemented surgically.

## Long-Term Optimization

- Unify still export and Live Photo still composition under one metadata policy
  path.
- Add `MediaAssetCapabilities`.
- Move footer geometry to future Layout Engine output before video/spatial work.

## Release Recommendation

Conditional Yes for still-image and main-app picker Live Photo TestFlight smoke.

Do not market Share Extension Live Photo, HDR/RAW preservation, general video,
or Spatial Photo support.
