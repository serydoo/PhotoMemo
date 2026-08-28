---
name: memomark-renderer-contract
description: Audit MemoMark presentation and export fidelity across preview, Layout Engine inputs, Renderer output, and Photo Library save-back. Use for bounded rendering or export work; do not make Renderer the owner of layout or memory meaning.
---

# MemoMark Renderer Contract

## Overview

Use this skill when MemoMark's visual output or export behavior needs an
evidence-backed review. Preserve the pipeline:

`Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export`

Renderer expresses resolved visual style; it does not calculate Life Position,
invent copy, or decide coordinates. New layout behavior requires research,
specification, Layout Engine ownership, renderer integration, and validation.

## Primary Files

Read the relevant subset of:

- `Source/MemoMark/MemoMark/Renderers/RecordCardRenderer.swift`
- `Source/MemoMark/MemoMark/Renderers/ClassicWhiteRenderer.swift`
- `Source/MemoMark/MemoMark/Services/RecordCardExportService.swift`
- `Source/MemoMark/MemoMark/Services/RecordCardBuildService.swift`
- `Source/MemoMark/MemoMark/Models/RecordCard.swift`
- the current research/layout specification relevant to the change

## Review Priorities

Check in this order:

1. resolved layout input and preview/export parity
2. original-image and metadata preservation
3. horizontal/vertical, color-space, orientation, and resource behavior
4. typography, spacing, and information hierarchy from accepted specifications
5. temporary-file, cancellation, failure, and save-back side effects
6. exact build and physical-device evidence where the Photos boundary is involved

For preview/export investigations, compare the same resolved input at both
ends of the pipeline. A preview screenshot, a rendered bitmap, and a saved
Photo Library asset are separate evidence artifacts; parity must be established
by contract or read-back, not by visual similarity alone.

## MemoMark Rendering Expectations

- Output creates a new image or supported paired resource; the original remains unchanged.
- Preview and export consume the same resolved presentation and layout contract.
- White-space, typography, and visual hierarchy must come from measurable specifications.
- Layout constants do not get added directly to a Renderer as a convenience fix.
- UI success is shown only after the corresponding save/share/copy/export operation succeeds.
- Changes preserve current macOS behavior and signed physical-device verification requirements.
- Same-source preset/style switching must not flash stale output, mutate the
  original asset, or commit durable configuration before explicit user save.
- Async renderer/export responses require a relevance check against the active
  Configuration Session before updating preview or showing success.
- Renderer performance claims require a before/after measurement; do not infer
  cost from a stable-looking frame rate.

## Output Format

When reviewing or planning, prefer:

1. `Render Risks`
2. `What The User Will Notice`
3. `Fix Order`
4. `Verification`

## Verification

Verify with:

- synthetic or approved sample images (never private research photos in the repository)
- aspect-ratio changes
- export/build tests
- code-path review from build service through export and Photo Library save-back
- physical iPhone 17 Pro Max checks for Photos/Live Photo lifecycle behavior when applicable

Report unverified media types or platform paths explicitly; do not imply RAW,
HDR, Live Photo, or metadata guarantees that the current contract and evidence
do not support.
