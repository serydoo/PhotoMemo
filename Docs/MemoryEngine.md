# Memory Engine

Last updated: 2026-06-20

## Purpose

PhotoMemo is no longer only a metadata overlay tool.

Its memory layer now has a dedicated domain foundation:

**照片记录的是瞬间，Memory Engine 记录的是时间。**

The Memory Engine is a local-first, offline, deterministic domain layer that converts canonical photo time and user-defined anchors into reusable memory variables.

It does not:

- upload anything
- use AI
- own rendering
- own export
- own batch behavior
- own UI workflow

## Current Pipeline

The current runtime path is:

`PhotoMetadataReader -> PhotoMetadata -> MemoryContext -> MemoryVariableProvider -> CardVariableProvider -> TemplateVariableEngine -> RecordCardBuildService -> Renderer`

Important notes:

- `PhotoMetadata` remains the only source of truth for capture time.
- `AnchorEngine` still owns existing smart-anchor calculation behavior.
- `MemoryVariableProvider` may reuse `AnchorResult` when available so existing user-facing summaries stay stable.
- Renderer and export still consume resolved strings only.

## Responsibilities

### MemoryContext

Holds the memory-domain inputs:

- normalized `PhotoMetadata`
- optional `Anchor`
- optional `AnchorResult`
- user story text

### MemoryVariableProvider

Produces memory variables for the template pipeline.

Current responsibilities:

- derive elapsed day / year / month / week values
- format baby-age text
- preserve current `memory_summary` behavior when anchor summaries already exist
- degrade gracefully for missing dates and future-relative anchors

### MemoryCalculationResult

Acts as the typed output boundary for memory variables before they are merged into `MetadataContext`.

## Supported Variables

| Variable | Meaning | Output Shape |
| --- | --- | --- |
| `{{days_since}}` | elapsed whole days since anchor | numeric string |
| `{{years_since}}` | elapsed whole years since anchor | numeric string |
| `{{months_since}}` | elapsed whole months since anchor | numeric string |
| `{{weeks_since}}` | elapsed whole weeks since anchor | numeric string |
| `{{baby_age}}` | birthday-style age text | formatted string |
| `{{memory_summary}}` | story text or memory summary fallback | formatted string |

## Behavior Rules

- If no anchor or no usable capture date exists, memory values stay empty instead of inventing data.
- Future-relative anchors never produce negative `*_since` values.
- `baby_age` only appears for birthday anchors and never uses awkward `0岁...` wording.
- If the user has written `story`, `memory_summary` uses that explicit text first.
- If an existing `AnchorResult.summaryText` already exists, Memory Engine preserves it to avoid behavior drift.

## Test Coverage

`MemoryEngineTests` currently verifies:

- under-one-year baby age formatting
- leap-year birthdays
- timezone boundary handling
- future-date clamping
- same-session integration into `CardVariableProvider`
- public variable-catalog exposure

Implementation note:

- the current regression suite lives inside the existing `PhotoMemoTests` target as a dedicated `MemoryEngineTests` Swift Testing suite
- this keeps the scope conservative while still giving Memory Engine its own repeatable verification surface

## Future Roadmap

Likely next safe expansions:

- richer anniversary phrasing derived from the same domain boundary
- timeline-oriented memory summaries for future iOS surfaces
- broader memory variable families without leaking business logic into renderer or export

Not planned for this layer:

- AI-generated prose
- cloud sync
- timeline UI state management
