# PhotoMemo V2 Master Plan

Last updated: 2026-06-23

Read `PROJECT_CONSTITUTION.md` before this file. The constitution is the highest-level repository instruction. This file remains the operational master plan.

## Vision

PhotoMemo is a local-first Memory Presentation Engine.

It is not a watermark application and it is not a clone of any existing product. PhotoMemo studies excellent design languages, extracts measurable layout principles, and turns those principles into reusable specifications, design tokens, layout rules, and renderer implementations. More importantly, PhotoMemo preserves the position every photograph occupies inside a person's life.

PhotoMemo does not only present photographs. It presents memories.

## Current Phase

PhotoMemo V2.1 Memory Engine.

Feature development is paused. Renderer polishing is paused. UI expansion is paused.

Runtime implementation remains paused.

PM-003 Content Layout System Phase 1 is frozen.

The current repository synchronization slice is:

```text
IA-001 Interaction Architecture
```

## Current Priority

Build the V2.1 documentation and architecture foundation:

1. Audit the existing repository.
2. Preserve project memory around the reset.
3. Establish research folders and document flow.
4. Define the future architecture boundary:
   - Metadata Engine
   - Memory Engine
   - Presentation Engine
   - Layout Engine
   - Stateless Renderer
   - Export
5. Keep Layout Specification waiting for reverse-engineering results.
6. Synchronize frozen interaction architecture and behavior principles into repository documentation.

## Long-Term Development Rule

Any new feature must pass through these five steps:

1. `PDR (Product Design Review)`
   Discuss and freeze the product decisions first.
2. `Repository Refactor`
   Synchronize product documents, constitution, philosophy, and design decisions.
3. `Architecture Review`
   Confirm the change does not break existing architecture or project principles.
4. `Implementation`
   Codex implements the approved change.
5. `Review & Freeze`
   Validate the result, freeze the accepted decisions, and record them in `Docs/FROZEN_REGISTRY.md`.

This is a permanent workflow rule for future PhotoMemo feature development.

## Product Philosophy

Every photo has objective information:

- EXIF
- capture time
- camera
- lens
- GPS

These answer when, where, and how a photo was captured.

Every memory has emotional information:

- Life Anchor
- relationship
- family
- child
- travel
- parents
- pets
- anniversaries

These answer what that moment means.

PhotoMemo preserves both.

The key new property is Life Position: where a photo belongs inside a person's life timeline.

PhotoMemo is not a photo manager.

PhotoMemo is a local-first Memory Capability inside Apple workflows.

The product should not change how users manage photos.

It should change how users understand them.

## Version Roadmap

### V2.0: Repository Reset

Status: complete.

Scope:

- repository reset
- V2 project constitution
- master plan
- project reset memory
- repository audit
- research directory
- V2 directory skeleton

### V2.1: Memory Engine

Status: current.

Scope:

- elevate Memory Engine into a first-class architecture module
- define Life Position and Memory Timeline
- clarify Life Anchor and time-anchor semantics
- preserve the rule that Memory Engine outputs reusable values, not complete sentences
- define how memory variables feed Presentation Engine
- keep renderer, UI, and runtime code frozen

### IA-001: Interaction Architecture

Status: current documentation synchronization slice.

Scope:

- define the Main App as a permanent Configuration Center
- freeze the Apple Photos -> Share -> PhotoMemo -> Memory Workflow -> Done path
- define Zero Interaction and Quiet Computing behavior
- define progress language, product personality, and Apple-native interaction principles
- define the boundary that PhotoMemo extends Apple Photos instead of replacing it

### V2.2: Layout Specification

Status: waits for reverse-engineering completion.

Scope:

- canvas specification
- panel specification
- typography specification
- color specification
- metadata-slot specification
- adaptive layout rules
- optical layout rules

### V2.3: Layout Engine

Status: future.

Scope:

- implement Layout Engine only after Layout Specification is stable
- move layout decisions out of renderer code
- define measurable layout contracts

### V2.4: Renderer Rewrite

Status: future.

Scope:

- rewrite renderers to draw Layout Engine output
- remove renderer-owned layout calculations
- preserve preview/export fidelity through measurable tests

### V2.5: macOS Release

Status: future.

Scope:

- stabilize the macOS app on top of the V2 architecture
- prepare open-source docs and release notes
- verify local-first export and metadata behavior

### V3.0: iOS

Status: future.

Scope:

- resume iOS product work after the V2 macOS architecture is stable
- reuse Memory Engine, Presentation Engine, Layout Engine, and Renderer boundaries

## Roadmap

### Phase 0: Reset And Audit

