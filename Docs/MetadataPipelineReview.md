# Metadata Pipeline Review

Last updated: 2026-06-20

## Scope

This review audits PhotoMemo's current metadata pipeline without changing behavior, architecture boundaries, rendering, export, or template persistence.

Core files reviewed:

- `Source/PhotoMemo/PhotoMemo/Models/PhotoMetadata.swift`
- `Source/PhotoMemo/PhotoMemo/Models/MetadataContext.swift`
- `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
- `Source/PhotoMemo/PhotoMemo/Engines/TemplateVariableEngine.swift`
- `Source/PhotoMemo/PhotoMemo/Engines/CardTextBlockEngine.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`

## 1. Current Pipeline Diagram

```text
Photo file
  ->
PhotoImportService
  ->
PhotoMetadataReader
  ->
PhotoMetadata
  ->
SelectedPhoto
  ->
RecordCardBuildService
  |- MetadataContext.build(from:)
  |- AnchorEngine.build(from:photoDate:)
  ->
RecordCard
  ->
CardVariableProvider.build(from:)
  ->
TemplateVariableEngine / CardTextBlockEngine
  ->
RecordCardRenderer
  ->
RecordCardExportService
  ->
PhotoLibraryExportService
  ->
System Photos album
```

Share extension path:

```text
Shared images
  ->
PhotoMemoShareExtensionIntakeService
  ->
ExternalPhotoIntakeStore
  ->
ExternalPhotoIntakeRequest(configuration snapshot only)
  ->
PhotoMemoAppRuntime.flushExternalRequests()
  ->
BatchQueueExecution
  ->
PhotoImportService
  ->
