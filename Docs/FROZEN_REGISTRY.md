# Frozen Registry

Last updated: 2026-07-21

## MemoMark Share Design v1

Status:

```text
Frozen
```

Primary source:

- `Docs/04_DesignSystem/MemoMarkShareDesignV1.md`

Frozen areas:

- Hero -> Summary Card -> Promise Card -> Brand Statement -> Primary Action
- Summary Card's fixed three rows: `照片`, `配置`, `相册`
- Promise Card's fixed four-row assurance contract
- One plain Brand Statement
- One primary button
- MemoMark shared typography token ownership
- 8pt spacing rhythm and 24pt button-to-safe-area spacing

## PM-003

Status:

```text
Frozen
```

Primary source:

- `Docs/PM-003_Content_Layout_System.md`

Frozen areas:

- Semantic Slot Principle
- Recorder
- Capture Summary
- Timeline
- Time Anchor
- Life Anchor
- Expression Grammar
- Typography Strategy

## IA-001

Status:

```text
Frozen
```

Primary sources:

- `Docs/Interaction/IA-001_Interaction_Architecture.md`
- `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
- `Docs/Guidelines/LANGUAGE_SYSTEM.md`
- `Docs/Guidelines/PRODUCT_PERSONALITY.md`
- `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md`
- `Docs/Configuration/CONFIGURATION_MODEL.md`
- `Docs/Product/ANTI_GOALS.md`
- `Docs/DESIGN_DECISIONS.md`
- `Docs/NEVER_BREAK.md`
- `Docs/PDR/PDR-003_Interaction_Architecture.md`
- `Docs/PDR/PDR_INDEX.md`

Frozen areas:

- Product Position
- North Star
- Configuration Center
- Primary Entry Principle
- Apple Photos Lifecycle
- Zero Interaction Principle
- Quiet Computing Principle
- Back To Photos Principle
- Progress Experience
- Smart Batch Recommendation
- Task Recovery Principle
- Device Adaptive Principle
- Storage Verification Principle
- Behavior State Machine
- Configuration Snapshot Principle
- Library Consistency Principle
- Original Never Changes Principle
- Metadata Preservation Principle
- Apple Naming Principle
- Apple Trust Principle
- Product Personality
- Language System
- Configuration Layer
- Product Boundary
- Anti Goals
- Never Break List
- PDR Index

## RSR-001

Status:

```text
Frozen
```

Primary sources:

- `Docs/REPOSITORY_VOCABULARY.md`
- `Docs/REPOSITORY_SIMPLIFICATION_REPORT.md`

Frozen areas:

- Repository Simplification Principle
- Configuration Center vocabulary
- Preset user-layer vocabulary
- Configuration Preview vocabulary
- Apple Photos Lifecycle
- Behavior State Machine
- Configuration Snapshot
- Batch Scale Language

## PDR-004

Status:

```text
Frozen
```

Primary source:

- `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`

Frozen areas:

- Configuration Center as Memory Engine Configuration Center
- Configuration Once, Benefit Forever
- Configuration Center edits Objects, not Data
- Everything starts from the Memory Card
- Configuration Center previews the real Memory Card, not an abstract layout
- Preview is the Renderer before Rendering
- Memory Card Preview owns the center preview surface
- NavigationSplitView layout
- Library as Memory Object Library
- Interactive Memory Card as Primary Object
- Bottom Card structure: Decoration -> Slot A -> Slot B -> Slot C + Slot D
- Region Strip as secondary slot selection surface
- CardRegion frozen set
- Object Inspector
- InspectorProvider routing
- Empty Inspector state
- MemorySubject Identity and MemoryBehavior separation
- MemoryTextBlock and MemoryTokenBlock
- TokenCategory
- DecorationAsset
- lightweight ConfigurationSession
- Capture-Time Principle
- MemoMark Design System
- IA-002 Configuration Center Architecture

## IA-003

Status:

```text
Current implementation track
```

Frozen entry condition:

- IA-002 architecture must not be reopened.
- IA-003 starts from `MemorySubject -> Configuration Snapshot -> Memory Engine`.
- IA-003A is `MemorySubject Adapter`.
- IA-003A must not modify Renderer, Metadata, Export, Share Extension, Photo Library behavior, or Layout Engine work.

Approved sequence:

```text
IA-003A MemorySubject Adapter
-> IA-003B Configuration Snapshot
-> IA-003C Memory Block Resolver
-> IA-003D CaptureTimeResolver
-> IA-003E Interactive Memory Card connects real data
-> IA-003F Renderer
```

## PDR-005

Status:

```text
Frozen
```

Primary source:

- `Docs/PDR/PDR-005_Memory_Language_Layer.md`

Frozen areas:

- Memory Language Layer
- MemoryBlock as content asset, not layout asset
- Field-Based MemoryBlock
- BlockField
- BlockField Value Sources
- Block Template
- Subject + Action + Result as Preset Schema #001
- Dynamic Block direction
- Modules calculate field values
- IA-003C Memory Block Resolver as first implementation point
