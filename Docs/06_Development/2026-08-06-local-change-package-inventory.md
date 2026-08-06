# Local Change Package Inventory

Date: 2026-08-06

Status: Historical Pre-Commit Inventory; Slice Commits Now Preserved Locally

Baseline: `fe201be115e0a86dc944ac9f01a1178c086c34f5`

## Snapshot

The initial local snapshot contained 110 changed or untracked files. It was not
ready for an all-at-once commit or GitHub push. Slices A through D have since
been reviewed and preserved in local commits; the current worktree retains the
release-language and governance slice only.

- `95` tracked files are modified and `15` files are untracked.
- Source view files account for about 31 percent of changed-file locations.
- Architecture contract tests account for about 24 percent.
- No new private photos, videos, archives, install packages, or device logs are
  present among untracked files.
- No project-file, entitlement, signing, marketing-version, or build-number
  change is part of the local package.

This inventory assigns every change a primary review slice. Its file counts are
the initial snapshot, while the commit references and current push gate below
describe the later local state.

## Slice A: Calendar-Day Memory Expression

Purpose: make time-anchor relationships use capture-calendar-day semantics,
including the dedicated birthday-day expression.

Primary source:

- `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/BirthdayAgeCalculator.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/BirthdayAgeExpressionProvider.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchorExpressionResolver.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryVariableProvider.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/RelativeTimeMemoryCalculator.swift`
- `Source/PhotoMemo/PhotoMemo/Models/MemoryAnchorExpressionStyle.swift`
- `Source/PhotoMemo/PhotoMemo/Models/MemoryAnchorVariableTextFormatter.swift`
- `Source/PhotoMemo/PhotoMemo/Models/MemoryResultVariableProjector.swift`

Coupled tests and records:

- `Tests/PhotoMemoTests/ArchitectureTests/MemoryExpressionEngineTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MemoryResultContractTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1TimeAnchorEntryPresenterTests.swift`
- `Tests/PhotoMemoTests/MemoryEngineTests/MemoryAnchorTextFormatterTests.swift`
- `Tests/PhotoMemoTests/MemoryEngineTests/MemoryEngineTests.swift`
- `Docs/06_Development/Birthday_Anchor_Day_Expression_Spec_2026-08-04.md`
- `Docs/PM-003_Content_Layout_System.md`

Review focus: date boundaries, birthday-day wording, legacy compatibility,
before/on/after expression semantics, and no layout or Renderer ownership
change.

## Slice B: Configuration Center And Device-Fit Refinement

Purpose: improve active Configuration Center and Memory Subject editing
readability without changing frozen IA-002 ownership.

Primary source:

- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Components/InspectorSectionView.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/SubjectAvatarCropSheet.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift`
- `Source/PhotoMemo/PhotoMemo/Models/AnchorType.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSessionBindingPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterTopPreviewSection.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdvancedModulesSheet.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationPageSurface.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeCardPrimitives.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeProjection.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewCardSections.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsExpressionGuide.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectPresentationModifier.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift`

Coupled tests and records:

- `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterMemoryDisplaySupportTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterSessionBindingPresenterTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/IPhoneResponsiveLayoutContractTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/TimeAnchorEditingTransactionTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationOptionListContractTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1DesignFreezePolishContractTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1IOSHomeProjectionTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1IOSSubjectOverviewPresenterTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1SettingsDisclosureContractTests.swift`
- `Docs/01_Product/V4_Configuration_Center_Anchor_Preview_Refinement_2026-08-05.md`
- `Docs/01_Product/V4_Interface_Language_Refinement_2026-08-05.md`

Review focus: Dynamic Type fallback, VoiceOver names, native sheet controls,
subject-name durability, and preservation of
`Library -> Interactive Memory Card -> Object Inspector`.

## Slice C: Appearance And Photo Description Presentation

Purpose: apply the iOS appearance choice and place Photo Description in a
clearer output-page card without creating a view-owned text-composition path.

Primary source:

- `Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift`
- `Source/PhotoMemo/PhotoMemo/Models/MemoryWriteTextComposer.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MemoryWriteOptionPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ResolvedMemoryWriteTextPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift`

Coupled tests and records:

- `Tests/PhotoMemoTests/ArchitectureTests/AppleNativeProductSurfaceContractTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterOutputPanelPresenterTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationSessionLayerTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MemoryWriteOptionPresenterTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1OutputMemoryWritePresenterTests.swift`
- `Docs/01_Product/V4_Output_Photo_Description_Card_Refinement_2026-08-06.md`
- `Docs/01_Product/V4_System_Appearance_Refinement_2026-08-06.md`

Review focus: system/light/dark persistence, no output-image color change,
one canonical Photo Description composer, and direct user-controlled text
joining.

## Slice D: Apple Photos Receipt And Queue Recovery

Purpose: fail closed after an ambiguous Apple Photos save, preserve durable
receipt-backed recovery, and avoid replacement outputs.

Primary source:

- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoSaveRequest.swift`
- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift`
- `Source/PhotoMemo/PhotoMemo/Models/ProductionDiagnosticEvent.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueuePersistence.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskFailurePolicy.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`

Coupled tests and records:

- `Tests/PhotoMemoTests/ArchitectureTests/ProductionConfigurationContractTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/ProductionDiagnosticsTests.swift`
- `Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift`
- `Tests/PhotoMemoTests/BatchTests/BatchQueueStorePersistenceTests.swift`
- `Tests/PhotoMemoTests/ExportTests/PhotoLibrarySaveReceiptStoreTests.swift`
- `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
- `Docs/06_Development/TX-001_Export_Commit_Protocol_Spec_2026-08-05.md`
- `Docs/06_Development/TX-001_Physical_Device_Validation_Protocol_2026-08-05.md`
- `Docs/06_Development/TX-001_Queue_Receipt_Reconciliation_Spec_2026-08-05.md`

