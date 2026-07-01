# iOS Views Map

Last updated: 2026-07-01

This folder is still physically flat because the Xcode project uses filesystem-synchronized groups and the repository keeps long handoff histories with direct file links.

Use this logical grouping when looking for code:

- Configuration Center
  - `ConfigurationCenteriOSView.swift`
  - `ConfigurationCenter*`
  - `IOSConfigurationPanel.swift`
  - `MemoryWriteOptionPresenter.swift`
- V1 shell and subject flow
  - `PhotoMemoiOSV1View.swift`
  - `V1Configuration*`
  - `V1Draft*`
  - `V1Preview*`
  - `V1IOSSubject*`
  - `V1SubjectHomeSummarySupport.swift`
- Home
  - `PhotoMemoiOSHomeView.swift`
  - `PhotoMemoiOSBackgroundStatusSheet.swift`
  - `V1IOSHome*`
- Diagnostics and support
  - `PhotoMemoiOSProcessingDiagnosticsSnapshot.swift`
  - `PhotoMemoiOSQueueDiagnosticsProjectionEngine.swift`
  - `V1DiagnosticsRefreshCoordinator.swift`
  - `PhotoMemoiOSTemporaryEntryView.swift`
  - `PhotoMemoiOSModuleCatalog.swift`
  - `IOSCompactEntryRow.swift`

Current rule:

- New iOS Configuration Center helpers should prefer the `ConfigurationCenter*` prefix.
- New V1 shell helpers should prefer the `V1*` prefix.
- Do not move files physically just for tidiness unless the slice also updates historical docs and verifies Xcode target membership afterward.
