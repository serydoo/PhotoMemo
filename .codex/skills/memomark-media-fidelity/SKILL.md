---
name: memomark-media-fidelity
description: Audit MemoMark media fidelity from Apple Photos resource resolution through metadata, Memory Engine inputs, rendering, export, and save-back. Use when EXIF, orientation, Live Photo, RAW, color, location, permission, or metadata preservation is in scope.
---

# MemoMark Media Fidelity

## Overview

Use this skill for media-boundary correctness, especially when user-visible
memory values or Photo Library output depend on capture context. EXIF is one
input, not the whole media contract. Keep PhotoKit API mechanics in the
generic `photokit` skill and keep MemoMark's preservation/degradation rules
here.

## Primary Files

Start from:

- `Source/MemoMark/MemoMark/Services/PhotoMetadataReader.swift`
- `Source/MemoMark/MemoMark/Models/PhotoMetadata.swift`
- `Source/MemoMark/MemoMark/Engines/AnchorEngine.swift`
- the current resource-resolution, build, export, and Photo Library services

## Review Priorities

Check in this order:

1. resource identity and still/motion pairing
2. capture date source, timezone/calendar semantics, and fallback order
3. orientation, color space, quality, device/lens/exposure fields
4. GPS/location privacy and unavailable-service degradation
5. limited-library, iCloud degraded/final callbacks, cancellation, and memory cost
6. metadata propagation into variables and preservation on new output

For every media type, write a small source-to-output evidence row:

| Stage | Required fact | Evidence | Degradation if unavailable |
| --- | --- | --- | --- |
| Photos resource | asset/resource identity and pairing | resource identifier or read-back | explicit unsupported/degraded state |
| Metadata | capture date, timezone, orientation, color, location | parsed value and source | no fabricated memory meaning |
| Memory input | value passed to Memory Engine | snapshot/contract test | block or mark unknown |
| Output | new resource and retained fields | output read-back/device check | report exact loss |

Do not treat a successful `UIImage` decode as proof that the resource, metadata,
Live Photo pairing, color profile, or iCloud final-quality state survived.

## MemoMark Media Expectations

- Memory calculations use the photo's capture context, not export time.
- Missing or ambiguous metadata degrades explicitly; it must not fabricate memory meaning.
- Never modify the original asset; output and supported paired resources are new results.
- Treat JPEG/HEIC, RAW/ProRAW/DNG, HDR, and Live Photo as distinct evidence paths.
- Location presentation is derived and permission-aware; local-first operation remains valid without geocoding.
- Do not claim a media type or metadata field is preserved without read-back or device evidence.
- Late PhotoKit callbacks must be ignored or cancelled when their task/session
  is no longer relevant; they must not overwrite a newer Memory Card state.
- Full-resolution residency, temporary files, and degraded-to-final transitions
  need an owner and cancellation path. Keep heavy work off the UI actor unless
  the API explicitly requires UI isolation.

## Output Format

When reviewing, report:

1. `Metadata Source`
2. `Observed Risk`
3. `User-Facing Impact`
4. `Fix Direction`
5. `Verification Cases`

Prefer concrete scenarios such as a capture date being replaced by export time,
a Live Photo pair being split, an iCloud degraded callback being treated as
final, or an absent capture date producing an explicit fallback.
