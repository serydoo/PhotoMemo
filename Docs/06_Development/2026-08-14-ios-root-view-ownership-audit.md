# iOS Root View Ownership Audit

Date: 2026-08-14
Status: Baseline established; Slices 1-6 implemented and verified
Primary loop: Engineering Loop
Risk: P1
Baseline: `main` at `1b3b9f7`, MemoMark `2.1.1 (80)`

## Purpose

This record establishes the current checkout baseline for the bounded iOS root
view ownership and structure work. The work is a maintenance refactor. It does
not add product capability, redesign IA-002, or change the Memory Engine,
Presentation Engine, Layout Engine, Renderer, Export, PhotoKit, Share Extension,
Live Photo, or original-photo behavior.

The objective is to clarify state ownership and lifecycle boundaries before any
production Swift source is moved. File size is a diagnostic signal only; it is
not an acceptance criterion.

## Clean Baseline

The current worktree was inspected before starting this audit. The previous
dirty worktree contained unrelated Device QA, PhotoKit, Live Photo, queue,
tests, and documentation changes. It was preserved in the local recoverable
stash:

```text
pre-root-view-optimization-2026-08-14
```

That snapshot contains the complete pre-audit tracked and untracked change set.
It is not part of this root-view work and must not be mixed into a future root
view commit without a separate review.

The clean baseline currently reports:

- branch: `main`
- commit: `1b3b9f7`
- product version: `2.1.1`
- build number: `80`
- iOS runtime root: `PhotoMemoiOSV1View`
- root source size: approximately 3,001 lines
- root property-wrapper declaration lines: 55 matches across `@State`,
  `@StateObject`, `@ObservedObject`, `@Binding`, `@FocusState`, `@AppStorage`,
  and `@Environment`

The valid project schemes are:

- `PhotoMemo`
- `PhotoMemoTests`
- `PhotoMemoiOS`
- `PhotoMemoShareExtension`
- `PhotoMemoWidgetExtension`

Use `PhotoMemoTests` for tests and `PhotoMemoiOS` for the iOS build. Do not
assume that historical QA schemes or untracked Device QA files are part of this
baseline.

## Runtime Entry Chain

```text
PhotoMemoRootSceneView
    -> PhotoMemoiOSV1View
    -> V1ConfigurationPageSurface
    -> V1EditorPageSurface
```

`PhotoMemoRootSceneView` remains responsible for runtime dependency injection,
interface language, appearance preference, external URL intake, and app-level
permission/resume refresh. `PhotoMemoiOSV1View` remains the iOS Configuration
Center composition root. The frozen product hierarchy remains:

```text
Library -> Interactive Memory Card -> Object Inspector
```

The Configuration Center must not become a Workspace, Dashboard, Task Center,
Batch Workbench, or Import Flow.

## Accepted Truths

### Live editing truth

`ConfigurationSession` is the live configuration editing truth. It owns the
current session state and exposes mutation/reconciliation APIs. A view or
extracted presentation surface must not create a second session or maintain a
parallel copy of selected Subject, selected Preset, configuration library, or
active configuration identity.

### Saved truth

The durable configuration aggregate and its persistence coordinator are the
saved truth. Root actions may assemble an apply payload and apply a returned
reconciliation patch, but presentation views must not write durable state
directly.

### Draft truth

`V1EditorDraft` and the existing draft runtime coordinate region-local editor
content and TextKit projection. The audit must verify the exact handoff from
editor draft to session-facing configuration projection, preview projection,
and save payload before moving this state. It must not be silently promoted to
an all-purpose root store.

### Preview truth

Preview is a projection of current session/draft state through the existing
preview composition and synchronization path. Preview changes must not create a
separate persistence truth or alter Renderer/Export ownership.

## State Inventory

