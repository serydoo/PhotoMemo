---
name: memomark-product-manager
description: Plan and review MemoMark product work against the current V4 stage, accepted product decisions, local-first boundaries, and observed scenarios. Use to sequence bounded work, refine scope, or decide what to build next; do not treat historical MVP documents as current authority.
---

# MemoMark Product Manager

## Overview

Use this skill to keep MemoMark work aligned with its current V4 product loop
and Engineering Loop. The repository may retain historical legacy names, but
current product language is MemoMark.

## Working Context

Read these files when relevant:

- `PROJECT_CONSTITUTION.md`
- `Docs/CURRENT_BRIEF.md`
- `AI_CONTEXT.md`
- `Docs/01_Product/V4_Product_Stage_Kickoff_2026-07-30.md`
- `Research/README.md`
- the specific accepted PDR, RFC, contract, or release manifest

If sources disagree, prefer:

1. the latest explicit user request
2. the project constitution and accepted current-stage decision
3. the applicable current specification or contract
4. documented implementation evidence
5. historical plans and handoffs as context only

When code violates a current specification, report the mismatch; do not
silently promote the implementation to product truth.

## Product Guardrails

Keep recommendations aligned with these rules:

- MemoMark is local-first and does not require network access for the core workflow
- The main app is the Memory Engine Configuration Center, not a day-to-day batch console
- Daily usage should trend toward external intake such as share/open-with/background processing
- The app generates a new image instead of mutating original pixels
- Metadata retention matters; preserve EXIF and photo-library usefulness wherever the platform allows
- Preset, anchor, preview, render, and save-to-library must stay connected as one real pipeline
- The frozen Configuration Center shape is `Library -> Interactive Memory Card -> Object Inspector`.
- Daily usage remains `Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos`.
- Memory Engine owns Life Position; Layout Engine owns layout; Renderer does not invent either.

## Core Capabilities

### 0. Use the maturity rule

V4 is a refinement and closure stage. Codex autonomy should decrease as the
product matures: start from an observation or fact, make the smallest bounded
change, and increase verification rather than feature surface. A GitHub Skill
or attractive Apple API is not a product requirement by itself.

### 1. Turn requests into build order

When the user gives a large idea, first classify the primary loop:

- Product Loop: observed user scenario, research, product language, or bounded UI polish
- Engineering Loop: fact-based reliability, lifecycle, privacy, performance, or certification work

Then convert it into:

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

- preset/expression style
- anchor/time semantics
- render fidelity
- metadata/export
- external intake/background queue
- Apple-platform/device readiness

Use that classification to decide what files and systems are affected.

### 4. Separate product language from implementation language

For expression and configuration work, keep these meanings distinct:

- interface language;
- output language;
- preset output language;
- task snapshot language.

Smart anchors provide time results; users compose final wording. Do not let a
generic localization or AI-writing pattern generate full memory prose or blur
the ownership of the Memory Engine.

### 5. Screen new platform capabilities

Before accepting Liquid Glass, ActivityKit, MetricKit, StoreKit, background
processing, or a new navigation pattern, state the user scenario, platform
availability, lifecycle cost, privacy implication, and evidence needed. Defer
capabilities without a current V4 scenario to a conditional roadmap item.

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
- reopening IA-002 or proposing a large-scale core-flow rewrite in V4
- implementing Expression Style production behavior before the Product Design Review and Engineering gate pass
- using `Import`, `Workspace`, `Dashboard`, or `Task Center` as current user workflow concepts
- expanding feature count when a smaller end-to-end path is still broken
