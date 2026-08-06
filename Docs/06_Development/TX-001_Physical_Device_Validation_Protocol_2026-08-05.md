# TX-001 Physical-Device Validation Protocol

Status: Deferred evidence collection; TX-001 remains open

Date: 2026-08-05

Primary loop: Engineering Loop

Risk: P0 - an Apple Photos commit that succeeds immediately before process
termination can be misunderstood as unfinished work and produce a duplicate
memory output after restart.

## Purpose

This protocol collects signed-device evidence for the export commit protocol.
It is intentionally deferred rather than treated as a routine manual test:
the relevant PhotoKit visibility and process-interruption window is rare in
ordinary use. Lack of an observed occurrence is not evidence that the window
cannot occur.

The protocol verifies the current recovery contract without changing product
behavior:

```text
PhotoKit commit accepted
-> task completion has not yet been durably persisted
-> app process terminates
-> app restarts
-> receipt identifies a visible exact PHAsset.localIdentifier
-> existing task completes without another render or Photos write
```

## Preconditions

- Use a signed physical iPhone with MemoMark granted its intended Photos
  access level.
- Record the device model, iOS version, MemoMark version and build number.
- Use a dedicated test album or record the output count before each attempt.
- Capture the free allowance count before the attempt when testing a free
  account.
- Keep the original input media identifiable. It must never be modified or
  deleted as part of this protocol.

## Required Evidence

### TX-001-D1 Static output, post-commit interruption

1. Share a static photo to MemoMark and begin processing.
2. When the task reaches the system-library save state, terminate MemoMark from
   the app switcher as quickly as practical.
3. Confirm whether a new output asset appears in Apple Photos.
4. Relaunch MemoMark and allow startup recovery to finish.

Pass criteria:

- when the output asset is visible, the original task reaches completed state;
- Apple Photos contains exactly one output for this operation;
- no second render or write begins after relaunch;
- the free allowance changes at most once;
- the original photo remains unchanged.

### TX-001-D2 Live Photo, post-commit interruption

Repeat TX-001-D1 with a Live Photo.

Additional pass criteria:

- the output remains a single Live Photo asset rather than a still-only output;
- Apple Photos long-press playback works after recovery;
- no duplicate Live Photo pair or duplicate still output is created.

### TX-001-D3 Immediate relaunch and delayed asset visibility

After forcing termination during the save stage, relaunch MemoMark immediately
and observe the first 30 seconds. Repeat with a short delay before relaunch
when practical.

Pass criteria:

- a not-yet-visible asset does not trigger a replacement Photos write;
- the receipt is retained while visibility remains ambiguous;
- once the exact receipt-backed asset is visible, a subsequent startup marks
  the task complete without duplicate output.

### TX-001-D4 Repeat-start idempotency

After a successful recovery in TX-001-D1 or TX-001-D2, restart MemoMark two or
three more times.

Pass criteria:

- completed state remains stable;
- output count remains one;
- allowance count does not increase again.

### TX-001-D5 Permission change during recovery

When feasible, change Photos permission after an interrupted attempt and
before relaunch.

Pass criteria:

- inaccessible readback is not silently interpreted as proof that no save
  occurred;
- no duplicate output is created;
- the user receives an actionable permission or recovery state.

## Observation Record

Record one row per attempt. Do not include private photos, filenames, people,
locations, or raw diagnostics that contain user content.

| Attempt | Scenario | Device / iOS | App build | Input media | Photos output before / after | Relaunch task state | Duplicate output | Live Photo playback | Allowance delta | Result / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  | Static / Live Photo |  |  | Yes / No | Pass / N/A |  |  |

For a failed attempt, retain only the local support ID and safe diagnostic
timestamps. Do not export or attach the user's media.

## Interpretation

- A pass in normal saving alone does not close TX-001-D1 or TX-001-D2; the
  evidence must include interruption and restart.
- An asset that is not yet visible immediately after restart is an expected
  ambiguous state. It is a failure only when MemoMark performs a second save,
  deletes a valid receipt prematurely, or loses the task's durable recovery
  path.
- TX-001 may be narrowed or closed only after the recorded device evidence is
  reviewed together with the remaining static-output readback, cancellation,
  and durable-receipt-write evidence.

## Non-Goals

- Forcing a production user to reproduce a rare interruption.
- Modifying the original photo or using a private-photo test archive.
- Claiming V3 production certification from simulator, unit-test, or a single
  successful manual save.
