# MemoMark Active-Code Naming Modernization

- Date: 2026-08-29
- Status: Accepted / Incremental Migration
- Authority: RFC-002 and product-owner request
- Behavior baseline: `2.2.3 (100)`
- Primary loop: Engineering Loop

## Objective

Remove stage-era `V1` naming from active production architecture and replace it
with stable responsibility-based terminology. Preserve historical documents,
release artifacts, stored keys, wire formats, and migration semantics where
`V1` describes a real version rather than an obsolete code-generation label.

The goal is formal, durable naming. It is not to rename active code from `V1`
to `V4`; product-stage names age quickly and do not explain ownership.

## Audit Snapshot

The 2026-08-29 source scan found:

- 132 production Swift files containing an active `V1...`,
  `MemoMarkiOSV1...`, or lower-camel `v1...` symbol;
- 89 Swift test files containing those symbols;
- approximately 1,360 test references;
- more than one hundred active production type names carrying a stage prefix;
- genuine compatibility storage including `photomemo.v1.*`, `jobs-v1.json`,
  Photo Library receipt `*.v1` keys, and schema compatibility records;
- at least one diagnostic/user-facing error string that still says “current V1
  configuration”.

This inventory makes a single repository-wide replacement unsafe. Some names
are presentation labels, some are active domain types, and some are the only
remaining clue that a stored format is legacy.

## Naming Rules

### Active Production Types

Use a name that identifies product responsibility and lifetime.

Examples:

| Current | Target |
| --- | --- |
| `MemoMarkiOSV1View` | `MemoMarkConfigurationCenterView` |
| `MemoMarkiOSV1EntrySection` | `ConfigurationCenterSection` |
| `V1RootPresentationState` | `ConfigurationCenterPresentationState` |
| `V1RootLifecycleState` | `ConfigurationCenterLifecycleState` |
| `V1RootConfigurationProjectionState` | `ConfigurationDraftProjectionState` |
| `V1ConfigurationDraftProjection` | `ConfigurationDraftProjection` |
| `V1ConfigurationAggregateDraft` | `ConfigurationAggregateDraft` |
| `V1ConfigurationAggregateCandidate` | `ConfigurationAggregateCandidate` |
| `V1ConfigurationAggregateCandidateBuilder` | `ConfigurationAggregateCandidateBuilder` |
| `V1IOSOutputTarget` | `ConfigurationOutputTarget` |
| `V1MediaOutputMode` | `MediaOutputMode` |
| `V1LogoMode` | `ConfigurationLogoMode` |
| `V1EditorDraft` | `MemoryCardEditorDraft` |
| `V1ContentItem` | `MemoryCardContentItem` |
| `V1PreviewDraft` | `MemoryCardPreviewDraft` |
| `V1PreviewCompositionEngine` | `MemoryCardPreviewCompositionEngine` |
| `V1SubjectPersistenceRuntimeCoordinator` | `SubjectPersistenceRuntime` |
| `V1OutputAlbumRuntimeCoordinator` | `OutputAlbumLoadingRuntime` |

`Coordinator`, `Presenter`, `Runtime`, `State`, `Draft`, `Projection`,
`Receipt`, and `Command` remain valid suffixes only when the type actually owns
that role.

### Versioned Compatibility Types

If a type decodes or projects a real historical representation, keep the
version explicit and move it to the end of the responsibility name.

Examples:

| Current | Target |
| --- | --- |
| `V1SubjectLibraryRecord` | `SubjectLibrarySchemaV1Record` |
| `StoredV1SubjectLibraryRecord` | `StoredSubjectLibrarySchemaV1Record` |
| a legacy-only V1 adapter | `LegacyV1...Adapter` |

Renaming a Swift type does not authorize changing `CodingKeys`, raw values,
storage keys, file names, checksums, or migration fallback order.

### Persisted Keys And Files

The following are compatibility identifiers and remain byte-for-byte stable
until a separate storage migration is specified and verified:

- `photomemo.v1.subjectLibrary`;
- `photomemo.v1.mediaOutputMode`;
- `photomemo.v1.welcomeSeen` and existing UI preference keys;
- `photomemo.photoLibrarySaveIntent.v1`;
- `photomemo.photoLibrarySaveReceipt.v1`;
- `memomark.commerce.v1*`;
- `jobs-v1.json`;
- `LivePhotoOutputFilenameSequence.v1.json`.

Production code should centralize these in explicitly named compatibility-key
namespaces. It must not duplicate or cosmetically rewrite them.

