# MemoMark 2.2.3 Codebase Health Refactoring Program

- Date: 2026-08-29
- Status: Accepted Engineering Program / Incremental Implementation
- Stable baseline: `2.2.3 (100)` at `main @ 0954bea`
- Primary loop: Engineering Loop
- Program owner: MemoMark application architecture

## Objective

Use the verified `2.2.3 (100)` candidate as the behavior baseline for a bounded
codebase-health refactoring program. The program reduces responsibility
mixing, retired implementation surface, file-level coupling, fragile source
contracts, and unsafe lifecycle orchestration so future maintenance becomes
more predictable and less likely to disturb memory truth, Apple Photos, or the
Configuration Center.

The program began as a bounded refactor. RFC-002 and ADR-011 now supersede its
earlier concrete-facade constraints and authorize a behavior-preserving core
architecture modernization. This is still not a big-bang rewrite. Success is
not defined by an arbitrary maximum line count. A change is valuable only when
it clarifies an owner, removes a retired path, narrows a dependency, creates an
independently verifiable transaction/lifecycle, or replaces an implementation-
coupled test with a stronger contract.

## Accepted Baseline And Evidence

- `2.2.3 (100)` is the stable behavior baseline for this program.
- The latest recorded complete `MemoMarkTests` run contains `1,611` passing,
  `0` failing, and `1` platform-conditional skipped test.
- The repository contains 457 production Swift files and approximately
  127,071 production Swift lines. Twenty-two files exceed 1,000 lines, but
  length is only a triage signal.
- `MemoMarkiOSV1View.swift` mixes root composition, configuration and subject
  persistence, editor orchestration, album loading, logo processing, photo
  intake, navigation, and diagnostics.
- `MemorySubjectEditorView.swift` mixes one editing draft with identity,
  relationship, time-anchor, avatar-media, crop, and presentation lifecycles.
- `ConfigurationCenterViewSupportComponents.swift` combines generic card chrome, preview
  layout, region editing, UIKit text fields, and TextKit attachment support.
- `PhotoLibraryExportService.swift` combines PhotoKit serialization, receipt
  persistence, recovery policy, album resolution, static asset writing, and
  read-back under a P0 external-commit boundary.
- The active iOS root is `MemoMarkiOSV1View`. A repository-wide symbol scan
  found no production construction of `ConfigurationCenteriOSView`; its only
  construction is its own `#Preview`, while several source-contract tests still
  read the retired file.
- `V1SlotATextKitEditor` has no production or test call site. Its neighboring
  `V1TextKitModuleAttachment` remains active and must not be removed with it.

## Architecture Decision Gate

### Owners And Dependency Direction

- SwiftUI root views own presentation state, bindings, navigation, and intent
  dispatch. They do not become persistence or media service owners.
- `ConfigurationSession` remains the single live Configuration Center session
  truth during migration. Its concrete facade may be replaced after the target
  editing transaction is authoritative; no parallel view model or second
  configuration aggregate may exist.
- Existing coordinators, repositories, presenters, request gates, and engines
  remain the preferred extraction destinations when their ownership matches.
- Memory Engine retains memory meaning and time semantics.
- Layout Engine retains canonical layout truth.
- Renderer remains stateless and does not absorb editor or layout ownership.
- Apple Photos retains original-asset ownership. PhotoKit mutations remain
  behind the existing export/save boundaries.
- `BatchQueueStore` remains a migration compatibility facade under ADR-011.
  Durable queue authority may move to an actor-backed ledger/runtime only by an
  additive caller migration that preserves one queue owner at every step.

### Active Naming

- Active production code uses stable responsibility-based names, not `V1` or
  `V4` stage labels.
- Real persisted/history formats retain explicit `SchemaV1` or `LegacyV1`
  naming and unchanged encoded/storage identifiers.
- The naming migration follows
  `Docs/03_Engineering/2026-08-29-active-code-naming-modernization.md`.

### Apple-Native Capabilities Evaluated

- SwiftUI remains the presentation framework for the Configuration Center.
- UIKit/TextKit continues to own the visible caret, selection, IME, undo, and
  attachment editing contract.
- PhotosUI/PhotoKit remain the media selection and Photo Library lifecycle
  boundaries; media work must not move into SwiftUI helpers or the Share
  Extension controller.
- Swift concurrency isolation and structured cancellation are evaluated per
  lifecycle. The program must not silence migration diagnostics with broad
  `@MainActor`, `@unchecked Sendable`, or `nonisolated(unsafe)` annotations.

### Risk Classification

- P2: retired-source removal, compilation-unit separation, pure view extraction,
  and source-contract cleanup with unchanged behavior.
- P1: primary iOS root, object editor, Share Extension lifecycle, accessibility,
  Swift concurrency boundaries, or other changes that can disturb a primary
  workflow even when product behavior is intended to remain unchanged.
- P0: PhotoKit commit/receipt/recovery, durable queue state, original media,
  memory truth, or any change that could duplicate output or lose user state.

## Program Phases

### Phase 1 — Retired Surface And Compilation-Unit Hygiene

1. Classify every test that still reads `ConfigurationCenteriOSView.swift`.
2. Move legitimate assertions to the active runtime owner; remove assertions
   that protect only the retired implementation.
3. Delete `ConfigurationCenteriOSView.swift` only after no production or test
   dependency remains.
4. Remove the confirmed-unused `V1SlotATextKitEditor` while preserving active
   attachment and UIKit support.
