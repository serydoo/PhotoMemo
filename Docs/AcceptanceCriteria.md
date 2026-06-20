# Acceptance Criteria

Last updated: 2026-06-20

## Purpose

This document defines the minimum product acceptance criteria for PhotoMemo's verification stage.

## Metadata Correctness

PhotoMemo is acceptable only if:

- capture date is read when valid EXIF/TIFF date metadata exists
- timezone suffixes are normalized when present
- GPS sign handling is correct for north/south/east/west
- missing metadata degrades gracefully without crashing
- metadata-derived public variables remain aligned with runtime context

## Render Correctness

PhotoMemo is acceptable only if:

- portrait and landscape orientation inference remain correct
- preview/build logic continues to consume normalized metadata
- renderer-facing values do not require business logic repair inside the renderer

## Export Correctness

PhotoMemo is acceptable only if:

- export produces a new rendered image
- output dimensions reflect the final rendered card
- output orientation is upright for the new rendered bitmap
- description metadata is written only when the corresponding setting is enabled
- batch export uses the same core export path as single export

## Performance Baseline

Current baseline in this sprint is qualitative, not benchmark-driven.

Minimum expectation:

- metadata normalization tests should run quickly as unit tests
- the first smoke suite should remain suitable for local developer runs and future CI

Formal performance budgets are deferred to a later sprint.

## Supported Formats

Current practical support baseline:

- JPEG
- HEIC / HEIF
- PNG
- TIFF

Operational priority:

- JPEG-first workflows are the primary verified baseline

## Unsupported Or Not Yet Verified Scenarios

- RAW import as a regression-guaranteed workflow
- Live Photo paired-resource preservation
- explicit ICC/profile parity guarantees across formats
- full end-to-end Photos integration tests in CI

## Known Limitations

- fixture coverage is currently synthetic and deterministic, not camera-original
- renderer snapshot coverage is not introduced in this sprint
- Photos save verification still depends on manual or environment-specific checks

## Sprint-010 Acceptance

Sprint-010 is considered successful if:

- committed synthetic JPEG/HEIC fixture binaries exist
- export -> read-back verification runs from fixtures
- metadata assertions cover EXIF / TIFF / GPS / orientation / dimensions / description families
- minimal batch fixture coverage exists for enqueue / cancel / retry semantics
- the `PhotoMemoTests` suite passes
- the project still builds for:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
  - `PhotoMemoTests`
