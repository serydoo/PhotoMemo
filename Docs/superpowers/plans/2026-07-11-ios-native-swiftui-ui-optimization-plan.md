# MemoMark iOS Native SwiftUI UI Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply system-native interaction polish across MemoMark iOS while preserving current content, Configuration Center preview, real-time configuration delivery, Share intake, background tasks, and Apple Photos behavior.

**Architecture:** Keep existing sessions, presenters, coordinators, callbacks, and UIKit Share lifecycle authoritative. Replace only generic interaction shells, add rollback/confirmation presentation logic at view boundaries, and verify each slice independently before moving forward.

**Tech Stack:** Swift 6, SwiftUI, UIKit Share Extension, Swift Testing, Xcode iOS Simulator, `xcrun simctl`.

---

### Task 1: Time Anchor Transaction Contract

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/TimeAnchorEditingTransaction.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/TimeAnchorEditingTransactionTests.swift`

- [ ] Write failing tests proving existing-anchor rollback, new-anchor cancellation, committed values, and selected-anchor restoration.
- [ ] Run the focused test target and confirm the new contract is absent.
- [ ] Implement a small value-type transaction that stores the original anchor, original selected ID, and whether the anchor was newly created.
- [ ] Run the focused tests and confirm all transaction cases pass.

### Task 2: Time Anchor Native Actions

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/TimeAnchorEditingTransactionTests.swift`

- [ ] Integrate the transaction at editor open, add, complete, cancel, and interactive-dismiss boundaries.
- [ ] Preserve every current `syncDraftToSession()` call required for real-time preview.
- [ ] Replace the custom row swipe shell with trailing `.swipeActions(allowsFullSwipe: false)`.
- [ ] Stage destructive deletion and present `confirmationDialog` before invoking existing deletion logic.
- [ ] Verify focused tests and the iOS simulator build.

### Task 3: Configuration Center Peripheral Polish

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterIOSSupportViews.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSummarySection.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterInsertableModuleLibrarySection.swift`
- Test: existing Configuration Center architecture tests

- [ ] Preserve `ConfigurationCenterTopPreviewSection` and preview helper behavior.
- [ ] Normalize toolbar placements, picker/menu labeling, focus, keyboard dismissal, and accessibility around existing bindings.
- [ ] Ensure selected-region module insertion continues through the existing coordinator.
- [ ] Run Configuration Center binding, selection, preview composition, and module-routing tests.

### Task 4: Module And Local Library Native Surfaces

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ModuleLibrarySurface.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibraryPresenter.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1LocalConfigurationLibraryPresenterTests.swift`

- [ ] Add native module search without changing available modules or insertion callbacks.
- [ ] Keep the primary restore action visible and move secondary backup actions to native context/swipe actions.
- [ ] Add destructive backup deletion confirmation.
- [ ] Keep Home configuration rows untouched.
- [ ] Run local-library and module selection tests plus iOS build.

### Task 5: Settings And Output Polish

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift`

- [ ] Retain branded cards and current information hierarchy.
- [ ] Replace generic custom action behavior with native links, labeled values, focus, submit, and system disabled states where semantics match.
- [ ] Remove page-wide keyboard gestures only where native focus/scroll dismissal fully replaces them.
- [ ] Preserve album, media output, description, and processing behavior.
- [ ] Run related presenter/policy tests and iOS build.

### Task 6: Task Surface Polish

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift`
- Modify only if required: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPagePresenter.swift`
- Test: existing queue/background status projection tests

- [ ] Keep task projections, queue state, diagnostics, recovery, and routing unchanged.
- [ ] Normalize empty state, progress accessibility, recent-task sheet, toolbar, and Dynamic Type behavior.
- [ ] Remove the unnecessary global keyboard-dismiss gesture when no editor is present.
- [ ] Run queue diagnostics, workflow summary, and background status tests.

### Task 7: Share Extension Presentation Polish

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- Test: existing Share intake, diagnostics, and workflow summary tests

- [ ] Retain the existing UIKit view controller and `ViewState` lifecycle.
- [ ] Normalize Dynamic Type, accessibility traits, status announcements, system button configuration, spacing, and visual tokens.
- [ ] Keep 20-photo admission, 21-photo rejection, provider handling, App Group handoff, completion, cancellation, and host opening untouched.
- [ ] Run Share Extension intake, diagnostics, workflow, and iOS Share Extension builds.

### Task 8: Simulator Validation And Screenshots

**Files:**
- Create screenshots under `/Users/rui/Desktop/MemoMark-UI-Optimization-QA-2026-07-11/`
- Update: `Docs/CURRENT_STATUS.md`
- Update: `HANDOFF.md`

- [ ] Build the iOS simulator app with code signing disabled.
- [ ] Boot an available iPhone simulator, install, and launch MemoMark.
- [ ] Exercise reachable optimized screens without mutating the frozen Home configuration implementation.
- [ ] Capture consistent screenshots with a 9:41 status bar into the QA folder.
- [ ] Build the Share Extension and run all targeted test groups.
- [ ] Run the required macOS build, iOS simulator build, `git diff --check`, and document what could not be manually verified.
