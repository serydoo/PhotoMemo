# Configuration Context And Processing Default Contract

Status: Accepted implementation contract.
Date: 2026-09-19.
Authority: Product-owner authorization to resolve the multi-subject and
multi-Preset state-flow root cause, following the local code and Chat On
Steroids read-only cross-review.

## Objective

MemoMark supports many Memory Subjects, each with many durable Presets. A
person may browse and edit one Preset without changing the Preset used by the
next `Apple Photos -> Share -> MemoMark` processing request.

Success means that selecting a Preset restores its complete authored state,
including its subject, Time Anchor, Classic White or Minimal content,
FilmMark's independent content and appearance, output policy, language, and
portable asset references. Opening is read-only; saving changes only that
Preset; only an explicit command changes the next-processing default; accepted
batch work stays frozen at admission.

## Root Cause And Decision

`ConfigurationLibraryRecord.activeSubjectID` and
`activeConfigurationID` currently serve both editor selection and production
selection. This makes an ordinary Home selection persist through the same path
as a production apply. The durable aggregate remains the only configuration
authority, but its active pair is now defined solely as the **Processing
Default**.

The Configuration Center holds an ephemeral **Editor Context** through
`selectedSubjectID` and `selectedMemoryPresetID`. These identify the object
currently projected into the Interactive Memory Card and Object Inspector.
They never become a durable default merely because a user opens or saves a
Preset.

```text
ConfigurationLibraryRecord
  Processing Default: activeSubjectID + activeConfigurationID
  Subjects 1:N Presets: durable authored truth and revisions

ConfigurationSession
  Editor Context: selectedSubjectID + selectedMemoryPresetID + current draft

Batch Job
  Frozen Production Snapshot: configuration ID + revision + full payload
```

## Commands And Product Semantics

| Command | Durable configuration content | Processing Default | Editor Context |
| --- | --- | --- | --- |
| Open Preset | no write | unchanged | restore selected Preset completely |
| Save Preset | save selected Preset and its revision | unchanged | remain selected |
| Set As Next Processing Default | no content rewrite when already saved | update active subject/configuration pair | remain selected |
| First Save (empty library) | save selected Preset | establish this first Preset as the initial default because the Share projection requires one | remain selected |
| Create From Current | create unsaved same-subject draft | unchanged | select new draft |
| Create Empty | create unsaved same-subject draft | unchanged | select new draft |

The production default is intentionally global because a Share Extension intake
has no Configuration Center browsing context. A future per-subject last-opened
convenience must be modeled separately and must never be read by production.

## Copy Policy

`Create From Current` copies authored expression state only: selected subject,
Time Anchor, card content for legacy styles, FilmMark configuration, FilmMark
independent content, memory copy, language, and supported logo selection.

It does not copy an external output destination or side-effect policy: existing
album identifier, new album title, Photos-description write policy/override,
queue state, or Processing Default identity. A new configuration starts with a
safe output policy and is not ready for production until the user saves and,
separately, makes it the next-processing default.

Cross-subject copying is not part of this slice. It would need a future,
explicit `Copy Expression Only` contract that cannot carry subject-specific
anchors, user-authored memory text, or Apple Photos output destinations.

## FilmMark Boundary

Classic White and Minimal remain backed by the legacy template dictionary.
FilmMark authored content remains exclusively in `FilmMarkContentSchemaV2`.
An editor preview may derive a FilmMark template for display compatibility, but
that derived value must have a separate API name and must never be presented as
a persisted card-region draft or be used as an authored-content save source.
An explicit FilmMark route without its independent payload fails closed in
production, queue admission, and rendering.

## Affected Owners And Dependencies

| Owner | Responsibility in this change |
| --- | --- |
| `ConfigurationLibraryRecord` | durable Preset entities and Processing Default only |
| `ConfigurationSession` / `ConfigurationEditingState` | Editor Context, full configuration restore, draft edits |
| `ConfigurationSavePayloadBuilder` / save transaction | build a save-only or save-and-set-default aggregate candidate explicitly |
| `ConfigurationPersistenceReconciler` | rebase a receipt only when its editor context is still relevant; never replace newer selection |
| `ConfigurationProjectionService` | resolve production only from Processing Default |
| Batch / Share | retain existing immutable snapshot admission behavior |
| FilmMark projection | expose authored content separately from display-only derivations |

No new Apple framework, permission, network dependency, cloud state, PhotoKit
operation, Renderer layout rule, or Share Extension processing work is added.

## Compatibility, Failure, And Recovery

- Existing Codable keys `activeSubjectID` and `activeConfigurationID` remain
  readable and keep their stored values; their clarified meaning is Processing
  Default.
- On restore, the Editor Context initially opens the Processing Default. Later
  browsing remains session-only.
- If a save completion returns after the user selects another Preset, the
  receipt may update the durable aggregate but must not replace the newer editor
  context.
- If a user saves a new Preset without making it default, an existing valid
  Processing Default remains valid.
