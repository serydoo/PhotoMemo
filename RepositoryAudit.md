# PhotoMemo Repository Audit

Last updated: 2026-06-22

## Audit Scope

Reviewed repository entry points, AI instructions, changelog, history file, document inventory, source tree, tests, scripts, architecture references, renderer references, metadata references, export references, and current Git state.

Key inputs included:

- `README.md`
- `AI.md`
- `AI_CONTEXT.md`
- `AGENTS.md`
- `HANDOFF.md`
- `CHANGELOG.md`
- `PROJECT_HISTORY.md`
- `Docs/`
- `Source/PhotoMemo/PhotoMemo/`
- `Tests/`
- `scripts/`

## Git And Repository Connection

- Remote: `git@github.com:serydoo/PhotoMemo.git`
- Branch: `main`
- Tracking: `origin/main`
- Working tree before reset-doc edits: clean

## Architecture Evaluation

### Current State

PhotoMemo V1 has a real local-first application architecture:

- app/runtime layer for startup, intake, deep links, and shared containers
- metadata layer with `PhotoMetadataReader` and typed `PhotoMetadata`
- memory layer with `MemoryEngine`
- template and variable engines
- renderer layer with Classic White and Immers-inspired paths
- export layer with generated-image output and photo-library save-back
- background queue and share-extension intake groundwork

### Strengths

- The main pipeline is real, not mock-only.
- Metadata ownership is relatively clear.
- Share Extension does not read EXIF directly, which protects metadata ownership.
- MainView has been decomposed into a coordinator shell and extension files.
- Tests exist across renderer, metadata, export, memory, batch, and variable behavior.

### Weaknesses

- Layout responsibility is still partly inside renderer files.
- Renderer tests currently protect renderer constants more than independent layout contracts.
- The architecture is app-centric rather than engine-centric.
- There is no first-class `PresentationEngine` or `LayoutEngine` boundary yet.
- Design-system tokens exist in documents and code, but are not yet a complete measurable specification system.

## Documentation Evaluation

### Current State

The repository has many useful documents, but they mix product direction, historical handoffs, implementation plans, architecture notes, QA notes, and release notes in one flat `Docs/` namespace.

### Strengths

- Strong project memory exists.
- Metadata, export, workflow, renderer, and MainView refactor areas have substantial written context.
- ADRs exist for several important boundaries.
- Current status and handoff docs are rich enough for agent continuity.

### Weaknesses

- There are too many possible starting points.
- Some docs reflect older positioning and should not remain active decision sources.
- Historical notes are not clearly separated from source-of-truth specifications.
- The V2 research/specification workflow did not previously have a canonical entry point.
- The product philosophy has now moved beyond Photo Presentation Engine toward Memory Presentation Engine.

### Duplication And Conflict Inventory

Documents that overlap and should eventually be consolidated after research specifications stabilize:

- product direction:
  - `Docs/PRODUCT_SPEC.md`
  - `Docs/MVP.md`
  - `Docs/ProductModel.md`
  - `Docs/ProductDirection.md`
  - `Docs/ProductBacklog.md`
  - `Docs/ROADMAP.md`
- MainView refactor planning:
  - `Docs/MAINVIEW_MVP_REFACTOR_SPEC.md`
  - `Docs/MAINVIEW_MVP_REFACTOR_PLAN.md`
  - `Docs/MAINVIEW_PERMISSION_AND_CONTENT_REFINEMENT_SPEC.md`
  - `Docs/MAINVIEW_PERMISSION_AND_CONTENT_REFINEMENT_PLAN.md`
  - `Docs/MAINVIEW_PREVIEW_DETAIL_REFACTOR_SPEC.md`
  - `Docs/MAINVIEW_PREVIEW_DETAIL_REFACTOR_PLAN.md`
  - `Docs/MAINVIEW_WORKSPACE_CONFIGURATION_SPEC.md`
  - `Docs/MAINVIEW_WORKSPACE_CONFIGURATION_PLAN.md`
- metadata and export:
  - `Docs/MetadataInventory.md`
  - `Docs/MetadataPipelineReview.md`
  - `Docs/MetadataRoadmap.md`
  - `Docs/MetadataTechnicalDebt.md`
  - `Docs/MetadataNormalizationPlan.md`
  - `Docs/ExportMetadataAudit.md`
  - `Docs/ExportReadbackVerification.md`
  - `Docs/OutputIntegrityReport.md`
