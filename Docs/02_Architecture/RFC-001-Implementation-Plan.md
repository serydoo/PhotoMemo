# Implementation Plan: RFC-001 Memory Enters the Production Pipeline

## Historical Record Notice

This implementation plan is preserved as a historical architecture record for
RFC-001. Do not use its completed task list as the current live-repository truth
without checking `Docs/CURRENT_STATUS.md` first. `CURRENT_STATUS.md` is the
single source of truth for the active repository state.

## Overview

This plan implements RFC-001 by changing exactly one architectural fact:

```text
Current:
Memory participates only in configuration and preview.

Target:
Memory participates in the production pipeline.
```

The plan keeps the existing production pipeline singular and additive. It does not redesign renderer inputs, replace `BatchConfigurationSnapshot`, or broaden into formula, location, weather, or configuration-source unification.

Repository Note:
This implementation plan was restored into `~/Desktop/PhotoMemo` on `2026-07-03` together with the canonical RFC/Baseline set after the repository line was corrected back to the live working tree.

## References

- `Docs/02_Architecture/RFC-001-Memory-Enters-the-Production-Pipeline.md`
- `Docs/02_Architecture/MemoMark_V1_Engineering_Baseline.md`
  - `D-002`
  - `D-004`
  - `I-003`

## Architecture Decisions

- The narrowest production seam is the current `BuildPreviewIntent -> PreviewCoordinator -> RecordCardBuildService -> RecordCard` path.
- RFC-001 should reuse the existing production pipeline and inject Memory there, rather than create a parallel Memory export path.
- RFC-001 should reuse existing `MetadataContext` / `TemplateVariableEngine` compatibility so renderer and export behavior remain unchanged.
- RFC-001 should carry Memory into production through an additive production-facing seam before any cleanup of legacy configuration ownership.

## Implementation Strategy

Current production path:

```text
SelectedPhoto
    -> BatchConfigurationSnapshot
    -> RecordCardBuildService
    -> RecordCard
    -> CardVariableProvider
    -> TemplateVariableEngine
    -> Renderer
    -> Export
```

Planned RFC-001 production path:

```text
SelectedPhoto
    -> BatchConfigurationSnapshot
    -> Production Memory Adapter / Resolver
    -> MemoryModule
    -> RecordCardBuildService
    -> RecordCard / MetadataContext
    -> CardVariableProvider
    -> TemplateVariableEngine
    -> Renderer
    -> Export
```

The intended effect is not to replace `RecordCard`, but to make Memory-derived output available to the existing production build path.

## Task List

### Phase 1: Production Memory Seam

- [x] Task 1: Define the additive production Memory seam
  - Description: Introduce the smallest production-facing boundary that can derive Memory from the existing production inputs without creating a second pipeline.
  - Acceptance:
    - one production-oriented type or resolver defines how Memory enters the build path
    - the seam consumes existing production inputs rather than configuration-preview-only state
    - no renderer or export API changes are required
  - Verify:
    - unit tests cover the new production seam
    - the seam can be instantiated from production inputs only
  - Files:
    - `Source/PhotoMemo/PhotoMemo/MemoryEngine/`
    - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/`
  - Estimated scope: Medium

- [x] Task 2: Resolve `MemoryModule` during production card build
  - Description: Make the current production build path produce Memory-derived output before renderer/export without changing the production pipeline shape.
  - Acceptance:
    - `RecordCardBuildService` or its immediate seam can resolve Memory during production build
    - `BuildPreviewIntent -> PreviewCoordinator -> RecordCardBuildService` remains the production build route
    - no second production export path is introduced
  - Verify:
    - targeted `RecordCardBuildService` tests prove Memory is resolved in production build
    - architecture tests still pass through the existing preview/build intent route
  - Files:
    - `Source/PhotoMemo/PhotoMemo/Coordinators/PreviewCoordinator.swift`
    - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
    - `Source/PhotoMemo/PhotoMemo/Intent/BuildPreviewIntent.swift`
    - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/ArchitectureMigrationFoundationTests.swift`
  - Estimated scope: Medium

### Checkpoint: Production Participation

- [x] Production build path still has one route
- [x] Memory is resolved before renderer/export
- [x] No renderer or export interface changed

### Phase 2: Compatibility Projection

- [x] Task 3: Project Memory-derived output into existing production context
  - Description: Bridge resolved Memory into the existing `MetadataContext` / variable model so the current renderer/export path can consume it without redesign.
  - Acceptance:
    - existing production variable context receives Memory-derived values
    - current template/renderer compatibility remains intact
    - the bridge is additive and traceable to one production seam
  - Verify:
    - regression tests prove `MetadataContext` receives Memory-derived values in production build
    - no snapshot or renderer changes are needed for the values to flow through
  - Files:
    - `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift`
    - `Source/PhotoMemo/PhotoMemo/Models/MetadataContext.swift`
    - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
    - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
  - Estimated scope: Medium

### Checkpoint: Compatibility Preserved

- [x] Memory-derived values are reachable through current production variables
- [x] Template-variable rendering still works
- [x] Renderer behavior remains unchanged

### Phase 3: Verification

- [x] Task 4: Add RFC-001 verification coverage
  - Description: Lock the new architectural fact in tests so future work can prove Memory is part of production without relying on preview-only paths.
    This task must remain verification-only and must not introduce any second
    architectural fact.
  - Acceptance:
    - one test proves production build resolves Memory
    - one test proves the production pipeline remains singular
    - one regression test proves renderer/export behavior is unchanged by the Memory entry point
  - Verify:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -destination 'platform=macOS' -only-testing:PhotoMemoTests test`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - Files:
    - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/ArchitectureMigrationFoundationTests.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/PreviewMigrationTests.swift`
  - Estimated scope: Medium

### Checkpoint: RFC-001 Complete

- [x] A production export can obtain Memory-derived data through the production path
- [x] The production path remains singular
- [x] Renderer behavior remains unchanged
- [x] Export behavior remains unchanged

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Memory seam accidentally creates a second build path | High | keep all production build entry routing inside `BuildPreviewIntent -> PreviewCoordinator -> RecordCardBuildService` |
| RFC broadens into configuration unification | High | prohibit changes to `BatchConfigurationSnapshot` ownership in this RFC |
| Renderer changes become tempting once Memory reaches context | High | project through existing `MetadataContext` compatibility keys first |
| Memory needs preview-only objects to work | Medium | adapt from production inputs using additive resolver types |

## Open Questions

- Should the production seam produce a `MemoryModule` directly, or a narrower production projection derived from it?
- Which existing `MetadataContext` keys are sufficient for the first production participation, and which can wait for later RFCs?

## Next Step After Plan Approval

RFC-001 verification is complete. Any further production-pipeline changes must
enter a new RFC rather than extend this one.
