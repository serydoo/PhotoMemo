# PhotoMemo V1 Architecture Migration Report

Last updated: 2026-06-30

## Scope

This report documents the Phase 1 foundation migration and the Phase 2 share
workflow migration requested for PhotoMemo V1 / MVP under the following
constraints:

- no UI behavior change
- no renderer/output change
- no Share / Export / Photo Library semantic change
- no new user-visible feature
- additive architecture only

Target structure:

```text
View
-> Intent
-> Coordinator
-> Service
-> Repository
-> Storage
```

## Phase 2E Update

Additional export follow-up adopted inside `PhotoMemoiOSMVPTestView`:

- added `MVPIOSOutputTarget`
- added `MVPResolvedAlbumSelection`
- added `MVPOutputAlbumSelectionRequest`
- added `ResolveMVPOutputAlbumSelectionIntent`

Current role:

- output-target branching no longer lives entirely inside the MVP view
- `.automatic`, `.applePhotos`, `.existingAlbum`, and `.newAlbum` resolution now
  route through one export intent boundary
- the view only keeps local UI-state follow-up for the `.newAlbum` case

Verification added in this slice:

- `ConfigurationMigrationTests`
- `ExportMigrationTests`
- `PhotoMemo` macOS Debug build
- `PhotoMemoiOSMVP` generic iOS Debug build

## Phase 2D Update

Additional configuration-save adoption landed for `PhotoMemoiOSMVPTestView`:

- added `Source/PhotoMemo/PhotoMemo/Intent/ConfigurationSaveIntents.swift`

New types:

- `MVPConfigurationSaveRequest`
- `MVPConfigurationSaveReceipt`
- `SaveMVPConfigurationIntent`

Current role:

- `PhotoMemoiOSMVPTestView.applyCurrentMVPConfiguration()` now routes its
  persistence path through:
  - `SaveMVPConfigurationIntent`
  - `ConfigurationCoordinator.saveMVPConfiguration(...)`
  - `SettingsRepository` / `ConfigurationRepository`
- birthday-anchor upsert, template save, badge save, photo-description save,
  and editor-state save no longer live entirely inside the view
- `session.applySelectedMemoryPreset()` intentionally remains in the view as
  local session synchronization

## Phase 2 Update

Phase 2 goal:

```text
ProcessShareIntent
-> ShareCoordinator
-> QueueRepository

and

BatchQueueExecution
-> ImportBatchPhotoIntent
-> BuildPreviewIntent
-> ExportRecordCardIntent
-> SaveRenderedPhotoIntent
-> PhotoLibraryRepository
```

Phase 2 remained strictly additive:

- no UI behavior change
- no renderer/output change
- no Share / Export / Photo Library semantic change
- no old interface deletion

### Newly Added Types

Added:

- `Source/PhotoMemo/PhotoMemo/Intent/ShareWorkflowIntents.swift`
- `Source/PhotoMemo/PhotoMemo/Repositories/PhotoLibraryRepository.swift`

New types:

- `ProcessedShareRequest`
- `ProcessShareIntent`
- `ImportBatchPhotoIntent`
- `PhotoLibraryRepository`

### Updated Adoption Points

