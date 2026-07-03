# V1 View Freeze Follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Freeze `View` growth and keep polishing V1 by moving orchestration, persistence, and service ownership out of `PhotoMemoiOSV1View` and `V1IOSSubjectOverviewSupport`.

**Architecture:** `PhotoMemoiOSV1View` remains the state owner and composition shell, but no new business flow or service work stays inside it. Flow orchestration moves into small V1 coordinators/support objects, and subject overview logic is split into state/presenter/view layers so the root view stops accumulating responsibilities.

**Tech Stack:** SwiftUI, Swift Concurrency, existing `ConfigurationCoordinator`, `ExternalPhotoIntakeCenter`, `ConfigurationSession`, V1 support/coordinator pattern already present in the repository.

## Global Constraints

- Freeze `View` growth: do not add new business responsibilities to `PhotoMemoiOSV1View`.
- Keep V1 as the active polish track; do not reopen old iOS/macOS view paths.
- Do not redesign Renderer, Export, Share Extension, Photo Library behavior, or Layout Engine.
- Preserve current V1 behavior and save pipeline semantics while extracting responsibilities.
- Prefer additive refactors with focused tests after each slice.

---

## Phase 1: Root View Responsibility Split

### Task 1: Extract V1 configuration save/apply side effects

**Description:** Move the save/apply flow out of `PhotoMemoiOSV1View` so the root view no longer constructs save requests, applies album follow-up, and manages post-save state transitions inline.

**Acceptance criteria:**
- `PhotoMemoiOSV1View` no longer owns the bulk of `applyCurrentV1Configuration()`.
- Save request building and save result reconciliation live in dedicated support/coordinator types.
- Existing V1 configuration apply tests still pass.

**Files likely touched:**
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplyCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/` new support file for request building or apply effects
- `Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationApplyCoordinatorTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationMigrationTests.swift`

**Verification:**
- `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1ApplyTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1ConfigurationApplyCoordinatorTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests test`

### Task 2: Extract bootstrap and restore flow from root view

**Description:** Move `bootstrapSavedSettings()`, `applyBootstrapState()`, welcome bootstrap, and draft bootstrap coordination into a dedicated V1 bootstrap flow object so root view only triggers the flow and applies a compact state result.

**Acceptance criteria:**
- `PhotoMemoiOSV1View` no longer contains the full bootstrap restore algorithm.
- Subject library restore, output restore, welcome restore, and draft restore are coordinated outside the view.
- Bootstrap behavior remains unchanged.

**Files likely touched:**
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationBootstrapCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftBootstrapCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomeFlowCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/` new bootstrap support file
- tests around V1 bootstrap presenters/coordinators

**Verification:**
- `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1BootstrapTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1ConfigurationBootstrapCoordinatorTests -only-testing:PhotoMemoTests/V1WelcomeFlowCoordinatorTests test`

### Checkpoint: Root View Split

- `PhotoMemoiOSV1View` retains state ownership and page composition only
- Save/apply and bootstrap flow are coordinator-driven
- V1 build remains green

---

## Phase 2: Subject Overview Decomposition

### Task 3: Split subject flow state from subject overview UI

**Description:** Pull `V1IOSSubjectConfigurationFlowState` and the presenter/factory logic out of `V1IOSSubjectOverviewSupport.swift` into dedicated files so the support file stops mixing domain-ish state and sheet UI.

**Acceptance criteria:**
- Flow state type lives in its own file.
- Flow presenter/factory lives in its own file.
- `V1IOSSubjectOverviewSupport.swift` becomes primarily presentation/UI.

**Files likely touched:**
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/` new `V1IOSSubjectConfigurationFlowState.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/` new `V1IOSSubjectConfigurationFlowPresenter.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1IOSSubjectOverviewPresenterTests.swift`

**Verification:**
- `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1SubjectFlowTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests test`

### Task 4: Split subject overview sheet/card UI into smaller surfaces

**Description:** Break `V1IOSSubjectOverviewSupport.swift` into smaller display-focused files: overview sheet shell, card rail/content, and supporting row/card views.

**Acceptance criteria:**
- `V1IOSSubjectOverviewSupport.swift` no longer acts as a giant grab-bag file.
- Card rail UI, sheet layout, and tiny presentational pieces are separated by responsibility.
- No behavior change in subject management flow.

**Files likely touched:**
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/` new sheet/card support files
- `Tests/PhotoMemoTests/ArchitectureTests/V1IOSSubjectOverviewPresenterTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift`

**Verification:**
- `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1SubjectOverviewTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests -only-testing:PhotoMemoTests/V1SubjectLibrarySupportTests test`

### Checkpoint: Subject Overview Split

- `V1IOSSubjectOverviewSupport.swift` drops below the current oversized state
- state/presenter/ui boundaries are explicit
- subject add/select/delete/activate flows remain covered by tests

---

## Phase 3: Service Ownership Cleanup

### Task 5: Move logo optimization service ownership out of root view

**Description:** Replace direct `LogoAssetOptimizationService()` ownership in `PhotoMemoiOSV1View` with a coordinator or injected dependency so future logo work does not grow the view.

**Acceptance criteria:**
- root view does not instantiate the logo optimization service directly
- logo optimization result handling is delegated to support code
- existing logo persistence and preview refresh behavior is preserved

**Files likely touched:**
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/` new or existing logo coordinator/support file
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift`
- tests covering bootstrap/persistence if needed

**Verification:**
- targeted V1 configuration migration/bootstrap tests
- `PhotoMemoiOSV1` simulator build

### Task 6: Move photo import service ownership out of root view

**Description:** Replace direct `PhotoImportService()` ownership in `PhotoMemoiOSV1View` with intake-specific support so picker-related import logic remains outside the view shell.

**Acceptance criteria:**
- root view no longer instantiates `PhotoImportService()` directly
- `importPickedPhotos()` becomes a thin orchestration call or disappears into a coordinator
- current file-representation-first picker path remains intact

**Files likely touched:**
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift`
- `Tests/PhotoMemoTests/BatchTests/PhotoMemoiOSV1PhotoIntakeTests.swift`

**Verification:**
- `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1IntakeTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests test`
- `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1IOSBuild CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

### Checkpoint: Service Ownership Cleanup

- root view owns state, not services
- picker/logo support code is reusable and isolated
- no new behavior path bypasses the V1 save pipeline

---

## Recommended Execution Order

1. Task 1: configuration apply side effects
2. Task 2: bootstrap/restore flow
3. Task 3: subject flow state split
4. Task 4: subject overview UI split
5. Task 5: logo optimizer ownership cleanup
6. Task 6: photo import service ownership cleanup

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Save/apply extraction accidentally changes persisted V1 semantics | High | keep `V1ConfigurationApplyCoordinatorTests` and `ConfigurationMigrationTests` green after each slice |
| Subject overview split breaks selection or active-anchor sync | High | preserve `V1SubjectLibrarySupportTests` and `V1IOSSubjectOverviewPresenterTests` after each split |
| Service extraction regresses picker/logo behavior | Medium | keep focused intake tests and simulator build on every related slice |
| Root view shrinks but support files become new god objects | Medium | split by flow/state/view, not by “misc support” bucket |

## Practical Rule For Future Work

- New V1 behavior goes into:
  - coordinator
  - presenter
  - support surface
  - state object
- New V1 behavior does **not** go into:
  - `PhotoMemoiOSV1View.swift`
  - old `PhotoMemoiOSHomeView`
  - old `ConfigurationCenteriOSView`

