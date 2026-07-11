# MemoMark Configuration Persistence And Local Library Design

Date: 2026-07-11
Status: Approved for implementation

## 1. Goal

Make configuration saving deterministic, complete, recoverable, and easy to
understand without changing the frozen Configuration Center architecture or
the production Renderer, Metadata, Share, Export, or Photo Library contracts.

The user-facing configuration unit combines:

- one Memory Subject and its object-level facts
- the selected Time Anchor and Memory Behavior
- Configuration Center editor content
- presentation and existing renderer-route inputs
- location and logo presentation
- output format, Live Photo policy, album destination, and description policy
- portable copies of configuration-owned assets

## 2. Governing Rules

1. `ConfigurationLibraryRecord` is the only durable configuration truth.
2. `MemorySubject` is the aggregate root.
3. Every saved configuration has a hidden stable UUID independent of its name.
4. Names are display values and may be duplicated or renamed.
5. Local configuration documents are backups, not active runtime truth.
6. Production behavior changes only after an explicit successful apply.
7. Existing batch jobs retain their frozen configuration snapshot.
8. Renderer internal layout constants are never serialized into configuration.
9. Legacy Settings keys are compatibility projections, not independent writers.
10. Every durable write returns an observable receipt or typed failure.
11. `classicWhite` is the only canonical preset name written by new code.
12. Legacy `template1`, `template2`, `template3`, and `immersWhite` values are
    accepted only by migration decoding and resolve to the current latest
    Classic White content without changing visual output.

## 3. Current Risks To Close

### 3.1 First-save identity and double-write risk

When a subject has no Preset, the persistence snapshot can create a candidate
configuration before the Session owns it. The success path then asks the
Session to create/save again and persists the subject library a second time.
Normal execution usually converges, but separate UUID generation and silent
second-write failure can leave Session, library, and active selection out of
agreement.

### 3.2 Multi-key non-atomic persistence

Template, Badge, location, subject, subject library, description, album, and
media output mode are written independently. A partial write can produce a
configuration assembled from different revisions.

### 3.3 Silent persistence failure

Several current Settings APIs return `Void` and use optional encoding. The
coordinator can report success even if a component did not encode or persist.

### 3.4 Split and global ownership

- `V1SubjectLibraryRecord` and legacy selected-subject keys remain writable.
- location configuration is global instead of configuration-scoped.
- custom Badge data and absolute asset paths are not fully Preset-owned.
- Template content and MemoryPreset state are persisted separately.
- production album and description state are only partly represented by the
  Preset.

### 3.5 Cross-subject fallback

When no configuration is selected, convenience accessors can still resolve a
global first Preset. A new configuration must never inherit another subject's
Preset identity or region mapping.

### 3.6 Portability failures

- PhotoKit album identifiers may not exist after reinstall or device transfer.
- absolute avatar and logo paths cannot be restored on another installation.
- newer schema documents must not be destructively decoded by older builds.

### 3.7 Semantic and legacy-store conflicts

- the V1 apply builder currently always enables Photos description writing and
  can reuse custom Memory write text as the description override, conflating
  two separate user decisions
- the apply builder currently constructs the production Template with a fixed
  `immersWhite` preset instead of preserving an explicit configuration-owned
  renderer route
- legacy configuration slots and active slot ID remain another persisted
  configuration representation outside subject/configuration ownership
- production snapshots currently carry transport UUIDs but no durable
  configuration ID or revision, so runtime evidence cannot prove which saved
  configuration revision produced a job
- the current public style is named Classic White while active source symbols
  still use `template1` and `immersWhite`, and an older implementation also
  owns `ClassicWhiteRenderer` naming

## 4. Target Domain Model

```text
ConfigurationLibraryRecord
├── schemaVersion
├── revision
├── subjects: [SubjectConfigurationRecord]
├── activeSubjectID
└── activeConfigurationID

SubjectConfigurationRecord
├── subject: MemorySubject
├── configurations: [MemoryConfigurationRecord]
└── assetManifest

MemoryConfigurationRecord
├── id
├── title
├── revision
├── savedAt
├── selectedTimeAnchorID
├── editor
├── presentation
└── output
```

`MemoryConfigurationRecord.Editor` stores the complete canonical Template and
region/module configuration required to rebuild the Configuration Center.

`MemoryConfigurationRecord.Presentation` stores existing preset/style routing,
location expression configuration, logo mode, and portable asset references.
It does not store renderer implementation constants.

The only canonical route written by schema version 1 is `classicWhite`. The
current latest visual implementation is preserved exactly while active types,
files, diagnostics, and tests are renamed to Classic White. The older Classic
White implementation is treated as legacy and removed after migration coverage
proves no production path consumes it.

`MemoryConfigurationRecord.Output` stores media output mode, Live Photo policy,
description policy, and a portable album destination descriptor. Memory-card
copy and Photos description writing remain separate fields.

## 5. Identity Rules

- Subject UUID defines subject identity; subject name never does.
- Configuration UUID defines configuration identity; configuration title never
  does.
- Anchor UUID defines anchor identity.
- Same name plus different UUID means different entity.
- Same UUID plus changed name means the same renamed entity.
- A restored copy receives a new configuration UUID by default.
- File names are friendly display names, while manifests retain authoritative
  UUIDs.

## 6. Persistence Architecture

Introduce a domain-level configuration repository whose write boundary accepts
and persists one complete `ConfigurationLibraryRecord`.

