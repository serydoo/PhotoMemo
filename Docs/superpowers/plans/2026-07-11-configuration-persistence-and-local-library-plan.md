# Configuration Persistence And Local Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Follow test-driven development and do not commit or push unless the user explicitly requests it.

**Goal:** Make every MemoMark configuration complete, atomically persistent, locally backable, safely restorable, and consistent across the main app, Share Extension, and frozen batch snapshots.

**Architecture:** Keep the frozen Configuration Center and production rendering pipeline. Introduce a versioned subject-owned configuration aggregate as durable truth, derive compatibility settings and production snapshots from it, and add an actor-backed backup repository whose documents are inert until explicitly restored.

**Tech Stack:** Swift, SwiftUI, Swift Testing, Codable, actors, App Group UserDefaults, Application Support file storage, FileDocument/document importer and exporter.

---

### Task 1: Close Existing Save Identity Defects

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterState.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplyRuntimeCoordinator.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationSessionConfigurationLifecycleTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationApplyRuntimeCoordinatorTests.swift`

- [ ] Add a failing test proving first save uses the same configuration UUID in the persistence candidate and reconciled Session.
- [ ] Add a failing test proving a subject with no configurations cannot inherit region IDs or summary from another subject's global first Preset.
- [ ] Replace the temporary tuple snapshot with a candidate object that can be reconciled into Session without generating another UUID.
- [ ] Make selected Preset lookup return `nil` when no selected ID exists instead of returning the global first Preset.
- [ ] Run the two focused suites and confirm both regressions pass.

### Task 2: Canonicalize Classic White Naming

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/Models/TemplatePreset.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Models/Template.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- Rename/Modify: current and legacy Classic White renderer source files
- Modify: active source and tests that write legacy preset values
- Test: `Tests/PhotoMemoTests/RendererTests/TemplatePresetRenderLayoutTests.swift`
- Test: `Tests/PhotoMemoTests/RendererTests/RecordCardRendererRoutingTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationMigrationTests.swift`

- [ ] Add failing tests proving new encoding writes only `classicWhite` and legacy `template1`, `template2`, `template3`, and `immersWhite` decode to `classicWhite`.
- [ ] Add snapshot/routing tests proving canonical Classic White preserves the current latest visual implementation.
- [ ] Rename active Immers symbols/files to Classic White and mark/remove the older renderer implementation without changing layout constants.
- [ ] Replace active production/test writers with `.classicWhite`; keep legacy raw strings only in migration fixtures and historical docs.
- [ ] Run renderer routing, layout, migration, export, Live Photo, and snapshot tests.

### Task 3: Define Complete Versioned Configuration Models

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/Models/MemoryConfigurationRecord.swift`
- Create: `Source/PhotoMemo/PhotoMemo/Models/ConfigurationLibraryRecord.swift`
- Create: `Source/PhotoMemo/PhotoMemo/Models/PortableMemoryConfigurationDocument.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationLibraryRecordTests.swift`

- [ ] Add failing round-trip tests for subject identity, anchors, Template, location, Badge reference, description policy, album descriptor, media output mode, revision, and selected IDs.
- [ ] Define schema version `1` and reject unsupported future versions through a typed compatibility result.
- [ ] Define portable relative asset references; prohibit serialization of renderer implementation constants.
- [ ] Add migration construction from the existing `V1SubjectLibraryRecord` plus saved compatibility settings.
- [ ] Run the focused model tests and confirm deterministic Codable round trips.

### Task 4: Add Atomic Aggregate Persistence

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/Repositories/ConfigurationLibraryRepository.swift`
- Create: `Source/PhotoMemo/PhotoMemo/Services/ConfigurationLibraryPersistence.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationLibraryRepositoryTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationMigrationTests.swift`

- [ ] Add failing tests for atomic success, encode failure, write failure, last-known-good recovery, and monotonically increasing revision.
- [ ] Add `ConfigurationLibrarySaveReceipt` and typed persistence errors.
- [ ] Serialize repository writes through an actor and write the complete aggregate as one Data value.
- [ ] Make legacy selected-subject, Template, Badge, album, location, and media keys compatibility projections emitted only after primary success.
- [ ] Make production snapshot refresh consume the saved aggregate revision.
- [ ] Run focused repository and migration tests.

### Task 5: Make Each Configuration Complete

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterState.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplySupport.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationBootstrapCoordinator.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationSessionConfigurationLifecycleTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationApplyRequestBuilderTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationMigrationTests.swift`

