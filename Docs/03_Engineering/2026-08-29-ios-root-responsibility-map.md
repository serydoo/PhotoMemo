# MemoMark iOS Root Responsibility Map

- Date: 2026-08-29
- Baseline: `2.2.3 (100)`, `main @ 0954bea`
- Primary loop: Engineering Loop
- Scope: `MemoMarkiOSV1View` and its existing iOS coordinators
- Risk: P1 for root-flow changes; P0 if durable configuration semantics change
- Status: Accepted map / implementation gate

## Purpose

Freeze the current iOS root's state, dependency, intent, asynchronous lifecycle,
completion-identity, and test-seam ownership before moving code. This map does
not authorize an IA-002 redesign, a new root ViewModel, or any change to the
Memory Engine, Layout Engine, Renderer, Apple Photos commit lifecycle, or saved
configuration semantics.

RFC-002 and ADR-011 now supersede the map's concrete-owner restriction while
retaining the same IA-002 product behavior, durable configuration semantics,
memory truth, Renderer/Layout contract, and Apple Photos guarantees. Treat the
owners below as the migration baseline, not the permanent target architecture.

The active route remains:

`MemoMarkRootSceneView -> MemoMarkiOSV1View -> Library / Interactive Memory Card / Object Inspector`

## Non-Negotiable Truth Boundaries

| Truth | Current owner | Root responsibility | Refactoring rule |
| --- | --- | --- | --- |
| Live Configuration Center aggregate | `ConfigurationSession` | Observe, bind, and dispatch explicit intents | Do not mirror it in a second observable store |
| Durable configuration library | `ConfigurationCoordinator` and repository layer | Submit candidates and reconcile receipts | Preserve revision and compatibility-warning reconciliation |
| Memory meaning and time results | Memory Engine and subject/anchor models | Select inputs and display projections | Do not calculate memory meaning in the view |
| Layout truth | Layout Engine | Supply presentation inputs | Do not move constants or layout decisions into Renderer/root helpers |
| Render/export behavior | Renderer/export coordinators | Trigger established application seams | No Phase 2 behavior change |
| Original photos | Apple Photos / intake and export boundaries | Present picker and submit managed intake payloads | Never mutate originals or upload media |
| Text editing semantics | UIKit/TextKit session | Present editor and dispatch editing intents | Keep caret, selection, IME, undo, and attachments in TextKit |

## Root State Groups

| State group | Concrete storage | Meaning | Durable? | Valid owner after refactor |
| --- | --- | --- | --- | --- |
| Configuration aggregate | `@StateObject ConfigurationSession` | Current subject, preset, anchors, configuration library, memory-copy settings | Yes through coordinator/repository | Remains in root-owned session |
| Editor drafts | `regionDrafts`, `regionDraftsByPresentationStyle` | Unsaved, style-specific Memory Card composition | No until configuration apply | Root plus existing draft coordinators |
| Text/module interaction | `V1EditorInteractionState` | Focused region, module route, insertion context | No | Root/editor presentation boundary |
| Entry/navigation | `EntryNavigationState` | Selected tab, welcome/settings/processing flow, expansion and scroll projection | No | Root presentation state |
| Transient presentations | `V1RootPresentationState` | Sheets, alerts, rename, picker, logo busy state, local backup UI | No | Root presentation state; request identity belongs to its lifecycle coordinator |
| Configuration projections | `V1RootConfigurationProjectionState` | Presentation style, logo, birthday, location/time display | Draft until apply | Root projection of `ConfigurationSession`; never a second durable truth |
| Output draft/resource state | `V1OutputDraftState` | Output choices plus album loading identity and results | Draft until apply | Root draft; album loading may return explicit patches |
| Root lifecycle | `V1RootLifecycleState` | Bootstrap guards, dirty/save status, subject-save busy flag | No | Root lifecycle, updated through explicit outcomes |
| Subject request sequencing | `V1SubjectPersistenceRuntimeCoordinator` | Latest-request-wins serialization and successful-receipt revision rebasing | No | Remains outside `ConfigurationSession`; owns lifecycle only, not configuration truth |
| Photo-intake request sequencing | `V1PhotoIntakeRuntimeCoordinator` | Snapshot-before-import ordering, cancellation, and stale completion rejection | No | Owns lifecycle identity only; picker, configuration, queue, and photo truth remain with existing owners |
| Logo optimization sequencing | `V1LogoAssetRuntimeCoordinator` | Request identity, editing-context validation, cancellation, and stale asset cleanup | No | Owns lifecycle only; root applies explicit patches to canonical logo draft state |
| Output-album request sequencing | `V1OutputAlbumRuntimeCoordinator` | Task cancellation, context validation, and newer-request stale completion rejection | No | Owns lifecycle identity only; `V1OutputDraftState` remains the live presentation projection and `ExportCoordinator` remains the Photos read boundary |
| Diagnostics projection | `shareDiagnosticEvents`, `processingDiagnosticsSnapshot` | User-facing processing status | Derived | Existing diagnostics coordinator/root display |
| Preferences | `@AppStorage` welcome and module usage | UI preference/history | Yes, non-domain | Remains in SwiftUI root |

