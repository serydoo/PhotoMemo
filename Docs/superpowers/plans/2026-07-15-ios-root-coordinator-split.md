# iOS Root Coordinator Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce `PhotoMemoiOSV1View` to iOS root-state ownership and event coordination by extracting navigation, Logo handling, configuration-library actions, and backup/restore orchestration without changing IA-002 or user behavior.

**Architecture:** Keep SwiftUI state in the root view and extract concrete, `@MainActor` coordinators that accept immutable inputs and return typed updates. Existing page surfaces remain unchanged. Persistence, session projection, draft refresh, and preview refresh continue to be applied by the root view.

**Tech Stack:** SwiftUI, PhotosUI, Swift Testing, existing Configuration Center coordinators, Xcode 26.6.

---

### Task 1: Extract Entry Navigation State

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/EntryNavigationState.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1EntryFlowCoordinatorTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/IPhoneResponsiveLayoutContractTests.swift`

- [ ] Add a value-type `EntryNavigationState` that owns `V1EntryFlowState`, expanded editor sections, profile/preview scroll offsets, and transition forwarding.
- [ ] Keep `@AppStorage hasSeenWelcome`, import processing, View builders, and runtime side effects in `PhotoMemoiOSV1View`.
- [ ] Replace root scalar navigation fields with one `@State` value and explicit bindings.
- [ ] Add tests for compact/regular Settings transitions and preservation of unrelated sheet state.
- [ ] Run entry-flow and responsive-layout tests, then build `PhotoMemoiOS` for a generic iOS Simulator.
- [ ] Commit as `Extract iOS entry navigation state`.

### Task 2: Extract Logo Asset Coordination

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/LogoAssetCoordinator.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Test: `Tests/PhotoMemoTests/RendererTests/LogoAssetOptimizationServiceTests.swift`
- Create: `Tests/PhotoMemoTests/ArchitectureTests/LogoAssetCoordinatorTests.swift`

- [ ] Wrap existing `V1LogoSelectionCoordinator` optimization and update mapping in a concrete `@MainActor` coordinator.
- [ ] Return typed updates for busy state, Logo mode, badge, status message, and configuration dirty state; do not retain the SwiftUI view or session.
- [ ] Preserve Apple mini-logo fallback, subject avatar behavior, and existing managed asset paths.
- [ ] Do not introduce old-Logo deletion; cleanup requires a separate referenced-asset policy.
- [ ] Run Logo tests and generic iOS Simulator build.
- [ ] Commit as `Extract Logo asset coordination`.

### Task 3: Extract Configuration Library Actions

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationLibraryActions.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1LocalConfigurationLibraryPresenterTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1HomeConfigurationActionContractTests.swift`

- [ ] Extract create/reset/rename/save/activate/delete user intents behind typed request/result values.
- [ ] Keep `ConfigurationSession`, draft bootstrap, preview refresh, and user feedback application in the root view.
- [ ] Preserve dirty-before-delete/save, last-durable-configuration protection, sibling selection, receipt revision, and composer refresh contracts.
- [ ] Update source-contract tests to inspect the new owner rather than deleting behavior assertions.
- [ ] Run presenter/action tests and generic iOS build.
- [ ] Commit as `Extract configuration library actions`.

### Task 4: Extract Backup And Restore Coordination

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationBackupRestoreCoordinator.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationImportCoordinatorTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/LocalConfigurationLibraryRepositoryTests.swift`
- Create: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationBackupRestoreCoordinatorTests.swift`

- [ ] Extract backup, list, delete, import, restore, asset URL collection, security-scoped access, and error mapping.
- [ ] Return typed results containing receipts, aggregate, warnings, backups, and status; never mutate SwiftUI state directly.
- [ ] Keep restored aggregate application, draft projection, preview refresh, and current-configuration application in the root view.
- [ ] Preserve make-current semantics, security-scope start/stop pairing, revision reconciliation, missing-asset warnings, and failure retention of the previous backup list.
- [ ] Run import/repository/coordinator tests and generic iOS build.
- [ ] Commit as `Extract configuration backup and restore coordination`.

### Task 5: Final Review And Status

- [ ] Confirm `PhotoMemoiOSV1View` owns state/side effects but no longer implements the extracted action bodies.
- [ ] Run focused tests, serial `PhotoMemoTests build-for-testing`, and generic iOS App build.
- [ ] Run `git diff --check` and review for dead helpers.
- [ ] Update `Docs/CURRENT_STATUS.md` with verified facts and unverified device behavior.
- [ ] Push the branch and integrate only after spec and quality review pass.
