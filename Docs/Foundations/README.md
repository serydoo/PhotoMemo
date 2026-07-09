# MemoMark Foundations

## Purpose

Foundations are durable infrastructure boundaries for MemoMark.

A Foundation defines one canonical truth for one core semantic area. Feature
work may adopt a Foundation, but it must not redefine the Foundation.

## Foundation Pattern

Every new Foundation should use this structure:

```text
Docs/Foundations/<FoundationName>/
    README.md
    Manifest.md
    Constitution.md
    FoundationChecklist.md
```

## Document Roles

- `README.md` is the entry point.
- `Manifest.md` explains why the Foundation exists in under one page.
- `Constitution.md` records rules that must not be violated.
- `FoundationChecklist.md` tracks Foundation completion and adoption.

## Foundation Development Method

MemoMark Foundations follow this method:

```text
Problem
    |
    v
Foundation Freeze
    |
    v
Canonical Truth
    |
    v
Consumers
    |
    v
Core Implementation
    |
    v
First Production Consumer
    |
    v
General Adoption
    |
    v
Foundation Stable
```

Short form:

```text
Problem -> Freeze -> Truth -> Core -> First Consumer -> General Adoption -> Stable
```

A Foundation Freeze ends when the Foundation can constrain the first
implementation. It does not wait for perfect documentation.

Implementation begins by proving the canonical truth. Consumer migration and
feature adoption happen after the truth is stable.

## Adoption Exit Rule

An Adoption Sprint is complete only when the consumer contains no duplicated
domain logic from the Foundation.

In practice:

```text
Every Foundation owns exactly one Canonical Truth.
Every consumer adopts it instead of re-deriving it.
```

Review should focus on what domain logic was removed from the consumer, not
only on what code was added.

## Current Foundations

| Foundation | Status | Canonical Truth |
|---|---|---|
| Media Geometry Foundation | Frozen | `CanonicalGeometry` |

## Future Candidates

- Export Foundation
- Asset Foundation
- Metadata Foundation
- Media Representation Foundation

## Rule

Do not create a feature-specific workaround when the problem belongs to a
Foundation.

When implementing a Foundation, ask first:

```text
What is the Truth?
```

Do not ask first:

```text
How do we render it?
```
