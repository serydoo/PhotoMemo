# JPEG / HEIC Compatibility

Last updated: 2026-06-20

## Scope

This document compares MemoMark output behavior for JPEG and HEIC based on the current export implementation.

## Current Output Modes

MemoMark currently has two practical output paths:

1. batch / iOS / photo-library pipeline
2. manual macOS export

Important current fact:

- batch and temporary export paths currently generate `.jpg` files
- HEIC is available only when the user manually exports to a `.heic` destination on macOS

## Compatibility Matrix

| Area | JPEG | HEIC | Notes |
| --- | --- | --- | --- |
| Renderer path | same rendered bitmap | same rendered bitmap | both use `ImageRenderer` + `CGImageDestination` |
| Metadata input | original `sourceProperties` pass-through plus sanitized patches | same strategy | no HEIC-specific metadata builder exists |
| Dimensions | rewritten to final rendered size | rewritten to final rendered size | identical logic |
| Orientation | forced to `1` | forced to `1` | identical logic |
| Description write | EXIF/TIFF/IPTC when enabled | EXIF/TIFF/IPTC when enabled | identical logic |
| Compression quality | not explicitly set | not explicitly set | ImageIO defaults currently decide |
| ICC / color profile | no explicit validation | no explicit validation | passive preservation only |
| Batch usage | yes, default path | no | current batch pipeline is effectively JPEG-only |
| Manual desktop export | yes | yes | depends on user-selected extension |

## What Is Consistent

MemoMark already keeps these parts format-neutral:

- same rendering layout
- same final pixel geometry rules
- same metadata patching logic
- same orientation normalization

## What Is Not Yet Explicitly Controlled

MemoMark does not currently set:

- JPEG compression quality
- HEIC compression quality
- HEIC-specific metadata handling
- explicit color-profile policy

This means visual and metadata consistency across JPEG and HEIC is **likely good for the shared path**, but not yet guaranteed by explicit format-specific controls.

## Product Boundary Today

The project should currently be described this way:

- JPEG is the primary operational output format
- HEIC is a supported manual-export destination, not the primary verified batch format

## Risks

1. HEIC has no dedicated verification path in the batch pipeline.
2. Compression behavior depends on platform defaults.
3. Metadata preservation remains pass-through-driven for both formats.

## Compatibility Conclusion

For Sprint-008, MemoMark is in a good position for:

- JPEG-first output reliability
- format-neutral render correctness

But it is not yet in a position to claim:

- fully validated JPEG/HEIC parity
- explicit compression equivalence
- explicit HEIC metadata guarantees beyond the shared pass-through strategy
