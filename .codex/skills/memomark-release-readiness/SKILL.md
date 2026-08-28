---
name: memomark-release-readiness
description: Audit MemoMark release readiness, evidence, version scope, and Git state. Use when work approaches validation, handoff, commit, or sync; default to recommendation-only and never perform external release mutation without explicit authorization.
---

# MemoMark Release Readiness

## Overview

Use this skill as an evidence orchestrator, not an upload bot. The default
result is `Audit -> Evidence -> Recommendation`; staging, commit, push,
TestFlight upload, App Store Connect changes, and App Store submission each
require separate explicit authorization.

## Working Context

Read the relevant subset of:

- `PROJECT_CONSTITUTION.md`
- `Docs/CURRENT_BRIEF.md`
- `AI_CONTEXT.md`
- `Docs/07_Releases/RELEASE_SYNC_STANDARD.md`
- the applicable version manifest and release notes
- `scripts/`
- `CHANGELOG.md` and `README.md` when version-facing text is in scope

Check repository state before recommending release actions.

## Release Priorities

Check in this order:

1. version scope, build identity, and target consistency
2. build and focused/full test status
3. runtime and physical-device evidence for the exact build
4. Photos permission, limited-library, Live Photo, metadata, localization,
   accessibility, privacy, and recovery evidence when in scope
5. whether docs and code still point at the same product shape
6. Git state, untracked/private materials, and authorization boundaries

When a release item touches a policy that changes over time, consult the
current Apple source for that run and record the checked date. A generic or
third-party `app-store-review` Skill is a checklist assistant, not the policy
authority.

## MemoMark Release Expectations

- Resolve the project path from the current checkout; do not assume a fixed
  absolute path in reusable instructions.
- Use the existing `xcodebuild` flow that has already been proven for this repo
- Do not treat signing setup as a blocker unless the user explicitly asks for
  signed delivery; do report when signed physical-device evidence is required
- Respect the dirty worktree; never revert unrelated user changes
- If the app is not buildable, fix that before talking about release polish

## Output Format

When asked for release readiness, answer with:

1. `Build And Tests`
2. `Device And Lifecycle Evidence`
3. `Release Risks`
4. `Git State And Authorization`
5. `Recommended Next Action`

Add these gates when the candidate includes the corresponding surface:

| Gate | Minimum evidence |
| --- | --- |
| Accessibility | semantic audit plus Dynamic Type/VoiceOver result; device status separate |
| Localization | supported-language parity and expansion/formatting evidence |
| StoreKit / entitlements | exact build configuration and signed-device result |
| Photos lifecycle | permission, limited library, Live Photo/metadata and save-back result |
| Performance | Instruments or measured before/after result, not visual inference |
| App Review | current Apple guideline/source date and unresolved policy risks |
| MetricKit | only after real deployed telemetry and privacy scope exist |

## Git Guidance

When preparing a sync:

- inspect `git status`
- inspect a small `git diff --stat`
- keep commit messages scoped and human-readable
- push only after the current work is clearly validated **and** the user has
  explicitly authorized the push in this task

## Evidence Vocabulary

Report each gate as `PASS`, `FAIL`, `NOT VERIFIED`, `BLOCKED`, or `N/A` with a
reason. Never infer physical-device, StoreKit, App Store Connect, or production
certification evidence from a compile or unit-test result. Never carry evidence
from another build number without stating why the source contract permits it.

For UI/media work, prefer the paired physical iPhone 17 Pro Max. Do not use an
iOS Simulator build, UI test, or screenshot as a substitute for required
physical-device acceptance.

## Anti-Patterns

Avoid:

- calling something ready when the app no longer builds
- mixing large unrelated changes into one release recommendation
- treating autosync as a substitute for understanding the current diff
- treating a successful archive or unit test as proof of physical-device or
  App Store readiness
