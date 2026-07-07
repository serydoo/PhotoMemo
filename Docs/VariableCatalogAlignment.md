# Variable Catalog Alignment

Last updated: 2026-06-20

## Goal

Sprint-007 aligns this chain:

`PhotoMetadata / MetadataContext / CardVariableProvider / TemplateVariableLibrary / TemplateVariable.all`

so the runtime metadata keys and the public variable catalog no longer drift independently.

## Runtime Key Source Of Truth

The canonical runtime key list now lives in:

- `Source/PhotoMemo/PhotoMemo/Models/MetadataContext.swift`
- `MetadataContext.Key`

All metadata and card-variable writers should use those keys instead of hard-coded string literals.

## Public Recognized Variables

The public recognized-variable catalog now includes:

- device and camera: `brand`, `model`, `lens`, `lens_brand`, `camera_summary`, `iso`, `aperture`, `shutter`, `focal_length`, `focal_len_in_35mm_film`
- date and time: `year`, `month`, `day`, `hour`, `minute`, `second`, `weekday`, `weekday_name`, `capture_date_display`, `capture_date_short`, `capture_time_short`, `capture_timezone`
- photo shape: `width`, `height`, `orientation`, `aspect_ratio`, `megapixels`
- location: `location`, `location_display`, `country`, `province`, `city`, `district`, `latitude`, `longitude`, `altitude`

## Public Intelligent Variables

The public intelligent-variable catalog now includes:

- `anchor_title`
- `anchor_primary`
- `anchor_smart_text`
- `anchor_secondary`
- `anchor_summary`
- `anchor_duration_text`
- `anchor_age_text`
- `anchor_total_days_text`
- `anchor_elapsed_text`
- `anchor_countdown_text`
- `anchor_day_index_text`
- `anchor_week_text`
- `anchor_month_age_text`
- `anchor_milestone_text`
- `memory_summary`
- `anchor_years`
- `anchor_months`
- `anchor_days`
- `anchor_total_days`

## Intentionally Internal Runtime Keys

These runtime keys still exist, but remain intentionally internal for now:

- `badge_name`
- `anchor_hours`
- `anchor_minutes`
- `anchor_seconds`

Reason:

- they are useful for internal composition or future expansion
- they are not yet important enough to justify more picker surface and help copy

## Priority Ordering

`TemplateVariableLibrary.recognized` now prioritizes the most valuable real-world metadata tokens first:

- `camera_summary`
- `model`
- `lens`
- `location_display`
- `capture_date_display`
- `capture_date_short`
- `capture_time_short`
- `focal_len_in_35mm_film`
- `aperture`
- `shutter`
- `iso`
- `location`

This keeps the picker aligned with real MemoMark usage instead of raw key order.
