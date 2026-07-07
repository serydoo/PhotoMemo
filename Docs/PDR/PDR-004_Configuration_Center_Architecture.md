# PDR-004 Configuration Center Architecture

Last updated: 2026-06-24

## Status

```text
Frozen
```

## Revision

```text
Repository Amendment
Configuration Center Architecture
Revision A
```

## Purpose

PDR-004 records the frozen Configuration Center architecture after IA-002A and IA-002B.

This is a repository amendment.

It is not a runtime implementation task.

It is not Renderer, Metadata, Export, Share Extension, Photo Library, or Memory Engine runtime work.

## Core Principle

The Configuration Center is not Settings.

The Configuration Center is not a Workspace.

The Configuration Center is the Memory Engine Configuration Center.

Its responsibility is to define long-term objects.

```text
Configuration Once.
Benefit Forever.
```

## Object Editing Principle

```text
Configuration Center edits Objects, not Data.
```

```text
Configuration Center 编辑的是对象，而不是数据。
```

Users are not primarily editing:

- a string
- a date
- a configuration item

Users are editing:

- a Memory Subject
- a Memory Card
- a Decoration
- a Preset

All data is only an object's properties.

## Memory Card Principle

```text
Everything starts from the Memory Card.
```

```text
Configuration Center previews the real Memory Card, not an abstract layout.
```

```text
Preview is the Renderer before Rendering.
```

The Memory Card is not a photo preview.

The center surface is Memory Card Preview.

The Memory Card is the Configuration Center's primary object.

All Configuration Center interaction should revolve around the Memory Card.

The center preview should show the same Bottom Card structure the future Renderer will produce, not a schematic grid of editable modules.

The Configuration Center must not preview a photo area plus a bottom card. Photos belong to Apple Photos. MemoMark owns the Memory Card.

Preview should not feel like an editor by default. It should look like an already-generated Memory Card; hover, selection, and Region Strip reveal editability only when needed.

## Configuration Center Layout

The Configuration Center uses `NavigationSplitView`.

The frozen layout is:

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

Do not restore:

- top-bottom layout
- Workspace layout
- dashboard layout
- task-center layout

## Library

The sidebar is formally named Library.

The Library manages Memory Subjects.

Future object groups may include:

- People
- Family
- Pets
- Places
- Relationship

The Library is the long-term Memory Object Library.

## Interactive Memory Card

The Memory Card is not:

- a photo
- an example image
- a background image surface
- a Renderer debugging surface

The Memory Card only displays content created by MemoMark.

The default card model is Bottom Card.

The frozen Bottom Card structure is:

```text
Decoration
-> Slot A
-> Slot B
-> Slot C + Slot D
```

Decoration includes Icon and Badge.

The four editable slots are:

- Slot A: Recorder
- Slot B: Timeline
- Slot C: Location
- Slot D: Memory Expression

The Memory Card carries three responsibilities:

- Preview
- Navigation
- Selection

The Region Strip below the card is a secondary selection surface for the same four slots:

```text
Recorder
Timeline
Location
Memory
```

## CardRegion

`CardRegion` is frozen as:

```text
subject
icon
badge
slotA
slotB
slotC
slotD
```

Future hover, selection, inspector routing, and accessibility must use `CardRegion`.

Do not use string-based region matching.

## Object Inspector

Inspector is formally upgraded to Object Inspector.

It is not a generic editor.

The Object Inspector shows the currently selected object.

Every inspected object should use a consistent structure:

```text
Overview
-> Properties
-> Behavior
-> Resources
-> Preview
```

Different object types must not create completely unrelated inspector layouts.

## Inspector Provider

Inspector routing must use `InspectorProvider`.

The intended route is:

```text
CardRegion
-> InspectorProvider
-> Object Inspector
```

Adding a future object or region should not require changing the core Object Inspector view.

## Empty Inspector

When no object is selected, the Object Inspector should show an Apple-native empty state:

```text
Select an object
from the Memory Card
to start editing.
```

## Memory Subject

`MemorySubject` keeps identity and behavior separated.

The model is:

```text
MemorySubject
-> Identity
-> MemoryBehavior
```

`MemoryBehavior` owns:

- Primary Anchor
- Memory Expression
- Icon Strategy
- Badge Strategy

Identity must not contain behavior logic.

## Memory Block

`MemoryExpression` is composed from:

- `MemoryTextBlock`
- `MemoryTokenBlock`

Apple Token corresponds to `MemoryTokenBlock`.

Plain text corresponds to `MemoryTextBlock`.

## Token Library

Tokens use `TokenCategory`.

Frozen categories:

- Memory
- Photo
- System

`System` is reserved.

The category model must support future search, sorting, and filtering.

## Decoration

Decoration is unified as `DecorationAsset`.

`DecorationAsset` covers:

- Icon
- Badge
- Future Decoration

Do not continue using Logo as a standalone configuration object.

## Configuration Session

`ConfigurationSession` stays lightweight.

It may own:

- Selection
- Hover
- Editing
- Undo, future
- Redo, future

It must not own:

- Renderer
- Store
- Business Logic
- Memory Engine runtime calculation

## Capture-Time Principle

Memory Tokens must always be calculated from:

```text
Photo Capture Date
+ Reference Date
```

Re-exporting a photo must not change the Memory Expression.

MemoMark records the time of capture.

MemoMark does not record the time of export as memory truth.

## Design System

MemoMark must establish a first-class MemoMark Design System.

All Configuration UI should reuse shared components for:

- Memory Card
- Object Inspector
- Sidebar
- Library
- Apple Token
- Section
- Property
- Button
- Empty State

Future Configuration Center pages must reuse the design system.

Do not repeatedly reimplement the same UI patterns.

## IA-002 Freeze

```text
IA-002 Configuration Center Architecture
```

Status:

```text
Frozen
```

Frozen IA-002 architecture includes:

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

Future work may polish visual execution, but must not overturn this architecture.

## Next Stage

The next implementation track is:

```text
IA-003 Memory Engine Integration
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

IA-003A may bridge the existing personal/profile layer into `MemorySubject`.

Do not connect Renderer, Metadata, Export, Share Extension, Photo Library behavior, or Layout Engine work until the approved IA-003 slice reaches that boundary.

## Repository Sources

- `PROJECT_CONSTITUTION.md`
- `Docs/MASTER_PLAN.md`
- `Docs/Configuration/CONFIGURATION_MODEL.md`
- `Docs/FROZEN_REGISTRY.md`
- `Docs/DESIGN_DECISIONS.md`
- `Docs/CURRENT_STATUS.md`
- `HANDOFF.md`
