# Regression Matrix

Last updated: 2026-06-20

## Purpose

This matrix defines the repeatable regression coverage MemoMark should maintain.

## Matrix

| Area | Input | Expected output | Failure condition |
| --- | --- | --- | --- |
| Metadata read | still photo with EXIF/TIFF/GPS | `PhotoMetadataReader` returns normalized metadata values | missing or incorrect capture date, camera, GPS, or dimensions |
| Metadata normalization | raw metadata values with mixed whitespace / sign / timezone formats | `PhotoMetadata.normalized()` returns canonical values | display fields remain inconsistent or invalid |
| Timezone normalization | capture-date string with timezone suffix | `captureTimezoneOffsetSeconds` and date-derived context reflect capture timezone | date parts or timezone text shift incorrectly |
| GPS normalization | latitude/longitude plus ref fields | signed coordinates match hemisphere | south/west values remain positive |
| Variable resolution | template string with known tokens | `TemplateVariableEngine` substitutes all available values | tokens remain unresolved or wrong values are inserted |
| Metadata context generation | `PhotoMetadata` with date, location, camera fields | `MetadataContext` contains aligned runtime keys | context key missing or mismatched |
| Render preparation | portrait/landscape metadata | derived orientation/aspect-ratio helpers remain correct | portrait/landscape inference regresses |
| Description writing | `shouldWritePhotoDescription = false` | exported description metadata is suppressed | metadata description still written |
| Export | selected photo + card + template | rendered file is produced with final dimensions and upright orientation | export fails or dimensions/orientation mismatch |
| Export read-back | exported file re-read by `PhotoMetadataReader` | width/height and preserved metadata remain acceptable | read-back loses required fields unexpectedly |
| Batch export | multiple intake payloads | per-task results are deterministic, cleanup occurs, partial failure is isolated | one failure corrupts full batch semantics or temp files leak |
| Photo Library save | exported file saved to Photos | asset is created, target album resolved, creation date applied when present | asset not created, album routing fails, or save error is silent |
| Live Photo boundary | still resource derived from Live Photo | app treats it as still-image input only | product claims paired-resource support without implementation |

## Automated Coverage Landed Through Sprint-010

The repository now automates:

- metadata normalization
- metadata context generation
- template variable resolution
- GPS normalization
- timezone normalization
- description writing switch
- aspect-ratio/orientation helpers
- fixture-backed JPEG import/export/read-back verification
- fixture-backed HEIC import plus export verification
- description metadata assertions across EXIF/TIFF/IPTC families
- batch queue fixture coverage for enqueue, cancellation, and retry eligibility

## Deferred Coverage

The following remain planned but not automated yet:

- renderer snapshot tests
- export file binary diff tests
- Photos save integration tests
- batch end-to-end rendered export/save execution against Photos

## Acceptance Use

This matrix is the baseline for future CI selection:

- smoke layer: pure logic and deterministic model tests
- fixture layer: committed synthetic sample import/export verification
- integration layer: Photos/batch/environment-dependent checks