- [ ] Add failing tests proving two configurations under one subject retain independent location, Template, Badge/logo, Memory copy, Photos description policy, album, renderer route, and media output settings.
- [ ] Add complete editor, presentation, and output records to the selected configuration lifecycle.
- [ ] Restore all configuration-scoped fields on Preset selection without changing production state until apply succeeds.
- [ ] Derive `BatchConfigurationSnapshot` from the active complete configuration.
- [ ] Carry durable configuration ID and revision into production snapshots and diagnostics.
- [ ] Project legacy configuration slots from the aggregate without allowing them to write back into aggregate truth.
- [ ] Preserve fallback decoding for existing stored records.
- [ ] Run focused lifecycle, request-builder, migration, and snapshot tests.

### Task 6: Implement Local Backup Repository

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/Repositories/LocalConfigurationLibraryRepository.swift`
- Create: `Source/PhotoMemo/PhotoMemo/Services/ConfigurationAssetPackager.swift`
- Create: `Source/PhotoMemo/PhotoMemo/Coordinators/LocalConfigurationLibraryCoordinator.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/LocalConfigurationLibraryRepositoryTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationAssetPackagerTests.swift`

- [ ] Add failing tests for subject UUID paths, atomic backup replacement, checksums, list ordering, and deletion isolation.
- [ ] Add failing tests for avatar/logo relative-path packaging and restored-path remapping.
- [ ] Store backups under Application Support using actor-serialized operations.
- [ ] Keep live deletion separate from backup deletion.
- [ ] Return backup receipts and typed errors.
- [ ] Run focused repository and asset tests.

### Task 7: Implement Import And Restore Coordination

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationImportCoordinator.swift`
- Create: `Source/PhotoMemo/PhotoMemo/Models/ConfigurationImportResolution.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationImportCoordinatorTests.swift`

- [ ] Add failing tests for same-name/different-ID subjects, same-ID configuration copy restore, missing anchor, missing album, missing asset, old schema, future schema, and corrupt documents.
- [ ] Validate documents without mutating live configuration.
- [ ] Restore same-ID configurations as new copies by default.
- [ ] Route `Restore And Make Current` through the normal aggregate apply path.
- [ ] Prove existing BatchJob snapshots do not change after import or deletion.
- [ ] Run focused import and batch-freeze tests.

### Task 8: Add Home Backup And Library UI

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift`
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibraryPresenter.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1LocalConfigurationLibraryPresenterTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1HomeConfigurationActionContractTests.swift`

- [ ] Add source and presenter tests for blue `保存`, red `删除`, footer `+`, accessibility labels, and current-subject filtering.
- [ ] Expand the row swipe reveal to expose save and delete without changing row selection behavior.
- [ ] Save dirty selected configuration through apply before backup; save non-selected rows from durable records.
- [ ] Add the current-subject local library sheet with restore, restore-current, import, export, and backup deletion actions.
- [ ] Surface readable success, missing-resource, and failure states.
- [ ] Run focused UI contract tests and generic iOS build.

### Task 9: Complete User Copy And Documentation

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- Create: `Docs/UserGuide/Configuration_Save_Backup_And_Restore.md`
- Create: `Docs/02_Architecture/Configuration_Persistence_And_Recovery_Flow.md`
- Modify: `Docs/CURRENT_STATUS.md`
- Modify: `HANDOFF.md`
- Test: `Tests/PhotoMemoTests/BatchTests/PhotoMemoShareIntakeDiagnosticsTests.swift`

- [ ] Add the approved warm 20-photo limit copy regression first and verify it fails.
- [ ] Apply the approved title, message, and `返回分批分享` action consistently.
- [ ] Write a simple user guide distinguishing save-current, local backup, restore, and frozen running jobs.
- [ ] Write the developer flow, schema, migration, diagnostics, and recovery rules.
- [ ] Update project status and handoff with verified and unverified behavior.
- [ ] Run focused Share tests, both generic iOS builds, and `git diff --check`.

### Task 10: Signed Device Verification

**Files:**
- Update after evidence: `Docs/CURRENT_STATUS.md`
- Update after evidence: `HANDOFF.md`

- [ ] Install the signed build on physical `iPhone7`.
- [ ] Verify save, app restart, configuration deletion, retained backup, restore as copy, and restore-current.
- [ ] Verify custom avatar/logo asset restoration.
- [ ] Verify missing album fallback and current revision in Share processing.
- [ ] Verify an already-running job retains its frozen configuration.
- [ ] Verify the 21-photo warm rejection UI and machine-readable event.
- [ ] Record what passed and any remaining manual-only limitations.
