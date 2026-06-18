---
name: photomemo-exif
description: Inspect PhotoMemo EXIF extraction, metadata mapping, capture-date handling, and downstream metadata usage. Use when Codex needs to review PhotoMetadataReader, PhotoImportService, anchor time calculations, photo-library save behavior, or any bug involving missing or incorrect EXIF-derived values.
---

# PhotoMemo EXIF

## Overview

Use this skill for metadata correctness work, especially when user-visible text depends on capture time, device info, or photo-library persistence.

## Primary Files

Start from:

- `Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/Models/PhotoMetadata.swift`
- `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift`
- `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`

## Review Priorities

Check in this order:

1. capture date source and fallback order
2. device model and lens extraction
3. exposure values such as ISO, aperture, shutter, focal length
4. GPS and location fields
5. metadata propagation into card variables
6. metadata preservation when saving the generated image

## PhotoMemo-Specific Expectations

- Anchor calculations are only trustworthy if capture time is trustworthy
- Missing EXIF should degrade gracefully instead of corrupting templates
- Photo-library save flow should preserve useful metadata wherever the platform supports it
- Avoid location-heavy behavior unless the user really needs it; local-first simplicity is preferred

## Output Format

When reviewing, report:

1. `Metadata Source`
2. `Observed Risk`
3. `User-Facing Impact`
4. `Fix Direction`
5. `Verification Cases`

Prefer concrete examples such as "new photo replaces old capture date" or "smart age text becomes empty because captureDate is nil."
