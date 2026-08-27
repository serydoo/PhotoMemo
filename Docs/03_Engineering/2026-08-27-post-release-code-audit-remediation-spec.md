# MemoMark Post-Release Code Audit Remediation Spec

**Date:** 2026-08-27
**Primary loop:** Engineering Loop
**Risk:** P1 reliability work with bounded P2 hygiene
**Stage:** Approved for implementation by the 2026-08-27 user direction

## Objective

Close the bounded, evidence-backed engineering findings from the 2026-08-27
post-release code audit without reopening MemoMark's frozen product flow,
Configuration Center architecture, renderer ownership, or V4 Expression Style
research scope.

Success means that queue durability no longer depends on an ever-growing
UserDefaults blob, shared-container migration copies only MemoMark-owned keys,
managed-intake containment is component-safe, persisted processing state can be
localized at presentation time, the current test gate is reconciled with
accepted behavior, and release bundles contain only intended resources.

## Explicit User Decisions And Exclusions

The following findings are intentionally preserved in their current state:

- `P0-1` high-resolution peak-memory verification and related execution changes
  are deferred because the required verification cannot currently be completed.
- `P0-2` EXIF timezone interpretation remains unchanged. MemoMark does not add a
  separate EXIF offset-time policy in this remediation.

This work must not:

- change `PhotoMetadataReader` capture-time behavior;
- change media-memory admission, decode, render, or export concurrency;
- change Renderer, Layout Engine, export geometry, metadata output, Live Photo
  pairing, PhotoKit commit semantics, or original-photo handling;
- redesign the Configuration Center or restore retired `MainView`/Workspace
  concepts;
- implement the V4 Expression Style System;
- add a third-party dependency.

## Observed Engineering Evidence

- The 2026-08-27 full `MemoMarkTests` run completed with `1550` passed, `31`
  failed, and `1` skipped out of `1582` tests.
- The queue currently persists the full `[BatchJob]` projection as one
  UserDefaults data value and rewrites it during task-state transitions.
- shared-defaults migration currently enumerates all standard-defaults keys.
- three managed-intake checks use raw string-prefix containment while the
  canonical file store uses path-component-aware containment.
- persisted batch progress contains Chinese presentation strings.
- the main app bundles currently include `README.md` and the Share Extension's
  nested Info.plist as resources.

## Ownership And Dependency Flow

The accepted dependency flow remains:

`Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export`

This remediation is limited to infrastructure surrounding that flow:

- queue persistence owns durable batch projections;
- shared-container policy owns App Group migration and directory identity;
- batch progress owns semantic processing state, while presentation owns
  localized user-facing text;
- tests validate behavior and separately enforce accepted architecture/source
  contracts;
- Xcode target configuration owns bundle resource membership.

## Apple-Native Capabilities Evaluated

- Foundation atomic file replacement for queue snapshots;
- App Group container URLs for cross-lifecycle durable storage;
- Codable schema compatibility for legacy queue migration;
- `URL.standardizedFileURL` plus path-component-aware descendant checks;
- String Catalog/Localizable format keys for dynamic interface and VoiceOver
  copy;
- Xcode file-system-synchronized build-file exclusions for bundle hygiene.

No new storage framework or package is justified for this bounded pass.

## Implementation Slices

### Slice 1 — Component-Safe Managed Intake Containment

- Add regression tests for sibling-prefix paths and the managed root itself.
- Route queue persistence, failure policy, and resource lifecycle checks through
  one component-safe containment rule.
- Preserve existing cleanup and retry behavior for valid managed URLs.

### Slice 2 — Shared Defaults Migration Allowlist

- Define the explicit MemoMark-owned legacy-default keys eligible for migration.
- Test that eligible keys migrate, existing shared values win, unrelated keys do
  not migrate, and the migration marker remains durable.
- Preserve test injection and App Group readiness behavior.

### Slice 3 — Semantic Batch Progress Presentation

- Introduce a backward-compatible semantic progress phase or localization key.
- Persist semantics rather than new finalized Chinese status copy.
- Localize at presentation time for Chinese, English, Japanese, and Korean.
- Add format-key coverage for affected dynamic accessibility labels.
- Preserve decoding of existing queues that contain only `statusMessage`.

### Slice 4 — File-Backed Queue Snapshot Foundation

- Add an atomic, read-back-verified file backend behind the existing persistence
  protocol.
- Make it the production default in the App Group container.
- On first load only, migrate an existing UserDefaults queue snapshot when no
  file snapshot exists; never overwrite an existing file with legacy data.
- Keep persistence failure fail-closed and preserve the last durable projection.
- Do not change queue scheduling or media execution concurrency.

### Slice 5 — Test-Gate Reconciliation

- Classify every existing failure as behavioral, environmental, fixture, or
  source-contract drift.
- Repair production behavior when an accepted contract is violated.
- Update brittle source contracts only when current accepted architecture and
  product language are already correct.
- Do not skip, disable, or silently weaken failing behavior tests.

### Slice 6 — Bundle Hygiene And Bounded Platform Maintenance

- Exclude `README.md` and nested target Info.plists from unrelated app bundles.
- Apply only source-compatible deprecation replacements that do not alter
  output naming or PhotoKit behavior.
- Do not delete uncertain legacy UI or non-empty source files in this pass.

## Testing Strategy

Use Swift Testing/XCTest already present in `Tests/MemoMarkTests`.

For behavior changes, follow RED -> GREEN -> REFACTOR:

- first add or identify a test that demonstrates the current defect;
- make the smallest production change;
- run the focused suite;
- run the complete `MemoMarkTests` scheme after integration;
- build macOS and generic iOS without signing;
- do not use the iOS Simulator for product verification.

Primary commands:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMarkTests -configuration Debug -derivedDataPath /tmp/MemoMarkRemediationTests -destination 'platform=macOS' test

xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMark -configuration Debug -derivedDataPath /tmp/MemoMarkRemediationMac CODE_SIGNING_ALLOWED=NO -quiet build

xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMarkiOS -configuration Debug -derivedDataPath /tmp/MemoMarkRemediationIOS -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO -quiet build
```

## Success Criteria

- The two deferred P0 areas have no production-code changes.
- Managed-intake sibling-prefix paths are never classified as descendants.
- Unrelated standard-default keys are not copied into the App Group.
- New queue state is durably file-backed with safe legacy import and read-back
  verification.
- Existing UserDefaults queue data remains recoverable during migration.
- Current-language presentation does not depend on persisted Chinese progress
  strings.
- The complete test run has no unexplained failure. Any environment-only test
  boundary is deterministic and explicitly modeled rather than skipped.
- macOS and generic iOS builds succeed.
- main app bundles do not contain `README.md` or the Share Extension Info.plist.
- `git diff --check` passes and all changes receive five-axis review.

## Manual Verification Boundary

This remediation does not claim physical-device acceptance for PhotoKit,
Share Extension lifecycle, memory pressure, VoiceOver, Dark Mode, Dynamic Type,
or Live Photo processing unless those checks are separately executed and
recorded. Source and automated verification must not be described as a new
production certification.
