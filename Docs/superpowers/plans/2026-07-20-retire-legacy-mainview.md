# Retire Legacy MainView Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Safely remove the obsolete macOS `MainView` editor/workspace implementation while preserving the current `ConfigurationCenterView`, iOS Configuration Center, shared services, and production pipeline.

**Architecture:** `PhotoMemoRootSceneView` is the runtime entry point: macOS uses `ConfigurationCenterView`, iOS uses `PhotoMemoiOSV1View`. The entire `Source/PhotoMemo/PhotoMemo/Views/Main` subtree is only referenced by `MainView` itself or its own extensions/tests, so it can be retired as one bounded legacy slice after confirming no external symbol references.

**Tech Stack:** SwiftUI, Swift Testing, Xcode schemes `PhotoMemo`, `PhotoMemoiOS`, and `PhotoMemoTests`.

---

### Task 1: Record the retirement boundary

**Files:**
- Modify: `HANDOFF.md`
- Create: `Docs/superpowers/plans/2026-07-20-retire-legacy-mainview.md`

- [x] Record that `PhotoMemoRootSceneView` no longer routes to `MainView` and that the `Views/Main` subtree has no external callers.
- [x] Define verification as `rg` reference checks, `PhotoMemoTests`, macOS Debug build, iOS Simulator Debug build, and signed iPhone7 build.

### Task 2: Remove the obsolete implementation subtree

**Files:**
- Delete: `Source/PhotoMemo/PhotoMemo/Views/Main/`

- [x] Delete only the legacy `MainView`, Composer, Workspace, importer, and supporting views in this subtree.
- [x] Do not delete shared files outside the subtree, even when their names look related.

### Task 3: Remove tests that only exercise deleted code

**Files:**
- Delete: `Tests/PhotoMemoTests/VariableTests/EditorProjectionEngineTests.swift`

- [x] Confirm no remaining test or source file references `EditorProjectionEngine`, `TemplateEditorModuleSpan`, `MainFieldSlot`, or `WorkspaceSessionController`.
- [x] Preserve tests for shared `Template`, `TemplateVariableEngine`, `CardTextBlockEngine`, Configuration Center, and production configuration behavior.

### Task 4: Verify build and behavior boundaries

**Commands:**
- `xcodebuild test -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoMainViewRemovalTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -quiet`
- `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoMainViewRemovalMac CODE_SIGNING_ALLOWED=NO -quiet build`
- `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoMainViewRemovalIOS CODE_SIGNING_ALLOWED=NO -quiet build`
- `git diff --check`

- [x] Confirm all commands exit successfully.
- [x] Confirm no deleted symbol appears in source or tests.

### Task 5: Deliver the verified build

**Commands:**
- Build signed `PhotoMemoiOS` for device `00008150-000A043136A1401C`.
- Install `/tmp/PhotoMemoIPhone7MainViewRemoval/Build/Products/Debug-iphoneos/PhotoMemoiOS.app` with `devicectl`.
- Launch `com.serydoo.PhotoMemo.iOS` after confirming the device is unlocked; if locked, record the system denial and leave manual launch for the user.

- [x] Confirm installation preserves the existing app data path.
- [x] Update `HANDOFF.md` and `Docs/CURRENT_STATUS.md` with the removal and verification evidence.