Review focus: exact `PHAsset.localIdentifier` readback only, no duplicate
Photos write, cancellation before an external mutation, durable state before
cleanup, and the still-open physical-device evidence.

## Slice E: Language, Release Copy, And Release Governance

Purpose: keep product language, localizations, release audiences, and current
status records truthful and internally consistent.

Primary source and records:

- `AGENTS.md`
- `Docs/CURRENT_STATUS.md`
- `Docs/Guidelines/LANGUAGE_SYSTEM.md`
- `Docs/Guidelines/PRODUCT_LANGUAGE_GUIDE.md`
- `Docs/06_Development/2026-08-06-overall-change-stability-and-structure-audit.md`
- `Docs/06_Development/2026-08-06-release-package-scope-and-p1-evidence-plan.md`
- `Docs/06_Development/2026-08-06-local-change-package-inventory.md`
- `Docs/07_Releases/2026-08-06-2.0.3-app-store-whats-new.md`
- `Docs/07_Releases/2026-08-06-2.0.3-internal-changelog.md`
- `Docs/07_Releases/2026-08-06-2.0.3-testflight-notes.md`
- `Source/PhotoMemo/PhotoMemo/Models/MemoMarkLanguage.swift`
- `Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings`
- `Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ReleaseNotesSheet.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MemoMarkCommerceUIContractTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MemoMarkNarrativeLanguageContractTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1ReleaseNotesContractTests.swift`

Review focus: distinct in-app, App Store, TestFlight, and internal language;
Chinese/English key parity; no internal issue identifiers or certification
claims in general-user copy; and no final version/build claim before it is
chosen.

## Staging Protocol

1. Keep the worktree unstaged while reviewing the slice map.
2. For each slice, inspect its complete diff and its coupled tests before
   staging any file.
3. Stage only that slice's listed files and run its focused verification.
4. Review the staged diff for private data and accidental generated artifacts.
5. Commit with one behavioral subject. Do not amend unrelated commits.
6. Re-run the full suite and required builds after all slices are integrated.
7. Keep the locked `2.0.3 (70)` identity consistent across project settings,
   release records, and build products.
8. GitHub synchronization may preserve this reviewed source checkpoint;
   physical-device Apple Photos recovery, appearance, Dynamic Type, VoiceOver,
   and language acceptance remain gates for release authorization.

## Current Source Checkpoint Gate

The GitHub source checkpoint is approved after package review, version lock,
and automated verification. Release authorization remains separate:

- Slice A is preserved in `aaaa99da`;
- Slice B is preserved in `301e1366`;
- Slice C is preserved in `94ffa9b`, `bdd1086`, and `6c413c8`;
- Slice D is preserved in `2c92fe0` and `d2a4a5c`; Slice E is preserved in
  `dd5a197` and `47bb375`;
- marketing version `2.0.3` and build `70` are locked and verified across all
  product bundles;
- the complete test suite and unsigned macOS/generic-iOS Debug builds pass;
- physical-device evidence for Apple Photos interruption and delayed visibility
  remains open;
- final visual, accessibility, and TestFlight-candidate acceptance remains
  pending;
- TX-001, BP-001, and the superseding production certification are not closed.