| Category | Current state | Current location | Initial ownership assessment |
| --- | --- | --- | --- |
| Canonical editing | `session` | `PhotoMemoiOSV1View` with `ConfigurationSession` | Keep as the only live configuration session |
| Editor draft | `regionDrafts` | root plus `V1DraftRuntimeCoordinator` | Audit handoff; possible second editing surface, not yet approved for extraction |
| TextKit interaction | four command buses | root `@State` | View-local/editor-owned candidate; preserve SwiftUI identity and region routing |
| Editor focus/insertion | active/focused regions, active item IDs, recent insertion IDs | root | View-local candidate; clear on identity changes |
| Navigation | `entryNavigationState` | root | Single navigation owner; do not duplicate in page surfaces |
| Disclosure/presentation | disclosure, rename, switch, local library state | root value types plus modifiers | Allowed transient state if it contains no domain truth |
| Logo projection | `logoMode`, `customLogoBadge` | root plus Logo/bootstrap coordinators | Audit against centralized Logo ownership and request identity |
| Subject projection | `birthdayDate`, subject-related bindings | root plus subject flow | Audit for false dirty and subject-switch ordering |
| Expression projection | location and time display configuration | root plus dedicated configuration APIs | Audit independent persistence and preview projection paths |
| Output draft | target, media mode, descriptions, album selection, Live Photo policy | root | Keep separate from album resources and durable aggregate |
| External resources | available albums, loading, album status | root plus album presenter | Derived/permission state; stale results must not mutate current configuration |
| Save status | `activeConfigurationStatus`, `isSavingConfiguration` | root plus draft/apply coordinators | Highest duplicate-state candidate; establish single mutation path before extraction |
| Bootstrap | bootstrap and saved-output application flags | root plus bootstrap coordinators | Preserve transaction guard against false dirty and stale projection |
| Subject persistence | subject-library persistence flags | root plus subject flow | Keep separate from configuration save status |
| Diagnostics | share events and processing snapshot | root plus diagnostics coordinator | Derived presentation; must not enter ConfigurationSession |
| Commerce | `commerceStore`, purchase sheet flags | runtime/root | Separate product access presentation from configuration truth |
| Environment | scene phase, size classes, app storage | system/root | Keep at platform shell; no device-model branching |

## Data Flow

```text
Bootstrap / durable aggregate
    -> ConfigurationSession restore/reconciliation
    -> root projections
    -> editor draft and preview

User edit
    -> session or region draft mutation
    -> preview synchronization
    -> configuration apply payload
    -> durable persistence
    -> receipt/reconciliation patch
    -> current session and projections
```

The audit must prove that each path has one authoritative write boundary. A
value being visually equal in two places is not sufficient evidence that the
ownership is correct.

## Async Callback Inventory

The following paths require request and current-identity review before they are
moved:

- bootstrap and draft bootstrap;
- album option loading;
- Logo optimization;
- Photos picker import;
- local configuration backup/restore;
- save and reconciliation;
- foreground processing/diagnostics refresh;
- Subject and Preset switching while a previous operation is pending.

For each result, the audit must record whether it is bound to:

```text
request identity
subject identity
configuration identity
```

An old result must be discarded without mutating the current session,
projection, draft, preview, or save status.

## Initial Risk Ranking

### P0 boundaries to preserve

- no second `ConfigurationSession`;
- no direct persistence from presentational views;
- no change to durable aggregate ownership;
- no change to Renderer, Layout Engine, Export, PhotoKit, Share Extension, or
  original-photo behavior;
- no reintroduction of retired MainView, Workspace, Composer, or import-first
  workflow concepts.

### P1 candidates for focused contracts

- Subject or Preset switch leaves stale draft, Logo, output, focus, or preview;
- save completion is followed by a stale `.dirty` transition;
- bootstrap or saved-output application overwrites user edits;
- album or Logo async result belongs to an old request;
- moving `@State` changes TextKit focus, selection, or editor identity;
- preview configuration and save payload diverge.

### P2 structure candidates

- root coordinator construction and closure volume;
- repeated projection adapters;
- source contracts coupled to file placement instead of semantic ownership;
- remaining page-composition glue that can move without changing lifecycle.

## Out of Scope

This audit does not authorize work on TX-001, BP-001, Instruments, xctrace,
CoreDevice sampling, PhotoKit receipt semantics, queue recovery, Share
Extension lifecycle, Renderer, Export, Live Photo writing/readback, StoreKit,
EXIF, or product-copy redesign. The user decision that BP-001 is closed for
this project stage is respected; this root-view effort must not reopen it.

## Slice 1: Editor Interaction State

The first production extraction is complete and deliberately narrow. The
following transient values now live together in
`V1EditorInteractionState`:

- active and focused editor regions;
- active TextKit item IDs;
- recent insertion marker identity;
- the four region-specific TextKit command buses.

