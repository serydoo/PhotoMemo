---
name: photomemo-renderer
description: Inspect and improve PhotoMemo rendering, export fidelity, spacing, typography, and preview-to-output consistency. Use when Codex needs to work on RecordCardRenderer, ClassicWhiteRenderer, export services, border sizing, horizontal/vertical layout rules, or final-image generation quality.
---

# PhotoMemo Renderer

## Overview

Use this skill for any task where PhotoMemo's visual output must match the intended template design and export behavior.

## Primary Files

Read the relevant subset of:

- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
- `Source/PhotoMemo/PhotoMemo/Models/RecordCard.swift`
- `Docs/RENDER_SPEC.md`

## Review Priorities

Check in this order:

1. preview and export parity
2. bottom border height consistency
3. horizontal vs vertical image rules
4. typography size, alignment, and spacing
5. left/center/right information balance
6. temporary-file/export flow side effects

## PhotoMemo-Specific Expectations

- The output must create a new image while preserving the original image area
- The bottom information bar is intentional product identity, not decorative filler
- White-space distribution matters as much as raw text content
- The right-side icon zone must coexist cleanly with metadata and smart text
- Changes should respect both current macOS previewing and future iOS rendering needs

## Output Format

When reviewing or planning, prefer:

1. `Render Risks`
2. `What The User Will Notice`
3. `Fix Order`
4. `Verification`

## Verification

Whenever possible, verify with:

- actual sample images
- aspect-ratio changes
- export/build tests
- code-path review from `RecordCardBuildService` through `RecordCardExportService`
