# IA-001 Interaction Architecture

Last updated: 2026-06-23

## Status

```text
Frozen
```

## Definition

IA-001 defines how MemoMark should enter, execute, and finish its default memory workflow.

IA-001 does not define runtime implementation details.

IA-001 defines frozen interaction architecture.

## Product Position

MemoMark is not:

- a photo editor
- an EXIF tool
- a renderer
- an image border tool

MemoMark is:

```text
a Local First Memory Capability inside the Apple ecosystem
```

MemoMark does not manage photos.

MemoMark only owns:

```text
Memory Workflow
```

## North Star

MemoMark should not change how users manage photos.

MemoMark should change how users understand photos.

## Configuration Center Role

MemoMark's foreground product surface is permanently:

```text
Configuration Center
```

It is responsible for long-term setup and preference management.

It is not the daily entry point.

## Primary Entry Principle

The frozen primary path is:

```text
Apple Photos
-> Share
-> MemoMark
-> Processing
-> Notification
-> Apple Photos
```

This is the product-primary experience.

## Apple Photos Lifecycle

```text
Reading
-> Share
-> Processing
-> Notification
-> Reading
```

## Zero Interaction Principle

The default happy path is:

- user shares
- MemoMark processes
- user waits
- MemoMark finishes

The default happy path should not require additional user operation.

## Quiet Computing Principle

The default posture is:

- finish in background
- notify at the end
- avoid interrupting the user

MemoMark should be present only when needed.

## Back To Photos Principle

After completion, the user should return to Apple Photos by default.

MemoMark should not try to capture attention after work is complete.

## Apple Native Principle

MemoMark should extend Apple-native capabilities before inventing its own interaction system.

It should integrate into Apple Photos behavior instead of replacing it.

## Invisible Product Principle

MemoMark should reduce its visible presence whenever possible.

The best MemoMark experience should feel naturally embedded in Apple Photos workflows.

## Configuration Center Principle

All deep decisions belong to configuration time, not sharing time.

That means:

- long-term setup belongs to the Configuration Center
- daily use belongs to Apple Photos share flow
- happy-path sharing should avoid reconfiguration

## Progress Experience

The frozen progress language is:

```text
MemoMark
正在创建记忆...

23 / 128

预计剩余：

约 1 分钟
```

Prohibited in user-facing progress:

- percentages
- `Renderer`
- `Metadata Pipeline`
- any development terminology

## Smart Batch Recommendation

MemoMark should not frame batching through fixed words such as:

- Maximum
- Limit
- Threshold

MemoMark should instead use:

```text
Smart Batch Recommendation
```

Batch scale language:

```text
Primary: 1-20
Secondary: 20-50
Advanced: 50+
```

MemoMark is better suited to processing a passage of memory worth returning to than to defining itself around large anonymous runs.

The system should recommend the best experience based on:

- device performance
- photo count
- runtime conditions

MemoMark does not forbid the user.

MemoMark recommends the best experience.

## Product Boundary

Apple Photos owns:

- photo storage
- timeline
- map
- people
- search
- albums
- reading

MemoMark owns:

- metadata usage
- Memory Workflow
- Life Anchor
- Time Anchor
- Memory Expression
- Memory Generation

## Result

IA-001 freezes MemoMark as a calm, background-first, Apple-native Memory Workflow surface rather than a foreground photo-management product.
