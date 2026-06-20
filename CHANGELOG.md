# Changelog

## Alpha 0.7 - 2026-06-20

### Added
- Added `Docs/Alpha/Alpha01.md` to define the real-world validation rhythm for the current stage.
- Added `Docs/Alpha/BugList.md`, `Docs/Alpha/UXNotes.md`, and `Docs/Alpha/KnownIssues.md` for lightweight product validation tracking.

### Changed
- Shifted repository-facing milestone wording for the current stage toward `Alpha 0.7` instead of continuing open-ended sprint naming.

### Notes
- This update is documentation-only and sets the operating model for the next round of real-device product validation.

## v0.7.4 - 2026-06-20

### Added
- Added `Docs/ShareExtensionReview.md` to evaluate the Share Extension as the primary product entry from a user perspective.
- Added `Docs/DesignSystem.md` to establish baseline UI rules for spacing, radius, typography, colors, cards, and buttons.
- Added `Docs/ProductBacklog.md` to structure future work into Now / Next / Later / Icebox.

### Changed
- Extended `Docs/ProductDirection.md` with an explicit product-polishing phase statement and links to the new supporting docs.

### Notes
- This release is documentation-only and does not change runtime behavior.

## v0.7.3 - 2026-06-20

### Added
- Added `Docs/ProductDirection.md` to formalize PhotoMemo's share-first product direction.
- Added `Docs/UX_PRINCIPLES.md` as a long-term UX baseline for future product decisions.

### Changed
- Updated the README homepage positioning to: "PhotoMemo is a memory generator built around Apple Photos, not a photo editor."
- Aligned repository-facing product language around a share-first workflow where the Main App is a configuration center and the Share Extension is the primary entry.

### Notes
- This release is documentation-only and does not change runtime behavior.

## v0.7.0 - 2026-06-20

### Added
- Added the first `MemoryEngine` foundation with `MemoryContext`, `MemoryCalculationResult`, and `MemoryVariableProvider`.
- Added new public memory variables:
  - `{{days_since}}`
  - `{{years_since}}`
  - `{{months_since}}`
  - `{{weeks_since}}`
  - `{{baby_age}}`
- Added `Docs/MemoryEngine.md` and `ADR-006` to document the new domain boundary.
- Added a dedicated `MemoryEngineTests` Swift Testing suite inside `PhotoMemoTests`.

### Changed
- Changed `CardVariableProvider` so memory-oriented values now flow through the shared Memory Engine boundary instead of ad-hoc inline fallback logic.
- Kept `memory_summary` behavior aligned with existing story-first and anchor-summary-first semantics.
- Started the repository's forward-looking version rhythm at `v0.7.0` for release-facing documentation.

### Notes
- This release intentionally does not change renderer, export, batch, or UI behavior.
- `MemoryEngineTests` currently lives inside the existing `PhotoMemoTests` target to keep the scope conservative while still providing repeatable verification.

## 2026-06-19

### Added
- Added a real `PhotoMemoiOS` target plus a buildable `PhotoMemoShareExtension` target.
- Added app-group-backed shared helpers for external intake persistence, shared defaults, and lightweight batch-configuration snapshot loading.
- Added a shared `ExternalPhotoIntakeRequest` model so the intake request schema is no longer tied to the main-app intake center file.

### Changed
- Continued shrinking `MainView` into a thin coordinator and moved more UI-heavy responsibilities into `MainView+*.swift` files.
- Refined the permission and background-processing surface so granted permissions stop occupying unnecessary sidebar space and failure summaries better describe partial-success batches.
- Changed share intake to support partial success, deduplicate repeated URLs, and filter stale/missing files before queue handoff.
- Tightened `PhotoMemoShareExtension` target membership so it now compiles against a much smaller shared core instead of dragging in the full main UI and unrelated app services.
- Updated share-extension feedback wording so partial-success messages only show non-zero skipped/failed counts.

### Notes
- The share-extension fallback path deliberately avoids `UIImage -> JPEG` re-encoding to reduce EXIF-loss risk before PhotoMemo starts real processing.
- Current iOS foundation is now target-ready and buildable, but still requires real share-sheet/manual workflow validation before calling the mobile flow polished.

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
