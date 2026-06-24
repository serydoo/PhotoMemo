# PhotoMemo

## Project Mission

PhotoMemo exists to help people read their memories, not just store their photos.

PhotoMemo 存在的意义，

不是帮助人们保存照片，

而是帮助人们阅读回忆。

## Project Manifesto

Photos preserve moments.

PhotoMemo reveals their meaning.

照片记录瞬间。

PhotoMemo 赋予意义。

## Repository Identity

PhotoMemo is a local-first Memory Presentation Engine.

It is not:

- a cloud photo product
- a general image editor
- a photo manager
- an EXIF tool
- a template marketplace
- a batch-first dashboard

It is:

- a research-first memory presentation system
- a memory timeline system
- a metadata-driven presentation engine
- a layout-specification project
- a system that generates a new image while preserving the original photo

PhotoMemo trusts Apple Photos as the user's photo library, timeline, map, people system, search system, sync system, and reading space.

PhotoMemo only owns the memory capability that helps a meaningful photo reveal its Life Position.

## Product Center

PhotoMemo is a Configuration Center, not a daily workbench.

The Configuration Center is the Memory Engine Configuration Center.

Configuration Once.

Benefit Forever.

Configuration Center edits Objects, not Data.

Everything starts from the Memory Card.

The Configuration Center is responsible for long-term setup:

- Memory Profile
- Life Anchor
- Preset
- Output
- Album
- Automation
- Advanced settings

Its frozen architecture is:

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

Daily use should begin and end in Apple Photos.

## Apple Photos Lifecycle

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

PhotoMemo should return users to Apple Photos instead of pulling them into an app-owned workflow.

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

Each processing task starts from a Configuration Snapshot. The snapshot freezes the selected configuration at task start, and the running task treats that configuration as read-only.

## Batch Philosophy

PhotoMemo is best at processing a passage of memory worth returning to, not a large anonymous photo dump.

Batch scale language:

```text
Primary: 1-20
Secondary: 20-50
Advanced: 50+
```

Larger runs are possible only as an advanced capability. They must not redefine PhotoMemo as a batch dashboard.

## Architecture

Target flow:

```text
Photo
-> Metadata Engine
-> Memory Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

Ownership:

- Metadata Engine owns photo facts and normalized metadata.
- Memory Engine owns Life Position calculations.
- Presentation Engine owns expression and content assembly.
- Layout Engine owns canvas, slots, typography placement, adaptive rules, and optical compensation.
- Renderer draws resolved layout instructions.
- Export creates a new output image and preserves metadata usefulness where the platform allows.

Renderer must not own layout decisions.

## Current Phase

PhotoMemo is in Research Phase and repository documentation synchronization.

Feature development is paused. Renderer polishing is paused. UI expansion is paused.

Start here:

1. `PROJECT_CONSTITUTION.md`
2. `Docs/MASTER_PLAN.md`
3. `PROJECT_RESET.md`
4. `RepositoryAudit.md`
5. `Research/README.md`
6. `Docs/REPOSITORY_VOCABULARY.md`
7. `Docs/REPOSITORY_SIMPLIFICATION_REPORT.md`

Old documents remain reference material for now. Do not migrate them until the research specifications stabilize.

## Design Review Principle

Every review should leave the repository simpler than before.

每一次设计评审，都应该让 PhotoMemo 比昨天更简单一点。
