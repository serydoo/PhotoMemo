# MemoMark iPad Adaptive Interface Implementation Plan

Date: 2026-07-14

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an iPad sidebar shell and wide Configuration Center composition while preserving the current iPhone navigation and all production behavior.

**Architecture:** Keep `PhotoMemoiOSV1View` as the single state owner and select between compact `TabView` and regular `NavigationSplitView` shells using horizontal size class. Extend the existing entry destination enum with Settings, keep compact Settings modal behavior, and adapt `V1EditorPageSurface` internally for a side-by-side preview/editor layout at regular width.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, Xcode iOS Simulator builds

---

### Task 1: Adaptive Destination Contract

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1EntryFlowSupport.swift`
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1EntryFlowCoordinatorTests.swift`

- [ ] **Step 1: Write the failing destination tests**

Add tests proving regular-width Settings selects a peer destination and compact Settings remains modal:

```swift
@Test("regular settings selects the settings destination")
func regularSettingsSelectsDestination() {
    let nextState = V1EntryFlowCoordinator.openSettings(
        presentation: .regular,
        from: V1EntryFlowState()
    )
    #expect(nextState.selectedTab == .settings)
    #expect(nextState.showsSettingsPage == false)
}

@Test("compact settings opens the settings sheet")
func compactSettingsOpensSheet() {
    let nextState = V1EntryFlowCoordinator.openSettings(
        presentation: .compact,
        from: V1EntryFlowState()
    )
    #expect(nextState.selectedTab == .home)
    #expect(nextState.showsSettingsPage == true)
}
```

- [ ] **Step 2: Run the focused test and confirm RED**

Run:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoIPadTests CODE_SIGNING_ALLOWED=NO -only-testing:PhotoMemoTests/V1EntryFlowCoordinatorTests test
```

Expected: failure because `.settings`, `V1EntryPresentation`, and `openSettings(presentation:from:)` do not exist.

- [ ] **Step 3: Implement the minimal destination contract**

Add:

```swift
enum V1EntryPresentation {
    case compact
    case regular
}

enum V1EntryTab: Hashable, CaseIterable, Identifiable {
    case home, editor, output, tasks, settings
    var id: Self { self }
}
```

Implement `openSettings(presentation:from:)` so regular selects `.settings` without a sheet and compact preserves the existing sheet behavior. Retain `openSettingsPage(from:)` as the compact compatibility entry if existing callers still require it.

- [ ] **Step 4: Run the focused test and confirm GREEN**

Run the command from Step 2. Expected: `V1EntryFlowCoordinatorTests` passes.

### Task 2: iPad Navigation Shell

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdaptiveNavigationShell.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1EntryFlowCoordinatorTests.swift`

- [ ] **Step 1: Write a failing compact-transition test**

Add a test proving a regular Settings destination becomes the compact Settings sheet when width contracts:

```swift
@Test("contracting from regular settings preserves access through the compact sheet")
func contractingSettingsPreservesAccess() {
    let state = V1EntryFlowState(selectedTab: .settings)
    let nextState = V1EntryFlowCoordinator.prepareForCompactPresentation(from: state)
    #expect(nextState.selectedTab == .home)
    #expect(nextState.showsSettingsPage == true)
}
```

- [ ] **Step 2: Run the focused test and confirm RED**

Run the Task 1 focused test command. Expected: failure because `prepareForCompactPresentation(from:)` does not exist.

- [ ] **Step 3: Implement transition logic and the adaptive shell**

Implement `prepareForCompactPresentation(from:)`. Create a focused shell containing:

```swift
struct V1AdaptiveNavigationShell<Compact: View, Detail: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selection: V1EntryTab
    @ViewBuilder let compact: () -> Compact
    @ViewBuilder let detail: (V1EntryTab) -> Detail
}
```

Use the existing compact `NavigationStack + TabView` unchanged. For regular width, render a `NavigationSplitView` with a native sidebar in the approved order and a detail switch for Home, Configuration Center, Output, Tasks, and Settings. Keep all page builders and state in `PhotoMemoiOSV1View`; the shell receives content closures only.

- [ ] **Step 4: Route Settings through width-aware behavior**

Change the Home Settings action to call `openSettings(presentation:from:)` using the current horizontal size class. Reuse one `settingsPage` builder for the regular detail and compact sheet. When size class becomes compact while `.settings` is selected, apply `prepareForCompactPresentation(from:)`.

- [ ] **Step 5: Run focused tests and build the iOS app**

Run the Task 1 focused test command, then:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIPadBuild CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO COMPILER_INDEX_STORE_ENABLE=NO -quiet build
```

Expected: tests pass and app build exits 0.

### Task 3: Wide Configuration Center Composition

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift`
- Create: `Tests/PhotoMemoTests/ArchitectureTests/V1AdaptivePageLayoutTests.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdaptivePageLayout.swift`

- [ ] **Step 1: Write failing layout-policy tests**

Add tests for a pure layout policy:

```swift
@Test("regular width uses side by side editor composition")
func regularWidthUsesSideBySideComposition() {
    #expect(V1AdaptivePageLayout.editorComposition(for: 1024) == .sideBySide)
}

@Test("narrow split view uses stacked editor composition")
func narrowWidthUsesStackedComposition() {
    #expect(V1AdaptivePageLayout.editorComposition(for: 640) == .stacked)
}
```

- [ ] **Step 2: Run the focused tests and confirm RED**

Run:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoIPadTests CODE_SIGNING_ALLOWED=NO -only-testing:PhotoMemoTests/V1AdaptivePageLayoutTests test
```

Expected: failure because `editorComposition(for:)` is missing.

- [ ] **Step 3: Implement the layout policy and composition**

Add `V1EditorComposition` with `.stacked` and `.sideBySide`, using a conservative width threshold. In `V1EditorPageSurface`, use `GeometryReader` to keep the existing stacked composition below the threshold and render preview and editor in adjacent panes above it. Preserve the existing page header, scrolling, keyboard dismissal, background, and coordinate-space behavior.

- [ ] **Step 4: Run focused tests and rebuild**

Run the Task 3 test command and the iOS build command from Task 2. Expected: both exit 0.

### Task 4: Verification And Chronicle

**Files:**
- Modify: `Docs/CURRENT_STATUS.md`

- [ ] **Step 1: Run regression builds**

Run:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIPadFinal CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO COMPILER_INDEX_STORE_ENABLE=NO -quiet build
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIPadShareFinal CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO COMPILER_INDEX_STORE_ENABLE=NO -quiet build
```

Expected: both builds exit 0.

- [ ] **Step 2: Review focused diff and repository state**

Run `git diff --check`, inspect only the task files, and confirm unrelated user changes remain untouched.

- [ ] **Step 3: Update the project chronicle**

Add a concise dated entry to `Docs/CURRENT_STATUS.md` describing the adaptive shell, Configuration Center composition, automated verification, and iPad interactions not manually verified.
