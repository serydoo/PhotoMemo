# MemoMark Evolution Review

## Volume II — Architecture Evolution

**Document version:** 1.0  
**Status:** Final  
**Scope:** V1 through V3  
**Author:** MemoMark Project  
**Last updated:** 2026-07-14

## Purpose

This document records the major architectural evolutions that shaped
MemoMark. Unlike a changelog, it focuses on why boundaries changed, what
problems the changes addressed, and why earlier designs were replaced.

This is an architectural history, not an Architecture Decision Record. It
connects decisions that are individually owned by [`Docs/ADR/`](../ADR/README.md),
product decisions owned by [`Docs/PDR/`](../PDR/PDR_INDEX.md), and stage
boundaries owned by
[`Docs/PRODUCT_VERSION_HISTORY.md`](../PRODUCT_VERSION_HISTORY.md).

Future contributors should understand this history before changing Renderer,
Metadata, Memory Engine, Configuration, Media Geometry, Export, Share
Extension, Photo Library, or Layout Engine boundaries.

### Source Priority and Historical Status

This review uses the following evidence order:

1. current repository source-of-truth documents and frozen registry entries;
2. accepted ADRs, RFCs, PDRs, and architecture contracts;
3. verified implementation, test, runtime, and release evidence;
4. historical notes, retrospective drafts, and design discussions.

If a retrospective draft conflicts with the repository, the repository wins.
Discussion material remains valuable as evidence of how the project reasoned,
but it does not become a current decision merely because it appears in this
history.

The document distinguishes:

- **Current boundary** — accepted and still authoritative;
- **Historical design** — previously active, later replaced or narrowed;
- **Historical discussion** — considered or proposed, without an assumption
  that it reached production;
- **Active proof** — architecturally accepted but still accumulating V3
  production evidence.

## Architecture at a Glance

MemoMark did not evolve through one strictly linear sequence. Product meaning,
configuration, rendering, and media delivery matured in parallel and then
converged into the production pipeline.

```text
PhotoMemo metadata foundation
        |
        +-> Memory Engine and semantic content
        |          |
        |          +-> Configuration Center and frozen snapshots
        |                     |
        |                     +-> Expression platform
        |
        +-> Batch queue and recoverable processing
        |          |
        |          +-> Share Extension handoff
        |
        +-> Media intake and media-type routing
                   |
                   +-> Media Geometry Foundation

All branches converge in V3 production-quality validation and delivery.
```

The current conceptual production chain is:

