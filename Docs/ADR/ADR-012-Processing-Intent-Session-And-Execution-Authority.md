# ADR-012: Processing intent, session and execution authority

Status: Release execution path implemented; production certification open
Original decision: 2026-10-07; implementation amendment: 2026-10-10
Owner authorization and pre-implementation decision record:
`Docs/03_Engineering/2026-10-07-processing-reliability-implementation.md`.

## Context

Task UUIDs protect task retries, not repeated Share output intentions. Job UI
and system schedulers represent different lifetimes. PhotoKit limited access
cannot manage user albums. Replacing durable intake/queue/receipt infrastructure
would discard essential recovery evidence.

## Decision

- `ProcessingIdentity` is a versioned output intent: materialized content or
  exact readable PhotoKit asset/version plus canonical frozen semantics. Keep
  media output, language, destination and description semantics; discard only
  transport snapshot UUID/time. Badge/avatar asset bytes participate where
  their reference is resolvable. Never hash arbitrary user text as a path.
- New identity-backed receipt records outlive visible job history. Legacy UUID
  records retain the existing migration/cleanup rules. Ambiguous PhotoKit
  outcomes never authorize a replacement save. Accounting uses a deterministic
  UUID derived from intent, so repeated receipt reuse does not consume another
  free record.
- Legacy tasks decode absent identity as nil and keep their exact UUID receipt
  keys. Completed historical inputs whose bytes are gone are not retroactively
  globally deduplicated. Missing/unreadable source identity remains an explicit
  compatibility limitation; do not describe all possible Share representations
  as globally certified until their physical matrix is complete.
- Session membership is an optional additive field on ledger-owned BatchJob.
  Consecutive admissions join a nonterminal session. Old jobs project their own
  UUID. Sessions project counters, not another queue or configuration owner.
- BatchQueueStore's execution arbiter owns a process-local generation lease.
  Foreground/grace may transfer; BGProcessing reserves before draining intake.
  Expiration matches the exact generation. Recovery normalization and loop
  quiescence precede release. Durable receipts remain recovery truth after death.
- Custom Live Activity follows session identity and counters. Continued owner
  suppresses custom requests/retries and ends tracked activities. A scheduling
  submission alone never acquires execution or presentation authority.
- DEBUG Continued Processing remains an expiring opt-in marker probe. It is
  separate from the Release adapter and never substitutes for production
  acceptance evidence.
- Release Share on iOS 26+ submits one Continued Processing task for the active
  durable continuation session. Overlapping Share admissions join that task
  through `ExternalIntakeRequestStore`; the callback drains requests serially
  under the shared execution lease and reports session progress. The existing
  BGProcessing recovery request is scheduled before Continued submission. If
  Photos authorization requires the host, or Continued submission fails, the
  existing host/BGProcessing recovery flow remains active. iOS 18–25 retain
  their existing BGProcessing and foreground recovery route.
- Add-only is recognized as creation capability but not admitted to the current
  readback-confirmed processing protocol. Explicit album requires full access;
  limited default destination becomes system library. Background never prompts.

## Consequences and gates

Preserves durable intake, actor ledger, frozen configuration, save receipts,
readback and Live Photo originals. The new schema is additive; no existing
queue is rewritten merely to adopt names. No Renderer/Layout changes or new UI.

Must prove multi-Share concurrency, different configuration, cancellation,
stale expiration, recovery, limited/full destinations and static/paired output.
iOS 18–25 immediate background scheduling remains deferred. The current
physical device runs iOS 27.2 Beta; it cannot certify stable iOS 26 or the full
supported OS matrix. Release source activation and generic Release compilation
do not establish physical Photos handoff, cancellation/expiration recovery,
or production certification.
