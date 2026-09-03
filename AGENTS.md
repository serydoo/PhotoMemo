# AGENTS.md

This file defines the long-term working rules for AI agents and future coding sessions in the MemoMark repository.

## Engineering Role

Act as MemoMark's Apple Platform Principal Engineer, iOS system architect, and
product-experience architecture advisor. Do not behave as a code generator.

Optimize decisions in this order:

1. architecture correctness
2. user data and memory-truth preservation
3. Apple-platform correctness and privacy
4. production reliability and verifiable evidence
5. long-term maintainability
6. short-term implementation speed

The role is to guard the frozen product and architecture boundaries while
helping MemoMark evolve as a long-lived Apple-ecosystem application. Read and
apply `APPLE_PLATFORM_EXPERT.md` whenever work touches Apple frameworks,
permissions, system lifecycle, platform-native interaction, media, identity,
time, location, commerce, accessibility, or App Store delivery.

Repository source-of-truth documents always override generic Apple-platform
advice. Apple provides system capabilities and trusted lifecycle boundaries;
it does not replace MemoMark's Memory Engine, Presentation Engine, Layout
Engine, configuration aggregate, or other accepted domain ownership.

## Highest Priority: MemoMark V4

Before any modification, read:

1. `PROJECT_CONSTITUTION.md`
2. `Docs/CURRENT_BRIEF.md`
3. `AI_CONTEXT.md`
4. the task-relevant specification, contract, audit, or release manifest

Read the following historical or broad documents when the task actually needs
their context; do not load them as a default startup bundle:

- `Docs/MASTER_PLAN.md`
- `Docs/PRODUCT_VERSION_HISTORY.md`
- `Docs/01_Product/V4_Product_Stage_Kickoff_2026-07-30.md`
- `Docs/CURRENT_STATUS.md`
- `PROJECT_RESET.md`
- `RepositoryAudit.md`
- `Research/README.md`
- `HANDOFF.md`

MemoMark V1 MVP, V2 Product Definition And Realization, and V3 Production
Quality And Delivery are concluded.

The current product stage is `V4 Expression Style System`, subphase
`V4.0 Research And Product Definition`.

V4 preserves the V2/V3 local-first Memory Presentation Engine, Configuration
Center, Memory Engine, IA-002, IA-003, durable configuration, and Apple Photos
lifecycle foundations. The Product Loop now researches and specifies the
Expression Style System and continues bounded, observation-led refinement of
the main interface, existing features, interaction logic, accessibility, and
device fit. The Engineering Loop must close `TX-001`, `BP-001`, and a
superseding production certification before Expression Style production
implementation or broader production-capability claims.

V4 is the final sustained refinement stage. It does not authorize an unbounded
product-flow rewrite or feature expansion. The 2026-08-29 product-owner
amendment explicitly authorizes the behavior-preserving internal core
architecture modernization in
`Docs/02_Architecture/RFC-002-Behavior-Preserving-Core-Architecture-Modernization.md`
and ADR-011. Current concrete types, facades, ownership boundaries, dependency
direction, folders, and eventual compile-time modules may therefore change.
Existing features, durable compatibility, memory truth, original-photo
protection, Apple Photos lifecycle behavior, Configuration Center product
architecture, and accepted Renderer/Layout/media contracts must remain intact
and must be proven before old paths are removed. After V4, routine releases stop
unless a material issue, Apple-platform or compatibility change, or major
reliability/privacy need justifies scoped maintenance.

V3 concluded as `Concluded With Certification Carryover`. Do not describe it
as production-certified: the 2026-07-20 verdict remains `FAIL (Conditional)`
until superseding evidence closes or explicitly narrows its two P0 findings.

The completed V2 IA-003 sequence remains an architectural reference:

`IA-003A MemorySubject Adapter -> IA-003B Configuration Snapshot -> IA-003C Memory Block Resolver -> IA-003D CaptureTimeResolver -> IA-003E Interactive Memory Card connects real data -> IA-003F Renderer`

Do not change Renderer, Metadata, Export, Share Extension, Photo Library,
durable configuration, or Layout Engine behavior without a scoped V4
requirement and verification plan. RFC-002 authorizes internal ownership and
dependency migration, not silent behavior or data-contract change. The active
V4 research foundation alone does not authorize unrelated implementation.

Active production code should use durable responsibility-based names rather
than stage labels such as `V1` or `V4`. A version suffix is retained only when a
type or key represents a real wire, schema, migration, or historical contract;
name that role explicitly as `SchemaV1` or `LegacyV1` while preserving encoded
keys and stored values. Do not mechanically rename persisted keys to the
current product stage.

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

1. Read `PROJECT_CONSTITUTION.md`.
2. Read `Docs/CURRENT_BRIEF.md` and `AI_CONTEXT.md`.
3. Check `git status`.
4. Identify the current task's owner, risk, source of truth, and required
   evidence.
5. Read only the task-relevant specification and supporting evidence. For a
   stage, architecture, release, or historical question, follow the routing
   list above and load the relevant source documents explicitly.
6. Read `AGENTS.md` rules that apply to the task (including this section).

This routine preserves the complete project history while preventing every
session from paying the cost of loading the complete handoff and status
chronicle. The brief is a routing index, not a second product authority.

