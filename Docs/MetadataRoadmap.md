# Metadata Roadmap

Last updated: 2026-06-20

## Goal

Strengthen PhotoMemo's metadata system without changing the core product shape:

- local-first
- template string remains the source of truth
- variable engine resolves strings only
- renderer consumes resolved values
- share extension remains an intake path, not a metadata-processing engine

## Recommended Implementation Order

### Phase 1: Canonical Metadata Contract

Goal:

- document one official inventory of:
  - raw metadata fields
  - normalized context keys
  - computed variables
  - public picker variables

Work:

- align code and docs around one field list
- expose hidden-but-supported variables intentionally or mark them internal
- add regression fixtures for representative photos

Why first:

- this reduces drift without changing architecture
- every later metadata expansion depends on knowing the current contract

### Phase 2: Capture-Time And GPS Normalization

Goal:

- make the existing canonical metadata more trustworthy

Work:

- review capture-date source priority and formatting policy
- handle GPS sign and altitude semantics correctly
- define timezone behavior even if timezone is not yet surfaced publicly

Why second:

- anchor semantics depend directly on `captureDate`
- future location and solar variables depend directly on GPS correctness

### Phase 3: Friendly Location Enrichment

Goal:

- make existing location fields truly usable

Work:

- wire a local-first location enrichment step into the import pipeline
- populate `city`, `district`, `province`, `country`, and `locationName`
- keep raw coordinates intact alongside friendly names

Why third:

- the model already anticipates this capability
- location is one of the highest-value missing metadata categories
- this should be done in the canonical metadata path, not in templates or renderer

### Phase 4: Variable Catalog Alignment

Goal:

- make the public variable system trustworthy

Work:

- align `TemplateVariable`, `TemplateVariableLibrary`, `TemplateItem`, and editor projection labels
- decide which runtime-only keys remain internal
- expose high-value existing keys that are already supported

Why fourth:

- after metadata quality improves, the public catalog can safely expand
- this phase improves user trust without changing rendering architecture

### Phase 5: Photo And Camera Metadata Expansion

Goal:

- add the most valuable missing photo and camera fields

Work:

- orientation
- aspect ratio
- megapixels
- flash
- white balance
- exposure bias / metering where worth the complexity

Why fifth:

- these variables are useful, but they should sit on top of a correct base
- they are lower priority than capture time and location integrity

### Phase 6: Advanced Computed Variables

Goal:

- add richer but still local-first derived values

Work:

- localized weekday / month names
- season / quarter / day period
- solar-state variables such as sunrise, sunset, golden hour, blue hour when GPS and time are good enough

Why sixth:

- these features provide product differentiation
- they are only safe after raw metadata normalization is mature

### Phase 7: Metadata Save-Back Verification

Goal:

- verify that exported and photo-library-saved outputs still carry the metadata PhotoMemo cares about

Work:

- add automated or semi-automated read-back checks
- confirm capture date, description fields, pixel dimensions, and useful preserved metadata
- document platform-specific limits clearly

Why seventh:

- PhotoMemo's promise is not just pretty rendering; it is metadata-friendly output
- export verification closes the loop on the whole pipeline

## What Should Not Happen Yet

- no `ComposerDocument`
- no renderer-side metadata ownership
- no share-extension EXIF parsing unless the app truly needs it
- no AI-generated metadata as a core dependency
- no new UI surface built on metadata categories that are not yet trustworthy

## Suggested Sprint Names

### Best next sprint

`Sprint-007: Metadata Normalization And Catalog Alignment`

Scope:

- canonical field inventory
- GPS/time correctness fixes
- variable catalog alignment
- regression test groundwork

Why this sprint first:

- it improves correctness before expansion
- it reduces architectural drift
- it unlocks future location and photo-shape variables safely

### Follow-up sprint

`Sprint-008: Location Enrichment And High-Value Variables`

Scope:

- friendly location resolution
- `location_display`
- short date/time variables
- aspect ratio / megapixels / orientation

## Bottom Line

The right roadmap is:

1. normalize ownership
2. correct raw metadata semantics
3. enrich location
4. align the catalog
5. expand variables
6. verify save-back

That order keeps PhotoMemo disciplined and preserves the architecture that is already working.
