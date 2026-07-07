# MemoMark Repository Line Strategy

Last updated: 2026-07-02

This document defines how MemoMark should preserve older product phases without turning the repository into a stack of duplicated version folders.

Read `PROJECT_CONSTITUTION.md` and `Docs/MASTER_PLAN.md` first. This strategy must not override the V2 reset rules.

## Purpose

MemoMark has already moved through several meaningful phases:

- macOS local export foundation
- iOS foundation
- MVP share-flow convergence
- V1 iPhone configuration and memory flow
- V2.1 Memory Engine Product Realization

Those phases are important project memory, but they should not each become a duplicated source tree inside the repository root.

## Active Lines

Use these lines going forward:

### `main`

`main` is the long-term project line.

It should represent:

- the current repository identity
- the V2 reset direction
- IA-003 Memory Engine Integration
- the latest source-of-truth documentation

Do not turn `main` into a dumping ground for every historical packaging checkpoint.

### `release/v1`

Use one durable V1 product branch for the current iPhone-oriented line.

It should represent:

- the V1 app shell
- current iPhone buildability
- share / configuration / memory-flow convergence that still belongs to the V1 product line

The existing `v1-checkpoint-20260702` branch is a checkpoint, not the long-term naming target.

### Tags And Releases

Preserve completed phases through tags and GitHub Releases instead of duplicated folders.

Preferred use:

- tags for durable code checkpoints
- GitHub Releases for packaged artifacts, notes, and screenshots
- branch names only for active development lines

## Historical Milestone Policy

Preserve old phases as milestones, not as root folders such as `MacVersion/`, `MVP/`, or `V1/`.

Recommended milestone grouping:

1. macOS foundation
2. iOS foundation
3. MVP share-flow stabilization
4. V1 checkpoints and release candidates
5. V2 architecture and IA-series checkpoints

If a historical phase needs a downloadable build, attach the artifact to a release. Do not keep multiple app copies in the main source tree.

## Repository Cleanup Rules

When cleaning the repository:

- prefer branch/tag/release cleanup over filesystem duplication
- prefer one active source tree under `Source/PhotoMemo/`
- prefer one current top-level README story
- keep historical notes readable, but do not let them compete with current source-of-truth docs
- do not migrate old documents in bulk until research specifications stabilize

Avoid:

- creating root-level version folders for each phase
- copying the app into `V0`, `MVP`, `V1`, and `V2` source directories
- mixing release artifacts into active source folders
- treating checkpoint branches as permanent product structure

## Suggested Next GitHub Shape

Recommended steady-state structure:

1. `main` for V2 / IA-003 / repository source of truth
2. `release/v1` for the active V1 product line
3. milestone tags for historical stages
4. GitHub Releases for packaged builds and phase notes

## Current Repository Constraint

Because the V2 constitution explicitly says old documents should not be migrated immediately, repository cleanup in the current phase should focus on:

- clarifying entry points
- reducing ambiguity
- defining active lines
- recording historical checkpoints cleanly

It should not yet focus on large physical document migration.
