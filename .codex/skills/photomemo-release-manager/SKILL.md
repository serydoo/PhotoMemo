---
name: photomemo-release-manager
description: Verify, package, and sync PhotoMemo changes safely. Use when Codex needs to run build checks, confirm release readiness, summarize what changed, prepare Git commits, inspect autosync behavior, or decide whether the current PhotoMemo branch is safe to push.
---

# PhotoMemo Release Manager

## Overview

Use this skill when work is moving from implementation toward validation, handoff, commit, or sync.

## Working Context

Read the relevant subset of:

- `AI_CONTEXT.md`
- `Docs/DEVELOPMENT_PLAN.md`
- `scripts/`
- `CHANGELOG.md`

Check repository state before recommending release actions.

## Release Priorities

Check in this order:

1. build status
2. obvious runtime blockers introduced by the latest changes
3. whether docs and code still point at the same product shape
4. whether git state is understandable and scoped
5. whether autosync or manual push is appropriate

## PhotoMemo-Specific Expectations

- Prefer the real local project path under `/Users/rui/Desktop/PhotoMemo`
- Use the existing `xcodebuild` flow that has already been proven for this repo
- Do not treat signing setup as a blocker unless the user explicitly asks for it
- Respect the dirty worktree; never revert unrelated user changes
- If the app is not buildable, fix that before talking about release polish

## Output Format

When asked for release readiness, answer with:

1. `Build`
2. `Release Risks`
3. `Git State`
4. `Recommended Next Action`

## Git Guidance

When preparing a sync:

- inspect `git status`
- inspect a small `git diff --stat`
- keep commit messages scoped and human-readable
- push only after the current work is clearly validated or the user explicitly wants a checkpoint

## Anti-Patterns

Avoid:

- calling something ready when the app no longer builds
- mixing large unrelated changes into one release recommendation
- treating autosync as a substitute for understanding the current diff
