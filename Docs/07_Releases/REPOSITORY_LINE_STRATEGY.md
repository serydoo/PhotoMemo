# MemoMark Repository Line Strategy

Last updated: 2026-07-11

This document defines how MemoMark should preserve older product phases without turning the repository into a stack of duplicated version folders.

Read `PROJECT_CONSTITUTION.md`, `Docs/MASTER_PLAN.md`, and
`Docs/PRODUCT_VERSION_HISTORY.md` first. This strategy must not override the
current V3 repository rules.

## Purpose

MemoMark has already moved through several meaningful phases:

- macOS local export foundation
- iOS foundation
- MVP share-flow convergence
- V1-compatible iPhone configuration and memory implementation
- V2 Product Definition and Realization
- V3 Production Quality and Delivery

Those phases are important project memory, but they should not each become a duplicated source tree inside the repository root.

## Active Lines

Use these lines going forward:

### `main`

`main` is the long-term project line.

It represents:

- the current repository identity
- the active V3 product and engineering line
- the V2 architecture and completed IA-003 integration baseline
- the latest source-of-truth documentation

Do not turn `main` into a dumping ground for every historical packaging checkpoint.

### Historical V1 Branches

The former V1 checkpoint branches have been merged into `main` and are not
active product lines.

Historical branch and tag names may still identify:

- the legacy-compatible iOS implementation baseline
- earlier iPhone build checkpoints
- V1 and V2 milestone evidence

Do not recreate `release/v1` or another permanent product-stage branch unless a
future release-maintenance requirement explicitly needs it.

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
4. V1-compatible implementation checkpoints and release candidates
5. V2 architecture and IA-series checkpoints
6. V3 production-quality and release-readiness checkpoints

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

Current steady-state structure:

1. `main` for the active V3 product and repository source of truth
2. milestone tags for historical stages
3. GitHub Releases for packaged builds and phase notes
4. temporary scoped branches only when active work requires isolation

## Current Repository Constraint

Because historical documents remain evidence, repository cleanup should focus on:

- clarifying entry points
- reducing ambiguity
- defining active lines
- recording historical checkpoints cleanly

It should not perform large physical document migration without a separately
reviewed documentation plan.
