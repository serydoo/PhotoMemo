# MemoMark Master Plan

Last updated: 2026-07-11

Read `PROJECT_CONSTITUTION.md` before this file. The constitution is the highest-level repository instruction. This file remains the operational master plan.

## Vision

MemoMark is a local-first Memory Presentation Engine.

It is not a watermark application and it is not a clone of any existing product. MemoMark studies excellent design languages, extracts measurable layout principles, and turns those principles into reusable specifications, design tokens, layout rules, and renderer implementations. More importantly, MemoMark preserves the position every photograph occupies inside a person's life.

MemoMark does not only present photographs. It presents memories.

## Current Phase

MemoMark is in `V3 Production Quality And Delivery`.

V1 MVP and V2 Product Definition And Realization are complete. The canonical
stage boundaries are recorded in `Docs/PRODUCT_VERSION_HISTORY.md`.

V3 carries the V2 architecture into production-quality validation and delivery.
It prioritizes durable configuration, real Apple Photos lifecycle correctness,
regression prevention, performance and memory evidence, and release readiness.

PM-003 Content Layout System Phase 1 is frozen.

IA-002 Configuration Center Architecture is frozen.

The completed V2 implementation track was:

```text
IA-003 Memory Engine Integration
```

The latest frozen V2 repository amendment is:

```text
PDR-004 Configuration Center Architecture
```

## Current Priority

Close V3 production-quality gaps without reopening frozen V2 architecture:

1. Keep `ConfigurationLibraryRecord` and its V3 successors as durable truth.
2. Close configuration save, restore, backup, and clean-install regressions.
3. Validate the real Apple Photos -> Share -> MemoMark -> Processing ->
   Notification -> Apple Photos lifecycle on signed devices.
4. Collect evidence for Live Photo, orientation, location, RAW/ProRAW/DNG,
   high-resolution media, performance, memory, and concurrency behavior.
5. Establish repeatable change-level and release-level production quality gates.
6. Preserve the frozen Configuration Center, Memory Engine, Presentation,
   Layout Engine, Renderer, and Export ownership boundaries.

## Long-Term Development Rule

Any new feature must pass through these five steps:

1. `PDR (Product Design Review)`
   Discuss and freeze the product decisions first.
2. `Repository Simplification Review`
   Remove stale concepts, synchronize vocabulary, and make the repository simpler before adding new decisions.
3. `Architecture Review`
   Confirm the change does not break existing architecture or project principles.
4. `Implementation`
   Codex implements the approved change.
5. `Review & Freeze`
   Validate the result, freeze the accepted decisions, and record them in `Docs/FROZEN_REGISTRY.md`.

This is a permanent workflow rule for future MemoMark feature development.

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

MemoMark preserves both.

The key new property is Life Position: where a photo belongs inside a person's life timeline.

MemoMark is not a photo manager.

MemoMark is a local-first Memory Capability inside Apple workflows.

The product should not change how users manage photos.

It should change how users understand them.

## Completed V2 Roadmap

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

Status: frozen.

Scope:

- define the Configuration Center as the long-term setup surface
- freeze the Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos lifecycle
- define Zero Interaction and Quiet Computing behavior
- define progress language, product personality, and Apple-native interaction principles
- define the boundary that MemoMark extends Apple Photos instead of replacing it

### RSR-001: Repository Simplification Review

Status: frozen.

Scope:

- remove stale workbench, workspace, dashboard, task-center, and import-first language from current source-of-truth documents
- standardize user-facing repository vocabulary around Configuration Center, Preset, Configuration Preview, Life Anchor, Time Anchor, Behavior, and Apple Native
- keep internal renderer/template implementation terminology where it reflects current code ownership
- establish Apple Photos Lifecycle as the daily workflow:

```text
Apple Photos
-> Share
-> MemoMark
-> Processing
-> Notification
-> Apple Photos
```

- establish batch scale language:

```text
Primary: 1-20
Secondary: 20-50
Advanced: 50+
```

### PDR-004: Configuration Center Architecture

Status: frozen.

Scope:

- define Configuration Center as the Memory Engine Configuration Center
- freeze the object editing principle:

```text
Configuration Center edits Objects, not Data.
```

- freeze the central interaction principle:

```text
Everything starts from the Memory Card.
```

- freeze the Configuration Center layout:

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

- freeze `CardRegion`, `InspectorProvider`, `TokenCategory`, `DecorationAsset`, `MemoryBehavior`, and Capture-Time Principle at the repository architecture level
- freeze the IA-002 object architecture:
  - Configuration Center
  - Library
  - Interactive Memory Card
  - Object Inspector
  - CardRegion
  - InspectorProvider
  - TokenLibrary
  - MemoryBlock
  - DecorationAsset
  - Configuration Snapshot
- freeze the principle:

```text
Configuration Center previews the real Memory Card, not an abstract layout.
```

- freeze Region Strip as Memory Card Navigation:

```text
Recorder
Timeline
Location
Memory
```

### PDR-005: Memory Language Layer

Status: frozen.

Scope:

- define MemoryBlock as a content asset, not a layout asset
- define the Memory Language Layer:

```text
MemoryBlock
-> Block Template
-> Block Field
-> Value Binding
```

- freeze the long-term MemoryBlock direction as field-based:

```text
MemoryBlock {
    templateID
    fields: [BlockField]
}
```

- freeze `Subject + Action + Result` as Preset Schema #001, not as the core model
- define value sources:
  - Fixed Text
  - Token Binding
  - Smart Module Binding
  - Custom Field Binding
- define IA-003C Memory Block Resolver as the first implementation point

### IA-003: Memory Engine Integration

Status: completed V2 integration track; preserved as a V3 architecture baseline.

Goal:

Produce the first real MemoMark by connecting real photo facts, Memory Subject, Configuration Snapshot, Memory Engine output, Memory Card, and Renderer in controlled slices.

Approved sequence:

```text
IA-003A MemorySubject Adapter
-> IA-003B Configuration Snapshot
-> IA-003C Memory Block Resolver
-> IA-003D CaptureTimeResolver
-> IA-003E Interactive Memory Card connects real data
-> IA-003F Renderer
```

IA-003 must preserve:

- local-first processing
- Apple Photos lifecycle
- Capture-Time Principle
- Memory Subject = Identity + MemoryBehavior
- MemoryBlock as field-based content asset
- Configuration Center edits Objects, not Data
- Everything starts from the Memory Card
- IA-002 architecture as frozen UI architecture

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
- preserve Configuration Preview/export fidelity through measurable tests

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

- The app already has a real local-first Apple Photos/share intake -> metadata -> memory -> render -> export path.
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

The next implementation slice is:

```text
IA-003A MemorySubject Adapter
```

IA-003A should bridge the existing personal/profile configuration into the new `MemorySubject` model.

Do not modify Renderer, Metadata, Export, Share Extension, Photo Library behavior, or Layout Engine work in IA-003A.

Do not migrate old documents until the research specifications stabilize.

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
- `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`
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
