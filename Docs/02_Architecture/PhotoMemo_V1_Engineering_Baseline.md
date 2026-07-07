# MemoMark V1 Engineering Baseline

Version: `V1.0 Baseline`

Assessment Date: `2026-07-03`

Assessment Scope:
- Repository commit: `5dd162f0f0b0d8e4649ebad595bec66cf4a09e91`
- Branch: `main`
- Assessment window: `2026-07-03`

Repository Note:
This baseline was originally produced against the earlier archive snapshot line and was restored into `~/Desktop/PhotoMemo` on `2026-07-03` so the engineering record remains in one canonical repository. It should be treated as a preserved engineering artifact until a fresh baseline is created against the live `~/Desktop/PhotoMemo` worktree.

Method:
- `PFL Decision`
- `Architecture Decision`
- `Implementation`
- `Verification`
- `Traceability`

Purpose:
Establish the factual engineering baseline of V1.
No redesign is proposed in this document.

Confidence Summary:
- High-confidence findings: `8`
- Medium-confidence findings: `3`
- Low-confidence findings: `0`

Evidence Count: `13`

Disposition Count:
- `KEEP`: `1`
- `MIGRATE`: `4`
- `REMOVE`: `1`
- `DEFER`: `2`

Open Question Count: `4`

## Executive Summary

MemoMark V1 is a real local-first production pipeline, but its live runtime still depends on the legacy `BatchConfigurationSnapshot -> RecordCard -> TemplateVariableEngine -> Renderer -> Export` stack, while the newer `MemorySubject -> ConfigurationSnapshot -> MemoryExpressionEngine` architecture is present mainly as a parallel preview and configuration path rather than the owning runtime path.

## Assumptions

### A-001 Production-path authority

Assumption:
The current production path is treated as the authoritative runtime path because it is the only path observed to complete import, card build, export, and save-back inside the live batch/share pipeline.

Related Evidence:
- E-001
- E-002

### A-002 Preview-path non-authority

Assumption:
The current Memory/Configuration Center path is treated as non-authoritative for runtime export because it is observed primarily in preview/configuration generation rather than in the live save-back pipeline.

Related Evidence:
- E-003
- E-012

### A-003 Repository-language priority

Assumption:
Frozen repository vocabulary is treated as the language reference point for this baseline, even where retained V1 runtime code still uses older terms.

Related Evidence:
- E-009

## Architecture Position Statement

Architecture synthesis in this baseline does not introduce new evidence. It explains the current structure by citing existing evidence from multiple decision surfaces.

### AD-1 What is the current architecture?

Statement:
The current architecture is a dual-track system: a legacy production track owns real intake, build, export, and save-back behavior, while a newer Memory/Configuration Center track owns a parallel preview and configuration path.

Evidence:
- E-001
- E-002
- E-003
- E-012

Confidence:
High

### AD-2 Why do the observed facts coexist?

Statement:
The observed facts coexist because configuration, composition, and presentation responsibilities are split across retained V1 runtime ownership and newer V2 architectural ownership. This produces multiple truths, duplicated vocabulary, preview/runtime seams, and weak traceability in the retained stack at the same time.

Evidence:
- E-003
- E-004
- E-005
- E-009
- E-010

Confidence:
High

### AD-3 Can the current architecture evolve toward PFL without replacement?

Statement:
Yes, with bounded migration.

Evidence:
- E-001
- E-011
- E-012
- E-004

Confidence:
High

## Evidence Index

### E-001 Runtime Batch Pipeline

- The live processing path freezes `request.configurationSnapshot` into `BatchJob.configuration` and then executes import -> preview/card build -> export -> save in the batch executor.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift:103`
  - `Source/PhotoMemo/PhotoMemo/Coordinators/ShareCoordinator.swift:177`
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift:129`
  - `Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift:434`
  - `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:293`
  - `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:336`
  - `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:377`
  - `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:427`

### E-002 Legacy Card Build Path