### Historical Material

Do not rename:

- `Docs/07_Releases/V1.0` and `V1.5-TestFlight`;
- V1 historical audits, product notes, interaction records, screenshots, or
  release assets;
- migrations whose title accurately describes the source version.

Historical documentation is evidence, not active architecture naming debt.

## Migration Families

### Family 1 — Active Root And User-Facing Diagnostics

- rename the active root type/file and entry-section type;
- update app routing, active README entries, tests, and source-contract paths;
- remove “V1 configuration” from current user-facing or diagnostic copy;
- rename internal coordinate-space and temporary-folder labels when they have
  no durable compatibility role;
- retain compatibility storage keys.

### Family 2 — Cross-Layer Product Models

- output target, media output mode, Logo mode, resolved album selection;
- configuration save/bootstrap command and receipt types;
- current production properties such as `v1MediaOutputMode` become stable
  product names while decoding the same raw values.

This family must land before feature-local types because it defines vocabulary
used across Configuration, queue, Share, and media processing.

### Family 3 — Configuration Center Feature State

- root presentation/lifecycle/projection state;
- entry, bootstrap, apply, deletion, selection, backup/restore and diagnostics
  flows;
- output, Home, Settings, Subject, welcome, and navigation surfaces.

Rename by cohesive feature slice. Each slice updates its test file names and
runtime assertions in the same change.

### Family 4 — Memory Card Editor And Preview

- editor draft/content item/interaction/clipboard/TextKit support;
- preview draft/render model/composition/adapter/sync;
- region editor and module library types.

The canonical input-geometry contract and physical-device acceptance remain
unchanged. TextKit names should describe editing responsibility, not product
stage.

### Family 5 — Subject And Time-Anchor Presentation

- Subject overview, selection, persistence, avatar and anchor presentation;
- date/time presenters and support models;
- historical storage records become `SchemaV1` rather than active `V1` names.

### Family 6 — Tests, Files And Compatibility Cleanup

- rename test types/files after the associated production family lands;
- update source-contract paths or replace them with behavior tests where an
  executable seam now exists;
- centralize legacy keys and schema adapters;
- add a final active-source rule that rejects new stage-prefixed production
  names outside approved `SchemaV1`, `LegacyV1`, key, and migration allowlists.

## Safety Rules

Always:

- use compiler-resolved symbol renames or bounded `apply_patch` changes;
- update production, tests, previews, documentation maps, and source contracts
  together;
- keep each family compiling and testable;
- preserve encoded keys, raw values, storage keys, paths, and migration readers;
- verify there is still one active runtime path.

Never:

- replace `V1` with `V4` mechanically;
- rename persisted strings because they look old;
- change a schema and its type name in the same unverified slice;
- update historical release documents or assets to look current;
- mix broad naming changes with behavior, rendering, or PhotoKit transaction
  changes in one diff.

## Verification

Every family requires:

1. repository-wide old/new symbol scan;
2. affected focused tests;
3. generic iOS and required macOS build;
4. `git diff --check` and governance;
5. diff review for changed string literals, CodingKeys, raw values, UserDefaults
   keys, file names, and App Group behavior;
6. complete tests at family checkpoints;
7. physical-device acceptance only when the slice touches current UI or Apple
   framework behavior beyond a symbol/file rename.

## Completion Criteria

The migration is complete when active production source contains no stage-
prefixed type, method, property, file, coordinate-space, temporary resource, or
current diagnostic label, except an explicitly allowlisted real schema,
legacy adapter, storage key, file format, or historical migration boundary.

## Recorded Migration: Subject-Library Schema

On 2026-09-02, the durable representation behind
`photomemo.v1.subjectLibrary` was renamed in active Swift code from
`V1SubjectLibraryRecord` to `SubjectLibrarySchemaV1Record`; its narrow
readiness decoder became `StoredSubjectLibrarySchemaV1Record`. The historical
name remains a deprecated source-compatibility alias only. This migration did
not alter Codable fields, storage keys, migration ordering, UUID identity, or
the persisted format. Focused migration/persistence/snapshot tests and generic
iOS compilation passed.

The same migration family explicitly renamed the Codable output payload nested
inside historical presets to `SavedOutputConfigurationSchemaV1`. Its old Swift
name remains a deprecated source-compatibility alias. The
`savedOutputConfiguration` coding key and every encoded output/albums field
remain unchanged; focused Configuration Session and migration tests plus
generic iOS compilation passed.