normal metadata pipeline starts here
```

### Stage summary

1. `PhotoImportService` loads file bytes and raw `CGImageSource` properties.
2. `PhotoMetadataReader` extracts a typed `PhotoMetadata` value from TIFF, EXIF, and GPS dictionaries.
3. `SelectedPhoto` keeps three parallel forms together:
   - original file URL
   - original image-source properties
   - typed `PhotoMetadata`
4. `RecordCardBuildService` converts `PhotoMetadata` into:
   - `MetadataContext`
   - `AnchorResult` derived from `captureDate`
   - final `RecordCard`
5. `CardVariableProvider` adds card-level and anchor-level computed values, producing the full variable-resolution context.
6. `TemplateVariableEngine` resolves `{{token}}` strings into plain strings.
7. `CardTextBlockEngine` converts resolved template items into visible text blocks for rendering.
8. `RecordCardRenderer` consumes `RecordCard` plus resolved text blocks; it does not read EXIF directly except through `card.metadata` for layout sizing.
9. `RecordCardExportService` renders the final image and writes a sanitized metadata dictionary based on original source properties.
10. `PhotoLibraryExportService` saves the finished image into Photos and can re-read the saved asset metadata for verification.

## 2. Metadata Ownership

| Component | Owns | Transforms | Should Never Modify |
| --- | --- | --- | --- |
| `PhotoMetadataReader` | Raw extraction rules from ImageIO dictionaries | TIFF/EXIF/GPS -> `PhotoMetadata` | Template strings, anchor semantics, user text |
| `PhotoMetadata` | Canonical in-memory photo metadata record | Nothing by itself | Rendering text, variable catalog, export wording |
| `PhotoImportService` | Import orchestration and `SelectedPhoto` assembly | File URL -> `SelectedPhoto` | Metadata semantics, variable names |
| `SelectedPhoto` | Parallel container of file URL, raw properties, image, metadata | Nothing by itself | Metadata values |
| `MetadataContext` | String-key runtime context for raw normalized values | Typed metadata -> string values | Photo file, export metadata, source properties |
| `AnchorEngine` | Time-relative derived metrics | `captureDate` + anchor -> `AnchorResult` | Raw EXIF fields |
| `RecordCardBuildService` | Composition of metadata, anchor, template, badge into `RecordCard` | `SelectedPhoto` + configuration -> `RecordCard` | Raw metadata extraction logic |
| `RecordCard` | Runtime package consumed by renderer/export | Nothing by itself | Source file metadata |
| `CardVariableProvider` | Card-level computed variables | `RecordCard` -> enriched `MetadataContext` | Raw `PhotoMetadata` storage |
| `TemplateVariableEngine` | Token replacement only | Template string + context -> plain string | Metadata extraction, anchor math |
| `CardTextBlockEngine` | Rendering block assembly | `RecordCard` -> `[CardTextBlock]` | Raw metadata |
| `RecordCardRenderer` | Visual presentation | Card + blocks -> SwiftUI view | Metadata values, template persistence |
| `RecordCardExportService` | Final image file and metadata write-back dictionary | Source properties + rendered image -> output file | Canonical `PhotoMetadata` |
| `PhotoLibraryExportService` | Photo library save/read-back orchestration | Output file -> Photos asset | Template, anchor, variable context |
| `BatchConfigurationSnapshot` | Template/anchor/badge/output preferences | Stored settings -> batch runtime config | Per-photo metadata |
| `PhotoMemoShareExtensionIntakeService` | Intake persistence only | Shared item providers -> managed files + config snapshot | EXIF parsing, variable resolution |
| `ExternalPhotoIntakeRequest` | Request envelope for later processing | Holds file URLs and configuration | Per-photo metadata |

## 3. Metadata Flow And Boundaries

### Import boundary

- Input: user-selected file URL or share-extension managed file URL
- Owner: `PhotoImportService`
- Output:
  - original `sourceProperties`
  - decoded display image
  - typed `PhotoMetadata`

This is the canonical metadata entry point. There is no second EXIF reader in the share extension or batch configuration path.

### Metadata read boundary

- Owner: `PhotoMetadataReader`
- Reads:
  - pixel width and height
  - TIFF make, model, fallback date
  - EXIF ISO, aperture, exposure time, focal lengths, lens model, original date
  - GPS latitude, longitude, altitude
- Does not currently resolve:
  - human-readable place names
  - timezone offsets
  - GPS direction references
  - flash / white balance / orientation / megapixels / aspect ratio

### Normalization boundary

- Owner: `MetadataContext.build(from:)`
- Converts typed values into string-key context values used by the variable system.
- Important detail:
  - the context is string-only
  - missing and empty values both collapse to empty string at lookup time

### Variable-resolution boundary

- Owners:
  - `CardVariableProvider`
  - `TemplateVariableEngine`
- `CardVariableProvider` adds computed values such as:
  - `capture_date_display`
  - `camera_summary`
  - `memory_summary`
  - all `anchor_*` values
- `TemplateVariableEngine` is deliberately dumb:
  - it performs token replacement only
  - it does not know where metadata came from

### Rendering boundary

- Owners:
  - `CardTextBlockEngine`
  - `RecordCardRenderer`
- Renderer consumes already-resolved strings.
- The only direct metadata coupling left in renderer/export layout is image sizing via `imageWidth` and `imageHeight`.

### Export boundary

- Owners:
  - `RecordCardExportService`
  - `PhotoLibraryExportService`
- Export reuses original `sourceProperties`, updates dimensions/orientation, and writes description text into EXIF/TIFF/IPTC/PNG dictionaries where possible.
- Photo library save sets Photos `creationDate` from `metadata.captureDate`.

### Share extension boundary

- Share extension does not read EXIF.
- Share extension only:
  - stores managed file copies
  - stores `BatchConfigurationSnapshot`
  - stores import summary counts
- Real metadata reading begins only after the main app drains the intake request and runs `PhotoImportService`.

## 4. Current Supported Metadata

### 4.1 Canonical raw metadata model

| Field | Description | Source | Current Usage | Future Potential |
| --- | --- | --- | --- | --- |
| `captureDate` | Photo capture timestamp | TIFF `DateTime`, EXIF `DateTimeOriginal` | Anchor calculations, display time, Photos creation date, export file dates | timezone-aware variables, day-period variables, solar-event variables |
| `deviceBrand` | Camera/phone make | TIFF `Make` | `{{brand}}` | brand-model compact variables |
| `deviceModel` | Camera/phone model | TIFF `Model` | `{{model}}`, camera summaries, default gear lines | short model, device family, front/back lens inference |
| `lensModel` | Lens model string | EXIF `LensModel` | `{{lens}}`, gear lines | lens-family variables, focal-profile grouping |
| `iso` | ISO value as string | EXIF ISO speed ratings | `{{iso}}`, `camera_summary` | exposure-grade variables |
| `aperture` | F-number as string | EXIF `FNumber` | `{{aperture}}`, `camera_summary` | depth-of-field style summaries |
| `shutterSpeed` | Exposure time string | EXIF `ExposureTime` | `{{shutter}}`, `camera_summary` | motion/long-exposure classification |
| `focalLength` | Native focal length | EXIF `FocalLength` | `{{focal_length}}` | lens angle labels |
| `focalLength35mm` | 35mm equivalent focal length | EXIF `FocalLenIn35mmFilm` | `{{focal_len_in_35mm_film}}`, `camera_summary` | wide/standard/tele classification |
| `imageWidth` | Source pixel width | ImageIO top-level properties | layout orientation, export size, `{{width}}` | aspect-ratio and megapixel variables |
| `imageHeight` | Source pixel height | ImageIO top-level properties | layout orientation, export size, `{{height}}` | aspect-ratio and megapixel variables |
| `latitude` | GPS latitude | GPS dictionary | available in `MetadataContext` only | mapping, place naming, local solar-time variables |
| `longitude` | GPS longitude | GPS dictionary | available in `MetadataContext` only | mapping, place naming, local solar-time variables |
| `altitude` | GPS altitude | GPS dictionary | available in `MetadataContext` only | travel/elevation variables |
| `city` | Friendly city name | model field exists but not populated by current import path | none in normal flow | location display variables |
| `district` | Friendly district name | model field exists but not populated by current import path | none in normal flow | more precise location summaries |
| `province` | Friendly province/state name | model field exists but not populated by current import path | none in normal flow | region-level location variables |
| `country` | Friendly country name | model field exists but not populated by current import path | none in normal flow | country-aware localization |
| `locationName` | Friendly display location | model field exists but not populated by current import path | none in normal flow | `{{location_display}}`, travel templates |

### 4.2 Normalized context keys produced by `MetadataContext`

| Context Key | Description | Source | Current Usage | Future Potential |
| --- | --- | --- | --- | --- |
| `brand` | normalized brand string | `deviceBrand` | template variables | short device variables |
| `model` | normalized model string | `deviceModel` | template variables, summaries | device grouping |
| `lens` | normalized lens string | `lensModel` | template variables | lens labeling |
| `iso` | normalized ISO string | `iso` | template variables, summaries | exposure categories |
| `aperture` | normalized aperture string | `aperture` | template variables, summaries | depth labels |
| `shutter` | normalized shutter string | `shutterSpeed` | template variables, summaries | motion labels |
| `focal_length` | normalized focal length | `focalLength` | template variables | focal classes |
| `focal_len_in_35mm_film` | normalized 35mm equivalent | `focalLength35mm` | template variables, summaries | lens semantics |
| `width` | pixel width string | `imageWidth` | template variables | aspect variables |
| `height` | pixel height string | `imageHeight` | template variables | aspect variables |
| `latitude` | latitude string | `latitude` | resolvable if manually typed token exists | map-aware variables |
| `longitude` | longitude string | `longitude` | resolvable if manually typed token exists | map-aware variables |
| `altitude` | altitude string | `altitude` | resolvable if manually typed token exists | elevation variables |
| `city` | city name | `city` | currently blank in normal flow | place summaries |
| `district` | district name | `district` | currently blank in normal flow | place summaries |
| `province` | province/state | `province` | currently blank in normal flow | place summaries |
| `country` | country | `country` | currently blank in normal flow | localization |
| `location` | friendly location | `locationName` | prioritized by variable library but not populated | high-value location display |
| `year` | capture year | `captureDate` | template variables | season and year-based grouping |
| `month` | zero-padded month | `captureDate` | template variables | seasonal variables |
| `day` | zero-padded day | `captureDate` | template variables | festival/anniversary logic |
| `hour` | zero-padded hour | `captureDate` | template variables | day period and golden-hour logic |
| `minute` | zero-padded minute | `captureDate` | template variables | time-only display variables |
| `second` | zero-padded second | `captureDate` | template variables | precise timestamp variants |
| `weekday` | numeric weekday | `captureDate` | not surfaced in picker | localized weekday variants |
| `weekday_name` | English weekday name | `captureDate` | template variables | localized weekday display |

### 4.3 Computed card and memory variables

| Variable / Key | Description | Source | Current Usage | Future Potential |
| --- | --- | --- | --- | --- |
| `title` | card title | `RecordCard.title` | user variables | richer editor presets |
| `story` | card story text | `RecordCard.story` | user variables | freeform memory writing |
| `tags` | comma-separated tags | `RecordCard.tags` | user variables | search/export descriptions |
| `badge_name` | badge/logo name | `RecordCard.badge` | hidden context key | export descriptions, audit trails |
| `capture_date_display` | formatted `yyyy.MM.dd HH:mm:ss` text | `captureDate` | template variable, export description | localized variants, short/long forms |
| `camera_summary` | compact camera parameter summary | camera fields | template variable, right-top defaults, export description | richer preset summaries |
| `memory_summary` | story text or anchor summary | story + anchor result | template variable, immers preset, export description | dedicated memory template family |
| `anchor_title` | anchor name | `Anchor` | template variables | user-defined milestone families |
| `anchor_primary` | main anchor result | `AnchorResult` | template variables | smarter defaults |
| `anchor_secondary` | formatted anchor date | `AnchorResult` | template variables | alternate date styles |
| `anchor_summary` | full anchor summary | `AnchorResult` | template variables | export summaries |
| `anchor_smart_text` | scenario-aware smart anchor text | `AnchorResult` + anchor type | template variables | future product copy presets |
| `anchor_countdown_text` | countdown text | `AnchorResult` | template variables | countdown templates |
| `anchor_age_text` | age text | `AnchorResult` | template variables | child-growth templates |
| `anchor_duration_text` | duration text | `AnchorResult` | template variables | anniversary templates |
| `anchor_total_days_text` | total day count text | `AnchorResult` | template variables | challenge/record templates |
| `anchor_elapsed_text` | elapsed day text | `AnchorResult` | template variables | relationship/exam templates |
| `anchor_day_index_text` | nth-day text | `AnchorResult` | template variables | daily-record templates |
| `anchor_week_text` | week span text | `AnchorResult` | template variables | pregnancy/baby templates |
| `anchor_month_age_text` | month-age text | `AnchorResult` | template variables | child-growth templates |
| `anchor_milestone_text` | milestone text | `AnchorResult` | template variables | milestone-first presets |
| `anchor_years` | numeric years | `AnchorResult` | template variables | numeric-only templates |
| `anchor_months` | numeric months | `AnchorResult` | template variables | numeric-only templates |
| `anchor_days` | numeric days | `AnchorResult` | template variables | numeric-only templates |
| `anchor_hours` | numeric hours | `AnchorResult` | hidden context key only | precise timers if later surfaced |
| `anchor_minutes` | numeric minutes | `AnchorResult` | hidden context key only | precise timers if later surfaced |
| `anchor_seconds` | numeric seconds | `AnchorResult` | hidden context key only | precise timers if later surfaced |
| `anchor_total_days` | numeric total days | `AnchorResult` | template variables | sorting / threshold logic |

## 5. Key Assessment

### What is healthy today

- There is one real metadata-read path: `PhotoMetadataReader`.
- `PhotoMetadata` is the only typed runtime metadata model.
- Share extension does not introduce a second metadata source of truth.
- Variable resolution is correctly separated from metadata extraction.
- Export uses original source properties as the preservation baseline instead of rebuilding metadata from scratch.

### What is incomplete today

- Friendly location fields exist in the model but are not populated by the current import path.
- Variable catalog coverage does not fully match runtime context coverage.
- Metadata normalization is string-only and loses provenance, locale intent, and missing-value semantics.
- Time and location semantics are only partially normalized, which limits future high-value variables.

## 6. Bottom Line

PhotoMemo already has a recognizable canonical metadata pipeline:

`PhotoMetadataReader -> PhotoMetadata -> MetadataContext / CardVariableProvider -> TemplateVariableEngine -> Renderer / Export`

That is a strong foundation.

The next architecture-safe step is not a rewrite. It is to harden the existing pipeline by:

1. aligning the variable catalog with the real context keys,
2. normalizing capture-time and GPS semantics more carefully,
3. wiring friendly location enrichment into the existing `PhotoMetadata` flow,
4. adding regression coverage around metadata preservation and variable output.
