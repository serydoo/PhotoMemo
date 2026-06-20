# Export Metadata Audit

Last updated: 2026-06-20

## Scope

This audit reviews the export metadata path in:

- `RecordCardExportService`
- `PhotoLibraryExportService`
- `PhotoMetadataReader`

Method used in this sprint:

- source-code audit
- export-path reasoning
- no dedicated photo fixture set exists in the repository yet

## Current Export Strategy

PhotoMemo does not rebuild output metadata from a new canonical writer model.

Current behavior is:

1. import the original file
2. keep original ImageIO property dictionaries in `SelectedPhoto.sourceProperties`
3. render a new bitmap for the final card
4. export by starting from the original metadata dictionary
5. overwrite only a small set of fields in `sanitizedMetadata(...)`
6. save the exported file into Photos when needed

This means PhotoMemo currently uses a **pass-through plus patching** strategy.

## Metadata Category Audit

| Category | Current behavior | Status | Notes |
| --- | --- | --- | --- |
| EXIF camera fields | preserved by carrying forward original EXIF dictionary | passive preserve | `LensModel`, ISO, aperture, shutter, focal length are not rewritten |
| EXIF pixel dimensions | rewritten to rendered output size | explicit modify | `ExifPixelXDimension` / `ExifPixelYDimension` become final card size |
| EXIF `DateTimeOriginal` | not explicitly rewritten | passive preserve | survives only if ImageIO keeps the original EXIF dictionary for the chosen output type |
| EXIF `UserComment` | written when export description is non-empty | explicit write | now also correctly disabled when `shouldWritePhotoDescription == false` |
| TIFF make/model | preserved by pass-through | passive preserve | useful for read-back camera model if destination keeps TIFF dictionary |
| TIFF `Software` | overwritten to `PhotoMemo` | explicit modify | intended provenance marker |
| TIFF `ImageDescription` | written when export description is non-empty | explicit write | disabled when description writing is off |
| GPS dictionary | not rewritten, carried forward | passive preserve | latitude/longitude/altitude rely on original dictionary surviving export |
| Top-level orientation | forced to `1` | explicit modify | correct for a newly rendered upright bitmap |
| Top-level width/height | rewritten to rendered output size | explicit modify | final exported image dimensions |
| IPTC caption | written when export description is non-empty | explicit write | `CaptionAbstract` only |
| PNG description | written only for PNG outputs | explicit write | no PNG-specific batch path exists today |
| ICC / color profile | not explicitly touched | unverified preserve | whatever is in `sourceProperties` is passed through; no dedicated validation code exists |
| File creation/modification dates | set to capture date when available | explicit file-system write | affects file attributes, not embedded EXIF |
| Photos asset creation date | set from `metadata.captureDate` during save | explicit Photos write | asset-level metadata, separate from embedded file dictionaries |

## Preserved Fields

Fields PhotoMemo tries to preserve today by carrying forward original metadata:

- EXIF camera/lens/exposure values
- TIFF make/model
- GPS values
- original capture-date dictionaries
- any additional dictionaries that ImageIO accepts for the chosen destination type

This is helpful, but it is not yet a hard guarantee because preservation depends on:

- the original file actually containing those fields
- the output format accepting those dictionaries
- ImageIO retaining them during destination finalization

## Modified Fields

Fields intentionally changed during export:

- pixel width
- pixel height
- EXIF pixel dimensions
- top-level orientation -> `1`
- TIFF `Software` -> `PhotoMemo`
- description/comment fields when enabled

These changes are expected because PhotoMemo exports a newly rendered derived image, not the original pixel buffer.

## Removed Or Not Explicitly Covered

This sprint found no explicit handling for:

- Live Photo paired video resources
- maker-note preservation validation
- XMP-specific write behavior
- explicit ICC/profile validation
- EXIF date rewrite when ImageIO drops original date fields

## Correctness Fix Landed In Sprint-008

One real export correctness issue was confirmed and fixed:

- `shouldWritePhotoDescription` previously did not actually stop metadata description writing
- `RecordCardBuildService` now returns an empty export description when description writing is disabled

Result:

- disabling photo-description writing now prevents `UserComment`, `TIFF ImageDescription`, `IPTC CaptionAbstract`, and PNG description from being written by PhotoMemo

## Audit Conclusion

PhotoMemo's current export metadata path is strongest for:

- still-photo export
- retaining original EXIF/TIFF/GPS opportunistically
- normalizing final orientation and dimensions
- stamping a controlled output description when enabled

The main remaining weakness is that preservation still depends on pass-through behavior rather than an explicit verified write contract for each metadata family.