- The production card build still runs through `AnchorEngine`, `CardVariableProvider`, and `TemplateVariableEngine`.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:20`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:68`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:111`
  - `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift:21`
  - `Source/PhotoMemo/PhotoMemo/Engines/TemplateVariableEngine.swift:10`

### E-003 New Memory Preview Path

- `ConfigurationSession` builds `ConfigurationSnapshot` and generates `MemoryModule` with a preview-only capture date.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:312`
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:318`
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSnapshotBuilder.swift:6`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift:24`

### E-004 Multiple Configuration Truth Sources

- Configuration is materialized separately from live settings, defaults-backed snapshot construction, and cached queue/intake copies.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:231`
  - `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:827`
  - `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift:40`
  - `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift:119`
  - `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:18`
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift:15`

### E-005 Workspace Session Duplication

- `MainView` owns app state directly, then mirrors a second mutable session into `WorkspaceSessionController`.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift:17`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceSession.swift:49`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/WorkspaceSessionController.swift:9`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/WorkspaceSessionController.swift:148`

### E-006 MainView Runtime Ownership

- `MainView` still owns service construction and derives `currentCard` by invoking the build service during view recomputation.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift:17`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift:59`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift:65`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+DerivedState.swift:28`

### E-007 Build-Service Purity Leak

- `RecordCardBuildService` reaches into shared defaults and decodes `PersonalProfile` while building a card from declared runtime inputs.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:11`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:151`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:171`

### E-008 Renderer/Layout Leakage

- Layout sizing and presentation math remain embedded in renderer/export code.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift:16`
  - `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteCardRenderer.swift:62`
  - `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteCardRenderer.swift:129`
  - `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift:15`
  - `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift:99`
  - `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift:217`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:121`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:527`

### E-009 Vocabulary Drift

- Frozen repository language says `Memory Card`, `Preset`, and forbids `Workspace` and `Import`, but active source still uses the older lexicon.
- Sources:
  - `Docs/REPOSITORY_VOCABULARY.md:43`
  - `Docs/REPOSITORY_VOCABULARY.md:48`
  - `Docs/REPOSITORY_VOCABULARY.md:72`
  - `Docs/REPOSITORY_VOCABULARY.md:73`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/WorkspaceState.swift:4`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/WorkspaceSessionController.swift:6`
  - `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift:32`
  - `Source/PhotoMemo/PhotoMemo/Models/RecordCard.swift:3`

### E-010 Verification Seams

- Preview catalogs and token identities are duplicated, and placeholder values are hardcoded into tests and preview helpers.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSModuleCatalog.swift:149`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSModuleCatalog.swift:220`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift:301`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift:372`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift:617`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPreviewCompositionHelper.swift:214`
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift:686`
  - `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterPreviewCompositionHelperTests.swift:193`

### E-011 Traceable Apple Photos Lifecycle

- The Apple Photos -> Share -> Processing -> Notification -> Apple Photos lifecycle remains explicit in product docs and live runtime.
- Sources:
  - `README.md:89`
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift:103`
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift:65`
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityBridgeService.swift:104`

### E-012 Traceable Memory Engine Slice

- The IA-003 slice already has a clean upward path from `PersonalProfile` to `MemoryModule`.
- Sources:
  - `README.md:124`
  - `PROJECT_CONSTITUTION.md:112`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift:6`
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSnapshotBuilder.swift:6`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift:24`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryModule.swift:4`

### E-013 Context Fragmentation

- Context ownership is spread across multiple `*Context` types rather than one singular capture-to-render chain.
- Sources:
  - `Source/PhotoMemo/PhotoMemo/Models/MetadataContext.swift:3`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryContext.swift:4`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionContext.swift:4`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift:4`

## Fact Report

### I. PFL

#### F-001 Two active lexicons

Observation:
The primary object and composition vocabulary are described with two concurrent naming systems.