- Create `PROJECT_RESET.md`.
- Create `RepositoryAudit.md`.
- Create `Docs/MASTER_PLAN.md`.
- Create the `Research/` structure.
- Mark V2 precedence in AI-facing documents.
- Create `PROJECT_CONSTITUTION.md` as the highest-level repository rule.

### Phase 1: Memory Engine Architecture

- Build research documentation before any runtime code.
- Define Memory Engine as a first-class module between Metadata Engine and Presentation Engine.
- Define Life Anchor semantics.
- Define memory variable ownership.
- Preserve the rule that sentence construction belongs outside Memory Engine.

### Phase 2: Research System

- Define reverse-engineering roadmap.
- Define measurement methodology.
- Collect observations from private datasets outside the repository only.
- Convert observations into reports.
- Destroy or exclude private datasets after extraction.
- Keep only research reports, layout specs, design tokens, and adaptive rules.

### Phase 3: Layout Specification System

- Define canvas rules.
- Define information-panel rules.
- Define brand-anchor rules.
- Define metadata-slot rules.
- Define typography, color, grid, and spacing tokens.
- Define optical compensation rules.

### Phase 4: Layout Engine

- Introduce a Layout Engine boundary.
- Move layout math out of renderers.
- Make renderer tests assert layout contracts through the Layout Engine.

### Phase 5: Stateless Renderer

- Renderers draw already-resolved layout instructions.
- Renderers do not calculate padding, spacing, font sizes, slot widths, or adaptive rules.

### Phase 6: Open Source Readiness

- Reorganize documentation into clear categories only after research specifications stabilize.
- Improve README, developer guide, examples, screenshots, and release notes.
- Keep the repository understandable without private chat history.

## Repository Health

Current strengths:

- The app already has a real local-first import -> metadata -> memory -> render -> export path.
- Metadata extraction and export preservation have real tests and docs.
- MainView has already been reduced into a coordinator shell.
- iOS and Share Extension groundwork exists.
- Renderer snapshot tests exist for Classic White.

Current risks:

- Renderer code still owns layout values.
- Design documents are numerous and partially overlapping.
- Current structure still reads like an app repository, not an engine repository.
- Research artifacts and layout specifications are not yet first-class.
- Open-source onboarding depends on too many historical documents.
- Interaction architecture rules are not yet centralized into stable reference documents.

## Architecture

V2 target flow:

```text
Photo
-> Metadata Engine
-> Memory Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

Ownership:

- Metadata Engine owns photo facts and normalized metadata.
- Memory Engine owns relationships between photo time and Life Anchors. It calculates Life Position and outputs reusable semantic variables, not prose.
- Presentation Engine owns expression: it combines metadata, memory variables, and templates into presentation content.
- Layout Engine owns canvas, grid, slots, typography placement, adaptive rules, and optical compensation.
- Renderer owns drawing only.
- Export owns file generation and metadata write-back.

## Next Step

The next implementation slice should be documentation and architecture only:

1. Finish repository audit.
2. Finish V2.1 Memory Engine architecture documentation.
3. Synchronize IA-001 Interaction Architecture as frozen repository documentation.
4. Identify old-document duplication and conflicts without moving files yet.
5. Wait for reverse-engineering results before expanding V2.2 Layout Specification.

Do not migrate old documents, write renderer code, or adjust UI until the research specification is stable.

## Document Index

Highest priority:

- `PROJECT_CONSTITUTION.md`
- `Docs/MASTER_PLAN.md`
- `PROJECT_RESET.md`
- `RepositoryAudit.md`
- `Research/README.md`
- `AGENTS.md`
- `AI.md`
- `AI_CONTEXT.md`

Current source-of-truth docs from V1 that remain useful:

- `Docs/MetadataPipelineReview.md`
- `Docs/ExportMetadataAudit.md`
- `Docs/RENDER_SPEC.md`
- `Docs/ClassicWhiteVisualQA.md`
- `Docs/MemoryEngine.md`
- `Docs/MainWorkflowConsolidation.md`
- `Docs/ARCHITECTURE.md`
- `Docs/ADR/INDEX.md`

Historical docs remain useful for context but must not override V2 reset direction.

## Forbidden Actions

- Do not continue feature development.
- Do not continue renderer polishing.
- Do not imitate Immers or any other product.
- Do not immediately migrate old documents.
- Do not commit private research photos.
- Do not use screenshots as permanent product assets.
- Do not place new layout constants inside renderer code.
- Do not let renderer code calculate layout, padding, spacing, font sizes, or adaptive rules.
- Do not skip research -> specification -> layout engine before renderer changes.