5. Split `ConfigurationCenterViewSupportComponents.swift` by established presentation
   responsibility without changing state or geometry.

### Phase 2 — iOS Root Responsibility Convergence

1. Map root state and each asynchronous lifecycle before moving code.
2. Keep the root as the top-level SwiftUI composition and state owner.
3. Move subject persistence scheduling, media selection/import orchestration,
   logo lifecycle, and pure preview/module projection only into matching
   existing application or presentation seams.
4. Preserve latest-request-wins reconciliation and reject stale completions.
5. Replace brittle file-layout tests with state/result contracts where a real
   behavior seam exists.

### Phase 3 — Memory Subject Editor Responsibility Convergence

1. Preserve one parent draft and explicit commit/cancel semantics.
2. Extract display-focused identity and time-anchor sections first.
3. Isolate avatar request identity, cancellation, optimization, crop, and stale
   result rejection without creating a second subject truth.
4. Verify keyboard, picker, crop, accessibility, localization, and device fit.

### Phase 4 — PhotoKit And Queue Boundary Decomposition

1. Keep the `PhotoLibraryExporting` contract and ADR-002 queue facade stable.
2. Separate pure receipt policies/store and save serialization into explicit
   compilation units before changing runtime collaboration.
3. Make any album/static-writer/read-back collaborator extraction part of the
   TX-001 verification matrix.
4. Prove cancellation, post-commit interruption, delayed visibility,
   idempotency, receipt recovery, album loss, and exact-identifier read-back.
5. Do not claim BP-001, TX-001, media fidelity, or production certification
   closure from structural compilation alone.

### Phase 5 — Supporting Health Gates

1. Continue staged Swift 6 readiness by real owner, separately from visual or
   PhotoKit behavior changes.
2. Split oversized tests only when one suite no longer communicates one
   contract; do not optimize test line count mechanically.
3. Reduce source-string contracts in favor of behavior, state, pure-policy,
   and dependency-direction tests.
4. Run a final architecture, accessibility, localization, performance, and
   physical-device quality review after the substantial UI phases.

## Testing Strategy

- Pure structural movement uses the existing focused behavior and contract
  suites as the before/after oracle. New source-layout tests are not added just
  to freeze the new file arrangement.
- Behavior or lifecycle changes follow RED -> GREEN -> REFACTOR with Swift
  Testing and controlled continuations/fakes where applicable.
- Source-contract tests are retained only for durable forbidden dependencies,
  target boundaries, or framework ownership that cannot be expressed as a
  runtime unit test.
- Every increment must leave the project compilable and must run the smallest
  focused suite that would catch an incorrect move.
- Every checkpoint runs the complete `MemoMarkTests` target and the affected
  unsigned build. UI, input, Photos, media, or performance phases require the
  paired physical iPhone 17 Pro Max before they are accepted.

## Commands

Governance:

```bash
python3 scripts/validate_codex_governance.py .
```

Focused tests use the relevant `-only-testing:` selections under:

```bash
xcodebuild -project Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMarkTests -configuration Debug \
  -derivedDataPath /tmp/MemoMarkRefactorTests \
  -destination 'platform=macOS,arch=arm64' test
```

Required repository build:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMark -configuration Debug \
  -derivedDataPath /tmp/MemoMarkDerivedData \
  CODE_SIGNING_ALLOWED=NO -quiet build
```

Generic iOS compilation for iOS-source slices:

```bash
xcodebuild -project Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMarkiOS -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/MemoMarkRefactorIOS \
  CODE_SIGNING_ALLOWED=NO -quiet build
```

## Always / Special Decision / Never

### Always

- Preserve the `2.2.3 (100)` user-visible behavior baseline unless a separate
  defect specification explicitly authorizes a behavior correction.
- Keep increments bounded, reviewable, and independently revertible.
- Run focused verification after each increment and full verification at phase
  checkpoints.
- Record substantial milestones in `Docs/CURRENT_STATUS.md`.

### Special Decision Required

- A discovered need to change a frozen owner, durable schema, PhotoKit commit
  semantics, original-media behavior, or user-facing product interaction.
- A destructive migration or removal whose runtime reachability cannot be
  established from source, target, test, and build evidence.
- A product tradeoff with multiple materially different user outcomes.

### Never

- Recreate `MainView`, Workspace, Dashboard, import-first, or batch-workbench
  architecture.
- Move layout truth into Renderer or memory meaning into presentation code.
- Introduce a second configuration, queue, subject, receipt, or media source of
  truth for convenience.
- Upload photos, modify originals, weaken receipt idempotency, or hide unsafe
  concurrency with unchecked annotations.
- Mix a broad visual redesign, Swift-language migration, and architecture
  refactor in one slice.

## Program Success Criteria

The program is complete when:

1. Retired production surfaces and confirmed dead editor implementations are
   absent, with no runtime or test dependency on them.
2. Large files that remain have one documented owner and cohesive reason to
   remain large.
3. The iOS root is a composition/state boundary rather than a collection of
   independent persistence and media workflows.
4. The Memory Subject editor has one draft owner and separately testable anchor
   and avatar lifecycles.
5. PhotoKit receipt/save/read-back responsibilities are explicit without
   weakening TX-001 behavior or the stable queue facade.
6. Source-string tests protect only durable architecture constraints; runtime
   behavior is covered by behavior/state tests wherever feasible.
7. Every phase has passing focused tests, complete tests, required builds,
   review evidence, and physical-device evidence where applicable.
8. The frozen MemoMark product pipeline and original-photo guarantees remain
   unchanged.
