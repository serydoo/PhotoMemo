# Configuration Aggregate And Local Backup Library

## Status

Accepted

## Date

2026-07-11

## Context

MemoMark configuration currently spans ConfigurationSession, MemoryPreset,
V1SubjectLibraryRecord, several Settings keys, production snapshots, and
absolute asset paths. The save path performs multiple writes and some writes
cannot report failure. This can allow different revisions of subject, Preset,
location, output, and assets to be observed by the UI and production pipeline.

Users also need repeatable device testing and recovery without rebuilding every
Memory Subject configuration after a reset or reinstall.

## Decision

MemoMark treats `MemorySubject` as the configuration aggregate root and adopts
one versioned `ConfigurationLibraryRecord` as the only durable configuration
truth. Each subject owns complete configuration entities containing editor,
presentation, output, and portable asset references.

Local `.memomarkconfig` documents are versioned backups. They never become
runtime truth until an explicit restore succeeds through the same aggregate
save/apply path. Legacy Settings keys remain compatibility projections only.

`classicWhite` is the only canonical preset identifier written by new
configuration records. Legacy template and Immers identifiers decode into the
current latest Classic White content; this is a naming and schema migration,
not a visual renderer change.

## Alternatives Considered

### Keep Independent Settings Keys As The Primary Store

Rejected because multi-key writes cannot provide one revision, one receipt, or
one rollback boundary. Partial writes can preserve stale production fields.

### Make Local Backup Files The Runtime Store

Rejected because user-visible files can be moved, deleted, or modified and
would create another source of truth competing with App Group configuration.

### Export Only MemoryPreset

Rejected because MemoryPreset does not currently contain complete subject,
Template, location, Badge asset, album, description, and media-output state.

### Store Renderer Implementation Constants

Rejected because Renderer is a consumer of resolved presentation input and
must not become the owner of portable configuration or layout truth.

## Consequences

### Positive

- Every save has one identity, revision, receipt, and failure boundary.
- Main app, Share Extension, and batch snapshots can agree on active revision.
- Each configuration can be backed up and restored with its subject and assets.
- Duplicate names and renamed objects remain safe because UUIDs are authority.
- Failed imports and missing device-specific resources degrade safely.

### Negative

- Existing Settings persistence requires an incremental compatibility adapter.
- Complete configuration records are larger than current MemoryPreset values.
- Asset lifecycle and schema migration become explicit repository concerns.

### Trade-offs

- The implementation keeps the current UI and production pipeline stable while
  replacing persistence authority underneath them.
- Local backups are intentionally not edited directly in Files; explicit export
  is required for portable user-managed copies.

## Follow-up Work

- Close first-save configuration identity and cross-subject fallback defects.
- Add aggregate models, repository receipts, typed failures, and migrations.
- Canonicalize active preset and renderer naming to Classic White while
  preserving current output pixels and layout behavior.
- Move production-affecting fields into complete configuration records.
- Add actor-backed local backup storage and import/restore coordination.
- Add Home save/library interactions and user documentation.
