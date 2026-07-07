# Output Integrity Report

Last updated: 2026-06-20

## Sprint-008 Summary

Sprint-008 focused on output reliability rather than new features.

This round delivered:

- export metadata audit
- read-back verification analysis
- JPEG / HEIC compatibility review
- batch export reliability review
- Live Photo boundary assessment
- one correctness fix for photo-description writing

## Current Strengths

1. MemoMark uses one real import -> build -> render -> export -> save pipeline.
2. Output dimensions and upright orientation are intentionally normalized for the newly rendered image.
3. Original EXIF/TIFF/GPS dictionaries are carried forward instead of being discarded outright.
4. Batch processing is conservative, deterministic, and already includes strong cleanup/cancellation guards.
5. Photos save-back sets asset creation date from the normalized capture date.

## Current Weaknesses

1. Metadata preservation is still mostly pass-through-driven, not explicitly guaranteed per field family.
2. MemoMark's own read-back model does not currently re-read description/comment fields.
3. JPEG is the real operational baseline; HEIC is supported but not yet equally verified in the batch path.
4. ICC / color-profile handling is not explicitly validated.

## Known Limitations

- no dedicated fixture-based export regression suite exists yet
- no full embedded metadata diff tool exists in-app
- no Live Photo paired-resource support exists
- batch export currently behaves as JPEG-first through the temporary export path

## Correctness Fix In This Sprint

Confirmed and fixed:

- disabling `shouldWritePhotoDescription` now truly prevents MemoMark from writing export description metadata

This was a real product-integrity bug because user intent and exported metadata could previously diverge.

## Top Product Risks

1. A field may appear preserved in normal usage but still rely on ImageIO pass-through behavior rather than an explicit MemoMark contract.
2. Users may assume HEIC input or Photos workflows imply Live Photo preservation.
3. Description metadata can now be written correctly, but the app still cannot fully read it back into `PhotoMetadata`.

## Overall Assessment

MemoMark is in a good place for:

- still-photo derived output
- JPEG-first export reliability
- deterministic batch processing
- preserving useful metadata opportunistically while normalizing output geometry

MemoMark is not yet in a good place to claim:

- complete metadata preservation guarantees across all output formats
- full JPEG/HEIC parity
- Live Photo support

## Suggested Sprint-009

The next highest-value sprint should be:

- fixture-based export verification

Suggested focus:

- add a small controlled photo-fixture set
- verify embedded EXIF/TIFF/GPS before and after export
- verify Photos save-back read-back against expected values
- decide whether description/comment fields should become part of `PhotoMetadataReader`
