# Repository Vocabulary

Last updated: 2026-06-24

## Status

```text
Frozen by RSR-001
```

## Purpose

This document defines the repository language for PhotoMemo after RSR-001.

The goal is simplification: future documents should make PhotoMemo easier to understand, not broader, louder, or more app-like.

## Repository Mission

PhotoMemo exists to help people read their memories, not just store their photos.

PhotoMemo 存在的意义，

不是帮助人们保存照片，

而是帮助人们阅读回忆。

Photos preserve moments.

PhotoMemo reveals their meaning.

照片记录瞬间。

PhotoMemo 赋予意义。

## Allowed Terms

Use these terms in current source-of-truth documents:

- Configuration Center
- Configuration Session
- Library
- Memory Object Library
- Interactive Memory Card
- Memory Card Preview
- Object Inspector
- Memory Workflow
- Memory Subject
- Memory Card
- Preset
- Time Anchor
- Life Anchor
- Behavior
- MemoryBehavior
- CardRegion
- InspectorProvider
- TokenCategory
- DecorationAsset
- Apple Native
- Apple Photos Lifecycle
- Configuration Preview
- Configuration Snapshot
- PhotoMemo Design System

## Forbidden User-Workflow Terms

Do not use these as user-facing product concepts or daily workflow language:

- Workspace
- Import
- Dashboard
- Task Center
- Photo Manager
- EXIF Tool
- Working Area
- Workspace Workflow
- Workspace State
- Import Flow
- Logo, when used as an independent configuration object

Historical documents may still contain these words when they describe past implementation work. New active documents should avoid them unless they are explicitly discussing stale terminology.

## Required Renames

Use these replacements in active repository language:

| Previous wording | Current wording |
| --- | --- |
| Main App | Configuration Center |
| Slot Editor | Slot Configuration |
| Template, when describing user configuration | Preset |
| Preview, when describing the center Memory Card surface | Memory Card Preview |
| Preview, when describing user calibration broadly | Configuration Preview |
| Open App -> Import -> Configure -> Export | Apple Photos -> Share -> PhotoMemo -> Processing -> Notification -> Apple Photos |
| Sidebar, when describing Configuration Center architecture | Library |
| Inspector, when describing selected configuration objects | Object Inspector |
| Logo, when describing configurable decoration objects | DecorationAsset |

Renderer-internal `Template` remains allowed because the current implementation model still uses `Template` as an internal content model.

SwiftUI `#Preview` and test names containing Preview remain allowed as platform or code terminology.

## Configuration Center

The Configuration Center owns long-term configuration only:

- Memory Profile
- Life Anchor
- Preset
- Output
- Album
- Automation
- Advanced

It is not:

- a daily workbench
- a workspace
- a dashboard
- a task center
- a temporary session surface
- a generic Settings page

The Configuration Center edits Objects, not Data.

Everything starts from the Memory Card.

## Apple Photos Lifecycle

The product lifecycle is:

```text
Reading
-> Share
-> Processing
-> Notification
-> Reading
```

The daily workflow is:

```text
Apple Photos
-> Share
-> PhotoMemo
-> Processing
-> Notification
-> Apple Photos
```

Do not describe daily use as:

```text
Open App
-> Import
-> Configure
-> Export
```

## Behavior State Machine

```text
Idle
-> Preparing
-> Processing
-> Completed
-> Reading
```

Exceptional path:

```text
Interrupted
-> Auto Recovery
-> Continue
```

## Configuration Snapshot

When a task starts, PhotoMemo freezes a Configuration Snapshot.

The running task treats that snapshot as read-only.

Any configuration change made during processing only affects the next task.

## Batch Scale Language

Use this scale:

```text
Primary: 1-20
Secondary: 20-50
Advanced: 50+
```

Avoid defining PhotoMemo around 300, 500, 1000, or other large-run marketing language.

PhotoMemo is better suited to processing a passage of memory worth returning to.

## Design Review Closing Principle

Every review should leave the repository simpler than before.

每一次设计评审，都应该让 PhotoMemo 比昨天更简单一点。
