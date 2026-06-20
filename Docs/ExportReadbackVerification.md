# Export Read-back Verification

Last updated: 2026-06-20

## Goal

Verify the current read-back chain:

`Export File -> PhotoMetadataReader`

and, for Photos saves:

`Saved Asset -> temporary exported resource -> PhotoMetadataReader`

## Read-back Path

Current implementation:

1. `RecordCardExportService` writes the rendered file
2. `PhotoLibraryExportService.readMetadata(forSavedAsset:)` exports the saved asset resource to a temporary file
3. `PhotoMetadataReader` reads that file back into `PhotoMetadata`

Important boundary:

- `PhotoMetadataReader` only reads width/height, TIFF, EXIF, and GPS
- it does **not** read description fields, ICC/profile fields, or Photos asset-level creation date

## Comparison Matrix

| Field | Embedded export expectation | `PhotoMetadataReader` read-back expectation | Result |
| --- | --- | --- | --- |
| Capture date | preserved only if original EXIF/TIFF date fields survive pass-through | readable if `DateTimeOriginal` or TIFF `DateTime` still exists | conditional |
| Capture timezone | preserved only if date string with timezone survives export | readable only when date string still contains a timezone suffix | conditional |
| Width / height | rewritten to final rendered card size | should read final exported size | strong |
| Orientation | top-level orientation forced to `1` | not read directly; normalized orientation is inferred from width/height | strong for final shape, weak for raw EXIF-orientation inspection |
| GPS | original GPS dictionary carried forward when possible | readable if destination keeps GPS dictionary | conditional |
| Camera make/model | preserved by TIFF pass-through | readable if TIFF survives export | conditional |
| Lens model | preserved by EXIF pass-through | readable if EXIF survives export | conditional |
| Description | written to EXIF/TIFF/IPTC/PNG when enabled | not read back into `PhotoMetadata` today | no normalized read-back support |
| Photos asset creation date | set during save to Photos | not part of `PhotoMetadataReader` contract | separate asset-level behavior |

## What Is Reliably Verifiable Today

The current normalized read-back path is reliable for:

- final output dimensions
- final aspect-ratio/orientation shape
- camera/lens/exposure values when the destination retains EXIF/TIFF
- GPS when the destination retains GPS

## What Is Not Reliably Verifiable Today

The current normalized read-back path does not verify:

- description text written into EXIF/TIFF/IPTC/PNG
- ICC / color profile preservation
- Photos asset creation date
- any metadata family not parsed by `PhotoMetadataReader`

## Photos Save Specific Notes

`PhotoLibraryExportService` sets:

- `PHAssetCreationRequest.creationDate = metadata.captureDate`

This helps the saved asset sort correctly in Photos, but it is not the same as proving that the exported file still embeds the original EXIF capture timestamp.

## Verification Conclusion

PhotoMemo currently has a useful read-back loop, but it is a **normalized metadata read-back**, not a complete embedded metadata diff tool.

For Sprint-008 this means:

- width/height/orientation behavior is reasonably auditable
- capture date, timezone, GPS, camera, and lens are only as strong as pass-through retention
- description metadata write behavior is now correct, but not fully re-readable by the app's own metadata model

## Recommended Follow-up

If a later sprint wants stronger export proof, add a dedicated file-level metadata validator that can inspect:

- EXIF date keys
- TIFF description keys
- IPTC caption
- ICC/profile presence
- raw orientation tag
