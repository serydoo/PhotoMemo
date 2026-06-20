# Metadata Inventory

Last updated: 2026-06-20

## Canonical Source Of Truth

The canonical metadata inventory now lives in code at:

- `Source/PhotoMemo/PhotoMemo/Models/PhotoMetadata.swift`
- `PhotoMetadata.canonicalInventory`

That inventory defines the authoritative metadata-field contract for Sprint-007:

- field name
- Swift type
- source
- owner
- public variables
- internal-only status
- default value
- documentation

## Stored Metadata Fields

| Field | Swift Type | Source | Owner | Public Variables | Default |
| --- | --- | --- | --- | --- | --- |
| `captureDate` | `Date?` | TIFF / EXIF capture date | `PhotoMetadata` | `year`, `month`, `day`, `hour`, `minute`, `second`, `weekday`, `weekday_name`, `capture_date_display`, `capture_date_short`, `capture_time_short` | `nil` |
| `captureTimezoneOffsetSeconds` | `Int?` | timezone suffix parsed from metadata date string when present | `PhotoMetadata` | `capture_timezone` | `nil` |
| `deviceBrand` | `String` | TIFF `Make` | `PhotoMetadata` | `brand` | `""` |
| `deviceModel` | `String` | TIFF `Model` | `PhotoMetadata` | `model` | `""` |
| `lensModel` | `String` | EXIF `LensModel` | `PhotoMetadata` | `lens` | `""` |
| `iso` | `String` | EXIF ISO | `PhotoMetadata` | `iso` | `""` |
| `aperture` | `String` | EXIF `FNumber` | `PhotoMetadata` | `aperture` | `""` |
| `shutterSpeed` | `String` | EXIF `ExposureTime` | `PhotoMetadata` | `shutter` | `""` |
| `focalLength` | `String` | EXIF `FocalLength` | `PhotoMetadata` | `focal_length` | `""` |
| `focalLength35mm` | `String` | EXIF `FocalLenIn35mmFilm` | `PhotoMetadata` | `focal_len_in_35mm_film` | `""` |
| `imageWidth` | `Int?` | ImageIO width | `PhotoMetadata` | `width`, `orientation`, `aspect_ratio`, `megapixels` | `nil` |
| `imageHeight` | `Int?` | ImageIO height | `PhotoMetadata` | `height`, `orientation`, `aspect_ratio`, `megapixels` | `nil` |
| `latitude` | `Double?` | GPS latitude plus ref sign | `PhotoMetadata` | `latitude`, `location_display` | `nil` |
| `longitude` | `Double?` | GPS longitude plus ref sign | `PhotoMetadata` | `longitude`, `location_display` | `nil` |
| `altitude` | `Double?` | GPS altitude plus altitude ref | `PhotoMetadata` | `altitude` | `nil` |
| `country` | `String?` | friendly location data if available | `PhotoMetadata` | `country`, `location_display` | `nil` |
| `province` | `String?` | friendly location data if available | `PhotoMetadata` | `province`, `location_display` | `nil` |
| `city` | `String?` | friendly location data if available | `PhotoMetadata` | `city`, `location_display` | `nil` |
| `district` | `String?` | friendly location data if available | `PhotoMetadata` | `district`, `location_display` | `nil` |
| `locationName` | `String?` | preferred friendly location label if available | `PhotoMetadata` | `location`, `location_display` | `nil` |

## Derived Metadata Fields

These are not stored separately; they are derived from canonical `PhotoMetadata`.

| Derived Field | Source | Public Variables |
| --- | --- | --- |
| `lensBrand` | normalized `lensModel` | `lens_brand` |
| `orientation` | `imageWidth` + `imageHeight` | `orientation` |
| `aspectRatio` | `imageWidth` + `imageHeight` | `aspect_ratio` |
| `megapixels` | `imageWidth` * `imageHeight` | `megapixels` |
| `locationDisplay` | `locationName` -> region hierarchy -> coordinates fallback | `location_display` |
| `captureDateShort` | `captureDate` + `captureTimezoneOffsetSeconds` | `capture_date_short` |
| `captureTimeShort` | `captureDate` + `captureTimezoneOffsetSeconds` | `capture_time_short` |
| `captureTimezone` | `captureTimezoneOffsetSeconds` | `capture_timezone` |

## Implementation Notes

- `PhotoMetadataReader` remains the only EXIF/GPS read entry point.
- `PhotoMetadata.normalized()` is now the single normalization pass for the raw model.
- `MetadataContext.Key` is the runtime-key source of truth for metadata and card variables.
- Share Extension still does not parse metadata; it only persists files and configuration snapshots.
