# ADR-012: Processing intent, session and execution authority

Status: Implementation under verification; production certification open
Date: 2026-10-07
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
- DEBUG Continued Processing is an expiring opt-in marker probe. It leaves real
  durable intake pending and never opens the host or runs the full queue.
  Only signed Photos-extension/host evidence can authorize full queue hookup.
- Add-only is recognized as creation capability but not admitted to the current
  readback-confirmed processing protocol. Explicit album requires full access;
  limited default destination becomes system library. Background never prompts.

## Consequences and gates

Preserves durable intake, actor ledger, frozen configuration, save receipts,
readback and Live Photo originals. The new schema is additive; no existing
queue is rewritten merely to adopt names. No Renderer/Layout changes or new UI.

Must prove multi-Share concurrency, different configuration, cancellation,
stale expiration, recovery, limited/full destinations and static/paired output.
iOS 18–25 scheduling remains deferred. Available device is iOS 27.2 Beta; that
cannot certify iOS 26 or the full supported OS matrix. Until signed marker
handoff passes, Continued Processing is not enabled for production BatchQueue.
