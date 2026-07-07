# Live Photo Assessment

Last updated: 2026-06-20

## Scope

This is an evaluation-only document.

No Live Photo support was implemented in Sprint-008.

## Current Behavior

MemoMark currently operates as a **derived still-image generator**.

Current pipeline assumptions:

- input import is photo-file oriented
- rendering produces one new bitmap
- export writes one image file
- Photos save path adds one `.photo` resource

There is no current support for:

- paired Live Photo video resources
- motion metadata preservation
- re-creating a Live Photo asset pair

## Code Boundaries Observed

`PhotoImportService` currently supports still-image file types such as:

- JPEG
- PNG
- HEIC / HEIF
- TIFF

`PhotoLibraryExportService` saves output using:

- `PHAssetCreationRequest.forAsset()`
- one `.photo` resource only

`readMetadata(forSavedAsset:)` reads back:

- `.photo`
- `.fullSizePhoto`
- or the first resource

No paired-video path is present.

## Product Reality Today

If a Live Photo enters the system today, MemoMark should be understood as handling only the still-image side when a usable image resource is available.

What does not survive:

- motion component
- paired video
- Live Photo identity as a combined asset

## Risks

1. Users could assume HEIC input means Live Photo support.
2. Saving a derived still image back to Photos may look visually related to the original Live Photo while no longer being a Live Photo.
3. Current metadata/read-back tooling does not model paired resources.

## Future Options

### Option 1

Explicitly treat Live Photos as unsupported beyond still-image flattening.

Pros:

- matches current architecture
- simplest and most honest product boundary

### Option 2

Support “import still frame from Live Photo, export still result only” as an explicit documented behavior.

Pros:

- useful without needing paired-video reconstruction

### Option 3

Build real Live Photo support later.

Would require at least:

- paired resource intake
- paired resource persistence model
- save-back with still + video resources
- product decisions about whether the rendered bottom bar should replace only the still photo or require motion regeneration logic

## Recommended Product Decision

For the current MemoMark phase, the best decision is:

- do not claim Live Photo support
- describe MemoMark as a still-image derivative workflow
- if Live Photo assets are encountered, treat support as “still-image only” unless and until a dedicated Live Photo project slice is built

## Conclusion

Live Photo support is currently outside MemoMark's verified product boundary.

That is acceptable for now, because the core product promise is still-photo memory-card generation with metadata preservation, not full motion-asset reconstruction.