- session history:
  - `HANDOFF.md`
  - `Docs/AI_HANDOFF_2026-06-21.md`
  - `Docs/AI_HANDOFF_2026-06-22.md`
  - `Docs/SESSION_LOG.md`
  - `PROJECT_HISTORY.md`

Known cross-document conflicts:

- Older docs describe PhotoMemo mainly as a memory card generator or template calibration center; V2 philosophy now defines it as a Memory Presentation Engine.
- Older renderer docs discuss fixed renderer-side values; V2 constitution requires Layout Engine ownership for layout decisions.
- Older docs recommend documentation migration as a next step; the constitution now says migration waits until research specification stabilizes.

Decision:

- Do not migrate old documents yet.
- Keep old documents as reference.
- Build new research documents first.
- Later migration should be a separate, reviewed slice.

## Renderer Evaluation

### Current State

The renderer layer currently includes:

- `RecordCardRenderer`
- `ClassicWhiteRenderer`
- `ClassicWhiteCardRenderer`
- `ImmersWhiteRenderer`
- `RenderTheme`
- `BadgeRenderer`

### Strengths

- Classic White has snapshot-grade regression coverage.
- Renderer routing is tested.
- Some theme constants are centralized.
- Preview/export direction has been carefully documented.

### Weaknesses

- Renderer still owns layout choices that should move to a Layout Engine.
- Some tests lock renderer-side layout values instead of measuring layout-engine outputs.
- The Immers-inspired path risks overfitting to visual imitation instead of reusable design principles.

## Workflow Evaluation

### Previous State

```text
Import -> Metadata -> Memory -> Renderer -> Export -> Share/Save
```

This old wording is now treated as historical implementation language, not product workflow language.

### Current State

The current product lifecycle is:

```text
Reading -> Share -> Processing -> Notification -> Reading
```

The daily workflow is:

```text
Apple Photos -> Share -> PhotoMemo -> Processing -> Notification -> Apple Photos
```

V2 target architecture is:

```text
Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export
```

### Strengths

- Apple Photos/share intake, metadata, memory, render, export, save-back, batch queue, and notifications all exist.
- The local-first and non-destructive rules are well preserved.
- Batch configuration snapshots already point toward immutable processing context.

### Weaknesses

- Memory Engine is now being elevated into a first-class architecture module.
- Presentation intent is not yet a separate first-class runtime layer.
- Layout intent is not yet a separate first-class layer.
- The repository still encourages implementation work before research/specification work.

## Repository Health Evaluation

### Strengths

- Meaningful test coverage exists.
- GitHub remote is connected.
- The worktree can be kept clean between slices.
- Scripts exist for local automation and sync.
- Project-specific AI rules exist.

### Risks

- Documentation volume can slow onboarding.
- Private research datasets must remain outside the repository.
- The codebase contains app/platform concerns and engine concerns in one source tree.
- Open-source readers need a cleaner top-level story.

## Open Source Readiness

### Ready

- Product mission is well documented.
- Local-first and privacy-first principles are clear.
- Tests and fixtures exist.
- Changelog exists.

### Not Ready

- V2 architecture is not yet implemented.
- Documentation is not yet reorganized into stable categories.
- Examples and screenshots are not yet curated for public onboarding.
- Research/specification artifacts are not yet established.
- Dataset policy needs to be visible from the main entry docs.

## Recommended V2 Refactor Order

1. Establish `Docs/MASTER_PLAN.md` as the single V2 entry.
2. Preserve `PROJECT_RESET.md` as permanent project memory.
3. Create the `Research/` structure.
4. Establish `PROJECT_CONSTITUTION.md` as the highest-level repository rule.
5. Build the new research documents.
6. Draft measurable Layout, Canvas, Panel, Slot, Typography, Color, Adaptive, and Optical specifications.
7. Only after research specifications stabilize, migrate or consolidate old documents in batches with no content loss.
8. Introduce Layout Engine data types.
9. Move renderer layout constants behind Layout Engine outputs.
10. Convert renderer tests to layout-contract tests where practical.

## Audit Conclusion

PhotoMemo has a strong V1 application foundation, but V2 requires a deliberate architecture reset.

The most important correction is not another renderer tweak. It is establishing memory philosophy, research, and specification as first-class project assets, then making Memory Engine and Layout Engine explicit architecture boundaries.
