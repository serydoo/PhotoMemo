# IA-001 Interaction Architecture

Last updated: 2026-06-23

## Status

```text
Frozen
```

## Definition

IA-001 defines how PhotoMemo should enter, execute, and finish its default memory workflow.

IA-001 does not define runtime implementation details.

IA-001 defines frozen interaction architecture.

## Product Position

PhotoMemo is not:

- a photo editor
- an EXIF tool
- a renderer
- an image border tool

PhotoMemo is:

```text
a Local First Memory Capability inside the Apple ecosystem
```

PhotoMemo does not manage photos.

PhotoMemo only owns:

```text
Memory Workflow
```

## North Star

PhotoMemo should not change how users manage photos.

PhotoMemo should change how users understand photos.

## Main App Role

The Main App is permanently:

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
-> PhotoMemo
-> Memory Workflow
-> Done
```

This is the product-primary experience.

## Zero Interaction Principle

The default happy path is:

- user shares
- PhotoMemo processes
- user waits
- PhotoMemo finishes

The default happy path should not require additional user operation.

## Quiet Computing Principle

The default posture is:

- finish in background
- notify at the end
- avoid interrupting the user

PhotoMemo should be present only when needed.

## Back To Photos Principle

After completion, the user should return to Apple Photos by default.

PhotoMemo should not try to capture attention after work is complete.

## Apple Native Principle

PhotoMemo should extend Apple-native capabilities before inventing its own interaction system.

It should integrate into Apple Photos behavior instead of replacing it.

## Invisible Product Principle

PhotoMemo should reduce its visible presence whenever possible.

The best PhotoMemo experience should feel naturally embedded in Apple Photos workflows.

## Configuration Center Principle

All deep decisions belong to configuration time, not sharing time.

That means:

- long-term setup belongs to the Main App
- daily use belongs to Apple Photos share flow
- happy-path sharing should avoid reconfiguration

## Progress Experience

The frozen progress language is:

```text
PhotoMemo
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

## Product Boundary

Apple Photos owns:

- photo storage
- timeline
- map
- people
- search
- albums
- reading

PhotoMemo owns:

- metadata usage
- Memory Workflow
- Life Anchor
- Time Anchor
- Memory Expression
- Memory Generation

## Result

IA-001 freezes PhotoMemo as a calm, background-first, Apple-native Memory Workflow surface rather than a foreground photo-management product.
