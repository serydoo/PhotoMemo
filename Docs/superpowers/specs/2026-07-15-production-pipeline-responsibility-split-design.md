# Production Pipeline Responsibility Split

**Date:** 2026-07-15
**Stage:** V3 Production Quality And Delivery
**Status:** Approved design, implementation pending

## Objective

Reduce oversized, mixed-responsibility Swift types without changing user-visible behavior, production contracts, or frozen V2 architecture. The work targets the highest production-risk boundaries first and lands as independently verifiable slices.

## Scope And Order

The approved order is:

1. `PhotoMemoiOSV1View`
2. `BatchQueueExecution`
3. `RecordCardExportService`
4. `PhotoMemoShareExtensionViewController`
5. `PhotoMemoShareExtensionIntakeService`
6. `ConfigurationSession`
7. `SettingsService` and `ExternalPhotoIntakeStore`

Each item is completed as a separate refactoring slice with focused tests, a build, a code review pass, and a commit. No slice may reopen IA-002 or change Renderer, Metadata, Export, Share Extension, Photo Library, or Layout Engine behavior except where the slice explicitly moves existing ownership without changing behavior.

## Target Boundaries

### PhotoMemoiOSV1View

Keep state ownership, app-runtime wiring, and top-level event coordination in the root view. Extract:

- `ConfigurationLibraryActions`: create, reset, rename, delete, and save-current actions;
- `ConfigurationBackupRestoreCoordinator`: backup, import, restore, security-scoped resource handling, and result presentation;
- `LogoAssetCoordinator`: custom-logo selection, optimization, and asset cleanup;
- `EntryNavigationState`: entry-section, settings presentation, scroll offsets, and compact navigation transitions.

Page presentation remains in the existing page-surface files.

### BatchQueueExecution

Keep a compatibility facade for current callers. Extract:

- `BatchQueueCoordinator`: enqueue, retry, cancel, processing-loop scheduling, and job-state transitions;
- `BatchTaskProcessor`: one-task static-image and Live Photo execution;
- `BatchTaskDiagnosticsRecorder`: admission, route, stage-duration, health-check, and task-duration evidence;
- `BatchTaskResourceLifecycle`: temporary exports, managed intake sources, retry preservation, and idempotent cleanup.

`BatchQueueStore` remains the only task-state persistence owner. The processor may request state updates but must not create a second store or durable state model.

### RecordCardExportService

Keep the public export entry points stable. Extract:

- `RecordCardExportPipeline`: render-to-file orchestration;
- `OutputFileNamingResolver`: source-derived names and uniqueness;
- `MetadataPreservingImageWriter`: ImageIO output and metadata policy;
- `JPEGExifUserCommentPatcher`: JPEG/TIFF UserComment parsing and patching;
- `RenderedImageArtifactGuard`: rendered-image artifact validation.

### Share Extension

Keep the view controller as lifecycle and event forwarding only. Extract:

- `ShareExtensionViewStateRenderer`: UIKit state application and status presentation;
- `ShareExtensionPreviewController`: preview loading, cards, selection, and layout;
- `ShareExtensionHandoffCoordinator`: main-app refresh, responder-chain handoff, and confirmation;
- `ShareExtensionProgressObserver`: queue progress and diagnostics observation;
- `ShareItemProviderLoader`: provider discovery and representation loading;
- `ShareManagedFileImporter`: managed copies and source preparation;
- `ShareLivePhotoRecovery`: static fallback and Live Photo bundle recovery;
- `ShareIntakeDiagnostics`: intake-stage evidence and failure context.

### Configuration And Settings

Keep `ConfigurationSession` as the compatibility facade. Extract:

- `ConfigurationEditingState`: selection, draft, region, and preset editing state;
- `ConfigurationPersistenceReconciler`: durable aggregate reconciliation and persistence snapshots;
- `LegacySettingsStore`: legacy UserDefaults compatibility;
- `ConfigurationLibraryStore`: durable configuration aggregate read/write;
- `ConfigurationProjectionService`: compatibility projections and batch snapshots;
- `ExternalIntakeRequestStore`: request persistence and drain;
- `ManagedIntakeFileStore`: managed-copy creation and source identity;
- `IntakeCleanupService`: orphan and empty-directory cleanup.

## Invariants

- The daily workflow remains `Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos`.
- No original photo is modified; outputs remain new files.
- Production configuration ID and revision remain exact and versioned.
- Live Photo and static-image routing remain behaviorally identical.
- Render Health Check remains before Photo Library save.
- Final notification remains at-most-once per job completion path.
- Cancellation and failure cleanup are idempotent.
- Retryable managed intake sources remain available for retry.
- `BatchQueueStore` remains the single durable task-state owner.
- Preview and production continue to use the same renderer/exporter contracts.

## Migration Method

For every target:

1. Add or strengthen behavior-level tests around the existing boundary.
2. Extract one cohesive responsibility with no behavior change.
3. Run focused tests and the relevant target build.
4. Inspect the diff for ownership leakage and dead helpers.
5. Commit the slice and update `Docs/CURRENT_STATUS.md`.

New protocols are introduced only when they provide a test seam or prevent a concrete dependency cycle. Pure helpers remain concrete types.

## Acceptance Criteria

- Each target's primary file is reduced to coordinator/facade responsibilities.
- Each extracted type has one sentence of ownership that remains true without reading its implementation.
- Existing focused tests pass, and new tests cover state outcomes rather than internal call order.
- Generic iOS Debug build and relevant macOS test target build pass after each slice.
- No unrelated product behavior, terminology, or frozen architecture changes.
- Every completed slice is pushed with a descriptive commit and recorded in current status.
