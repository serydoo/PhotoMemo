# PhotoMemo AI Context

## V2 Reset

PhotoMemo has completed the IA-002 Configuration Center architecture phase and is entering controlled Product Realization.

Unscoped feature development, renderer polishing, and UI architecture expansion remain paused.

PM-003 Phase 1 is frozen.

IA-002 is frozen.

The current implementation track is:

```text
IA-003 Memory Engine Integration
```

The new target is a local-first Memory Presentation Engine:

```text
Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export
```

Read these first:

1. `PROJECT_CONSTITUTION.md`
2. `Docs/MASTER_PLAN.md`
3. `PROJECT_RESET.md`
4. `RepositoryAudit.md`
5. `Research/README.md`

Renderer must not own layout decisions. New layout work must move through research, specification, Layout Engine, renderer, validation, and release.

Old documentation should not be migrated immediately. Build the new research documentation first, then migrate old docs after research specifications stabilize.

## IA-001 Frozen State

IA-001 is now frozen at the repository-documentation level.

Primary references:

- `Docs/Interaction/IA-001_Interaction_Architecture.md`
- `Docs/PDR/PDR-003_Interaction_Architecture.md`
- `Docs/PDR/PDR_INDEX.md`
- `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
- `Docs/Guidelines/LANGUAGE_SYSTEM.md`
- `Docs/Guidelines/PRODUCT_PERSONALITY.md`
- `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md`
- `Docs/Configuration/CONFIGURATION_MODEL.md`
- `Docs/Product/ANTI_GOALS.md`
- `Docs/DESIGN_DECISIONS.md`
- `Docs/NEVER_BREAK.md`
- `Docs/FROZEN_REGISTRY.md`

## PDR-004 Frozen State

PDR-004 is now frozen at the repository-architecture level.

Primary reference:

- `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`

Frozen principles:

- Configuration Center is the Memory Engine Configuration Center
- Configuration Center edits Objects, not Data
- Everything starts from the Memory Card
- Configuration Center previews the real Memory Card, not an abstract layout
- Preview is the Renderer before Rendering
- Configuration Center layout is `Library -> Interactive Memory Card -> Object Inspector`
- Library is the Memory Object Library
- Memory Card is the primary object
- Bottom Card structure is `Decoration -> Slot A -> Slot B -> Slot C + Slot D`
- Region Strip is Memory Card Navigation for `Recorder / Timeline / Location / Memory`
- Memory Card Preview is the center surface; photos belong to Apple Photos
- Object Inspector replaces generic editor language
- `CardRegion -> InspectorProvider -> Object Inspector`
- `CardRegion` is frozen as `subject`, `icon`, `badge`, `slotA`, `slotB`, `slotC`, `slotD`
- `MemorySubject -> Identity + MemoryBehavior`
- `MemoryExpression -> MemoryTextBlock + MemoryTokenBlock`
- `TokenCategory` is Memory / Photo / System
- `DecorationAsset` unifies Icon, Badge, and future Decoration
- ConfigurationSession remains lightweight
- Memory Tokens use capture time, not export time
- IA-002 is frozen; future UI work is polish, not architecture redesign

## IA-003 Current Track

IA-003 is Memory Engine Integration.

Goal:

```text
Photo
-> EXIF
-> Memory Subject
-> Configuration Snapshot
-> Memory Engine
-> Memory Card
-> Renderer
```

Approved sequence:

```text
IA-003A MemorySubject Adapter
-> IA-003B Configuration Snapshot
-> IA-003C Memory Block Resolver
-> IA-003D CaptureTimeResolver
-> IA-003E Interactive Memory Card connects real data
-> IA-003F Renderer
```

IA-003A may connect the existing personal/profile layer into `MemorySubject`.

IA-003A must not modify Renderer, Metadata, Export, Share Extension, Photo Library behavior, or Layout Engine work.

## PDR-005 Frozen State

PDR-005 freezes the Memory Language Layer.

Primary reference:

- `Docs/PDR/PDR-005_Memory_Language_Layer.md`

Frozen principles:

- MemoryBlock is a content asset, not a layout asset
- Subject + Action + Result is Preset Schema #001, not the core model
- the long-term MemoryBlock architecture is field-based
- conceptual shape is `MemoryBlock { templateID, fields: [BlockField] }`
- BlockField values may come from Fixed Text, Token Binding, Smart Module Binding, or Custom Field Binding
- Block Templates define field schemas, not slot positions
- modules calculate field values; they do not define the whole block
- the first implementation point is IA-003C Memory Block Resolver

IA-003A should prepare for this direction but must not expand into a full Memory Language Engine implementation.

## PM-003 Frozen State

PM-003 is now in:

```text
Architecture Frozen
```

The single source of truth is:

- `Docs/PM-003_Content_Layout_System.md`

Frozen decisions:

- Slot always means semantic role, not layout position
- Slot A = Recorder
- Slot B = Capture Summary
- Slot C = Timeline
- Slot D = Time Anchor
- Slot D never displays raw metadata blocks
- Timeline default expression is `记录于｜日期｜时间`
- Timeline Action default is `记录于`
- seconds do not display

Life Anchor rules:

- Life Anchor is a Life Event, not a raw date
- V1 supports 3 user-defined Life Anchors
- V1 fields in use are `name`, `date`, `description`
- `category` and `enabled` remain reserved

Time Anchor rules:

- PhotoMemo does not directly display time
- PhotoMemo displays the distance between a person and an important life event
- past and future are unified by Time Anchor Engine

Expression rules:

- Subject -> Anchor Prompt -> Anchor Result -> Anchor Suffix
- Subject, Anchor Prompt, and Anchor Suffix are editable expression parts
- Anchor Result is engine-calculated and not editable
- Expression and Engine must remain fully decoupled

## Product Position

PhotoMemo V1 is a local-first memory card generator. PhotoMemo V2 repositions the project as a local-first Memory Presentation Engine.

Photos have timestamps. Memories have positions.

It is not:

- a cloud photo service
- a generic gallery app
- a destructive photo editor

It is:

- a Configuration Center for long-term memory setup
- a metadata and memory presentation system
- a background photo-processing capability that writes finished images back to the system photo library

PhotoMemo is not an EXIF viewer.

PhotoMemo is a memory expression system.

PhotoMemo is not a standalone photo product.

PhotoMemo is a Memory Capability inside Apple Photos workflows.

## Current Product Shape

- The foreground app is the Configuration Center for Memory Profile, Life Anchor, Preset, Output, Album, Automation, and Advanced settings
- The Configuration Center edits Objects, not Data
- Everything starts from the Memory Card
- The Configuration Center architecture is `Library -> Interactive Memory Card -> Object Inspector`
- The Configuration Center is not the daily workflow surface
- The main UI should keep one Configuration Preview image as the calibration surface
- The primary entry path is Apple Photos -> Share -> PhotoMemo -> Processing -> Notification -> Apple Photos
- Real day-to-day usage should move toward external intake such as open-with, share, or similar background entry points
- The app should generate a new image and preserve original photo usability in the library as much as the platform allows
- PM-003 freezes semantic content ownership before any future UI or layout implementation
- PhotoMemo should return users back to Photos instead of pulling them into the Configuration Center
- Apple Photos and PhotoMemo now have an explicit product-boundary split

## Core Lifecycle

Daily lifecycle:

```text
Reading
-> Share
-> Processing
-> Notification
-> Reading
```

Daily workflow:

```text
Apple Photos
-> Share
-> PhotoMemo
-> Processing
-> Notification
-> Apple Photos
```

Configuration lifecycle:

1. Maintain Memory Profile, Life Anchor, Preset, Output, Album, Automation, and Advanced settings in the Configuration Center.
2. Use one Configuration Preview image to calibrate the current preset against real EXIF and anchor rules.
3. Start daily processing from Apple Photos through Share.
4. Process in background from a frozen Configuration Snapshot.
5. Save finished images into the system library and target album.

Default interaction posture:

- Zero Interaction on the happy path
- Quiet Computing by default
- no developer language in user-facing progress
- no percentage-based progress language
- configuration is frozen per task through a Configuration Snapshot
- Smart Batch Recommendation guides users without imposing a hard limit

## Current Technical State

- SwiftUI macOS app
- Light-mode-first minimal system-style UI
- Preset configuration supports four custom regions through the internal template model
- Smart time-anchor tokens are wired into real EXIF-based calculations
- Background batch queue exists for external intake and photo-library output
- Batch notifications now exist for queued and completed background jobs
- PM-003 Phase 1 documentation now freezes semantic slots, Life Anchor V1, and Time Anchor grammar
- IA-001 documentation now freezes interaction architecture, behavior rules, and language tone

## Near-Term Priorities

1. complete IA-003A MemorySubject Adapter
2. preserve Memory Engine and Time Anchor architecture boundaries
3. keep the Configuration Center separate from the daily Apple Photos lifecycle
4. ensure Memory Card, Configuration Snapshot, render, export, and metadata retention stay aligned

Current implementation priority inside V2.1:

1. keep IA-002 architecture frozen
2. connect real data only through the approved IA-003 sequence
3. use `MemorySubject -> Configuration Snapshot -> Memory Engine` as the next integration path
4. avoid Renderer, Metadata, Export, and Share Extension changes until their IA-003 slice is reached

## Product Guardrails

- local-first by default
- no fake-data-first UI decisions
- no network dependency for core processing
- no irreversible mutation of the original image
- no feature expansion that outruns the real end-to-end pipeline
- no sentence assembly inside calculation engines
- no semantic slots defined as raw layout coordinates
- no user-facing developer terms such as renderer or metadata pipeline
- no separate PhotoMemo-owned gallery, map, people, search, dashboard, workspace, or task center
- never break the permanent rules recorded in `Docs/NEVER_BREAK.md`
