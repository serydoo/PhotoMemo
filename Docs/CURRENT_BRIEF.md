# MemoMark Current Brief

Last updated: 2026-10-11

Owner accepts the current version for their needs and authorizes a scoped source
consolidation/commit/GitHub push, retaining2.3.6(124). The four-style physical
Share matrix is paused and incomplete; only current Classic actual-content
evidence is established. Resume by checking current configuration/output
ownership and visually confirmed notification baseline before further device
work. See `Docs/03_Engineering/2026-10-11-four-card-share-physical-acceptance.md`
and `Docs/07_Releases/2026-10-11-2.3.6-source-checkpoint-sync-manifest.md`.

2026-10-11 Share background route closure: ordinary Photos Share persists
intake and submits BGProcessing recovery before continuing. On supported iOS,
with sufficient Photos permission, an accepted Continued Processing request
closes Share without opening MemoMark. Permission recovery, unsupported systems
and rejected submissions retain the foreground fallback. The canonical frozen
configuration projection already exists; historical revision41 rejection does
not describe this candidate.

Signed Release build26 on the paired iPhone17ProMax (iOS27.2Beta) now passes
`MemoMarkPinnedAllDirectLayer20261011`: 15 pinned inputs produce 15 real outputs
without host foreground after Share through readback. All 15 Classic footers
were individually read and visually inspected: Chinese text, date/location,
anchor result and logo visible on the intended light background. Static layers
use ImageRenderer.render directly into a CPU bitmap; the prior cgImage-copy
candidate produced 14 black footers, and its dark-pixel-only QA was rejected.
The strengthened light-background plus foreground gate correctly rejects that
old candidate. No final size, format, layout or media standard was lowered.

Current pinned repeated-share intent also completed all15 tasks independently
(processed=true, no cancellation/pause); output asset identifiers stayed equal.
Live output retained its full-size HEIC/MOV pair, matching identifiers and valid
unique still marker. Photos supplied 14 static JPEG representations, including
RAW-backed assets; this is not original RAW decoding certification. Input
content identity/catalogue stayed equal; this optimized input round did not
hash every original byte. The earlier local-five repeat failure is retained as
a distinct historical open finding, not rewritten by this pinned scenario.

Latest full macOS suite: 2111 definitions / 2181 executions passed, 1 existing
skip, zero failures. Native expanded progress was observed while the host stayed
background. The old failed system card was subsequently dismissed with a scoped physical
UI gate (1passed) and before/after screenshots, preserving other notifications.
The driver subsequently stopped creating Live Activities from untracked
terminal/history projections. Signed Release build27 is installed; physical
host launch independently logged the current completed repeat session and
untrackedTerminal;activityNotCreated, with zero new ActivityKit requests.
Existing tracked activities still update/end. Latest full suite remains
2111 definitions / 2181 executions passed, 1skip, zero failures. Media batch
evidence is build26; this final main-driver-only change has its own build27
physical launch evidence. Latest native completion-banner timing and
stable-system/cold-host/pressure/other-style certification remain separate gates. Every round preserves evidence then deletes only the named QA
Outputs after terminal state, checking Inputs unchanged and Outputs zero.
See `Docs/03_Engineering/2026-10-11-share-background-route-closure.md`.

The earlier foreground-only repair is superseded by the owner's explicit
background requirement. The route uses the existing ADR-012 system-granted
extension callback and canonical pipeline; this does not imply a permanently
running or automatically awakened host. Wider production certification remains
open. Submission alone is never saved-output evidence.

2026-10-07 research execution: use
`Docs/03_Engineering/2026-10-07-post-2.3.6-research-execution-plan.md` for the
combined competitor, GlassCard/Live Photo and adaptive-form roadmap. Released
source baseline is `06eebcd2` (2.3.6/124); post-release floating-rail
source checkpoint is separate. Live selected SDK is 27.2, with isolated 27.1 adaptive API
typecheck passing. Small-phone landscape direction is provisionally accepted; the complete keyboard/accessibility matrix remains open. See
`Docs/03_Engineering/2026-10-07-landscape-source-checkpoint.md`. Existing
GlassCard motion already resolves material per source frame and is SDR-only.

This is a compact routing brief for a new Codex session. It is not a
replacement for the project constitution, accepted specifications, contracts,
audits, certification records, or release manifests. When a decision matters,
follow the linked source-of-truth document.

## Current Product Stage

- GlassCard native material is integrated into local main: shared output-size preview, still/motion artifacts, old-system fallback and explicit DEBUG device validation. Owner directs restoring Release authoring in2.3.6(124) after observing the missing entry; both build configurations must expose the same four existing styles. Two real pairs were saved/read back on iPhone17ProMax during115 development;116 evidence is tracked separately. See `Docs/03_Engineering/2026-10-02-glasscard-native-material-delivery.md` and the116 sync manifest.

- Stage: `V4 Expression Style System`
- Subphase: `V4.0 Research And Product Definition`
- Product loop: `ES-001 User Expression Scenarios`, expression-style taxonomy,
  measurable Classic and Minimal studies, and bounded existing-surface polish.
- Engineering loop: the `2.3.3 (111)` release record initially closes `TX-001`,
  `BP-001`, and the specified iPhone 17 Pro Max FilmMark full path for this
  version; later user feedback or new evidence may reopen them. The scoped
  decision is recorded in
  `Docs/01_Product/V4_FilmMark_2.3.3_111_Initial_Production_Closure_2026-09-23.md`.
- Architecture loop: execute the behavior-preserving core modernization in
  RFC-002 and ADR-011. Internal owners and facades may change; product features,
  durable compatibility, media truth, and Apple Photos guarantees may not.
- Expression Style production implementation and broader production claims
  remain gated by the V4 Product Design Review and Engineering gate.

## Current Candidate

- Project: `Source/MemoMark/MemoMark.xcodeproj`
- Marketing version: `2.3.6`
- Build: `124`
- Release status: `Version Locked; Release Evidence Open`
- Release scope starts from public 2.3.5 (122), source53b7edd3; accepted checkpoint19139c49 and incident repair follow. See `Docs/07_Releases/2026-10-06-2.3.6-sync-manifest.md`.
- Commerce: `MemoMark Commerce v1.1` — historical lifetime and activation-code
  entitlements preserved; new users may choose monthly/annual subscription or the existing lifetime SKU; see the accepted 2026-10-06 lifetime amendment;
  all built-in memory expression styles are included in the subscription.
- Latest current-state record: `Docs/CURRENT_STATUS.md`
- Latest handoff record: `HANDOFF.md` (historical continuity; read on demand)
- Queue architecture: runtime durable mutations are actor-owned by
  `BatchQueueDurableLedger`; `BatchQueueStore` is the main-actor compatibility
  and presentation facade. Startup-only receipt reconciliation remains an
  isolated pre-actor Bootstrap Adapter.

The earlier signed 111 package has been installed over the existing app container on
the paired physical iPhone 17 Pro Max, read back as `2.3.3 (111)`, and launched
successfully without clearing data. The scoped FilmMark full-path initial
acceptance, together with `TX-001` and `BP-001`, is closed for this version by
the product-owner decision recorded above. This does not imply StoreKit
sandbox acceptance, App Store Connect submission, or a global/permanent
production certification; unrelated app-wide visual or manual acceptance still
follows its own evidence boundary. It is historical evidence and does not certify
the current 115 candidate.

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
- Current product positioning and user-selection boundary:
  `Docs/01_Product/MemoMark_Product_Positioning_And_Memory_Selection.md`.
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
