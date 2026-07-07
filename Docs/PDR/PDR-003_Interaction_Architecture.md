# PDR-003 Interaction Architecture

Last updated: 2026-06-23

## Status

```text
Frozen
```

## Purpose

PDR-003 records the frozen interaction architecture for MemoMark after PM-003 Content Layout System Phase 1.

This is not a runtime implementation task.

This is a repository documentation synchronization task.

## Core Decision

MemoMark is not a foreground photo-management app.

MemoMark is a Local First Memory Capability inside Apple Photos workflows.

The Main App is the Configuration Center.

The product-primary path is:

```text
Apple Photos
-> Share
-> MemoMark
-> Memory Workflow
-> Done
```

## Supporting Frozen Decisions

- Zero Interaction
- Quiet Computing
- Back To Photos
- Apple Native First
- Apple Trust
- human and calm progress language
- behavior recovery before interruption
- explicit anti-goals against building parallel Apple Photos systems

## Repository Sources

- `PROJECT_CONSTITUTION.md`
- `PROJECT_PHILOSOPHY.md`
- `AI_CONTEXT.md`
- `Docs/CURRENT_STATUS.md`
- `Docs/Interaction/IA-001_Interaction_Architecture.md`
- `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
- `Docs/DESIGN_DECISIONS.md`
- `Docs/FROZEN_REGISTRY.md`
