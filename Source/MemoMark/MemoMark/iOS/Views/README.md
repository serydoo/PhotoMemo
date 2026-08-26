# iOS Views Map

Last updated: 2026-08-26

This folder is still physically flat because the Xcode project uses filesystem-synchronized groups and the repository keeps long handoff histories with direct file links.

Use this logical grouping when looking for code:

- Configuration Center
  - `ConfigurationCenteriOSView.swift`
  - `ConfigurationCenter*`
  - `IOSConfigurationPanel.swift`
  - `MemoryWriteOptionPresenter.swift`
- V1 shell and subject flow
  - `MemoMarkiOSV1View.swift`
  - `V1Configuration*`
  - `V1Draft*`
  - `V1Preview*`
  - `V1IOSSubject*`
  - `V1SubjectHomeSummarySupport.swift`
- Home
  - `MemoMarkiOSHomeView.swift`
  - `MemoMarkiOSBackgroundStatusSheet.swift`
  - `V1IOSHome*`
- Diagnostics and support
  - `MemoMarkiOSProcessingDiagnosticsSnapshot.swift`
  - `MemoMarkiOSQueueDiagnosticsProjectionEngine.swift`
  - `V1DiagnosticsRefreshCoordinator.swift`
  - `MemoMarkiOSModuleCatalog.swift`
  - `IOSCompactEntryRow.swift`

Current rule:

- New iOS Configuration Center helpers should prefer the `ConfigurationCenter*` prefix.
- New V1 shell helpers should prefer the `V1*` prefix.
- The retired temporary dual-entry switcher has been removed. The production
  iOS root owns one accepted entry through `MemoMarkiOSV1View`.
- Do not move files physically just for tidiness unless the slice also updates historical docs and verifies Xcode target membership afterward.