Evidence:
- E-002
- E-003
- E-009

Decision:
The current codebase is not yet consistently expressible with one shared language. The legacy `RecordCard / Template / Import / Workspace` lexicon and the newer `Memory Card / Configuration Snapshot / MemorySubject` lexicon are both active.

Confidence:
High

#### F-002 Context names are fragmented

Observation:
The current language surface does not expose one singular capture-to-render context chain.

Evidence:
- E-013

Decision:
Current V1 terminology fragments context ownership across multiple `*Context` types without one stable `Capture Context` or `Render Context` term.

Confidence:
High

### II. Architecture

#### F-003 Real runtime still follows the legacy production path

Observation:
The processing pipeline that reaches export still runs through the batch snapshot and record-card stack.

Evidence:
- E-001
- E-002

Decision:
The newer Memory/Configuration Center architecture exists in the repository, but it is not yet the owning production chain.

Confidence:
High

#### F-004 Configuration has more than one truth source

Observation:
Configuration is rebuilt and cached from multiple runtime entry points.

Evidence:
- E-004
- E-005

Decision:
Configuration ownership is currently split between live settings state, defaults-backed snapshot construction, workspace/session copies, and batch/intake caches.

Confidence:
High

#### F-005 Runtime owning domains are incomplete

Observation:
Presentation and layout responsibilities are distributed across services and renderers rather than concentrated in first-class runtime modules.

Evidence:
- E-002
- E-008

Decision:
V1 has a real pipeline, but it does not yet expose a first-class runtime `PresentationEngine` or `LayoutEngine` boundary.

Confidence:
High

### III. Implementation

#### F-006 MainView remains an application hub

Observation:
The main view layer still owns service wiring, mutable app state, and cross-feature behavior.

Evidence:
- E-005
- E-006

Decision:
`MainView` is thinner than before, but it still acts as a controller/session hub rather than a pure coordination shell.

Confidence:
High

#### F-007 Purity boundaries leak in build, render, and export code

Observation:
Build, render, and export subsystems still reach across persistence, layout, and artifact concerns.

Evidence:
- E-007
- E-008

Decision:
Implementation boundaries are functional but not pure. The declared subsystem seams do not fully match actual responsibility ownership.

Confidence:
High

### IV. Verification

#### F-008 Translation seams are the highest regression surface

Observation:
Preview token catalogs, module identities, and placeholder display values are duplicated across UI-local paths.

Evidence:
- E-003
- E-010

Decision:
The most likely breakpoints for future `Location`, `Formula`, or `Weather` work are preview/runtime translation seams, not renderer entry routing itself.

Confidence:
High

#### F-009 Tests protect placeholders more than end-to-end ownership

Observation:
Current tests verify individual builders and preview text behavior, but not an end-to-end handoff from configuration-center state into production export.

Evidence:
- E-001
- E-003
- E-010

Decision:
Verification coverage is meaningful, but it is stronger at preserving local behavior than at proving a unified runtime architecture.

Confidence:
Medium

### V. Traceability

#### F-010 Core Apple-native pipeline remains strongly traceable

Observation:
Metadata intake, processing, save-back, and the current IA-003 memory slice all still map clearly to product intent.

Evidence:
- E-001
- E-011
- E-012

Decision:
The core Apple Photos pipeline is not orphaned. MemoMark still has a real, explainable product spine.

Confidence:
High

#### F-011 The active V1 stack is only weakly justified by the V2 story

Observation:
The retained `Workspace`, `Template`, and `RecordCard` stack still powers runtime behavior, but it aligns weakly with current V2 repository language.

Evidence:
- E-002
- E-006
- E-009

Decision:
The biggest traceability gap is not the existence of V1, but that an active parallel V1 stack remains the owning runtime path while the V2 language describes a different center of gravity.

Confidence:
Medium

## Decision

### D-001 `KEEP`

Decision:
Keep the Apple Photos intake -> processing -> save-back spine as a stable baseline asset.

