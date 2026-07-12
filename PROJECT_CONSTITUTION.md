# MemoMark Project Constitution

Last updated: 2026-07-11

This is the highest-level repository instruction for MemoMark.

Every AI agent and future coding session must read this before making any modification.

## V3 Amendment

MemoMark V1 and V2 are complete. The current product stage is:

```text
V3 Production Quality And Delivery
```

The canonical product-stage history is `Docs/PRODUCT_VERSION_HISTORY.md`.

V3 preserves the local-first Memory Presentation Engine, Configuration Center,
Memory Engine, IA-002, and IA-003 boundaries established during V2. The active
work now emphasizes production correctness, durable configuration, full Apple
Photos lifecycle evidence, regression control, performance, and release
readiness.

Historical V2 sections below remain binding architectural foundations unless a
later V3 decision explicitly amends them. References to V2 as the current phase
are historical and must not override this amendment or `Docs/CURRENT_STATUS.md`.

## Current Status

MemoMark Repository V2 Reset has already been completed.

The repository already contains:

- `Docs/MASTER_PLAN.md`
- `PROJECT_RESET.md`
- `RepositoryAudit.md`
- `Research/`
- AI workflow files
- Repository V2 directory skeleton

These documents are the new project entry.

Historical V2 repository phase:

```text
Product Realization Preparation
```

The architecture remains repository-led and review-gated.

PM-003 Phase 1 is frozen.

IA-002 Configuration Center Architecture is frozen.

The V2 product-realization slice was:

```text
IA-003 Memory Engine Integration
```

This is the first controlled return to real pipeline integration after Product Definition.

The latest repository amendment is:

```text
PDR-004 Configuration Center Architecture
```

PDR-004 freezes the Configuration Center as object-centered architecture.

V3 work must preserve the approved IA-003 result and must not reopen IA-002 architecture without an explicit new product decision.

## Mission

MemoMark is not a photo watermark application.

MemoMark is a:

- local-first
- privacy-first
- open-source-oriented
- Apple-ecosystem-native

Memory Presentation Engine.

MemoMark is also a:

```text
Local First Memory Capability
```

inside Apple Photos workflows.

MemoMark does not only present photographs. It presents memories.

MemoMark does not manage photos.

MemoMark only owns:

```text
Memory Workflow
```

The long-term workflow is:

```text
Research
-> Specification
-> Memory Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
-> Application
```

Renderer is no longer the project center.

Layout Engine becomes the center.

## First Principles

- The project no longer aims to reproduce Immers.
- Immers is only a research reference.
- The purpose is to study excellent design languages.
- The goal is to extract reusable layout rules.
- MemoMark must build its own Design System.
- Photos have timestamps.
- Memories have positions.
- EXIF records when a photo was taken.
- Memory Engine calculates where that photo belongs inside a person's life.
- MemoMark should not change how users manage photos.
- MemoMark should change how users understand photos.
- Configuration Center edits Objects, not Data.
- Everything starts from the Memory Card.
- Configuration Center previews the real Memory Card, not an abstract layout.
- Capture-Time Principle preserves memory truth from the photo's capture time.
- Memory Subject equals Identity plus MemoryBehavior.
- Apple Photos remains the trusted photo-management system.
- Pictures are temporary.
- Knowledge is permanent.
- Specifications are permanent.
- Architecture is permanent.
- Renderer is only implementation.

## Project Philosophy

- Local First
- Privacy First
- Research First
- Specification First
- Layout Before Renderer
- Renderer Is Stateless
- Metadata Is Single Source Of Truth
- Memory Engine Calculates Life Position
- Presentation Engine Expresses Meaning
- Apple Native First
- Invisible Product
- No Guessing
- No Magic Numbers
- Every Layout Decision Must Be Measurable

## Apple Trust Principle

MemoMark trusts Apple.

Not because it is Apple as a brand.

But because Apple Photos has already proven its maturity and reliability in real large-scale photo management.