Updated:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`
- `Source/PhotoMemo/PhotoMemo/Coordinators/ShareCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Coordinators/ExportCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift`

Current role:

- `PhotoMemoAppRuntime.flushExternalRequests()` no longer reaches straight into
  `BatchQueueStore.enqueue(...)`; it now routes drained requests through
  `ProcessShareIntent -> ShareCoordinator.process(...) -> QueueRepository`.
- `ShareCoordinator` now owns request validation, in-drain de-duplication,
  temporary managed-file cleanup, intake-summary adjustment, and queue-title
  derivation for drained share requests.
- `BatchQueueExecution.processTask(...)` still owns the existing queue phase
  state machine, retry/failure semantics, notification timing, and cleanup, but
  its business steps now flow through the intent layer:
  - `ImportBatchPhotoIntent`
  - `BuildPreviewIntent`
  - `ExportRecordCardIntent`
  - `SaveRenderedPhotoIntent`
- `PhotoLibraryRepository` is now the thin repository boundary for save-back to
  the system photo library.
- `ExportCoordinator` now saves through `PhotoLibraryRepository` instead of
  reaching into `PhotoRepository` for photo-library writes.

### Compatibility Preserved

Phase 2 intentionally keeps these old seams alive:

- `ExternalPhotoIntakeCenter.submit(...)`
- `ExternalPhotoIntakeCenter.drainPendingRequests()`
- `PhotoMemoAppRuntime.flushExternalRequests()`
- `BatchQueueStore.enqueue(urls:...)`
- `BatchQueueStore.enqueue(payloads:configuration:...)`
- `BatchQueueExecution.processTask(at:in:)`
- `BatchProcessingCoordinator.importPhoto/buildCard/exportCard/saveRenderedPhoto`

This means Phase 2 changes adoption order, not public behavior.

### Phase 2 Verification

Added/updated architecture regression coverage:

- `Tests/PhotoMemoTests/ArchitectureTests/ShareDrainMigrationRegressionTests.swift`

What the new tests prove:

- `SubmitExternalURLsIntent` still refreshes the default batch configuration and
  still keeps only supported, de-duplicated image inputs.
- drained share-request queueing still preserves:
  - `launchSource`
  - `BatchConfigurationSnapshot`
  - `ExternalPhotoImportSummary`
  - payload metadata written into `BatchJob` / `BatchTask`
- `ProcessShareIntent` preserves drained request semantics while routing through
  the new intent/coordinator/repository path.

Additional regression coverage re-run against the new queue-processing path:

- `ArchitectureMigrationFoundationTests`
- `BatchFixtureCoverageTests`

Confirmed in this Phase 2 slice:

- passed `PhotoMemoTests/ShareDrainMigrationRegressionTests`
- passed `PhotoMemoTests/ArchitectureMigrationFoundationTests`
- passed `PhotoMemoTests/BatchFixtureCoverageTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build

Not fully reconfirmed in this session:

- `PhotoMemoShareExtension` generic iOS Debug build

Why it remains listed separately:

- one rerun hit a locked `build.db` because overlapping derived-data work was
  still active
- one later `-quiet` rerun did not return a clean tool completion signal before
  session close, so it should be treated as not yet fully reconfirmed rather
  than silently assumed green

## Completed

### 1. Result Foundation

Added:

- `Source/PhotoMemo/PhotoMemo/Architecture/PhotoMemoResult.swift`

New types:

- `PhotoMemoErrorCode`
- `PhotoMemoError`
- `PhotoMemoResult<Value>`

Current role:

- provides one typed success/failure envelope for the new migration layer
- wraps persistence read/write failures into one error model
- supports `map` and `flatMap` for intent/coordinator composition

### 2. Intent Layer

Added:

- `Source/PhotoMemo/PhotoMemo/Intent/PhotoMemoIntent.swift`
- `Source/PhotoMemo/PhotoMemo/Intent/BuildPreviewIntent.swift`
- `Source/PhotoMemo/PhotoMemo/Intent/AppFlowIntents.swift`

New types:

- `PhotoMemoIntent`
- `BuildPreviewIntent`
- `ExportRecordCardIntent`
- `SaveRenderedPhotoIntent`
- `LoadConfigurationSnapshotIntent`
- `QueueBatchJobIntent`
- `SubmitExternalURLsIntent`

Current role:

- standardizes business actions as `execute() async -> PhotoMemoResult<Output>`
- keeps typed output at the intent boundary
- remains thin and delegates to coordinators instead of reimplementing logic

### 3. Coordinator Layer

Added:

- `Source/PhotoMemo/PhotoMemo/Coordinators/ShareCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Coordinators/QueueCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Coordinators/PreviewCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Coordinators/ExportCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift`

New types:

- `ShareCoordinator`
- `QueueCoordinator`
- `PreviewCoordinator`
- `ExportCoordinator`
- `ConfigurationCoordinator`
- `ShareSubmissionReceipt`

Current role:

- centralizes orchestration for share submission, queue enqueue, preview build,
  export, save-back, and configuration snapshot loading
- uses existing services/repositories internally
- does not change business semantics

### 4. Repository Layer

Added:

- `Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift`
- `Source/PhotoMemo/PhotoMemo/Repositories/QueueRepository.swift`
- `Source/PhotoMemo/PhotoMemo/Repositories/DiagnosticsRepository.swift`
- `Source/PhotoMemo/PhotoMemo/Repositories/PhotoRepository.swift`
- `Source/PhotoMemo/PhotoMemo/Repositories/ConfigurationRepository.swift`

