# Variable Engine Roadmap

Last updated: 2026-06-20

## Current Position

PhotoMemo should keep its current rule:

- template source of truth remains `String`
- editor remains independent
- renderer consumes resolved strings
- variable engine transforms metadata; it does not own metadata

That means the future variable system should evolve by improving:

1. variable catalog completeness
2. variable naming consistency
3. metadata normalization quality
4. computed-variable coverage

It should not evolve by introducing a document tree or rich-text dependency for this subsystem.

## 1. Current Variable Architecture

### Current runtime chain

```text
Template string
  ->
TemplateVariableEngine.render()
  ->
lookup by key in MetadataContext
  ->
resolved plain string
```

### Current variable owners

- Raw normalized metadata keys come from `MetadataContext.build(from:)`
- Computed card and anchor values come from `CardVariableProvider.build(from:)`
- Public picker/catalog variables come from `TemplateVariable.all`
- Default template snippets come from `TemplateItem`

This means the current variable engine is simple and stable, but the variable catalog is distributed across several files.

## 2. Current Public Variables

### User

- `{{title}}`
- `{{story}}`
- `{{tags}}`

### Recognized: device and camera

- `{{brand}}`
- `{{model}}`
- `{{lens}}`
- `{{camera_summary}}`
- `{{iso}}`
- `{{aperture}}`
- `{{shutter}}`
- `{{focal_length}}`
- `{{focal_len_in_35mm_film}}`

### Recognized: time and image

- `{{year}}`
- `{{month}}`
- `{{day}}`
- `{{hour}}`
- `{{minute}}`
- `{{second}}`
- `{{weekday_name}}`
- `{{capture_date_display}}`
- `{{width}}`
- `{{height}}`

### Intelligent: anchor and memory

- `{{anchor_title}}`
- `{{anchor_primary}}`
- `{{anchor_smart_text}}`
- `{{anchor_secondary}}`
- `{{anchor_summary}}`
- `{{anchor_duration_text}}`
- `{{anchor_age_text}}`
- `{{anchor_total_days_text}}`
- `{{anchor_elapsed_text}}`
- `{{anchor_countdown_text}}`
- `{{anchor_day_index_text}}`
- `{{anchor_week_text}}`
- `{{anchor_month_age_text}}`
- `{{anchor_milestone_text}}`
- `{{anchor_years}}`
- `{{anchor_months}}`
- `{{anchor_days}}`
- `{{anchor_total_days}}`

## 3. Current Hidden But Resolvable Variables

These keys exist in runtime context today but are not consistently surfaced in the variable picker:

### Location and geography

- `{{location}}`
- `{{latitude}}`
- `{{longitude}}`
- `{{altitude}}`
- `{{city}}`
- `{{district}}`
- `{{province}}`
- `{{country}}`

### Extra date / anchor internals

- `{{weekday}}`
- `{{anchor_hours}}`
- `{{anchor_minutes}}`
- `{{anchor_seconds}}`

### Card metadata

- `{{badge_name}}`
- `{{memory_summary}}`

## 4. Current Catalog Gaps

### Gap A: picker/catalog drift

`TemplateVariableLibrary.recognized` prioritizes `{{location}}`, but `TemplateVariable.all` does not currently define a public `location` variable entry.

Impact:

- the runtime can conceptually resolve location-related keys
- the public variable system does not present a complete or trustworthy catalog

### Gap B: context/picker drift

Some keys are set in `MetadataContext` or `CardVariableProvider` but are invisible in the public picker.

Impact:

- advanced users may only discover them by reading code or old templates
- future UI and help-center copy cannot rely on one single variable list

### Gap C: computed summary drift

Default templates and helper lines such as:

- `{{model}} · {{camera_summary}}`
- `{{memory_summary}}`
- `今天{{anchor_age_text}}`

are defined in `TemplateItem`, not in the variable catalog itself.

Impact:

- reusable summary patterns are spread across presets instead of being treated as a first-class variable strategy

## 5. Recommended Future Variable Groups

### Camera

Existing:

- `brand`
- `model`
- `lens`
- `camera_summary`
- `iso`
- `aperture`
- `shutter`
- `focal_length`
- `focal_len_in_35mm_film`

Recommended additions:

- `flash`
- `white_balance`
- `exposure_bias`
- `metering_mode`
- `exposure_program`
- `camera_model_short`
- `lens_display`

### Photo

Existing:

- `width`
- `height`

Recommended additions:

- `orientation`
- `aspect_ratio`
- `megapixels`
- `image_format`
- `color_profile`

### Time

Existing:

- `year`
- `month`
- `day`
- `hour`
- `minute`
- `second`
- `weekday`
- `weekday_name`
- `capture_date_display`

Recommended additions:

- `capture_date_short`
- `capture_time_short`
- `capture_timezone`
- `weekday_localized`
- `month_name`
- `season`
- `quarter`
- `day_period`

### Location

Existing in runtime context:

- `latitude`
- `longitude`
- `altitude`
- `city`
- `district`
- `province`
- `country`
- `location`

Recommended additions:

- `location_display`
- `city_province_line`
- `country_city_line`
- `elevation_text`
- `gps_coordinates_compact`

### Memory

Existing:

- `memory_summary`
- all `anchor_*` variables already in use

Recommended additions:

- `anchor_short_title`
- `anchor_result_only`
- `anchor_phase`
- `anchor_is_future`
- `milestone_level`

These should stay computed from anchor semantics, not from new editor-side logic.

### Export and audit

Existing:

- `badge_name`

Recommended additions:

- `export_description`
- `output_album_name`

These are lower priority and should only be added if a real user-facing need appears.

## 6. Long-Term Design Rules

### Rule 1: one catalog, multiple producers

Future variables should still be produced by different components:

- `PhotoMetadata` and `MetadataContext` for raw metadata
- `CardVariableProvider` for computed card values
- `AnchorEngine` for time-relative derived metrics

But they should be documented and exposed through one catalog contract.

### Rule 2: plain strings remain the public contract

The variable engine should keep returning strings.

Why:

- templates are already string-based
- renderer already expects resolved strings
- export already expects resolved strings
- batch configuration snapshots already persist string templates safely

### Rule 3: missing values resolve quietly, but catalog should say why

At runtime, empty-string fallback is still acceptable.

But the system should eventually document whether a variable is:

- always available
- requires EXIF
- requires GPS
- requires anchor
- requires future location enrichment

### Rule 4: summaries belong beside raw fields, not instead of raw fields

High-level variables such as `camera_summary` and `memory_summary` are valuable.

But they should complement, not replace:

- raw camera fields
- raw date fields
- raw location fields

This keeps PhotoMemo flexible for users who want custom phrasing.

## 7. Recommended Variable Backlog

### Highest-value near-term additions

1. `{{location_display}}`
2. `{{capture_date_short}}`
3. `{{capture_time_short}}`
4. `{{aspect_ratio}}`
5. `{{megapixels}}`
6. `{{orientation}}`
7. `{{weekday_localized}}`
8. `{{capture_timezone}}`
9. `{{flash}}`
10. `{{season}}`

### Why these ten first

- They improve real templates without changing product shape.
- They depend on metadata normalization, not on UI redesign.
- They make both family-memory and photography use cases better.
- They stay local-first and do not require cloud services.

## 8. Recommendation

PhotoMemo should not introduce a new Variable Engine architecture right now.

It should keep the current string-based engine and invest in:

1. canonical variable catalog alignment,
2. richer metadata normalization,
3. more complete variable exposure,
4. regression tests for variable output.

That path preserves the current architecture while making the variable system much more trustworthy and scalable.
