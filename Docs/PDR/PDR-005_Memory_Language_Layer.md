# PDR-005 Memory Language Layer

Last updated: 2026-06-24

## Status

```text
Frozen
```

## Revision

```text
Repository Amendment
Memory Language Layer
Revision A
```

## Purpose

PDR-005 defines PhotoMemo's Memory Language Layer.

This is a repository amendment.

It is not a runtime implementation task.

It is not Renderer, Metadata, Export, Share Extension, Photo Library, Layout Engine, or Memory Engine runtime work.

## Core Decision

Memory Block is a content asset.

Memory Block is not a layout slot.

Memory Block must not be permanently shaped by the current four-slot layout.

The Configuration Center may display Memory Blocks through slots, cards, strips, or future layouts, but the content model must remain independent from those layouts.

## Memory Language Layer

PhotoMemo now separates:

```text
Layout Layer
-> Slot A / Slot B / Slot C / Slot D
```

from:

```text
Content Layer
-> Token / Smart Module / Fixed Text
```

and introduces:

```text
Memory Language Layer
-> MemoryBlock
-> Block Template
-> Block Field
-> Value Binding
```

The Memory Language Layer answers:

```text
What memory is being expressed?
```

The Layout Layer answers:

```text
Where is it placed?
```

Renderer answers:

```text
How is it drawn?
```

## Field-Based MemoryBlock

The long-term MemoryBlock model is field-based.

Conceptual shape:

```swift
struct MemoryBlock {
    var templateID: MemoryBlockTemplate.ID
    var fields: [BlockField]
}

struct BlockField {
    var key: String
    var valueSource: BlockFieldValueSource
}
```

This document defines the architecture principle, not the final Swift API.

The current IA-002 Swift `MemoryBlock` skeleton may remain temporarily as text/token expression scaffolding until IA-003 reaches Memory Block Resolver work.

## BlockField Value Sources

Each `BlockField` may be backed by:

- Fixed Text
- Token Binding
- Smart Module Binding
- Custom Field Binding

Examples:

```text
Fixed Text:
沐沐
```

```text
Token Binding:
{{capture_date}}
```

```text
Smart Module Binding:
{{age}}
```

```text
Custom Field Binding:
{{school}}
```

## Block Template

Configuration Center should eventually edit Memory Block Templates, not isolated low-level modules.

A Block Template defines:

- field schema
- default labels
- default value bindings
- default presentation intent
- allowed module types

It does not define the final visual slot position.

## Subject Action Result

`Subject + Action + Result` is useful.

It is not the permanent core MemoryBlock structure.

It is frozen as:

```text
Preset Schema #001
Narrative Memory Block
```

Example:

```text
Subject:
沐沐

Action:
来到这个世界

Result:
1岁2个月16天
```

This schema is appropriate for growth, anniversaries, life anchors, and narrative memory records.

It is not appropriate for every block.

Do not force all Memory Blocks into `Subject + Action + Result`.

## Other Block Schemas

PhotoMemo must support future schemas such as:

```text
Device Record
设备
iPhone 17 Pro Max

镜头
24mm

参数
F1.8 ISO64
```

```text
Travel Record
地点
西安

景点
大雁塔

时间
2026.06.23
```

```text
Custom Life Record
宝宝
出生体重
出生身高
年龄
地点
```

These are all Memory Blocks, but they do not share the same field names.

## Module Types

Module types calculate or provide values.

They do not define the whole Memory Block.

Examples:

- AgeModule
- AnniversaryModule
- DaysSinceModule
- CounterModule
- LocationModule
- DateModule
- DeviceModule
- CameraParameterModule
- CustomModule

The module result becomes a field value.

The Memory Block remains a field-based content object.

## Dynamic Block

Future Memory Blocks should be able to support dynamic fields.

Users or Presets may add fields when the memory type requires them.

Dynamic fields must still resolve through explicit value sources.

Do not introduce free-form ambiguity into Memory Engine calculations.

## Relationship To Existing Architecture

Memory Subject remains:

```text
Identity + MemoryBehavior
```

MemoryBehavior may reference Memory Block Templates and field bindings in the future.

Configuration Snapshot must freeze resolved block configuration at task start.

Memory Engine calculates reusable results.

Memory Language Layer organizes those results into memory expressions.

Layout Engine and Renderer display the resolved content.

## IA-003 Boundary

PDR-005 affects IA-003 planning, but it does not expand IA-003A.

IA-003A remains:

```text
MemorySubject Adapter
```

IA-003A should prepare for field-based Memory Blocks, but should not implement the full Memory Language Engine.

The first implementation point for this amendment is:

```text
IA-003C Memory Block Resolver
```

## Frozen Principles

- MemoryBlock is a content asset, not a layout asset.
- Subject + Action + Result is Preset Schema #001, not the core model.
- The long-term MemoryBlock architecture is field-based.
- BlockField values come from explicit value sources.
- Modules calculate field values; they do not define the entire block.
- Block Templates define field schemas, not slot positions.
- Layout and Renderer must consume resolved Memory Blocks instead of owning memory language.

