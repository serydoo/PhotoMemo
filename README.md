# MemoMark

> 让照片，不止记录画面，更记录人生。

MemoMark is a local-first Memory Presentation Engine for Apple Photos.

时光记是一款围绕 Apple Photos 打造的本地化照片记忆增强应用。它不会修改原始照片，也不是传统意义上的水印工具。它读取照片的拍摄事实，结合用户设定的 Memory Subject、Life Anchor、Time Anchor 和表达内容，为照片生成一张新的记忆版本。

多年以后，当再次翻开照片时，看到的不只是画面，更是那一天在生命时间线里的位置。

<!--
Hero image slot:

Add a public, non-private product image here when available.
Recommended path: Screenshots/memomark-hero.png

![MemoMark memory card example](Screenshots/memomark-hero.png)
-->

## Why MemoMark Exists

Today, we take more photos than we can meaningfully reread.

The details people care about years later are rarely only camera settings. More often, they are:

- Where was this?
- How old was the child?
- What happened that day?
- Why was this photo taken?
- Where does this photo belong in a person's life?

MemoMark exists to help people read their memories, not just store their photos.

时光记存在的意义，不是帮助人们保存照片，而是帮助人们阅读回忆。

Photos preserve moments.

MemoMark reveals their meaning.

照片记录瞬间。时光记赋予意义。

## What MemoMark Is

MemoMark is:

- a local-first Memory Presentation Engine
- a memory timeline system
- a metadata-driven presentation engine
- a research-first layout-specification project
- a system that generates a new image while preserving the original photo
- a Memory Capability inside Apple Photos workflows

MemoMark is not:

- a cloud photo product
- a general image editor
- a photo manager
- an EXIF tool
- a template marketplace
- a batch-first dashboard
- a watermark clone app

Apple Photos remains the trusted library, timeline, map, people system, search system, sync system, and reading space. MemoMark only owns the Memory Workflow that helps a meaningful photo reveal its Life Position.

## Core Principles

### Memory, Not Parameters

EXIF is data. Memory is relationship.

MemoMark does not display photo facts for their own sake. It uses capture time, location, camera information, Life Anchors, and user expression to make a photo easier to understand later.

Photos have timestamps.

Memories have positions.

### Local First

All core processing is local.

MemoMark does not upload photos, does not depend on cloud processing, and does not mutate the original image. The output is a newly generated image.

### Apple Native

MemoMark extends Apple Photos instead of replacing it.

The intended daily lifecycle is:

```text
Apple Photos
-> Share
-> MemoMark
-> Processing
-> Notification
-> Apple Photos
```

MemoMark should return users to Apple Photos instead of pulling them into a separate app-owned workflow.

### Configuration Once, Benefit Forever

The foreground app is the Configuration Center.

The Configuration Center is responsible for long-term setup:

- Memory Profile
- Life Anchor
- Preset
- Output
- Album
- Automation
- Advanced settings

The Configuration Center edits Objects, not Data.

Everything starts from the Memory Card.

## Memory Card Workflow

MemoMark's long-term workflow is:

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

## Time Anchor

Time Anchor is one of MemoMark's core capabilities.

A photo already has a capture time. MemoMark adds relationships between that capture time and important life events.

Examples of anchors:

- birth
- marriage
- relationship
- first meeting
- graduation
- travel
- pet adoption
- memorial day
- custom life event

The Memory Engine calculates reusable time results such as:

- `1岁3个月18天`
- `相识267天`
- `结婚第8年`
- `旅行第5天`
- `还有86天`

Smart anchor variables output time results, not complete prose. Users remain in control of the final sentence by combining literal text and variables.

## Memory Subject

MemoMark is not centered on generic contacts.

It is centered on Memory Subjects: the people, relationships, events, and life contexts that make a photo meaningful.

A Memory Subject may include:

- display name
- nickname
- relationship
- reference date
- Life Anchors
- Time Anchors
- expression behavior
- decoration assets
- default presentation choices

One photo may belong to multiple life timelines. The long-term goal is to let every meaningful photo know where it belongs inside a person's life.

## Current Status

MemoMark is in `V3 Production Quality And Delivery`.

V1 MVP and V2 Product Definition And Realization are complete. V3 turns the
established Memory Presentation Engine into a production-ready,
evidence-backed delivery system.

Current priorities include:

```text
Durable Configuration
-> Apple Photos Lifecycle Validation
-> Regression And Performance Evidence
-> TestFlight / App Store Readiness
```

IA-002 Configuration Center Architecture and the completed IA-003 Memory Engine
integration remain architectural foundations. V3 does not reopen them by
default.

Recent IA-003-compatible foundation work has established the first Memory Expression Engine path:

```text
MemorySubject
-> ConfigurationSnapshot
-> MemoryExpressionEngine
-> MemoryModule
```

See `Docs/PRODUCT_VERSION_HISTORY.md` for the canonical distinction between
product stages, App release versions, audit-report versions, and legacy `V1*`
implementation identifiers.

## Repository Map

Current source and project structure:

- `Source/PhotoMemo/` - current Xcode project and app source
- `Research/` - research and specification history
- `Docs/` - product, architecture, behavior, QA, release, and historical documents
- `App/` - reserved app-facing structure
- `DesignSystem/` - reserved durable design-system assets
- `LayoutEngine/` - reserved future Layout Engine boundary
- `Renderer/` - reserved future renderer boundary
- `Examples/` - public non-private examples
- `Screenshots/` - public non-private screenshots
- `Tests/` - fixtures and Swift tests
- `scripts/` - local automation helpers

Existing source files remain under `Source/PhotoMemo/` until a reviewed migration slice moves them safely.

## Repository Lines

MemoMark should preserve historical product phases through branches, tags, and releases rather than duplicated version folders.

Current intended line split:

- `main` - active V3 repository and product source-of-truth line
- milestone tags and releases - macOS foundation, iOS foundation, MVP, and V1 checkpoints

Repository cleanup should not create root-level copies such as `MacVersion/`, `MVP/`, or `V1/`.

See `Docs/07_Releases/REPOSITORY_LINE_STRATEGY.md` for the current repository-line policy.

## Start Here

For project context, read:

1. `PROJECT_CONSTITUTION.md`
2. `Docs/MASTER_PLAN.md`
3. `Docs/PRODUCT_VERSION_HISTORY.md`
4. `Docs/CURRENT_STATUS.md`
5. `PROJECT_PHILOSOPHY.md`
6. `PROJECT_DIRECTION.md`
7. `Docs/DOCUMENT_INDEX.md`
8. `Docs/PROJECT_STRUCTURE.md`

Old documents remain reference material for now. Do not migrate them until the research specifications stabilize.

## Design Review Principle

Every review should leave the repository simpler than before.

每一次设计评审，都应该让时光记比昨天更简单一点。

## Closing

照片记录的是那一刻。时光记希望记录的是，那一刻背后的故事。
