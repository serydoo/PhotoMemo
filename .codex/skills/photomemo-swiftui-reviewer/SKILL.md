---
name: photomemo-swiftui-reviewer
description: Review PhotoMemo SwiftUI views, state flow, layout stability, and editing interactions. Use when Codex needs to inspect or improve MainView, permission flows, template editing, preview alignment, toolbar behavior, or macOS-to-iOS readiness in the PhotoMemo UI layer.
---

# PhotoMemo SwiftUI Reviewer

## Overview

Use this skill to review and refine PhotoMemo's SwiftUI layer with emphasis on stability, clarity, and future iOS portability.

## Primary Files

Start from these files when applicable:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/PhotoImporterView.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Preview/CardPreviewView.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Template/`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoApp.swift`

## Review Priorities

Check in this order:

1. state ownership and duplication
2. editing focus/cursor behavior
3. slot routing for inserted variables and smart modules
4. preview layout stability
5. light-mode readability and system-style polish
6. whether the interaction model can later translate to iOS without rethinking everything

## PhotoMemo-Specific Expectations

- The preview is a calibration surface, not a heavy editor canvas
- All four custom regions must be independently editable
- Module insertion should go to the currently active slot, not a hard-coded fallback
- UI changes should not break the real render/export pipeline
- Permission prompts and album/export actions should feel explicit and understandable

## Review Output

When asked to review, lead with findings.

For each finding, include:

- severity
- file path
- the broken behavior or risk
- the likely fix direction

If no serious findings exist, say that clearly and mention remaining UX debt or testing gaps.

## Implementation Guidance

When editing:

- prefer simplifying state instead of layering more flags
- preserve the existing minimal white system-style direction
- avoid fake controls that do not map to the final product
- keep macOS-specific code isolated where possible so iOS adaptation stays realistic