```text
Editing Session
    -> build validated candidate aggregate
    -> ConfigurationLibraryRepository.save(...)
    -> atomic primary record write
    -> SaveReceipt(revision, subjectID, configurationID)
    -> derive shared production snapshot
    -> update Session from the same receipt
    -> emit legacy Settings compatibility projections
```

Primary-record failure leaves the previous aggregate and production snapshot
unchanged. Compatibility-projection failure is diagnosable but cannot replace
or invalidate the primary truth.

The repository must serialize writes. File-system access is hidden behind
small injectable protocols so disk-full, permission, corruption, and partial
write paths can be tested.

## 7. Save Semantics

### Save As Current Configuration

1. Build or update exactly one configuration entity in Session.
2. Reuse that same entity ID through validation, persistence, receipt, and UI.
3. Resolve album selection before the primary record is committed.
4. Validate subject/configuration/anchor ownership.
5. Persist one complete aggregate.
6. Publish the new production snapshot only after persistence succeeds.
7. Mark UI state saved only after receipt reconciliation succeeds.

### Save To Local Library

1. If the selected configuration is dirty, save it as current first.
2. Read the successful configuration revision from the primary repository.
3. Copy the subject facts, selected configuration, and owned assets into the
   subject's local backup library.
4. Write through a temporary document and atomic replacement.
5. Return a backup receipt with checksum, revision, and saved date.

Saving a non-selected row backs up its last durable revision and never captures
unrelated editor drafts.

## 8. Local Backup Library

Internal app-managed layout:

```text
Application Support/MemoMark/MemorySubjects/<Subject UUID>/
├── subject.json
├── Assets/
└── Configurations/<Configuration UUID>.memomarkconfig
```

The in-app library is the supported browser. Users do not edit internal files
directly. Explicit export creates a self-contained `.memomarkconfig` document
for Files or external backup.

Each portable document contains:

- schema and app version
- subject snapshot
- one complete configuration
- portable album descriptor
- asset manifest with relative paths and checksums
- document checksum

## 9. Import And Restore

Import validates schema, checksum, ownership, and assets before changing live
state.

- same subject UUID: import under that subject
- different subject UUID: restore a separate subject even when names match
- same configuration UUID: restore as a new copy by default
- missing anchor: import as inactive and require anchor repair
- missing album: retain title, fall back to automatic destination
- missing custom logo/avatar: retain configuration, use safe fallback, surface
  the missing resource
- older schema: migrate through explicit version adapters
- newer schema: reject safely with a readable compatibility message

Import alone does not change production behavior. Only `Restore And Make
Current` runs the normal aggregate save/apply path and publishes a new snapshot.

## 10. Deletion Rules

- deleting a live configuration does not delete its local backup
- local backups are deleted only from the local configuration library
- deleting a subject prompts separately for live data and local backups
- active batch jobs continue using their frozen snapshots after deletion
- asset cleanup removes only resources no longer referenced by live records or
  retained backups

## 11. UI Design

The Home configuration row reveals two compact actions:

- `保存`: blue, saves the durable revision into the subject local library
- `删除`: red, deletes the live configuration only

The configuration card footer adds a compact `+` action that opens the current
subject's local configuration library. The library supports view, restore,
restore-and-make-current, import, export, and backup deletion.

The interaction is polish inside the frozen Home/Configuration Center shape;
it does not introduce Workspace, Dashboard, Task Center, or Import Flow product
concepts.

## 12. Diagnostics And Recovery

Record privacy-safe events for:

- primary save started/completed/failed
- compatibility projection failed
- local backup saved/failed
- import validated/rejected
- restore completed/failed
- album fallback applied
- asset recovery fallback applied

On corrupt primary data, preserve the corrupt file for diagnostics, attempt the
last-known-good record, then offer local backup recovery. Never silently reset
to defaults when a recoverable record exists.

## 13. Test Matrix

### Identity And Aggregate

- first save uses one configuration UUID end to end
- subject switch cannot inherit another subject's Preset
- rename does not change identity
- duplicate names remain independent

### Persistence

- aggregate write is atomic
- encoding/write failure returns typed failure
- failed save leaves previous production snapshot active
- compatibility projection failure does not replace primary truth
- concurrent saves serialize and highest successful revision wins

### Completeness

- location, Template, Badge, description, output, and media policy round-trip
- custom assets restore through relative paths
- no renderer constants enter the document

### Import And Recovery

- same-ID import restores as copy
- missing album falls back safely
- missing asset surfaces fallback
- old schema migrates
- new schema rejects without mutation
- corrupt document does not mutate current state

### Runtime

- Share Extension reads the same active revision as the main app
- existing jobs retain frozen configuration after restore/delete
- app restart restores the same subject/configuration/revision
- reinstall plus imported document restores usable output

## 14. Implementation Order

1. Close current first-save identity and cross-subject fallback defects.
2. Canonicalize all active preset naming to Classic White without visual change.
3. Define versioned aggregate/configuration/document models.
4. Add typed repository save receipts and failures.
5. Make the aggregate the primary persistence truth.
6. Fold all production-affecting fields into each configuration.
7. Derive legacy Settings and production snapshots from the aggregate.
8. Add the actor-backed local backup repository.
9. Add import, migration, asset remapping, and restore coordination.
10. Add Home swipe save and local-library UI.
11. Add user documentation and signed-device verification.

## 15. Documentation Deliverables

- architecture ADR explaining the single-truth decision
- developer persistence and recovery flow
- schema and migration reference
- user guide written in simple language:
  - what `保存为当前配置` means
  - what the row `保存` backup action means
  - how to restore a configuration
  - why existing processing jobs do not change
  - what happens when an album or custom resource is unavailable
