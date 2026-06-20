# Metadata Normalization Plan

Last updated: 2026-06-20

## Sprint-007 Outcome

Sprint-007 implemented normalization inside the existing pipeline without adding a new architectural layer.

Normalization now happens in two places:

1. `PhotoMetadataReader`
2. `PhotoMetadata.normalized()`

## Normalization Rules Implemented

### Capture date and timezone

- capture date still prefers EXIF original time when present
- timezone suffixes such as `Z`, `+0800`, `+08:00` are now parsed when present
- timezone offset is preserved separately as `captureTimezoneOffsetSeconds`
- date component rendering now respects capture timezone when available

### GPS

- latitude now respects `LatitudeRef`
- longitude now respects `LongitudeRef`
- altitude now respects `AltitudeRef`
- coordinates are range-checked and rounded
- invalid coordinates degrade to empty values instead of unsafe output

### Friendly string cleanup

- brand, model, lens, and location strings now trim and collapse whitespace
- common brand values are normalized to stable display forms
- location hierarchy avoids duplicate repeated segments

### Photo shape

- width and height are normalized to positive-only values
- orientation is derived from width and height
- aspect ratio is derived from reduced width/height
- megapixels is derived from width/height

### Location display

`location_display` now resolves with this order:

1. `locationName`
2. `country -> province -> city -> district`
3. `latitude, longitude`
4. empty string

This preserves backward compatibility for `location` while giving users a better fallback variable.

## What Sprint-007 Did Not Do

- no reverse-geocoding pipeline was added
- no share-extension EXIF parsing was added
- no renderer/export architecture changes were made
- no new metadata persistence format was introduced

## Remaining Follow-Up

Best next follow-up is still:

- metadata regression tests
- optional location enrichment
- more complete camera metadata such as flash and white balance
