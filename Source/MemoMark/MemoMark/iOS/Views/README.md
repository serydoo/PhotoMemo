# iOS Views Map

Last updated: 2026-09-03

This folder remains physically flat because the Xcode project uses
`PBXFileSystemSynchronizedRootGroup`. The organization below is logical and
is the source map for the current active implementation. Do not create nested
folders or move files solely for visual tidiness; a move must have an owner
change, updated contracts, and a build verification record.

Use this grouping when looking for code:

- Configuration Center root and composition
  - `MemoMarkConfigurationCenterView.swift`
  - `MemoMarkConfigurationCenterView+*.swift`
  - `MemoMarkConfigurationCenterDependencies.swift`
  - `ConfigurationCenter*`
  - `ConfigurationDraftProjection.swift`
  - `ConfigurationPersistenceStatus.swift`
- Entry, root lifecycle, and navigation
  - `Entry*`
  - `Welcome*`
  - `Adaptive*`
  - `Root*`
- Configuration, library, modules, and presets
  - `Configuration*`
  - `LocalConfigurationLibrary*`
  - `ModuleLibrarySurface.swift`
  - `Preset*`
  - `LogoAssetSelectionCoordinator.swift`
- Memory Card editor and preview
  - `MemoryCard*`
  - `MemoryWriteTextPresenter.swift`
  - `MemoryCardPreview*`
  - `PreviewDraftAdapter.swift`
  - `PreviewSyncCoordinator.swift`
- Home and task presentation
  - `Home*`
  - `Task*`
  - `TimeAnchor*`
  - `Subject*`
- Photo intake and foreground processing
  - `PhotoIntake*`
  - `PhotoProcessingQuickActionCoordinator.swift`
  - `UIKitPhotoPicker.swift`
- Settings and support content
  - `Settings*`
  - `About*`
  - `Community*`
  - `DataSafety*`
  - `Feedback*`
  - `GettingStarted*`
  - `MemoMarkPlus*`
- Diagnostics and system surfaces
  - `Diagnostics*`
  - `ReleaseNotesSheet.swift`
  - `MemoMarkiOSBackgroundStatusSheet*`
  - `IOSCompactEntryRow.swift`

Naming and compatibility rules:

- New active files use responsibility-based names; do not introduce new
  stage-based `V1*` names.
- Existing `V1*` bridge files are not a second product entry. They remain
  until a separately verified compatibility-naming slice removes or renames
  them without changing persisted keys, pasteboard types, or schema values.
- The retired `ConfigurationCenteriOSView.swift` and the temporary dual-entry
  switcher are not part of the active tree.
- The production iOS root is `MemoMarkConfigurationCenterView`.
- Picker presentation, intake resolution, snapshot capture, queue submission,
  PhotoKit output, and durable state must remain in their existing owners;
  this folder is a presentation and lifecycle-adapter surface, not a second
  domain or persistence layer.
