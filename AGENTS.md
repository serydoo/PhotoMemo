# AGENTS.md

This file defines the long-term working rules for AI agents and future coding sessions in the PhotoMemo repository.

## Project Identity

PhotoMemo is a **local-first macOS-native photo memory card generator**.

It is not:

- a cloud photo product
- a general image editor
- a template marketplace
- a batch-first dashboard UI

It is:

- a template calibration center
- a real EXIF + anchor driven rendering tool
- a system that generates a new image while preserving the original photo

## Required Startup Routine

At the start of any new session:

1. Read `README.md`
2. Read `AI_CONTEXT.md`
3. Read `HANDOFF.md`
4. Read `AGENTS.md`
5. Read `Docs/CURRENT_STATUS.md`
6. Check `git status`

If the task touches the main editor flow, inspect:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- the latest `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+*.swift` files

## Product Guardrails

Always preserve these rules:

- The app is fully local-first
- Do not upload photos
- Do not modify the original photo
- Generate a new output image instead
- The main UI is a template calibration center, not a future batch workbench
- Do not expand feature surface faster than the real import-render-export pipeline can support
- Preview fidelity must stay tied to the real renderer/exporter

## Template And Anchor Rules

- Smart anchor variables output **time results**, not full sentence copy
- Users compose the final sentence by combining literal text with variables
- Do not revert to a model where anchor modules generate full prose automatically

Examples:

- `{{anchor_age_text}}` -> `1岁2个月18天`
- `{{anchor_countdown_text}}` -> `还有86天`

Final wording should remain user-controlled.

## Immers White Border Rules

When working on the Immers-inspired preset:

- only borrow the bottom white-bar design language
- keep content centered on PhotoMemo memory/smart-module semantics
- use `Logo 标识` terminology consistently
- if no custom logo is selected for `immersWhite`, keep the classic Apple mini-logo fallback
- preserve the horizontal layout refinement already made for tighter title width and denser right-side parameters

## MainView Refactor Rules

`MainView.swift` should keep moving toward a **coordinator** role.

Preferred direction:

- state lives in `MainView`
- persistence and side effects live in `MainView`
- display-heavy sections move into `MainView+*.swift`
- do not move business logic into decorative subviews

When refactoring `MainView`, preserve these behaviors:

- insertion must go into the explicitly selected custom region
- do not restore the old implicit right-bottom insertion fallback
- template switch / reset / rename must refresh composer editing state
- do not break drag-sort and local editor-state synchronization

## Development Workflow

Preferred workflow for non-trivial changes:

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

Installed skills available for this workflow:

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

## Verification Rules

For meaningful UI or architecture changes:

- run a build before closing the task
- summarize what was verified
- call out what was **not** manually verified

Preferred build command:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

## Editing Rules

- Do not revert unrelated user changes
- Do not use destructive git commands unless explicitly requested
- Keep changes scoped to the current slice
- Prefer additive refactors over wide rewrites
- If a UI extraction creates dead helper code, remove only the helpers that are clearly unused

## Architecture Priorities

When choosing between possible improvements, prefer:

1. Render/export correctness
2. Metadata retention reliability
3. MainView decomposition
4. Permission and album-save clarity
5. iOS-readiness and reduced macOS-only coupling

Prefer these over:

- decorative UI expansion
- speculative abstractions
- unrelated feature additions

## Handoff Expectation

At the end of a substantial work session, update at least one project-internal state document.

Preferred targets:

- `Docs/CURRENT_STATUS.md`
- `HANDOFF.md`

If the work changes long-term repository rules, update `AGENTS.md` too.
