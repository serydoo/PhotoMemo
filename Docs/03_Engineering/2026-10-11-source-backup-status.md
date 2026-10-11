# Source backup status — 2026-10-11

This concise, repository-safe status accompanies the internal 2.3.6 (124)
source checkpoint. The full local `Docs/CURRENT_STATUS.md` remains the working
chronicle and is excluded from this candidate because it contains personal
contact details, device identifiers, and machine-local paths in historical
entries. No history was rewritten or deleted.

## Included engineering changes

- Configuration Center landscape/portrait sizing and preview/header alignment
  were refined, with rotation-focused UI contracts added. Physical rotation and
  portrait-restoration acceptance remains open where the device UI runner did
  not complete.
- Share/processing contracts, completion and interruption notification
  behavior, admission diagnostics, and recovery accounting were tightened.
  Ordinary Share now durably records intake, schedules recovery, and hands the
  request to MemoMark so the app resolves canonical configuration and owns the
  visible progress state.
- The sandbox purchase entitlement snapshot path was aligned across the main
  app and Share extension. This is a sandbox QA correction, not a new commerce
  entitlement or a StoreKit production certification.
- The release-audit remediation and its source-of-truth engineering records
  are included in the explicit allowlist. Open device and production gates are
  stated in those records.

## Evidence and boundary

- Share/background contracts: 3 passed, 0 failed.
- Formal Xcode 27.0 iOS Release build and signed 2.3.6 (124) install/launch on
  the paired iPhone 17 Pro Max: passed.
- Release Share UI automation: not verified; the physical XCUITest runner
  exited before test connection, and did not execute a Photos Share.
- This is a source backup checkpoint, not a new app release. No claim is made
  that the App Store build changed or that all lifecycle/device acceptance is
  closed.
