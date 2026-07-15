# Remaining Responsibility Splits Implementation Plan

> **Execution:** Use isolated worktrees, TDD, incremental commits, independent
> specification review, independent quality review, and integration verification.

**Goal:** Complete the remaining risk-ranked responsibility splits without
changing MemoMark V3 product behavior, IA-002, renderer output, metadata
semantics, Share workflow behavior, persistence formats, or compatibility keys.

**Architecture:** Existing public services/controllers remain facades. New
types own one cohesive responsibility and return typed values. Callers keep
their current state ownership. All branches start from the same `main` commit
and merge into `codex/remaining-responsibility-splits` only after review.

## Phase 1: Independent High-Risk Splits

### Task 1: Record Card Export Infrastructure

**Branch:** `codex/export-service-split`

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- Create focused files under `Source/PhotoMemo/PhotoMemo/Services/`
- Update/add focused export tests under `Tests/PhotoMemoTests/`

**Acceptance criteria:**
- [ ] Keep `RecordCardExportService` as the existing facade/API.
- [ ] Extract `RecordCardExportPipeline`, `OutputFileNamingResolver`,
  `MetadataPreservingImageWriter`, `JPEGExifUserCommentPatcher`, and move the
  existing `PhotoMemoRenderedImageArtifactGuard` to its own source file.
- [ ] Preserve renderer invocation, output geometry, original filename
  resolution, ImageIO properties, EXIF cleaning, JPEG UserComment bytes, file
  replacement behavior, and artifact rejection exactly.
- [ ] Do not change Renderer or Layout Engine decisions.
- [ ] Add tests before production extraction and verify focused export tests,
  serial test build, and generic iOS Simulator build.

### Task 2: Share Intake Infrastructure

**Branch:** `codex/share-intake-split`

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- Create focused files in the same Share Extension directory.
- Update/add focused intake tests under `Tests/PhotoMemoTests/`.

**Acceptance criteria:**
- [ ] Keep `PhotoMemoShareExtensionIntakeService` as the existing facade/API.
- [ ] Extract `ShareItemProviderLoader`, `ShareManagedFileImporter`,
  `ShareLivePhotoRecovery`, and `ShareIntakeDiagnostics`.
- [ ] Preserve provider order, registered-type selection, file representation
  lifetime, managed-copy paths, Live Photo pairing/static fallback, date hints,
  original filenames, cancellation, and diagnostic events.
- [ ] Do not broaden permissions, introduce uploads, or change handoff records.
- [ ] Add tests before production extraction and verify focused intake tests,
  Share Extension build, and generic iOS Simulator app build.

### Task 3: Share Extension View Controller

**Branch:** `codex/share-controller-split`

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- Create focused files in the same Share Extension directory.
- Update/add focused controller contract tests.

**Acceptance criteria:**
- [ ] Keep the view controller responsible for lifecycle, view installation,
  and forwarding user/system events only.
- [ ] Extract `ShareExtensionViewStateRenderer`,
  `ShareExtensionPreviewController`, `ShareExtensionHandoffCoordinator`, and
  `ShareExtensionProgressObserver` behind typed inputs/updates.
- [ ] Preserve state transitions, preview rendering, open-main-app handoff,
  progress/KVO observation, diagnostics monitoring, cancellation, accessibility,
  and Preview Provider compatibility.
- [ ] Do not alter intake or processing semantics.
- [ ] Add tests before production extraction and verify controller contracts,
  Share Extension build, and generic iOS Simulator app build.

## Checkpoint 1

- [ ] Each task passes independent specification review.
- [ ] Each task passes independent quality review.
- [ ] Merge all three branches without shared-file conflicts.
- [ ] Run combined export/intake/share tests and app/extension builds.

## Phase 2: State And Persistence Splits

### Task 4: Configuration Session Layers

**Acceptance criteria:**
- [ ] Extract `ConfigurationEditingState` and
  `ConfigurationPersistenceReconciler` while keeping `ConfigurationSession` as
  the caller-compatible facade.
- [ ] Preserve subject/library restoration, preset/anchor/region editing,
  preview text, composer refresh, and persistence projection semantics.
- [ ] Verify focused session/reconciliation tests and iOS build.

### Task 5: Settings Persistence Layers

**Acceptance criteria:**
- [ ] Extract `LegacySettingsStore`, `ConfigurationLibraryStore`, and
  `ConfigurationProjectionService` while keeping `SettingsService` compatible.
- [ ] Preserve all UserDefaults keys, legacy migration, aggregate revision,
  snapshot construction, and local-first behavior.
- [ ] Verify focused settings/migration tests and iOS build.

### Task 6: External Intake Storage Layers

**Acceptance criteria:**
- [ ] Extract `ExternalIntakeRequestStore`, `ManagedIntakeFileStore`, and
  `IntakeCleanupService` while keeping `ExternalPhotoIntakeStore` compatible.
- [ ] Preserve request encoding, managed copy identity, deduplication,
  referenced-file retention, orphan cleanup, cancellation, and app-group paths.
- [ ] Verify focused intake/persistence tests and iOS build.

## Checkpoint 2

- [ ] Each task passes independent specification and quality review.
- [ ] Run focused suites, serial `PhotoMemoTests build-for-testing`, generic
  iOS Simulator app build, and Share Extension build.
- [ ] Run `git diff --check` and dead-helper/source-contract review.
- [ ] Update `Docs/CURRENT_STATUS.md` with facts and unverified device behavior.
- [ ] Push the integration branch, fast-forward `main`, verify, and push GitHub.

## Explicit Deferrals

- Broad `V1` naming removal remains a separate compatibility migration.
- Existing persistence keys and on-disk records are not renamed.
- Physical-device Share, Photos save, and manual UI verification must be
  reported honestly if not performed.
