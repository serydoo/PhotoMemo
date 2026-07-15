# MemoMark Evolution Review

## Volume I — From PhotoMemo to MemoMark

**Document version:** 1.0  
**Status:** Final  
**Author:** MemoMark Project  
**Last updated:** 2026-07-14

## Purpose

This document records the origin, evolution, and enduring product philosophy
of MemoMark.

It is not a development log, release history, or replacement for an
Architecture Decision Record. It is a permanent project-history document that
explains why PhotoMemo evolved from a photo-information tool into MemoMark, a
local-first Memory Presentation Engine.

Its purpose is to preserve the reasoning behind that transition so future
product and architecture decisions remain consistent with the project's
identity.

Canonical dates and stage boundaries remain owned by
[`Docs/PRODUCT_VERSION_HISTORY.md`](../PRODUCT_VERSION_HISTORY.md). Individual
architecture decisions remain owned by [`Docs/ADR/`](../ADR/README.md).

### Source and Status Convention

When source material conflicts, this review follows the repository's current
source-of-truth documents, frozen decisions, accepted ADRs, and verified code
or release evidence. Retrospective notes and discussion drafts are treated as
historical input, not as authority over the repository.

This volume uses three distinct meanings:

- **Current boundary** describes an architecture or product rule that remains
  in force.
- **Historical design** describes a direction that existed and was later
  replaced or narrowed.
- **Historical discussion** describes an idea considered during evolution but
  not necessarily adopted or implemented.

Historical material is preserved to explain the project's reasoning. Its
presence does not reactivate superseded vocabulary or architecture.

## 1. The Origin

The project began as **PhotoMemo**.

Its initial goal was straightforward:

> Attach meaningful information to every photo.

The first product foundation focused on facts already present in or associated
with a photograph:

- capture date
- camera model
- lens
- aperture
- shutter speed
- ISO
- location

The early model was:

```text
Photo
-> Metadata
-> Information Card
```

At this stage, PhotoMemo behaved much like a modern EXIF card generator. This
was a useful foundation, but it did not yet express the lasting meaning of a
photograph.

## 2. The First Turning Point

The first major realization was simple:

> EXIF is information. It is not memory.

Years later, people rarely remember a photograph because it was captured at
`f/1.8`, `ISO 100`, or `1/250`. They remember who was there, what happened, how
old someone was, whether the moment was a first, and why it mattered.

The project therefore changed its center of gravity:

```text
Metadata as the destination
-> Metadata as evidence
-> Memory as meaning
```

Metadata remained essential, but it became an input to a larger system. This
shift established the philosophical foundation of MemoMark: photographs have
timestamps, while memories have positions inside a life.

## 3. Local First

One principle remained unchanged from the beginning:

> User photos, metadata, configurations, and memory context remain local.

MemoMark does not upload photos for core processing. It does not modify the
original photo. It generates a new output image and leaves the source under the
user's control.

Local First is therefore not an implementation preference. It is a permanent
product boundary that protects ownership of:

- photos
- metadata
- configurations
- memories

Cloud processing is intentionally excluded from the core architecture.

## 4. Apple Native

MemoMark was not designed as a generic cross-platform photo manager. It
deliberately embraces the Apple ecosystem through technologies and conventions
such as:

- SwiftUI
- PhotoKit
- Live Photo
- App Groups
- Share Extension
- Apple Human Interface Guidelines

The project does not seek to replace Apple Photos. Apple Photos remains the
trusted photo-management system; MemoMark supplies a local memory capability
inside that workflow.

The daily product lifecycle is:

```text
Apple Photos
-> Share
-> MemoMark
-> Processing
-> Notification
-> Apple Photos
```

## 5. From Templates to Expression

Early versions were template-oriented. Layout and content were largely fixed,
and the renderer sat near the center of the product model.

As the project matured, visual templates became carriers for semantic content.
The architecture introduced and refined concepts including:

- expressions
- semantic slots
- Memory Subjects
- Memory Blocks
- tokens
- decorations
- configuration snapshots

The system evolved from arranging fixed information into resolving meaning:

```text
Photo facts + Memory Subject + Configuration
-> Memory and expression resolution
-> Presentation and layout
-> Rendering and export
```

This transition moved business meaning out of the renderer. Renderer became a
consumer of resolved presentation and layout truth rather than the owner of
memory semantics or geometry decisions.

## 6. Learning to Replace Earlier Decisions