Evidence:
- E-001
- E-011
- E-012

Confidence:
High

### D-002 `MIGRATE`

Decision:
The current production truth still sits in the legacy batch snapshot and record-card pipeline.

Evidence:
- E-001
- E-002
- E-004

Confidence:
High

### D-003 `MIGRATE`

Decision:
Parallel configuration ownership across `SettingsService`, defaults snapshots, workspace/session state, and batch/intake caches is a migration-grade architecture fact.

Evidence:
- E-004
- E-005
- E-006

Confidence:
High

### D-004 `MIGRATE`

Decision:
The Memory Engine path exists, but today it behaves primarily as a preview/configuration path rather than the owning runtime path.

Evidence:
- E-003
- E-012

Confidence:
High

### D-005 `REMOVE`

Decision:
`Workspace` and `Import` remain active engineering language in the current V2 line even though they are frozen as forbidden repository language.

Evidence:
- E-009

Confidence:
High

### D-006 `DEFER`

Decision:
View-surface reduction inside `MainView` and related iOS surfaces remains a known implementation hotspot, but the baseline records it without prescribing immediate redesign.

Evidence:
- E-005
- E-006

Confidence:
Medium

### D-007 `DEFER`

Decision:
Renderer-owned layout responsibility is a confirmed architecture fact, but it remains outside the immediate baseline’s redesign scope.

Evidence:
- E-008

Confidence:
Medium

### D-008 `MIGRATE`

Decision:
Preview/runtime translation seams around token identity, placeholder values, and memory-block binding are migration-grade risks for future feature expansion.

Evidence:
- E-003
- E-010

Confidence:
High

## Open Questions

### Q-001

Question:
Should the `MemorySubject -> ConfigurationSnapshot -> MemoryExpressionEngine` path become the owning production chain, or remain a configuration-preview-only layer?

Owner:
Architecture

Status:
Open

### Q-002

Question:
Will `ConfigurationSnapshot` replace `BatchConfigurationSnapshot`, or will both remain as separate runtime artifacts with different ownership?

Owner:
Architecture

Status:
Open

### Q-003

Question:
What is the durable runtime identity of a computed module: display string, token binding, resolver key, or another object shape?

Owner:
Architecture

Status:
Open

### Q-004

Question:
What is the eventual single vocabulary for the primary output object: `RecordCard`, `Memory Card`, or a future renamed core object?

Owner:
PFL

Status:
Open

## Proposal

No redesign is proposed in this document.

This baseline records the current system as observed. Follow-up RFC, ADR, and migration work should reference the evidence and dispositions above rather than extend this document with implementation plans.

## Drift

No drift recorded in `V1.0 Baseline`.

Future baselines, RFCs, ADRs, or migration documents should record any divergence from `D-001` through `D-008` here rather than editing historical baseline facts.

## Baseline Invariants

### I-001

Current production export is owned by the legacy batch/record-card pipeline.

References:
- D-002
- E-001
- E-002

### I-002

Configuration currently has multiple concurrent truth sources.

References:
- D-003
- E-004
- E-005

### I-003

The Memory/Configuration Center path exists, but it is not yet the owning runtime production path.

References:
- D-004
- E-003
- E-012

### I-004

Preview/runtime translation seams are currently a first-order regression boundary for future feature expansion.

References:
- D-008
- E-003
- E-010

### I-005

The Apple Photos intake -> processing -> save-back spine remains a stable and traceable product core.

References:
- D-001
- E-011
- E-012

## Definition of Done

- [x] Scope frozen to one repository state and assessment window
- [x] Five decision surfaces completed
- [x] Evidence indexed
- [x] Every decision backed by evidence
- [x] Fact and proposal fully separated
- [x] Open questions listed
- [x] No implementation changes introduced during assessment
- [x] Baseline statement included

## Baseline Statement

This document represents the factual engineering baseline of MemoMark V1. It records the current system as observed, without prescribing redesign or migration.
