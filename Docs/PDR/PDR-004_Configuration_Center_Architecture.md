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

The Memory Card is not a photo preview.

The Memory Card is the Configuration Center's primary object.

All Configuration Center interaction should revolve around the Memory Card.

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
- a Renderer preview
- a background image surface

The Memory Card only displays content created by PhotoMemo.

The default card model is Bottom Card.

The Memory Card carries three responsibilities:

- Preview
- Navigation
- Selection

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

PhotoMemo records the time of capture.

PhotoMemo does not record the time of export as memory truth.

## Design System

PhotoMemo must establish a first-class PhotoMemo Design System.

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

## Next Sprint

The next Configuration Experience sprint is:

```text
IA-002C Object Inspector
```

Goal:

- Object Inspector
- Inspector Sections
- Empty State
- Inspector Animation
- Library Style
- Memory Card true layout

Still use mock data.

Do not connect:

- Renderer
- Metadata
- Export
- Memory Engine runtime
- PersonalProfile Adapter

After Object Inspector stabilizes, the following sprint should be:

```text
IA-002D MemorySubject Adapter
```

## Repository Sources

- `PROJECT_CONSTITUTION.md`
- `Docs/MASTER_PLAN.md`
- `Docs/Configuration/CONFIGURATION_MODEL.md`
- `Docs/FROZEN_REGISTRY.md`
- `Docs/DESIGN_DECISIONS.md`
- `Docs/CURRENT_STATUS.md`
- `HANDOFF.md`
