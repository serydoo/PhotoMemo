# MemoMark Current Brief

Last updated: 2026-09-05

This is a compact routing brief for a new Codex session. It is not a
replacement for the project constitution, accepted specifications, contracts,
audits, certification records, or release manifests. When a decision matters,
follow the linked source-of-truth document.

## Current Product Stage

- Stage: `V4 Expression Style System`
- Subphase: `V4.0 Research And Product Definition`
- Product loop: `ES-001 User Expression Scenarios`, expression-style taxonomy,
  measurable Classic and Minimal studies, and bounded existing-surface polish.
- Engineering loop: close `TX-001` Export Commit Protocol, `BP-001` enforced
  single-task memory contract, and publish superseding production certification.
- Architecture loop: execute the behavior-preserving core modernization in
  RFC-002 and ADR-011. Internal owners and facades may change; product features,
  durable compatibility, media truth, and Apple Photos guarantees may not.
- Expression Style production implementation and broader production claims
  remain gated by the V4 Product Design Review and Engineering gate.

## Current Candidate

- Project: `Source/MemoMark/MemoMark.xcodeproj`
- Marketing version: `2.3.0`
- Build: `103`
- Commerce: `MemoMark Commerce v1.1` — historical lifetime entitlement preserved;
  new users use MemoMark+ annual subscription; first-party expression styles are
  included in the subscription.
- Latest current-state record: `Docs/CURRENT_STATUS.md`
- Latest handoff record: `HANDOFF.md` (historical continuity; read on demand)
- Queue architecture: runtime durable mutations are actor-owned by
  `BatchQueueDurableLedger`; `BatchQueueStore` is the main-actor compatibility
  and presentation facade. Startup-only receipt reconciliation remains an
  isolated pre-actor Bootstrap Adapter.

The build and test evidence for build 100 does not imply physical-device visual
acceptance or production certification. The 100 package still needs installation
and review on the paired physical iPhone 17 Pro Max where the task requires it.

## Frozen Boundaries

- Local-first; no photo upload for core processing.
- Apple Photos remains the photo-library owner.
- Originals are never modified; output is a new image or supported paired
  resource.
- Configuration Center architecture remains:
  `Library -> Interactive Memory Card -> Object Inspector`.
- Memory Engine owns memory meaning and Life Position.
- Layout Engine owns layout decisions and canonical geometry.
- Renderer consumes resolved presentation/layout input and does not invent
  business meaning or layout truth.
- Share Extension is an intake boundary; heavy processing remains outside it.
- Existing Card Content Editor input geometry follows the canonical line-box
  specification and UIKit/TextKit caret ownership.

The concrete Swift types and facade boundaries that currently implement these
contracts are not frozen. RFC-002 defines their additive migration into Domain,
Application Transaction, Platform Adapter, Presentation Feature, and
Composition Root ownership.

## Verification Defaults

- For UI and media lifecycle work, prefer the paired physical iPhone 17 Pro Max
  and report the exact build installed.
- Do not use Simulator builds, UI tests, or screenshots as a substitute for the
  required physical-device acceptance.
- Separate automated tests, builds, device install/launch, manual acceptance,
  StoreKit/App Store Connect evidence, and production certification.
- A missing evidence item is `NOT VERIFIED` or `BLOCKED`, not `PASS`.
- Do not commit, push, upload, or submit externally unless this task explicitly
  authorizes that mutation.

## Routing Rules

Read only the sources relevant to the task after this brief:

- Codex workflow governance: `Docs/03_Engineering/2026-08-28-codex-governance-spec.md`.
- GitHub iOS/Apple Skill research and selection rules:
  `Docs/03_Engineering/2026-08-28-github-ios-skills-research.md`.

- Product stage and frozen architecture: `PROJECT_CONSTITUTION.md`,
  `Docs/MASTER_PLAN.md`, and the accepted V4 kickoff.
- Core architecture modernization:
  `Docs/02_Architecture/RFC-002-Behavior-Preserving-Core-Architecture-Modernization.md`
  and `Docs/ADR/ADR-011-Application-Transactions-And-Dependency-Direction.md`.
- Current implementation and milestone evidence: `Docs/CURRENT_STATUS.md`.
- Product research: `Research/README.md` and the relevant V4 research document.
- Apple-platform boundary: `APPLE_PLATFORM_EXPERT.md`.
- Release work: the applicable `Docs/07_Releases/*` manifest and
  `RELEASE_SYNC_STANDARD.md`.
- Cross-cutting UI/release quality gate: `.codex/skills/memomark-quality-gates/SKILL.md`
  (load only for substantial UI or release audits).
- Historical decisions and prior sessions: `HANDOFF.md`, old audits, and
  `Docs/PRODUCT_VERSION_HISTORY.md`, only when the task needs that history.

Before implementation, state the affected owner, risk level, source of truth,
Apple capability evaluated, and required evidence. Keep changes bounded and
leave the repository simpler.