MemoMark does not rebuild those systems.

MemoMark focuses on:

```text
Memory Capability
```

This principle comes from long-term real use.

The developer has used Apple Photos to manage more than 110,000 life photos over time.

Therefore:

```text
MemoMark fully trusts Apple Photos.
```

## Immediate Task

IA-002 is complete and frozen at the architecture level.

The next approved implementation track is:

```text
IA-003 Memory Engine Integration
```

IA-003 must proceed in small reviewed slices:

```text
IA-003A MemorySubject Adapter
-> IA-003B Configuration Snapshot
-> IA-003C Memory Block Resolver
-> IA-003D CaptureTimeResolver
-> IA-003E Interactive Memory Card connects real data
-> IA-003F Renderer
```

Do not:

- reopen IA-002 UI architecture
- replace the Library -> Interactive Memory Card -> Object Inspector structure
- modify Renderer, Metadata, Export, Share Extension, or Photo Library behavior before the approved IA-003 slice reaches that boundary
- migrate old documents before research specifications stabilize

Focus on turning frozen repository concepts into one real MemoMark pipeline while preserving local-first and Apple Photos lifecycle boundaries.

## Repository Simplification Principle

MemoMark is now moving from Repository Refactor to Repository Simplification.

Every review should leave the repository simpler than before.

每一次设计评审，都应该让时光记比昨天更简单一点。

Current repository-facing vocabulary must preserve:

- Configuration Center
- Configuration Session
- Memory Workflow
- Preset
- Time Anchor
- Life Anchor
- Behavior
- Apple Native

Current repository-facing vocabulary must avoid user-workflow concepts such as:

- Workspace
- Import
- Dashboard
- Task Center
- Photo Manager
- EXIF Tool

Daily workflow is:

```text
Apple Photos
-> Share
-> MemoMark
-> Processing
-> Notification
-> Apple Photos
```

The Configuration Center owns long-term configuration only:

- Memory Profile
- Life Anchor
- Preset
- Output
- Album
- Automation
- Advanced

The Configuration Center is the Memory Engine Configuration Center.

Its frozen architecture is:

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

The Configuration Center edits Objects, not Data.

Everything starts from the Memory Card.

## Repository Audit Phase

Continue reviewing:

- Architecture
- Documentation
- Workflow
- Directory structure
- Single source of truth
- Cross-document consistency

Identify:

- duplicated documents
- outdated documents
- conflicting documents

Prepare Repository V2 through research-first documentation, not through premature code or file migration.

## Documentation Strategy

Do not immediately migrate old documents.

Migration should happen after research specification becomes stable.

Current priority:

- build the new research documentation
- keep old documentation as reference
- avoid moving documents twice

## Research System

`Research/` is now the highest-priority repository area.

Required documents:

- `README.md`
- `ReverseEngineeringRoadmap.md`
- `LayoutSpecification.md`
- `CanvasSpecification.md`
- `PanelSpecification.md`
- `BrandAnchorSpecification.md`
- `MetadataSlotSpecification.md`
- `TypographySpecification.md`
- `ColorSpecification.md`
- `AdaptiveRules.md`
- `OpticalLayout.md`
- `ResearchHistory.md`
- `MeasurementMethodology.md`

## Reverse Engineering Targets

- Canvas
- Information Panel
- Brand Anchor
- Metadata Slots
- Typography
- Color
- Spacing
- Grid
- Adaptive Layout
- Optical Layout

The goal is not screenshot similarity.

The goal is extracting reusable rules.

## Measurement

Avoid vague language such as:

- approximately
- looks similar
- seems

Prefer measurable language:

- pixels
- ratios
- percentages
- bounding boxes
- baselines
- cap height
- x-height
- optical center
- safe area
- grid unit
- token value
- min/max constraint
- acceptance threshold

If a layout decision cannot yet be measured, record it as an open research question instead of hard-coding it.