## Injected Dependencies

| Dependency | Purpose | Optionality behavior | Boundary decision |
| --- | --- | --- | --- |
| `PreviewCoordinator` | Sync real preview inputs | Optional preview integration | Preserve existing `V1PreviewSyncCoordinator` |
| `ExportCoordinator` | Album listing and configuration apply/export support | Empty/error projection when unavailable | Keep PhotoKit access outside view logic |
| `QueueCoordinator` | Processing diagnostics | Optional diagnostics | Preserve read-only projection path |
| `ConfigurationCoordinator` | Legacy and aggregate configuration persistence | Several actions become unavailable or no-op | Keep as durable-write facade |
| `DiagnosticsRepository` / `ProductionDiagnosticsRepository` | Runtime and production evidence | Optional recording | No UI ownership expansion |
| `LocalConfigurationLibraryCoordinator` | Local backup/restore | Always constructed by root | Preserve existing runtime coordinator |
| `ExternalPhotoIntakeCenter` | Submit managed picker payloads | Defaults to shared center | Preserve immutable snapshot submission |
| `MemoMarkBackgroundStatusService` | Active/completed task state | Required observed service | Remains injected observed dependency |
| `MemoMarkCommerceStore` | Settings/paywall state | Required observed service | No Phase 2 commerce change |

## Existing Flow Owners

The root already delegates meaningful logic. These owners should be reused,
not wrapped by a new generic architecture layer:

- configuration apply: `V1ConfigurationApplyPayloadBuilder`,
  `V1ConfigurationApplyCoordinator`, `V1ConfigurationApplyRuntimeCoordinator`;
- bootstrap: `V1BootstrapFlowCoordinator`, `V1BootstrapRuntimeCoordinator`;
- editor draft mutation/sync: `V1DraftRuntimeCoordinator`,
  `V1DraftOrchestrationCoordinator`, `V1PreviewSyncCoordinator`;
- configuration delete/backup/restore: the existing deletion, selection,
  backup/restore, and local-library runtime coordinators;
- subject mutation: `V1SubjectOverviewActionCoordinator`,
  `V1SubjectLibraryPersistenceCoordinator`, and
  `V1SubjectSelectionMutationCoordinator`;
- logo policy and lifecycle: `LogoAssetCoordinator`,
  `V1LogoAssetRuntimeCoordinator`, and `V1LogoSelectionCoordinator`;
- album lifecycle and projection: `V1OutputAlbumRuntimeCoordinator` and
  `V1ExportAlbumLoadingPresenter`;
- picker/import ordering: `V1PhotoIntakeRuntimeCoordinator`,
  `V1PhotoProcessingQuickActionCoordinator`, and `V1PhotoIntakeImporter`;
- preview/module projection: `PreviewDraftAdapter` and
  `V1PreviewCompositionEngine`;
- root observations: `V1RootChangeObservationModifier`.

## Asynchronous Lifecycle Map