- The first persisted Preset establishes the initial Processing Default. This
  is an invariant of the current local Share compatibility projection, not a
  browsing or activation side effect.
- Deleting the Processing Default requires an explicit replacement choice; a
  non-default deletion cannot alter it.
- Existing queue jobs remain valid because they carry immutable configuration
  identity, revision, and canonical snapshot.

## Implementation Plan

1. Add failing state/transaction tests for open, save-only, explicit default,
   cross-subject selection, stale receipt relevance, and safe creation.
2. Make save-only aggregate preparation and explicit default mutation separate
   operations; keep the Processing Default independent from the legacy draft
   marker used by older editor tests.
3. Replace automatic Home activation persistence with an open-only action and
   add an explicit native command for setting the next-processing default.
4. Apply the same command separation to new-configuration creation and output
   copy policy.
5. Split FilmMark authored-content projection from legacy region-draft
   projection and close the existing production-contract failure.
6. Run focused and full automated tests, review the diff, obtain Chat On
   Steroids read-only review, then signed iPhone 17 Pro Max install/launch and
   manual Configuration Center plus Apple Photos/Share acceptance.

## Ordered Implementation Tasks

### Task 1 — Make Processing Default a first-class aggregate intent

- Acceptance: aggregate preparation can save a selected Preset without moving
  the active pair, or save and move it only when commanded; first-save and
  restore compatibility are explicit.
- Verify: `LocalConfigurationLibraryPresenterTests`, aggregate validation, and
  Configuration Session lifecycle tests.
- Scope: `LocalConfigurationLibraryPresenter`, save-payload builder, save
  reconciliation, their focused tests.

### Task 2 — Keep Editor Context independent and relevance-checked

- Acceptance: opening a saved Preset is projection-only; subject selection
  cannot rewrite Processing Default; a late save receipt cannot restore an old
  subject or Preset over a newer Editor Context.
- Verify: Configuration Session lifecycle and persistence-reconciler tests.
- Scope: `ConfigurationEditingState`, `ConfigurationSessionPresentationState`,
  `ConfigurationPersistenceReconciler`, focused tests.

### Task 3 — Expose native open/save/default commands

- Acceptance: Home activation only opens; save means save; the explicit
  `设为下次处理默认` command is visible, accessible, localized, and preserves
  unsaved-change protection.
- Verify: action-presenter/source-contract tests, focused build, iPhone manual
  scenario after integration.
- Scope: configuration actions, Configuration Center action footer/page wiring,
  localization, focused tests.

### Task 4 — Make creation copy policy safe and visible

- Acceptance: from-current and empty creation are explicit; neither inherits
  album destination, Photos description side effect, queue state, or default
  identity; same-subject authored content and FilmMark content remain intact.
- Verify: Configuration Session creation/copy tests and output payload tests.
- Scope: session creation reducer, creation presentation, save payload, tests.

### Task 5 — Close FilmMark authored-versus-derived projection boundary

- Acceptance: only Classic White and Minimal expose persisted legacy region
  drafts; FM uses a separately named display projection and its V2 content
  remains the sole authored save carrier.
- Verify: `ProductionConfigurationContractTests`, FilmMark presentation tests,
  queue snapshot tests.
- Scope: record/draft projection and FilmMark contract tests only.

### Task 6 — End-to-end evidence and review

- Acceptance: all required automated suites/builds pass, a COS read-only
  reviewer finds no unresolved P0/P1 correctness issue, and the signed build
  is installed/launched on the paired iPhone 17 Pro Max for manual acceptance.
- Verify: commands in this document plus a documented device scenario matrix.
- Scope: no product behavior changes except fixes required by evidence.

## Verification Commands

```bash
python3 scripts/validate_codex_governance.py .
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMarkTests -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/MemoMarkConfigurationContextDerivedData -only-testing:MemoMarkTests/ConfigurationSessionConfigurationLifecycleTests -only-testing:MemoMarkTests/ConfigurationLibraryActionsTests -only-testing:MemoMarkTests/ProductionConfigurationContractTests test
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMark -configuration Debug -derivedDataPath /tmp/MemoMarkConfigurationContextBuildDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

## Success Criteria

- Selecting and reopening any durable Preset restores the exact selected
  configuration without changing the Processing Default or aggregate revision.
- Saving a non-default Preset advances only that Preset/aggregate revision and
  leaves the next-processing default untouched.
- Only the explicit default command changes `activeSubjectID` and
  `activeConfigurationID`; a save-and-set-default command changes them only
  after the Preset save succeeds.
- A new configuration does not inherit an album destination, Photos-description
  write setting, queued work, or default identity implicitly.
- FilmMark content survives save/reload/copy/queue snapshots through its
  independent schema and cannot be mistaken for persisted legacy region drafts.
- Classic White and Minimal compatibility, Apple Photos original protection,
  Share intake boundaries, and immutable queue snapshots remain intact.
- Focused tests, full relevant tests, build, code review, COS read-only review,
  and paired-device acceptance all have recorded evidence before this slice is
  called complete.
