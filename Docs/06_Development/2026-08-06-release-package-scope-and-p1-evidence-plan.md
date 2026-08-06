# Release Package Scope And P1 Evidence Plan

Date: 2026-08-06

Status: Active Release-Preparation Record; D1/D2 Local Commits Preserved

Primary loop: Engineering Loop

Risk: P1 for release integrity, user-facing claims, and the primary Apple
Photos workflow.

## Current State

The initial 110-file package has been split into independently reviewable local
commits. Slices A, B, and C are already preserved in local history; the Apple
Photos slice is preserved as D1 `2c92fe0` and D2 `d2a4a5c`. Slice E remains in
the worktree for final language, release-copy, localization, and state-record
review. GitHub has not been pushed.

## Observed Evidence

The local worktree is intentionally ahead of the last GitHub-synced baseline
`fe201be115e0a86dc944ac9f01a1178c086c34f5`. It currently combines product
refinement, queue-recovery hardening, localization, tests, release records,
and project-state updates across 110 changed or untracked files: `95` tracked
modifications and `15` untracked files.

Automated tests and unsigned builds have passed for the current local state,
but release packaging remains unsafe if all changes are treated as one
undifferentiated commit. The in-app release notes also currently contain
engineering terminology, historical test counts, and certification boundaries
that belong in internal records rather than in Settings -> About.

## Boundaries

- Do not change the marketing version or build number in this preparation
  slice. The final release identity is still `TBD`.
- Do not stage the remaining E files until their inventory and logical
  boundaries are reviewed.
- Do not claim that TX-001, BP-001, physical Apple Photos interruption
  evidence, or the superseding production certification is closed.
- Do not turn the full worktree into a generic cleanup commit, and do not use
  destructive Git operations to manufacture a commit history.
- Do not include private photos, datasets, generated install packages, device
  logs, or asset identifiers in the Git package.

## Release-Copy Slice

This bounded slice includes only the following audience-specific material and
its contract coverage:

- the Settings -> About -> What's New sheet and its Chinese and English
  localizations;
- the App Store Connect What's New draft;
- the TestFlight testing notes;
- the source-level release-note contract test;
- this release-package scope record.

The copy must remain truthful to implemented behavior:

- Time relationships use the photo capture time zone's calendar day, and
  birthday-day wording no longer displays a mechanical zero-day result.
- The Configuration Center, expression preview, appearance choice, Photo
  Description presentation, and small-device behavior were refined.
- Apple Photos save recovery and duplicate-result protection were strengthened,
  without promising that every interruption or delayed-visibility scenario has
  production certification.
- Photos remain on device and original Apple Photos assets remain unchanged.

The public and in-app notes must not include issue IDs, test counts, internal
module names, build-certification statements, or unresolved engineering
evidence. TestFlight notes may describe test paths and explicit validation
boundaries, but should use plain tester language.

## Planned Git Slices

After the release-copy slice is reviewed, organize the existing local work into
independently reviewable commits. File paths are an aid to inventory, not the
only grouping rule; each slice must include its coupled source, tests, and
records.

1. Memory expression and calendar-day compatibility: preserved locally.
2. Configuration Center and iPhone device-fit refinements: preserved locally.
3. Appearance and Photo Description presentation refinements: preserved
   locally.
4. Apple Photos receipt reconciliation and queue recovery hardening: preserved
   locally as D1 `2c92fe0` and D2 `d2a4a5c`.
5. Release records, language resources, and state documentation: active E
   worktree slice.

No slice may be staged until it has a clear behavior statement, affected
ownership boundary, private-data check, and focused verification evidence.

## Review Record

- Slice A, calendar-day Memory Expression, received an independent five-axis
  review on 2026-08-06 and is preserved in local commit `aaaa99da`. The review found and repaired one
  P1 compatibility gap: the active legacy card `AnchorResult` path used the
  device calendar while the canonical Memory Engine used
  `PhotoMetadata.captureCalendar`. Card construction now injects the capture
  calendar so both paths preserve the Capture-Time Principle.
- Red/green coverage first reproduced the mismatch, then verified birthday-day
  semantics in two distant capture time zones. The pre-staging review also
  found and repaired a registered-calculator path that still read
  `Calendar.current`: `RelativeTimeMemoryCalculator` now uses the existing
  `MemoryExpressionContext.captureCalendar`. Its regression test holds the
  device default time zone apart from the photo capture time zone. The focused
  Slice A tests and an unsigned generic-iOS `PhotoMemoiOS` Debug build pass
  after the repair. The review reconfirmed that the change does not alter
  Renderer, Layout Engine, metadata extraction, durable configuration,
  PhotoKit, export, or original-photo behavior.
- This Slice A review does not satisfy the final staging or push gate. It does
  not close TX-001, BP-001, physical-device Apple Photos validation, final
  release identity, or the superseding production certification.