| Lifecycle | Root entry | Identity / stale-result rule | Current owner seam | Current test seam | Next direction |
| --- | --- | --- | --- | --- | --- |
| Configuration apply | `applyCurrentV1Configuration()` | Reject while `isSavingConfiguration`; reconcile durable receipt/revision | Apply payload + runtime coordinators | Apply coordinator, payload, runtime tests | Keep stable in Phase 2 |
| Subject edit persistence | `persistCurrentSubjectChanges()` | Runtime coordinator keeps only the newest queued candidate and rebases it onto a successful earlier receipt | `V1SubjectPersistenceRuntimeCoordinator` plus root patch application | Seven runtime lifecycle tests plus subject-library/selection tests | Implemented; physical-device acceptance remains |
| Active selection persistence | `persistActiveConfigurationSelection()` | Reconcile only against current aggregate | Selection persistence coordinator | Coordinator tests | Keep separate from subject edit persistence |
| Album loading | `loadAlbumOptions()` | Runtime request UUID plus subject + configuration + output target + selected album context; older completion cannot clear newer loading | `V1OutputAlbumRuntimeCoordinator` plus album presenter | Runtime lifecycle, context identity, and presenter tests | Implemented; root applies explicit loading/projection updates only |
| Logo optimization | `optimizeSelectedLogo()` | Runtime request UUID plus subject/configuration editing context; stale asset is discarded and cannot clear a newer busy state | `V1LogoAssetRuntimeCoordinator` plus `LogoAssetCoordinator` | Policy, active completion, cancellation, and newer-request tests | Implemented; root applies explicit patches only |
| Photo quick action | `importPickedPhotos`, `importPickedPHPickerResults`, `performPhotoQuickAction` | Freeze durable configuration snapshot before import; cancellation/newer request rejects stale submission and UI completion | `V1PhotoIntakeRuntimeCoordinator` plus importer and `ExternalPhotoIntakeCenter` | Photo intake lifecycle, cleanup-containment, external intake, and entry-flow tests | Implemented; picker presentation remains in SwiftUI |
| Configuration delete | `deleteHomePresetNow()` | Runtime coordinator validates dirty/save availability and returns durable result | Deletion runtime coordinator | Deletion tests | No current extraction need |
| Backup/restore | local-library methods | Runtime coordinator owns work state and applies explicit feedback | Local-library runtime coordinator | Backup/restore tests | No current extraction need |
| Bootstrap | `bootstrapIfNeeded()` | One-shot `didBootstrap`; explicit bootstrap patch | Bootstrap flow/runtime coordinators | Flow/runtime tests | No current extraction need |
| Diagnostics refresh | `refreshProcessingState()` | Latest repository/service snapshot | Diagnostics refresh coordinator | Diagnostics tests | Keep as derived read path |

## Observation Graph

`V1RootChangeObservationModifier` is a presentation-side event router. It owns
no durable truth, but currently receives ten bindings and eleven callbacks. Its
important reactions are:

- app activation and Editor/Output tab entry reload albums;
- selected preset applies its saved projection and rebuilds drafts;
- selected subject aligns disclosure and birthday behavior;
- birthday, logo, route, and output edits mark the configuration dirty under
  bootstrap/output-restore suppression rules;
- Photos picker changes start logo optimization or photo intake.

This modifier should not absorb persistence or media work. After each lifecycle
is consolidated, it should continue to dispatch a narrow intent or async
operation and bind only presentation state.

## Audit Findings

| Severity | Surface | Evidence | Apple/product principle | Fix direction | Business impact |
| --- | --- | --- | --- | --- | --- |
| P1 | Subject persistence | `MemoMarkiOSV1View.persistCurrentSubjectChanges()` performs legacy persistence, anchor projection, preview refresh, request gating, aggregate mapping, async save, receipt reconciliation, warning classification, recursive retry, and UI status changes | Durable edits need one testable transaction and stale-completion policy | Extract one lifecycle coordinator; keep `ConfigurationSession` as truth and apply explicit result patches in root | Reduces risk of a later maintenance change losing or overwriting object edits |
| P1 | Logo lifecycle | Root owns request creation, picker reset, busy state, async optimization, editing-context comparison, stale-file cleanup, and result application while `LogoAssetCoordinator` owns only part of the lifecycle | Media work needs clear request identity, cancellation, and cleanup ownership | Extend the established logo coordinator boundary; do not add a logo ViewModel | Reduces leaked managed assets and wrong-object logo application risk |
| P1 | Photo intake orchestration | Snapshot saving, two picker adapters, import, submission, feedback, processing refresh, and navigation update are split between root and the quick-action coordinator | Photos UI should present selection; application layer should own processing order and immutable payload | Keep picker presentation in SwiftUI and move the remaining orchestration into the existing intake seam | Makes the daily Apple Photos workflow easier to verify and maintain |
| P2 | Album loading | Strong stale-result identity already exists, but request creation, busy state, defer cleanup, projection fetch, identity validation, and field application are all in the root | Async resource loading should expose one explicit state transition | Add a bounded album runtime result/patch after higher-risk subject flow is stable | Lowers accidental loading/status regressions during UI edits |
| P2 | Root composition | Eight computed coordinator factories and a high-arity observation modifier make dependency flow hard to scan, despite generally correct underlying owners | SwiftUI root should compose focused views and dispatch intents | Reduce closure wiring only as lifecycle owners become explicit; do not create an umbrella coordinator | Improves reviewability without replacing the accepted MV structure |
| P2 | Source-contract tests | Several tests assert source paths and strings because view behavior lacks executable seams | Prefer behavior/state contracts over file-layout contracts | Replace opportunistically when a real runtime seam is introduced | Allows safe file movement and reduces false-positive maintenance cost |