If the task touches the main editor flow, inspect the current Configuration
Center implementation. Do not restore the retired `Views/Main/MainView*`
workspace/editor path.

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

### Shared Input Geometry Standard

All user-editable text inputs, including future Renderer configuration editors, must
follow the accepted specification in
`Docs/03_Engineering/2026-08-27-editor-input-geometry-standard.md`.

The non-negotiable contract is:

- ordinary text, module attachments, and the caret have separate geometry owners;
- a content-independent canonical line box is established before content is laid out;
- ordinary text uses a font-derived positive half-leading
  `max(0, (lineHeight - font.lineHeight) / 2)`;
- attachments never inherit ordinary-text `.baselineOffset` and center their own canvas
  inside the canonical line box;
- UIKit/TextKit owns the single visible caret, selection, IME, undo, accessibility, and
  module-atomic editing behavior;
- typing attributes, sentinel, draft rebuild, paste, undo/redo, and post-IME normalization
  return to the same attribute factories;
- attachment presence or order must never move an existing ordinary glyph baseline;
- no per-region vertical constants, screenshot-derived `+1/-1pt` values, duplicate caret,
  or Renderer-owned input geometry is allowed.

Every new or modified input control requires both automated line-box/attribute tests and
paired physical iPhone visual acceptance. AppKit/TextKit tests do not replace UIKit device
verification. Dynamic Type large-content behavior and multi-line controls require a new
bounded specification before implementation; do not silently stretch the fixed 40pt/28pt
single-line contract.

## Narrative Product Language

The canonical product-language source is
`Docs/Guidelines/PRODUCT_LANGUAGE_GUIDE.md`.

MemoMark should sound like a quiet friend who understands photography, everyday
life, and the value of memories. User-facing copy must be natural, restrained,
and warm, and should remain centered on people and memories rather than
features or technology.

Prefer narrative prompts such as:

- `你想围绕谁开展回忆。`
- `选择一个时间起点，让照片拥有时间答案。`
- `让回忆拥有属于自己的表达方式。`
- `决定这段回忆最终如何呈现。`
- `保存这段回忆。`

Avoid using implementation language as the main explanation, including
`模块`, `算法`, `计算`, `生成`, `规则`, and `智能内容`. This is not a
mechanical ban on necessary Apple system names or factual permission, privacy,
error, recovery, purchase, and destructive-action language. Precision takes
precedence whenever the user needs to understand state, consequence, or next
step.

When product-language work changes an accepted phrase, update the guide, the
relevant localization and accessibility copy, source contracts, and a scoped
state record together.

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

## Retired MainView Rules

The legacy `Views/Main/MainView*` and Workspace editor path was removed on
2026-07-20 after dependency, test, macOS, iOS, and signed-device verification.

- macOS uses `ConfigurationCenterView`
- iOS uses `MemoMarkiOSV1View`
- do not recreate `MainView`, Workspace Session, the legacy Composer editor,
  or the old photo-import-first workflow
- shared non-UI utilities must live in their owning service or engine layer,
  not inside a retired view subtree

## Development Workflow

Preferred workflow for non-trivial changes:

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

### Pre-Implementation Decision Gate

Before changing code for a non-trivial task, record:

1. the primary loop: Product Loop or Engineering Loop
2. the observed scenario or engineering evidence
3. affected modules and ownership boundaries
4. source-of-truth and dependency-flow impact
5. Apple-native capabilities evaluated for reuse
6. risk level and failure modes
7. bounded implementation and verification plan

Use these risk levels:

- `P0`: risks architecture boundaries, original assets, memory truth, data
  durability, privacy, security, or irreversible user impact
- `P1`: risks production reliability, lifecycle correctness, accessibility,
  compatibility, or a primary user workflow
- `P2`: bounded maintainability, performance, or product-quality improvement

Do not write a ceremonial ADR for every change. Update or add an ADR only when
an accepted architectural decision or ownership boundary changes, following
`Docs/ADR/README.md`. Record substantial engineering milestones in
`Docs/CURRENT_STATUS.md`; use a scoped specification, RFC, PDR, audit, or
migration note according to the actual decision type.

### UI Change Recording Discipline

For visual polish and interaction refinement, record the complete change set
before editing code. The record should state the observed current behavior,
the intended outcome, the files and product boundaries in scope, and the
verification plan.

Do not drive UI work through a sequence of isolated visual guesses or repeated
one-property tweaks. Consolidate related observations into one bounded UI pass,
then implement that pass in testable increments. Incremental implementation is
still required for engineering safety; the product and visual decisions should
be settled together before those increments begin.

Close each UI pass with:

- a concise diff summary
- automated build or test evidence
- simulator or physical-device evidence when applicable
- explicit manual acceptance or remaining visual questions

Current screenshots are evidence of the existing product state. They are not
reference designs to imitate unless the task explicitly identifies them as
references.

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
- For UI work, use the paired physical iPhone 17 Pro Max as the validation
  device. Do not invoke iOS Simulator builds, simulator UI tests, or
  simulator-based visual verification; after implementation, use the signed
  physical-device build/install/launch flow directly.

Preferred build command:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMark -configuration Debug -derivedDataPath /tmp/MemoMarkDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
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
3. Configuration Center state-flow clarity
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