- Slice D, Apple Photos receipt reconciliation and queue recovery, received an
  independent five-axis review on 2026-08-06 and is preserved in local commits
  `2c92fe0` and `d2a4a5c`. The review
  found and repaired one P1 Live Photo path: an exact asset readback that is
  temporarily unavailable after a durable receipt is now classified as
  recoverable rather than terminal. A readback that proves the result is not a
  Live Photo remains terminal.
- The focused receipt, queue-persistence, queue-execution, and Live Photo
  writer suites pass after the red/green repair. The review also reconfirmed
  identifier-scoped lookup, no replacement write while the receipt outcome is
  ambiguous, persistence before cleanup, and cancellation checks around the
  serial save gate.
- This review does not satisfy the final staging or push gate. In particular,
  it does not replace signed-device forced-termination and delayed-visibility
  evidence, nor does it close TX-001, BP-001, or the production certification
  carryover.
- Slice B, Configuration Center and device-fit refinement, received an
  independent five-axis review on 2026-08-06 and is preserved in local commit
  `301e1366`. The review
  repaired three P1 state-consistency paths without changing IA-002 ownership:
  the full editor retains its last valid Object Name while the field is empty;
  deleting the current Time Anchor atomically switches the active identifier,
  primary-anchor title, and reference date to a stable remaining anchor; and
  editing the current Time Anchor atomically refreshes those same projections.
- The Slice B regressions also verify that removing a noncurrent Time Anchor
  preserves the active identifier, primary-anchor title, and reference date.
  The focused macOS command passed all eight selected Configuration Center,
  device-fit, and Settings suites, and the unsigned generic-iOS
  `PhotoMemoiOS` Debug build passed. `git diff --check` was clean before the
  status-record update.
- Slice B does not satisfy the final staging or push gate. Manual iPhone
  visual layout, Dynamic Type, VoiceOver traversal, and nested Time Anchor
  sheet-dismissal semantics remain release-candidate acceptance work. It does
  not close TX-001, BP-001, Apple Photos interruption evidence, final release
  identity, or the superseding production certification.
- Slice C, Appearance and Photo Description presentation, received an
  independent five-axis review on 2026-08-06 and is preserved in local commits
  `94ffa9b`, `bdd1086`, and `6c413c8`. The review
  found no additional P1 defect: `MemoryWriteTextComposer` supplies one
  trimmed, newline-separated result to preview, Memory Module, production
  expression context, and final right-bottom Photo Description, so optional
  custom text is not duplicated downstream.
- The review also confirmed one persisted appearance preference and one iOS
  root projection. No global UIKit appearance override, Share Extension
  override, PhotoKit lifecycle change, Renderer change, Layout Engine change,
  or original-photo behavior change was introduced. Focused macOS suites,
  unsigned generic-iOS `PhotoMemoiOS` Debug build, localization syntax/key
  parity, and `git diff --check` passed.
- Slice C does not satisfy the final staging or push gate. Real iPhone
  acceptance remains required for System/Light/Dark behavior, Dynamic Type,
  VoiceOver, Photo Description interaction, and the non-guaranteed Apple
  Photos display/search presentation. It does not close TX-001, BP-001,
  Apple Photos interruption evidence, final release identity, or the
  superseding production certification.
- Slice E, release copy and governance, received an independent five-axis
  review on 2026-08-06 and remains the active worktree slice. The review confirmed that the
  in-app and App Store material stays short and nontechnical, the TestFlight
  notes contain actionable real-device checks without internal issue IDs, and
  only the internal changelog carries P0 and certification detail.
- The review repaired one P1 truth issue in the TestFlight draft: "local
  calendar day" could be interpreted as device time. The draft now correctly
  specifies the photo capture time zone's calendar day. A new release-note
  contract assertion failed before the wording repair and passed afterward.
  Focused `V1ReleaseNotesContractTests`, localization syntax/key parity, and
  `git diff --check` pass.
- Slice E does not satisfy the final staging or push gate. Final version/build
  identity and all physical-device release-candidate evidence remain open; the
  copy does not claim TX-001, BP-001, Apple Photos interruption evidence, or
  superseding production certification closure.

## Verification Plan

For the release-copy slice:

1. Run the focused `V1ReleaseNotesContractTests`.
2. Verify Simplified Chinese and English localization files parse and expose
   matching release-note keys.
3. Run `git diff --check`.
4. Build and run broader tests only after the source/localization changes are
   complete.

Before any push:

1. Re-inventory changed and untracked files, including a private-data and
   generated-artifact scan.
2. Review each proposed commit slice separately, with its source, tests, docs,
   and evidence.
3. Confirm the final version and build identity.
4. Complete the required physical-device acceptance that applies to the
   release candidate, especially the remaining Apple Photos recovery,
   accessibility, and appearance checks.
5. Re-run the final test, build, diff, and package review. A push is permitted
   only after those checks and an explicit user-facing release decision.