No verified P0 defect was found in this audit. The subject, logo, and photo
changes are classified P1 because they touch primary workflows; any proposal
that changes durable aggregate, request ordering, original-media, or PhotoKit
commit semantics is automatically escalated to P0 and stops for a separate
specification and evidence plan.

## First Bounded Implementation Slice

The first Phase 2 change is subject persistence orchestration because it is the
only root-local lifecycle that combines durable aggregate writing with its own
request gate and recursive retry.

Required behavior tests before moving the root method:

1. a no-op aggregate mapping finishes as subject-synchronized without a write;
2. one delayed save publishes its revision and synchronized status;
3. an edit arriving during the delayed save causes the first completion to be
   treated as stale and the latest snapshot to be saved next;
4. compatibility-projection failure returns the existing warning status;
5. a current save failure returns the localized/repository error and permits a
   later retry;
6. a stale failure does not overwrite the newer edit with failure state.

The destination may be a focused `V1SubjectPersistenceRuntimeCoordinator`
beside the current subject-flow support. It may own request generations and the
save lifecycle, but it must not own subjects, presets, configuration aggregate,
preview state, or navigation. The root supplies an immutable request snapshot
and applies an explicit completion patch.

## Verification Gate

- Focused subject tests must execute, not merely compile, before the new
  lifecycle replaces the root method.
- The test target, generic iOS build, and required macOS build must pass.
- Full `MemoMarkTests` remains required at the Phase 2 checkpoint.
- Because the eventual change touches object editing and save feedback, the
  exact signed build must receive paired iPhone 17 Pro Max object-editing,
  save, rapid-edit, failure/retry, and subject-switch acceptance before Phase 2
  is complete.
- No Simulator evidence is used.

Xcode 27 beta test execution was restored by building the macOS host and test
bundle in the same DerivedData before `test-without-building`. Runtime suites
now execute normally. Suites that read repository source through `#filePath`
still hang in the app-hosted runner with zero CPU; these source-contract tests
compile, and their affected assertions have been checked statically, but the
hang remains a separate test-infrastructure issue and is not counted as a pass.

## Slice 2-4 Implementation Outcome

The remaining Phase 2 slices were completed together on 2026-08-29 without
adding an umbrella ViewModel or changing a durable owner:

- photo intake lifecycle identity moved to `V1PhotoIntakeRuntimeCoordinator`;
- Logo optimization lifecycle identity moved to
  `V1LogoAssetRuntimeCoordinator`;
- module item/text projection converged on `PreviewDraftAdapter` and the
  canonical preview composition engine;
- output-album request identity converged on
  `V1OutputAlbumRuntimeCoordinator` while album values remain in the output
  draft;
- `V1RootPresentationState` no longer mirrors Logo request identity;
- the root still presents pickers, owns transient composition state, observes
  `ConfigurationSession`, and applies explicit lifecycle results.

The focused Phase 2 regression evidence now covers 66 tests with zero failures
or skips across the completed lifecycle slices.
Required macOS and generic iOS Debug builds passed. An Apple Development signed
`2.2.3 (100)` app passed `codesign --verify --deep --strict`; installation,
launch, and avatar crop visual acceptance remain a separate physical-device
gate because the paired device was unavailable.
