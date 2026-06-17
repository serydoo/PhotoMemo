# Changelog

## 2026-06-17

### Added
- Added a real bottom-card export pipeline with `RecordCardExportService`, save panel support, and rendered image output.
- Added source file tracking on imported photos so exports can reuse original metadata where possible.
- Added time-anchor based smart fields including age text, duration text, total day count, and anchor summary variables.
- Added a minimalist white system-style main interface with dedicated sections for photo import, template preset, time anchor, variable insertion, and field editing.
- Added export description generation so the rendered card's memory text can also be written into image metadata comment/description fields for later indexing.
- Added three real local presets for your current workflow: growth memorial, daily record, and gear note.

### Changed
- Refactored the card template model from a simple three-column structure to fixed semantic regions: left top, left bottom, right top, right bottom, and badge.
- Switched anchor calculations to use the photo EXIF capture time instead of the current system time.
- Updated date/time template variables to output zero-padded values for month, day, hour, minute, and second.
- Changed anchor editing to support precise date and time input.
- Reworked the live preview renderer to use orientation-specific bottom border proportions for landscape and portrait images.
- Changed photo import to stay local-only by default and stop automatic reverse geocoding during import.
- Updated export metadata sanitization to keep source properties, refresh rendered pixel dimensions, and write PhotoMemo descriptions into TIFF, IPTC, EXIF, and PNG metadata dictionaries when available.
- Polished the main screen with stronger status feedback, softer system-style chips, and cleaner field editor presentation.
- Removed the unused reverse-geocoding service so the default offline workflow no longer compiles deprecated location lookup code.
- Reduced the main variable picker to offline-safe fields by removing reverse-geocoded location placeholders from the default UI.
- Refined the bottom card renderer with cleaner white card styling, lighter dividers, better text hierarchy, and an invisible empty badge state for final exports.
- Changed template 1 to use the anchor summary as its default right-bottom memory line so preview text and exported metadata stay aligned.

### Notes
- Locked sample-derived border height ratios:
  - Landscape: `1021 / 4536`
  - Portrait: `753 / 8064`
- Current export preserves original metadata where possible through ImageIO property copying, while rendering a new final image file.
- The right-bottom memory text and anchor summary now share the same export description source to keep preview content and saved metadata aligned.
