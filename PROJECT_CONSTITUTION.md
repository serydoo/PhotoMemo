# PhotoMemo V2 Project Constitution

Last updated: 2026-06-23

This is the highest-level repository instruction for PhotoMemo V2.

Every AI agent and future coding session must read this before making any modification.

## Current Status

PhotoMemo Repository V2 Reset has already been completed.

The repository already contains:

- `Docs/MASTER_PLAN.md`
- `PROJECT_RESET.md`
- `RepositoryAudit.md`
- `Research/`
- AI workflow files
- Repository V2 directory skeleton

These documents are the new project entry.

Current repository phase:

```text
Documentation Synchronization
```

The architecture remains documentation-first.

PM-003 Phase 1 is frozen.

The current documentation slice is:

```text
RSR-001 Repository Simplification Review
```

This is not runtime development.

The latest repository amendment is:

```text
PDR-004 Configuration Center Architecture
```

PDR-004 freezes the Configuration Center as object-centered architecture.

## Mission

PhotoMemo is not a photo watermark application.

PhotoMemo is a:

- local-first
- privacy-first
- open-source-oriented
- Apple-ecosystem-native

Memory Presentation Engine.

PhotoMemo is also a:

```text
Local First Memory Capability
```

inside Apple Photos workflows.

PhotoMemo does not only present photographs. It presents memories.

PhotoMemo does not manage photos.

PhotoMemo only owns:

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
- PhotoMemo must build its own Design System.
- Photos have timestamps.
- Memories have positions.
- EXIF records when a photo was taken.
- Memory Engine calculates where that photo belongs inside a person's life.
- PhotoMemo should not change how users manage photos.
- PhotoMemo should change how users understand photos.
- Configuration Center edits Objects, not Data.
- Everything starts from the Memory Card.
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

PhotoMemo trusts Apple.

Not because it is Apple as a brand.

But because Apple Photos has already proven its maturity and reliability in real large-scale photo management.

PhotoMemo does not rebuild those systems.

PhotoMemo focuses on:

```text
Memory Capability
```

This principle comes from long-term real use.

The developer has used Apple Photos to manage more than 110,000 life photos over time.

Therefore:

```text
PhotoMemo fully trusts Apple Photos.
```

## Immediate Task

Development remains paused.

Renderer remains frozen.

Current work is repository simplification for frozen product language, interaction architecture, and Apple Photos lifecycle alignment.

Do not:

- modify runtime code
- optimize Renderer
- adjust UI
- modify Engine, Metadata, Export, or pipeline behavior
- migrate old documents before research specifications stabilize

Focus on repository documentation, product definition, and architecture alignment.

## Repository Simplification Principle

PhotoMemo is now moving from Repository Refactor to Repository Simplification.

Every review should leave the repository simpler than before.

每一次设计评审，都应该让 PhotoMemo 比昨天更简单一点。

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
-> PhotoMemo
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
