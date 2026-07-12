# AGENTS.md

This file defines the long-term working rules for AI agents and future coding sessions in the MemoMark repository.

## Highest Priority: MemoMark V3

Before any modification, read:

1. `PROJECT_CONSTITUTION.md`
2. `Docs/MASTER_PLAN.md`
3. `Docs/PRODUCT_VERSION_HISTORY.md`
4. `Docs/CURRENT_STATUS.md`
5. `PROJECT_RESET.md`
6. `RepositoryAudit.md`
7. `Research/README.md`

MemoMark V1 MVP and V2 Product Definition And Realization are complete.

The current product stage is `V3 Production Quality And Delivery`.

V3 preserves the V2 local-first Memory Presentation Engine, Configuration
Center, Memory Engine, IA-002, and IA-003 foundations. Current work prioritizes
production correctness, durable configuration, full Apple Photos lifecycle
evidence, regression control, performance, and release readiness.

The completed V2 IA-003 sequence remains an architectural reference:

`IA-003A MemorySubject Adapter -> IA-003B Configuration Snapshot -> IA-003C Memory Block Resolver -> IA-003D CaptureTimeResolver -> IA-003E Interactive Memory Card connects real data -> IA-003F Renderer`

Do not reopen frozen V2 architecture or change Renderer, Metadata, Export,
Share Extension, Photo Library, or Layout Engine behavior without a scoped V3
requirement and verification plan.

Do not immediately migrate old documents. Build the new research documentation first; migrate old documents only after research specifications stabilize.

The established architecture is a local-first Memory Presentation Engine:

`Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export`

Renderer must not own layout decisions. New layout work must follow:

`Research -> Specification -> Layout Engine -> Renderer -> Validation -> Release`

## Project Identity

MemoMark is a **local-first Memory Presentation Engine**.

It is not:

- a cloud photo product
- a general image editor
- a template marketplace
- a batch-first dashboard UI
- a watermark clone app

It is:

- a research-first memory presentation system
- a memory timeline system
- a metadata-driven presentation engine
- a layout-specification project
- a real EXIF + anchor driven rendering tool
- a system that generates a new image while preserving the original photo

## Required Startup Routine

At the start of any new session:

1. Read `PROJECT_CONSTITUTION.md`
2. Read `Docs/MASTER_PLAN.md`
3. Read `Docs/PRODUCT_VERSION_HISTORY.md`
4. Read `Docs/CURRENT_STATUS.md`
5. Read `PROJECT_RESET.md`
6. Read `RepositoryAudit.md`
7. Read `Research/README.md`
8. Read `README.md`
9. Read `AI_CONTEXT.md`
10. Read `HANDOFF.md`
11. Read `AGENTS.md`
12. Check `git status`

If the task touches the main editor flow, inspect:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- the latest `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+*.swift` files

## Product Guardrails

Always preserve these rules:

- The app is fully local-first
- Do not upload photos
- Do not modify the original photo
- Generate a new output image instead
- Do not commit private research photos or private datasets
- Do not imitate screenshots; extract reusable measurable specifications
- Do not add layout constants directly inside renderers
- Keep Memory Engine as the owner of Life Position calculations
- Keep Layout Engine as the only future source of layout truth
- The main UI is a Configuration Center, not a future batch workbench
- The Configuration Center is the Memory Engine Configuration Center
- Configuration Center edits Objects, not Data
- Everything starts from the Memory Card
- Configuration Center previews the real Memory Card, not an abstract layout
- The Configuration Center architecture is `Library -> Interactive Memory Card -> Object Inspector`
- IA-002 Configuration Center Architecture is frozen; future UI work is polish, not architecture redesign
- Do not expand feature surface faster than the real Apple Photos -> Share -> Processing -> Notification -> Apple Photos lifecycle can support
- Configuration Preview fidelity must stay tied to the real renderer/exporter
- User-facing configuration language should say Preset, not Template; the internal renderer/template model may keep `Template`
- Do not reintroduce Workspace, Dashboard, Task Center, Working Area, or Import Flow as user workflow concepts

## Repository Simplification Rules

RSR-001 established that repository language should prefer simplification over expansion.

Allowed user-facing repository terms:

- Configuration Center
- Configuration Session
- Library
- Interactive Memory Card
- Object Inspector
- Memory Workflow
- Preset
- Time Anchor
- Life Anchor
- Behavior
- Apple Native

Forbidden user-facing repository terms:

- Workspace
- Import
- Dashboard
- Task Center
- Photo Manager
- EXIF Tool

Daily workflow must be described as:

`Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos`

Do not describe daily use as:

`Open App -> Import -> Configure -> Export`

## Preset And Anchor Rules

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
- keep content centered on MemoMark memory/smart-module semantics
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
- preset switch / reset / rename must refresh composer editing state
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

RFC guidance:

- `Docs/02_Architecture/RFC-001-Memory-Enters-the-Production-Pipeline.md`
  is the canonical MemoMark RFC reference
- new RFCs should default to its structure and closure discipline unless there
  is an explicit reason to diverge
- RFC follow-up work should be driven by real architectural need, not by the
  existence of a prewritten next step

Dual-loop guidance:

- MemoMark now operates with two distinct development loops:
  - `Product Loop`
  - `Engineering Loop`
- issue intake should classify one primary source before implementation begins
- if an item appears to belong to both loops, the problem has not yet been
  framed clearly enough
- Product Loop work should begin from observation and scenario
- Engineering Loop work should begin from fact and evidence

## Release Rhythm

Starting from the Memory Engine phase, prefer versioned release labels in project-facing docs and changelogs.

Examples:

- `v0.7.0`
- `v0.8.0`
- `v0.9.0`

Historical `Sprint-*` notes may remain in older handoff/status history, but new release-facing summaries should use version numbers when practical.

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

`Docs/CURRENT_STATUS.md` should now be treated as the repository chronicle for
major engineering events and milestones, not as a general daily dev log.

If the work changes long-term repository rules, update `AGENTS.md` too.
