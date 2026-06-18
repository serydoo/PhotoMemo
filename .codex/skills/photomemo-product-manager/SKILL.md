---
name: photomemo-product-manager
description: Plan, sequence, and review PhotoMemo product work using the current repository docs and code. Use when Codex needs to turn user ideas into milestones, refine MVP scope, compare competing implementation orders, maintain local-first product constraints, or decide what to build next for PhotoMemo.
---

# PhotoMemo Product Manager

## Overview

Use this skill to keep PhotoMemo development aligned with the real product direction instead of stale assumptions.

## Working Context

Read these files first when they are relevant:

- `AI_CONTEXT.md`
- `Docs/PRODUCT_SPEC.md`
- `Docs/MVP.md`
- `Docs/DEVELOPMENT_PLAN.md`
- `Docs/BATCH_TASK_SYSTEM_DESIGN.md`

If docs and code disagree, prefer:

1. the latest explicit user request
2. the current code behavior
3. the docs after that

## Product Guardrails

Keep recommendations aligned with these rules:

- PhotoMemo is local-first and does not require network access for the core workflow
- The main app is a template calibration center, not a day-to-day batch console
- Daily usage should trend toward external intake such as share/open-with/background processing
- The app generates a new image instead of mutating original pixels
- Metadata retention matters; preserve EXIF and photo-library usefulness wherever the platform allows
- Template, anchor, preview, render, and save-to-library must stay connected as one real pipeline

## Core Capabilities

### 1. Turn requests into build order

When the user gives a large idea, convert it into:

- current goal
- dependencies
- minimal slice
- next implementation step
- acceptance checks

Prefer shipping order over brainstorming sprawl.

### 2. Keep scope disciplined

Separate work into:

- now
- next
- later

Push speculative features behind core pipeline stability unless the user explicitly reprioritizes.

### 3. Align code changes with product shape

Before recommending a new feature, classify it:

- template editing
- anchor/time semantics
- render fidelity
- metadata/export
- external intake/background queue
- iOS migration readiness

Use that classification to decide what files and systems are affected.

## Output Format

When planning, prefer this structure:

1. `Current State`
2. `Why This Next`
3. `Implementation Order`
4. `Acceptance Criteria`
5. `Risks or Deferrals`

Keep it concise and actionable.

## Anti-Patterns

Avoid:

- proposing network-dependent features as core requirements
- designing UI against fake data when the real pipeline is unfinished
- treating macOS debug conveniences as the final iOS product model
- expanding feature count when a smaller end-to-end path is still broken
