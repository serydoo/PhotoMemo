# MemoMark Post-Release Code Audit Remediation Plan

**Specification:** `Docs/03_Engineering/2026-08-27-post-release-code-audit-remediation-spec.md`

## Assumptions Confirmed By The User Direction

- P0-1 memory verification and execution behavior remain unchanged.
- P0-2 EXIF timezone behavior remains unchanged.
- “Continue with the other parts” authorizes bounded implementation of the
  remaining P1/P2 findings, tests, documentation, and build configuration.
- Existing product and architecture source-of-truth documents remain dominant.

## Task 1 — Managed Intake Containment

**Acceptance:** Root and true descendants are managed; sibling-prefix and
unrelated paths are not. Existing retry and cleanup behavior is preserved.

**Verify:** Focused failure-policy, queue-persistence, and resource-lifecycle
tests pass.

**Files:** Shared containment owner, three consumers, focused tests.

**Dependencies:** None.

## Task 2 — Shared Defaults Allowlist

**Acceptance:** Only explicit MemoMark-owned keys migrate; existing App Group
values win; unrelated standard defaults stay private; migration remains
idempotent.

**Verify:** `MemoMarkSharedContainerTests` focused run passes.

**Files:** `MemoMarkSharedContainer.swift` and its focused tests.

**Dependencies:** None.

## Task 3 — Semantic And Localized Progress

**Acceptance:** New progress updates persist a semantic phase; existing queue
JSON still decodes; presentation resolves the semantic phase in the current
interface language; affected dynamic accessibility copy has four-language
format keys.

**Verify:** Focused progress/status/localization tests pass.

**Files:** Batch progress model/processor, background projection, localization
resources, focused tests.

**Dependencies:** None.

## Checkpoint A

- Integrate Tasks 1-3.
- Review overlapping changes.
- Run focused tests and an iOS generic build.

## Task 4 — File-Backed Queue Snapshot

**Acceptance:** Production queue state uses an atomic file; legacy defaults are
imported only when the file is absent; read-back mismatch remains a hard
persistence failure; dependency-injected tests remain supported.

**Verify:** Add RED migration/precedence/read-back tests, then run all queue
persistence and queue execution tests.

**Files:** Queue persistence implementation and focused tests, plus shared
container path ownership if needed.

**Dependencies:** Task 2 establishes App Group storage policy.

## Task 5 — Existing Failure Reconciliation

**Acceptance:** Every one of the 31 baseline failures is classified and either
fixed against accepted behavior or updated as a stale source contract. No test
is skipped or weakened to hide a behavioral failure.

**Verify:** Complete `MemoMarkTests` run.

**Files:** Primarily test contracts; production files only where accepted
behavior is actually wrong.

**Dependencies:** Tasks 1-4 integrated so failure counts are current.

## Task 6 — Bundle Hygiene And Safe Deprecations

**Acceptance:** Main macOS/iOS app bundles omit nested target Info.plists and
README files. Only behavior-neutral SDK rename migrations are applied.

**Verify:** Both builds pass; inspect bundle file lists; run affected naming and
PhotoKit tests.

**Files:** Xcode project exclusions and bounded API call sites.

**Dependencies:** None, but integrate after Checkpoint A to minimize concurrent
project-file conflicts.

## Final Checkpoint

- Run `git diff --check`.
- Run the complete test scheme and record exact totals.
- Build macOS and generic iOS without signing.
- Inspect both application bundles.
- Review correctness, readability, architecture, privacy/security, and
  performance.
- Update `Docs/CURRENT_STATUS.md` with exact evidence and unresolved manual
  boundaries.

## Parallel Ownership

- Agent A: Task 5 baseline failure classification and non-overlapping test fixes.
- Agent B: Task 3 semantic/localized progress.
- Agent C: Tasks 1-2 shared-container and path safety.
- Primary agent: Tasks 4 and 6, integration, verification, review, and status.
