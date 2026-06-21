# PhotoMemo Main Workflow Consolidation

Last updated: 2026-06-21

## Purpose

This document captures the parts of `PhotoMemo v0.4 Main Workflow Consolidation` that are worth adopting now without forcing a new architecture rewrite.

It does not introduce a new ADR.

It does not replace existing accepted boundaries such as:

- Template String as the canonical content model
- Memory Engine as a dedicated calculation layer
- renderer/export/batch separation

Instead, it defines the current internal workflow standard that future work should follow.

## Canonical Internal Workflow

PhotoMemo should be reasoned about through one internal execution path:

Import

-> Metadata

-> Memory

-> Renderer

-> Export

-> Share

This does not mean every user interaction starts at the same UI.

It means every meaningful product change should clearly belong to one of these six stages.

## Stage Ownership

| Stage | Responsibility | Must Not Own | Current Primary Owners |
| --- | --- | --- | --- |
| Import | bring photos into the app or shared container, preserve source facts, create runtime inputs | memory wording, render styling, export naming policy beyond source preservation | `PhotoImportService`, share intake services, photo pickers |
| Metadata | normalize and expose canonical photo facts | render layout, user identity, share progress UI | `PhotoMetadata`, `PhotoMetadataReader`, `MetadataContext` |
| Memory | derive meaning from metadata and long-term anchors/profile data | raw EXIF parsing, visual styling, saving results | Memory Engine types, `AnchorEngine`, memory variable providers |
| Renderer | turn prepared card content into pixels | business calculation, EXIF interpretation, save policy | `RecordCardRenderer`, renderer implementations |
| Export | write output files and save results while preserving usefulness | UI decisions, memory logic, template authoring | export services, Photo Library save services |
| Share | execute the lightweight share-first flow and communicate outcome | profile editing, style authoring, deep renderer logic | share extension workflow, intake bridge, app wake-up path |

## What We Are Adopting Now

### 1. One workflow standard

All future work should map cleanly to:

Import -> Metadata -> Memory -> Renderer -> Export -> Share

If a proposed change does not fit any stage cleanly, it probably needs to be simplified before implementation.

### 2. Renderer is not the product center

Renderer quality still matters, but renderer is the final visual output layer, not the place where product meaning or workflow policy is decided.

### 3. Template and Renderer stay separate

- Template or Style owns content arrangement and variable selection.
- Renderer owns visual presentation rules.

This separation is already directionally present and should be preserved.

### 4. Metadata remains the canonical photo fact surface

`PhotoMetadata` and the metadata pipeline remain the trusted place for normalized photo facts.

Current code is already close to this goal for EXIF, GPS, time, dimensions, and device data.

The main remaining gap is import-origin facts such as:

- original filename
- asset identifier
- source type / UTI
- source container provenance

These still need tighter lifecycle alignment.

### 5. Share stays product-primary, but not through a risky rewrite

PhotoMemo should keep moving toward a share-first experience, but this round does not force a full rewrite where generation must immediately move entirely into the Share Extension.

Stability remains more important than purity.

## What We Are Explicitly Not Adopting Now

- No new abstract `PhotoWorkflow` layer just for architectural neatness
- No large folder reorganization
- No broad rename sweep across the whole codebase
- No immediate rewrite that makes Share Extension the only execution surface
- No forced migration where every import-origin fact must be moved in one risky step

## Near-Term Consolidation Focus

The next worthwhile consolidation work should focus on:

1. preserving original import facts more consistently from intake through export
2. keeping renderer free of business logic drift
3. making share failures stage-visible and user-readable
4. verifying the happy path:
   Photos -> Share -> PhotoMemo -> Generate -> Save

## Acceptance Standard

We should consider the current consolidation direction healthy when these statements remain true:

- A new contributor can explain which stage owns a change before editing code.
- Metadata facts do not need to be re-parsed or guessed inside renderer or export code.
- Memory wording and age-style calculations stay outside renderer implementations.
- Share UI does not expose internal pipeline terms to users.
- Build verification stays green while the product becomes simpler instead of more layered.