New types:

- `SettingsRepository`
- `QueueRepository`
- `DiagnosticsRepository`
- `PhotoRepository`
- `ConfigurationRepository`

Current role:

- provides one access seam above existing stores/services
- adapts existing persistence and photo operations without moving core logic yet
- starts reducing direct service/store reach-through from higher layers

### 5. Dependency Container

Added:

- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift`

New types:

- `PhotoMemoServiceContainer`
- `PhotoMemoRepositoryContainer`
- `PhotoMemoCoordinatorContainer`
- `AppEnvironment`

Current role:

- becomes the app-side composition root
- wires repositories, coordinators, services, queue store, and intake center
- avoids introducing new singleton-only dependencies for the migration layer

### 6. Runtime Injection Boundary

Updated:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift`

Current role:

- `PhotoMemoAppRuntime` now accepts `AppEnvironment`
- `ExternalPhotoIntakeCenter` and `BatchProcessingCoordinator` now support
  explicit dependency injection while preserving old convenience behavior
- existing runtime behavior remains unchanged

### 7. Share Extension Compile Boundary

Applied:

- app-only migration types are guarded with `#if !PHOTOMEMO_SHARE_EXTENSION`
- `BuildPreviewIntent.swift` was tightened so the full file is excluded from the
  share-extension target

Why this matters:

- the share extension compiles a reduced source surface
- Phase 1 infrastructure must not leak app-only types into extension builds

## Verification

Confirmed after the latest compile-boundary fix:

- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoTests/ArchitectureMigrationFoundationTests`

Added test coverage:

- `Tests/PhotoMemoTests/ArchitectureTests/ArchitectureMigrationFoundationTests.swift`

What the new architecture test proves:

- `PhotoMemoResult.map` preserves success/failure semantics
- `BuildPreviewIntent` executed through `AppEnvironment.live(...)` preserves the
  current `RecordCardBuildService` card output

Known baseline blockers still present outside this migration slice:

- `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
  still fails because the current output is `记录于...` while the test expects
  `拍摄于...`
- `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
  still fails with a snapshot mismatch:
  - differing pixels: `93 / 768000`
  - max channel delta: `212`

These two failures were reproduced again after Phase 1 and are treated as
existing baseline issues, not regressions introduced by the architecture layer.

## What Phase 1 Does Not Yet Do

Phase 1 is infrastructure only. It does not yet:

- migrate old call sites broadly onto intents/coordinators
- replace all legacy `Bool` / `String` / `NSError` style flow control in the
  existing codebase
- remove direct service usage from existing views everywhere
- rewrite repository internals or move storage logic wholesale

That is intentional for this slice.

## Migration Assessment

Phase 1 objective status:

- Intent layer: complete
- Coordinator layer: complete
- Repository layer: complete
- unified result/error types: complete
- dependency container: complete
- no UI/render/export semantic change: preserved

Practical status:

- the foundation is now in place
- the app can compile through the new composition root
- the new layers are still additive adapters, which is the correct scope for
  this phase

## Recommended Next Steps

### Phase 2: Adoption

- move selected high-value flows to intent/coordinator entry points
- start with share submission, queue enqueue, preview build, and configuration
  snapshot loading
- keep changes vertical and behavior-preserving

### Phase 3: Access Discipline

- progressively stop new view code from calling services/stores directly
- prefer `View -> Intent -> Coordinator -> Repository`

### Phase 4: Error Unification Expansion

- replace additional ad-hoc `Bool` / raw `String` / silent-return branches with
  `PhotoMemoResult` where risk is high and semantics are clear
- prioritize diagnostics, queue, settings autosave, and external intake paths

### Phase 5: Repository Deepening

- move more storage and persistence logic behind repositories only after call
  sites stabilize
- avoid mixing deep repository migration with UI refactors

## Summary

Phase 1 infrastructure migration is complete in additive form.

The repository now has:

- a typed intent boundary
- coordinator seams for core flows
- repository seams above existing data access
- a unified result/error model for the new layer
- an app-side dependency container

The remaining work is adoption and expansion, not re-foundation.
