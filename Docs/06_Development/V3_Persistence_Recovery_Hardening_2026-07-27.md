# V3 Persistence And Recovery Hardening

Date: 2026-07-27
Status: Implemented and verified
Primary loop: Engineering Loop
Risk: P0/P1

## Evidence

The current checkout has verified gaps at failure boundaries rather than in the
normal-path persistence tests:

- a Share intake request can be acknowledged after queue persistence fails;
- corrupt intake metadata can be followed by managed-file orphan cleanup;
- stale complete configuration aggregates can overwrite unrelated newer saves;
- canonical corruption can be hidden by legacy compatibility state or mock UI;
- one corrupt local backup can block healthy backups and prevent self-repair;
- restored avatar or custom Logo assets are validated in the backup location but
  are not copied into the App Group runtime location;
- stale Live Activities and generated attachment files lack complete lifecycle
  reconciliation.

## Ownership Boundaries

- Apple Photos continues to own original assets. This pass never modifies or
  deletes an original Photos asset.
- External intake storage owns staged Share copies until a durable queue commit
  succeeds.
- `BatchQueueStore` owns the durable queue commit result.
- `ConfigurationLibraryRecord` remains the sole canonical saved configuration
  truth; legacy settings remain compatibility projections only.
- `LocalConfigurationLibraryRepository` owns backup-file isolation, while
  `ConfigurationAssetPackager` owns verified asset transfer.
- ActivityKit owns system presentation; MemoMark owns reconciliation against the
  current durable queue.

## Apple-Native Evaluation

No new permission, cloud service, background entitlement, or Photos capability
is required. Existing App Group storage, security-scoped file access, Swift
Concurrency, atomic file replacement, PhotoKit receipts, and ActivityKit end
semantics remain the correct platform boundaries.

## Bounded Implementation

1. Make queue admission report durable commit failure and keep Share requests
   and staged files until the queue commit succeeds.
2. Suppress orphan cleanup whenever intake metadata cannot be decoded.
3. Reject stale canonical aggregate saves instead of renumbering and overwriting
   newer truth; preserve startup corruption and migration-failure diagnostics.
4. Isolate corrupt local backups, allow a newer valid backup to self-repair, and
   copy verified restored assets into the App Group before saving the aggregate.
5. Clear mock configuration state on recovery, preserve real dirty edits across
   switching decisions, reconcile stale Live Activities, and reclaim unreferenced
   generated files.

## Verification

- Every bug starts with a focused failing Swift Testing regression.
- Run focused suites after each bounded implementation slice.
- Run the broader configuration, queue, Share, import, ActivityKit, and resource
  lifecycle suites after integration.
- Run `git diff --check`, a generic unsigned build, then a signed iOS build.
- Overwrite-install on the paired physical iPhone 17 Pro Max, launch, confirm the
  process remains live, and check for new crash reports.
- Corrupt-file and disk-write-failure scenarios remain automated tests; do not
  destructively inject them into the user's device data.

## Result

- Share admission now rolls back the in-memory queue when durable persistence
  fails, leaving the intake request and staged files available for retry. A
  persisted Share request identity makes acknowledgement retries reuse the same
  durable job instead of creating duplicate outputs.
- Canonical configuration recovery never replaces an existing corrupt primary
  with legacy defaults. Stale aggregate saves are rejected, and file-backed
  compare-and-replace is serialized across repository instances in the app
  process.
- Corrupt local backups no longer block healthy entries or self-repair. Restore
  copies verified avatar and Logo assets into managed runtime storage before
  committing the aggregate and removes newly created files on failure. Restore
  operations are serialized, and unmanaged absolute asset references are
  rejected before packaging.
- Configuration and subject switching protect dirty, failed-save, and
  subject-synced edits. Recovery clears transient mock presets instead of
  presenting them as durable user state.
- Live Activity startup ends invalid, duplicate, and stale activities. Invalid
  requests are suppressed per job, transient failures schedule a real delayed
  15-second retry, and service-level failures disable requests for the current
  run.
- Queue history cleanup is reference-aware and runs only after durable queue
  persistence succeeds. Terminal and cancelled tasks also retain their managed
  source until the terminal queue state is durably committed. Notification
  attachments use a two-observation cleanup boundary.

Automated evidence on 2026-07-27:

- focused configuration, migration, backup, Share, queue, session, ActivityKit,
  and resource-lifecycle suites passed;
- the complete serialized `PhotoMemoTests` suite passed 1,153 tests with one
  existing skip and zero failures;
- `git diff --check` passed;
- unsigned macOS `PhotoMemo` Debug and signed generic iOS `PhotoMemoiOS` Debug
  builds passed;
- the final generic iOS build is development-signed and passes strict signature
  verification. Earlier `2.0 (47)` hardening builds were overwrite-installed and
  launched on the paired physical iPhone 17 Pro Max without clearing local data;
  the final review follow-up was not reinstalled during this repository-sync pass.

Corrupt backup files are isolated rather than deleted. A future diagnostics
surface may expose quarantine and explicit cleanup; this is not a data-loss or
runtime blocker for the current pass.