The root view still owns `ConfigurationSession`, `regionDrafts`, output draft,
bootstrap state, save state, and all persistence-facing projections. The
extraction preserves the command-bus instances as `@State`-retained values so
TextKit routing does not acquire a new reference identity during SwiftUI
updates. It does not claim that `activeTextItemIDs` has already been removed
from every coordinator bridge; that bridge remains an explicit follow-up
audit item.

Verification for Slice 1:

- `PhotoMemoiOS` unsigned Debug build: passed;
- focused `PhotoMemoTests`: passed for
  `V1ModulePanelCoordinatorTests`, `V1DraftRuntimeCoordinatorTests`,
  `V1DraftOrchestrationCoordinatorTests`, and
  `ConfigurationSessionConfigurationLifecycleTests`;
- `git diff --check`: passed;
- source scope: one new state type, one root-view edit, and this audit record;
- no Renderer, Layout Engine, Export, PhotoKit, Share Extension, Live Photo,
  StoreKit, or durable persistence files changed.

The focused test invocation still emitted existing Xcode Beta diagnostics of
the form `SwiftCompile ... exit code 0 but produced no further output` while
compiling unrelated target files. The command exited successfully and the
selected test cases reported passed. This is recorded as toolchain noise, not
as full-suite certification.

## Slice 2: Root Presentation State

Transient presentation state is now grouped in `V1RootPresentationState`:

- memory-source disclosure;
- photo/logo picker presentation and optimization request;
- rename presentation;
- region-content, welcome-information, and MemoMark Plus sheets;
- Subject/Preset switch alerts and pending selection values;
- local configuration library presentation and feedback.

This is a presentation container, not a domain store. It deliberately excludes
`ConfigurationSession`, editor drafts, output draft, bootstrap flags, save
status, and durable persistence. `EntryNavigationState` remains a separate
navigation owner.

Verification for Slice 2:

- RED contract failed before the extraction;
- GREEN `V1RootPresentationStateContractTests`: passed;
- `PhotoMemoiOS` unsigned Debug build after extraction: passed;
- the Slice 1 focused regression set remained passed;
- no product-flow, persistence, renderer, or media ownership changed.

## Slice 3: Output Draft State

Output-facing transient state is now grouped in `V1OutputDraftState`:

- output target and media output mode;
- Photos description draft;
- album title, existing album selection, new album name;
- Live Photo output policy;
- available album resources, loading state, and album feedback.

The state is explicitly a live output projection. The root still passes its
values into `V1ConfigurationApplyPayloadBuilder`, and the durable aggregate
continues to be reconciled through the existing apply runtime coordinator.
Album options remain derived resource/permission state and are not persisted by
this container.

Verification for Slice 3:

- RED contract failed before the extraction;
- GREEN `V1OutputDraftStateContractTests`: passed;
- `PhotoMemoiOS` unsigned Debug build after extraction: passed;
- combined focused set passed:
  `V1OutputDraftStateContractTests`,
  `V1RootPresentationStateContractTests`,
  `V1ModulePanelCoordinatorTests`,
  `V1DraftRuntimeCoordinatorTests`,
  `V1DraftOrchestrationCoordinatorTests`, and
  `ConfigurationSessionConfigurationLifecycleTests`;
- `git diff --check`: passed after the implementation slices.

## Slice 4: Album Load Identity Guard

The album-loading path now creates a `V1OutputAlbumLoadRequest` containing a
request ID, the current Subject ID, and the current configuration ID. The
result is applied only when all of the following remain true:

- the request is still the active request;
- the selected Subject ID still matches;
- the selected configuration ID still matches.

Cleanup is conditional on the same request identity, so an old result cannot
clear the loading state of a newer request. The request value is kept
cross-platform and pure so host tests can verify its identity semantics; the
UI-only output draft container remains iOS-gated.

Verification for Slice 4:

- RED test initially failed because the identity type did not exist;
- the first implementation compile caught and corrected an invalid `return`
  from a `defer` body;
- GREEN `V1OutputAlbumLoadIdentityTests`: passed;
- `PhotoMemoiOS` unsigned Debug build after the guard: passed;
- combined focused regression set passed, including configuration lifecycle,
  editor interaction, presentation-state, output-state, and album identity
  contracts.

## Slice 5: Configuration Projection State

The remaining root-owned configuration projections are now grouped in
`V1RootConfigurationProjectionState`:

- Logo mode and custom Logo badge;
- birthday/time-anchor date projection;
- location display configuration;
- time display configuration.

This container is a value-state boundary only. It does not own
`ConfigurationSession`, durable configuration, persistence calls, preview
composition, or Logo optimization. The root view keeps narrow computed access
for existing call sites and uses the container's projected bindings where
SwiftUI requires a binding. The initializer still loads the saved time display
configuration through the existing `ConfigurationCoordinator` path.

Verification for Slice 5:

- RED contract was established before the state container was available;
- the first GREEN attempt exposed the host-test/iOS-only boundary and was
  corrected to a source-structure contract;
- the iOS compiler then caught the actual `ExpressionModuleConfiguration`
  type and `@State` nonmutating-setter requirements; both were corrected;
- GREEN `V1RootConfigurationProjectionStateContractTests`: passed;
- `PhotoMemoiOS` unsigned Debug build after the extraction: passed;
- combined focused regression set passed, including
  `V1ConfigurationApplyRuntimeCoordinatorTests`, configuration lifecycle,
  editor interaction, presentation-state, output-state, album identity, and
  the new projection-state contract;
- `git diff --check`: passed after the implementation slice.

The host test invocation still reports existing Xcode Beta diagnostics of the
form `SwiftCompile ... exit code 0 but produced no further output` while
compiling unrelated target files. The selected tests exited successfully and
reported passed. This is not full-suite certification.

## Slice 6: Root Lifecycle State

The root-local lifecycle flags and configuration status are now grouped in
`V1RootLifecycleState`:

- configuration-saving flag;
- bootstrap completion and bootstrap-application guards;
- saved-output projection guard;
- birthday-date change behavior;
- Subject-library persistence intent and in-flight flag;
- active configuration status.

This extraction moves state storage only. The root view still owns the
behavioral decisions and keeps the existing callbacks into
`V1BootstrapRuntimeCoordinator`, `V1ConfigurationApplyRuntimeCoordinator`,
Subject persistence, and configuration-library actions. No save store,
session copy, or durable aggregate copy was introduced.

Verification for Slice 6:

- RED `V1RootLifecycleStateContractTests` failed before the container existed;
- `PhotoMemoiOS` unsigned Debug build after the extraction: passed;
- GREEN lifecycle contract: passed;
- combined focused regression set passed, including lifecycle, configuration
  projection, output/presentation state, album identity, editor interaction,
  Subject/Preset lifecycle, and configuration apply/reconciliation tests;
- `git diff --check`: passed after the implementation slice.

The first host run again exposed the repository's known Xcode Beta broad
compile-no-output diagnostics; the final cached focused run exited successfully
and every selected test case reported passed. This remains focused evidence,
not full-suite certification.

## Next Controlled Slice

The next production extraction should not be started automatically. Before
moving any more state, add RED contracts for:

1. Subject switch reprojects current subject, draft, Logo, output, and preview
   without retaining old identity;
2. configuration switch does not lose or silently save dirty edits;
3. save reconciliation cannot be overwritten by an old callback or return to
   `.dirty` from bootstrap/on-change ordering;
4. stale Logo and album results cannot mutate the current configuration;
5. editor interaction state preserves four-region routing and focus return.

Slices 1-6 have now covered the low-risk local state boundaries. The remaining
root state is deliberately held for a separate, evidence-led pass:
`ConfigurationSession`, `regionDrafts`, save/bootstrap lifecycle flags,
Subject persistence, diagnostics, and navigation. These values either carry
live domain truth or cross async lifecycle boundaries; extracting them only to
reduce line count would increase architectural risk.

The first production extraction, after those RED contracts are established,
should be limited to editor-local interaction state. It must not move
`ConfigurationSession`, `regionDrafts`, save workflow, output persistence,
bootstrap, or PhotoKit behavior in the same increment.

## Verification Contract

For every implementation slice:

1. write or confirm the failing contract;
2. implement one ownership boundary;
3. run the focused tests;
4. run serialized `PhotoMemoTests` with isolated DerivedData;
5. build `PhotoMemoiOS` unsigned with isolated DerivedData;
6. run `git diff --check`;
7. inspect the diff for unrelated files;
8. record manual device/VoiceOver/visual acceptance separately.

Host tests and an unsigned build do not certify physical-device visual,
accessibility, Apple Photos, or production memory behavior.
