# PhotoMemo MVP

## Goal

Ship a reliable local-first pipeline that turns a photo into a finished PhotoMemo image with real EXIF-driven context.

## MVP Workflow

1. Set template
2. Set anchor
3. Import one preview photo
4. Read EXIF and capture time
5. Render bottom card with custom regions and smart modules
6. Save configuration
7. Receive future photos from external entry points
8. Process in background
9. Save generated images to the system photo library and chosen album

## Must Have

### Template Calibration

- one stable preview surface
- four independently editable custom regions
- module insertion based on the active region
- badge/icon slot

### Anchor Semantics

- past anchor support
- future anchor support
- smart outputs such as age, duration, elapsed days, countdown, day index, week text, month age

### Real Metadata

- capture date
- device and lens fields
- exposure fields
- graceful fallback when metadata is incomplete

### Export

- generate a new image
- write to system photo library
- support default PhotoMemo album or chosen existing album
- preserve metadata usefulness as much as platform APIs allow

### Background Entry

- open file or external intake into queue
- background batch processing
- success and failure notifications

## Not In MVP

- cloud sync
- online reverse geocoding as a default requirement
- template marketplace
- social sharing layer
- Live Activities or Dynamic Island as a shipping requirement on macOS