```text
Photo
-> Metadata Engine
-> Memory Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

Media intake, configuration snapshots, queue persistence, and diagnostics
support this chain without taking ownership of its domain responsibilities.

## 1. Metadata Foundation

### Initial Direction

The earliest PhotoMemo architecture focused on reading photo facts and
rendering an information card:

```text
Photo
-> Metadata
-> Renderer
-> Export
```

The renderer consumed values such as capture date, camera, lens, aperture,
shutter speed, ISO, and location. This architecture was small and effective
for an EXIF-oriented product.

### Why It Changed

Metadata describes how and when a photograph was captured. It does not explain
why the moment matters. The architecture needed a domain that could derive
life-relative meaning without placing that meaning inside Renderer, Export, or
UI code.

### Lasting Result

Metadata remained the source of truth for objective photo facts. Its role
changed from final content to trusted input for memory and presentation.

## 2. Memory Engine

### Problem

Memory-oriented values were initially spread across anchor calculation,
variable formatting, and fallback logic. Expanding those paths would have
mixed domain meaning with renderer and variable-wiring responsibilities.

### Decision

MemoMark introduced Memory Engine as a dedicated local-first domain boundary:

```text
Photo Metadata + Memory Subject + Life Anchor
-> Memory Engine
-> Normalized memory results
```

Memory Engine owns Life Position and memory calculations. It produces reusable
values; it does not generate final prose, control layout, or render pixels.

### Architectural Effect

- metadata remains objective evidence;
- memory results become deterministic and testable;
- users retain control of final wording by combining literal text and smart
  variables;
- Renderer and Export remain consumers rather than owners of memory meaning.

This boundary is recorded in
[`ADR-006`](../ADR/ADR-006-MemoryEngineFoundation.md).

## 3. Semantic Content and Layout

### Earlier Direction

Early bottom-card content was strongly associated with physical positions such
as left-top or right-bottom. This made content identity depend on one visual
arrangement.

### Decision

PM-003 introduced semantic slots and separated content meaning from physical
placement. Concepts such as Recorder, Timeline, Location, and Memory could be
resolved as content before Layout Engine decided where they belonged.

```text
Meaning
-> Semantic content
-> Layout specification
-> Layout Engine
-> Renderer
```

### Architectural Effect

- content can survive layout changes;
- layout decisions have one future source of truth;
- Renderer no longer invents semantic meaning;
- configurable regions can remain understandable to users.

The long-term rule became:

> Content defines what is presented. Layout Engine defines where it is
> presented. Renderer draws the resolved result.

## 4. Configuration Center

### Earlier Direction

The main editing surface historically used workspace-oriented language and
session concepts. That model reflected a generic editing area more than the
product's real purpose.

### Decision

MemoMark froze the Configuration Center as an object-centered architecture:

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

Its defining principles are:

- Configuration Center edits Objects, not Data;
- everything starts from the Memory Card;
- the preview is the real Memory Card, not an abstract layout;
- Configuration Center owns long-term configuration, not the daily Apple
  Photos workflow.

### Architectural Effect

The app stopped presenting a generic work area as its product center. Durable
Memory Subjects, Presets, behaviors, anchors, and card objects became the
configuration model.

This was a product-architecture replacement, not an instruction to rename
every historical source symbol immediately. Compatibility-oriented workspace
types may remain until a scoped migration proves that changing them is safe.

## 5. Snapshot Architecture

### Problem

Mutable runtime state and independently reconstructed configuration could
produce drift between preview, batch, Share Extension, and production output.
Rendering needed one complete and repeatable input.

### Decision

MemoMark introduced a freeze boundary:

```text
Durable Configuration
-> Resolve one exact revision
-> Freeze Configuration Snapshot
-> Memory and expression resolution
-> Renderer and Export
```

The snapshot is immutable production input. Consumers do not reconstruct
defaults, read unrelated live editor state, or silently combine revisions.

### Architectural Effect

- rendering becomes deterministic;
- preview and production can prove configuration parity;
- queued work can retain the intended configuration revision;
- restart recovery does not require reconstructing transient UI state;
- tests can verify complete production inputs.

The V3 configuration aggregate strengthens this boundary: one versioned
`ConfigurationLibraryRecord` is durable truth, while local backup documents
become runtime truth only after explicit restore succeeds.

## 6. Batch and Recoverable Processing

### Problem

Single synchronous image processing was insufficient for multiple assets,
background continuation, failure recovery, notification, and durable history.

### Decision

MemoMark introduced a persistent batch boundary with a stable public facade.
Internal responsibilities can be decomposed, but callers continue to use one
queue entry point.

```text
Request
-> Frozen configuration
-> Persistent job and tasks
-> Controlled processing
-> Save result
-> History and diagnostics
```

### Architectural Effect

- queued work survives process and lifecycle boundaries;
- task results can be recovered and diagnosed;
- configuration construction has one authoritative provider;
- concurrency and admission policy can evolve without creating parallel queue
  entry points.

The queue is persistence and coordination infrastructure. It does not own
Memory Engine semantics, media geometry, rendering, or export policy.

These boundaries are recorded in [`ADR-001`](../ADR/ADR-001-BatchConfigurationSnapshotProvider.md)
and [`ADR-002`](../ADR/ADR-002-BatchQueueStoreFacade.md).

## 7. Provider-Based Expression Architecture

### Problem

Continuously expanding one metadata context would have mixed Metadata,
Location, Memory, presentation policy, preview values, and renderer behavior.
Each new semantic domain needed an owner without creating a separate rendering
language.

### Decision

Canonical providers compile domain facts into provider-neutral expression
values:

```text
Domain Facts
-> Context Builder
-> Resolver
-> Formatter
-> Expression Value
-> Expression Context
-> Renderer
```

### Architectural Effect

- Renderer consumes resolved expression values;
- domain fallback and formatting remain with their providers;
- preview and production share one expression language;
- Location, Memory, Metadata, and future domains can evolve without turning
  Renderer into a domain engine.

The expression platform does not replace Memory Engine. Memory Engine owns
memory calculation; the provider compiles its result into the shared
expression language.

This boundary is recorded in
[`ADR-007`](../ADR/ADR-007-ProviderBasedExpressionArchitecture.md).

## 8. Media Intake and Media Routing

### Problem

Treating every provider result as an ordinary still image became unsafe when
the product encountered Live Photo pairs, high-resolution images, RAW-family
inputs, orientation differences, and source-resource identity.

### Decision

MemoMark established media intake as a distinct responsibility:

```text
Provider or Photo Library asset
-> Inspect source facts
-> Classify media
-> Apply admission and routing policy
-> Decode and process through the appropriate capability
```

Different media types can require different loaders, resource preservation,
or composition paths. They still share common production contracts rather
than becoming isolated mini-products with separate renderers.

### Architectural Effect

- media identity is established before rendering;
- Live Photo still and motion resources remain one paired asset;
- RAW and high-resolution inputs can receive explicit admission policy;
- static fallback becomes a declared policy rather than an accidental result;
- Renderer remains focused on presentation output.

## 9. Media Geometry Foundation

### Problem

Live Photo work exposed a deeper geometry defect: still rendering, still
composition, and video composition could infer orientation and dimensions from
different facts. Multiple geometry truths allowed portrait media to become
stretched or horizontal.

### Decision

Geometry became a media foundation:

```text
Media Asset
-> Media Geometry Facts
-> Geometry Normalizer
-> CanonicalGeometry (immutable)
-> Renderer / Composer / Exporter (read-only consumers)
```

The governing principles are:

- geometry is a property of media;
- geometry is resolved once and consumed everywhere;
- `CanonicalGeometry` is the only geometry truth crossing module boundaries;
- downstream consumers do not repair geometry without evidence that the
  foundation is wrong.

### Architectural Effect

- orientation and transforms become machine-testable before rendering;
- Renderer, Composer, and Exporter lose duplicated inference logic;
- one foundation can support still images, Live Photo, RAW-family media, and
  future media capabilities;
- runtime failures are classified before foundational contracts are reopened.

This boundary is recorded in
[`ADR-008`](../ADR/ADR-008-MediaGeometryFoundation.md).

## 10. Share Extension as a Reliable Entry

### Earlier Direction

The Share Extension began as a bridge that accepted images from Apple Photos
and initiated MemoMark work. Without a strict boundary, extension code could
accumulate loading, validation, configuration, processing, and UI
responsibilities under severe memory and lifecycle constraints.

### Current Direction

The Share Extension is a constrained intake and handoff surface:

```text
Apple Photos
-> Share Extension admission
-> Media/provider intake
-> Configuration identity and snapshot handoff
-> Persistent queue
-> Controlled processing
-> Notification
-> Apple Photos
```

The architectural goal is not to make Share another Configuration Center or a
second processing architecture. It should validate entry conditions, preserve
the information needed for production, persist work safely, and keep the
Apple Photos lifecycle observable.

### Architectural Effect

- configuration remains owned outside the Share UI;
- jobs cross the extension boundary durably;
- admission limits protect extension resources;
- processing diagnostics can distinguish intake, handoff, route, render,
  export, and save failures;
- signed-device evidence, not simulator success alone, determines lifecycle
  readiness.

## 11. V3 Production Architecture

V1 established the usable local-first foundation. V2 defined and realized the
Memory Presentation Engine. V3 does not introduce a replacement product
architecture; it proves that the V2 system is durable enough to ship.

V3 concentrates on:

- one durable configuration truth and exact revision ownership;
- save, restore, backup, and clean-install correctness;
- full Apple Photos Share-to-save lifecycle evidence;
- Live Photo, orientation, location, RAW-family, and high-resolution media
  validation;
- performance, memory, concurrency, and resource-release evidence;
- repeatable regression and release gates.

Production quality is therefore an architectural stage: a boundary is not
complete merely because it compiles. It must remain correct across persistence,
process, media, device, and release conditions.

## Architectural Replacements

MemoMark's history includes active replacement of designs that once served the
project. These are not failures to erase. They document paths that future work
should not reopen without new evidence.

### Workspace-Oriented Product Model

```text
Earlier: Generic workspace and editing-session language
Later:   Configuration Center editing durable memory objects
```

**Reason:** The product is a Memory Engine Configuration Center, not a generic
photo workspace. Daily use remains inside Apple Photos.

### Mutable Runtime Configuration

```text
Earlier: Consumers observe mutable or independently reconstructed state
Later:   One exact configuration revision freezes into one snapshot
```

**Reason:** Preview, queue, Share, renderer, and export must not observe
different configuration revisions.

### Downstream Geometry Inference

```text
Earlier: Renderer or Composer derives orientation and geometry locally
Later:   Media Geometry Foundation resolves immutable CanonicalGeometry
```

**Reason:** A production task can have only one geometry truth.

### Position-First Content

```text
Earlier: Content identity follows physical card regions
Later:   Semantic content is resolved before layout placement
```

**Reason:** Meaning must survive layout changes, and Renderer must not define
content semantics.

### Duplicated Domain Formatting

```text
Earlier: Metadata context and consumers accumulate domain-specific logic
Later:   Canonical providers compile domain results into ExpressionContext
```

**Reason:** Each domain needs one owner while preview and production need one
shared expression language.

### Undifferentiated Image Intake

```text
Earlier: Provider results converge quickly on one still-image assumption
Later:   Intake classifies source media and routes explicit capabilities
```

**Reason:** Live Photo, RAW-family inputs, high-resolution media, and resource
identity cannot be handled safely as interchangeable static images.

### Share as an Expanding Mini-Application

```text
Earlier risk: Share accumulates configuration and processing responsibilities
Later goal:   Share admits, preserves, persists, and hands off work reliably
```

**Reason:** An extension operates under constrained lifecycle and memory. It
must not become a second Configuration Center or a parallel production system.

## Stable Boundaries and Active Proof

“Stable” does not mean “never change.” It means changes require scoped V3
requirements, ownership analysis, and verification evidence.

Stable architectural boundaries include:

- Metadata Engine as owner of photo facts;
- Memory Engine as owner of Life Position and memory calculations;
- Configuration aggregate as durable configuration truth;
- Configuration Snapshot as frozen production input;
- Expression providers as owners of domain-to-expression compilation;
- Media Geometry Foundation as owner of geometry truth;
- Layout Engine as owner of layout decisions;
- Renderer as a stateless consumer of resolved presentation and layout;
- Export as owner of new output generation and metadata policy.

Active production-quality work includes:

- Share lifecycle evidence;
- queue, worker, and recovery reliability;
- diagnostics and regression gates;
- media capability evidence;
- performance, memory, and concurrency validation;
- TestFlight and App Store delivery readiness.

These systems may evolve, but they must preserve the stable ownership
boundaries above. MemoMark does not use `Task Center`, `Processing Center`, or
other dashboard-style concepts as user workflow architecture.

## Lessons Learned

### Freeze Before Consumption

Mutable configuration should not cross production boundaries. Resolve one
revision, freeze it, and let downstream systems consume it read-only.

### One Kind of Truth per Owner

Metadata owns facts. Memory Engine owns life-relative meaning. Layout Engine
owns layout. Media Geometry owns geometry. Renderer renders. Export generates
the new artifact.

### Reduce Responsibility

Maturity comes from removing duplicated ownership, not from adding coordinating
layers around it.

### Foundation Before Feature Expansion

New capability should pass through research, specification, foundation,
consumer adoption, validation, and release. A foundation is proven by the
consumer that deletes its duplicate logic.

### Preserve Compatibility Deliberately

Historical source names and adapters may remain when migration risk exceeds
naming value. Product vocabulary can advance without forcing unsafe code
renames.

### Evidence Before Reopening Architecture

A runtime failure does not automatically invalidate a foundation. Classify the
failure, identify one root cause, and change the owning boundary only when
evidence proves it is wrong.

### Local First Is an Architectural Constraint

Local processing, original-photo preservation, durable local configuration,
and Apple Photos integration are not optional implementation details. They
define what MemoMark is.

## Conclusion

MemoMark matured through deliberate architectural replacement rather than
unbounded feature accumulation.

The major transitions all moved in the same direction:

- from information toward meaning;
- from mutable state toward frozen truth;
- from duplicated inference toward single ownership;
- from renderer-centered behavior toward an explicit production pipeline;
- from a standalone photo tool toward a local memory capability inside Apple
  Photos.

Future development should continue reducing coupling, increasing determinism,
and protecting the ownership boundaries that made the current product
possible.

## Primary References

- [`PROJECT_CONSTITUTION.md`](../../PROJECT_CONSTITUTION.md)
- [`Docs/MASTER_PLAN.md`](../MASTER_PLAN.md)
- [`Docs/PRODUCT_VERSION_HISTORY.md`](../PRODUCT_VERSION_HISTORY.md)
- [`Docs/PM-003_Content_Layout_System.md`](../PM-003_Content_Layout_System.md)
- [`Docs/PDR/PDR-004_Configuration_Center_Architecture.md`](../PDR/PDR-004_Configuration_Center_Architecture.md)
- [`Docs/ADR/ADR-001-BatchConfigurationSnapshotProvider.md`](../ADR/ADR-001-BatchConfigurationSnapshotProvider.md)
- [`Docs/ADR/ADR-002-BatchQueueStoreFacade.md`](../ADR/ADR-002-BatchQueueStoreFacade.md)
- [`Docs/ADR/ADR-006-MemoryEngineFoundation.md`](../ADR/ADR-006-MemoryEngineFoundation.md)
- [`Docs/ADR/ADR-007-ProviderBasedExpressionArchitecture.md`](../ADR/ADR-007-ProviderBasedExpressionArchitecture.md)
- [`Docs/ADR/ADR-008-MediaGeometryFoundation.md`](../ADR/ADR-008-MediaGeometryFoundation.md)
- [`Docs/ADR/ADR-009-Configuration-Aggregate-And-Local-Backup-Library.md`](../ADR/ADR-009-Configuration-Aggregate-And-Local-Backup-Library.md)
- [`Docs/02_Architecture/High_Resolution_Media_Intake_Foundation_2026-07-05.md`](../02_Architecture/High_Resolution_Media_Intake_Foundation_2026-07-05.md)