MemoMark's evolution was not driven only by adding capabilities. It also
required replacing responsibilities and vocabulary that no longer matched the
product.

Representative transitions include:

| Earlier direction | Later direction | Meaning of the transition |
|---|---|---|
| Workspace-oriented product language | Configuration Center | The product edits durable memory objects instead of presenting a generic work area. |
| Geometry derived by downstream consumers | Media Geometry Foundation and immutable `CanonicalGeometry` | Geometry is resolved once and consumed read-only by Renderer, Composer, and Exporter. |
| Mutable runtime configuration spread across owners | Frozen Configuration Snapshot and durable configuration aggregate | One resolved revision crosses production boundaries consistently. |
| Share-path-specific media handling | Media Intake and explicit media routing | Intake identifies media facts and policy before processing begins. |
| Fixed layout content | Semantic content and expression resolution | Content meaning is resolved before layout and rendering. |

These transitions did not erase history. Earlier decisions remain useful
records of the constraints present when they were made. Later architecture
supersedes them only where the repository explicitly freezes a new boundary.

The recurring lesson is:

> Great architecture is achieved by reducing responsibilities, not by
> accumulating them.

## 7. Product Identity

MemoMark is no longer accurately described as:

- an EXIF viewer
- a watermark tool
- an image editor
- a photo manager

MemoMark is a:

> Local-First Memory Presentation Engine for the Apple Photos workflow.

Photos are the entrance, not the whole product. MemoMark combines objective
photo facts with user-defined memory context to present:

- time
- memory
- growth
- relationships
- story
- life position

The resulting image preserves both what the camera recorded and what the
moment means.

## 8. Enduring Product Principles

### Local First

Core processing and user-owned memory context remain on the user's devices.

### Memory Before Metadata

Metadata provides evidence. Memory provides meaning. Metadata supports the
memory presentation but does not define the product by itself.

### Apple Native

MemoMark extends Apple Photos instead of rebuilding photo management. Product
behavior should feel native to the Apple ecosystem.

### Original Preservation

MemoMark never modifies the original photograph. It creates a new output image
and preserves the source.

### Stable Foundations

Core boundaries should change only through scoped requirements and evidence.
The protected foundations include:

- Metadata Engine
- Memory Engine
- Presentation Engine
- Layout Engine
- Media Geometry Foundation
- Renderer and Export contracts
- Configuration aggregate and snapshot contracts

Feature work should build on these foundations rather than quietly moving
their responsibilities.

### Separation of Responsibility

Each subsystem owns one kind of truth:

```text
Metadata Engine -> Photo facts
Memory Engine -> Life Position and memory results
Configuration Aggregate -> Durable configuration truth
Configuration Snapshot -> Frozen production input
Media Intake -> Media identification and routing
Layout Engine -> Layout truth
Renderer -> Rendering
Export -> New output generation and metadata policy
```

No downstream consumer should rediscover or silently correct truth owned by an
upstream foundation.

## Conclusion

PhotoMemo began as a tool for presenting information about photographs.

MemoMark became a system for presenting the place those photographs occupy in
a life.

That transition—from information to memory, from isolated rendering to an
owned production pipeline, and from a standalone tool to an Apple Photos memory
capability—defines the architectural decisions that followed.

Future development should continue to protect this identity:

```text
Photo
-> Metadata Engine
-> Memory Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

The original photograph remains untouched. The generated image carries the
memory forward.

## Historical References

- [`PROJECT_CONSTITUTION.md`](../../PROJECT_CONSTITUTION.md)
- [`Docs/PRODUCT_VERSION_HISTORY.md`](../PRODUCT_VERSION_HISTORY.md)
- [`Docs/PM-003_Content_Layout_System.md`](../PM-003_Content_Layout_System.md)
- [`Docs/PDR/PDR-004_Configuration_Center_Architecture.md`](../PDR/PDR-004_Configuration_Center_Architecture.md)
- [`Docs/ADR/ADR-006-MemoryEngineFoundation.md`](../ADR/ADR-006-MemoryEngineFoundation.md)
- [`Docs/ADR/ADR-008-MediaGeometryFoundation.md`](../ADR/ADR-008-MediaGeometryFoundation.md)
- [`Docs/ADR/ADR-009-Configuration-Aggregate-And-Local-Backup-Library.md`](../ADR/ADR-009-Configuration-Aggregate-And-Local-Backup-Library.md)
