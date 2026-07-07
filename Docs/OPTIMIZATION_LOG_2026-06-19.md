# MemoMark Optimization Log

Date: 2026-06-19

## This Round

- stabilized the inline custom-region editor around real module spans instead of regex-only label matching
- added [MainView+ComposerDisplayEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerDisplayEngine.swift) as a shared display engine for:
  - raw token -> visible label rendering
  - visible text + module spans -> raw template reconstruction
  - module-aware selection adjustment
  - module-aware replacement range expansion
- updated [MainView+ComposerEditor.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift) so macOS and UIKit now share the same module-boundary rules instead of relying on plain `〔...〕` regex matching
- updated [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift) to store editor module spans per slot and rebuild raw template values only from true module spans
- removed the now-unused `templateVariable(for:)` helper from `MainView`

## What Improved

- user-typed literal text such as `〔型号〕` or `〔城市〕` is no longer silently converted into real EXIF tokens
- module styling and whole-block deletion now target only actual inserted modules, not any text that happens to use full-width brackets
- selection replacement no longer collapses to only the module body when the user selected normal text plus one or more modules together
- UIKit is closer to the macOS editing behavior and no longer trails as a pure plain-text path

## Verification

- build command passed:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

- result:
  - compile succeeded
  - only Xcode destination-selection warning remained
- not manually verified yet:
  - caret placement around mixed text + modules
  - direct replacement of a selection that spans ordinary text and modules
  - UIKit visual parity by live interaction

## MainView Re-Review

Current line count of [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift): `3621`

The file is better aligned with a coordinator role than before, but it still carries three heavy clusters that are worth extracting next:

1. Editor session state
   - current hotspot lines start around `1634`, `1680`, `1715`, `1734`, and `3054`
   - this includes display text, selection, module-span bindings, raw-template sync, and template-to-editor resync
   - recommended target file: `MainView+ComposerSession.swift`

2. Workspace configuration lifecycle
   - current hotspot lines start around `3346` and `3381`
   - this includes save-current-slot, switch-slot, restore-default, and snapshot application
   - recommended target file: `MainView+WorkspaceConfigurationState.swift`

3. Batch/output synchronization and save flow
   - current hotspot lines start around `3516` and `3527`
   - this includes batch default snapshot sync, permission refresh, export, album resolution, and success/failure alert routing
   - recommended target file: `MainView+ExportActions.swift`

## Recommended Next Order

1. extract editor session helpers first
2. extract workspace configuration state second
3. extract export/save actions third
4. only after those are stable, revisit larger UI polish or new feature surface

## Why This Order

- editor session remains the highest regression-risk area
- workspace slot logic now shapes more and more product behavior and should stop growing inside `MainView`
- export/save flow is already meaningful enough to deserve its own action-focused slice
- this order keeps the app aligned with the repository rule that `MainView` should act as coordinator, not long-term feature host

## Refactor Completion

The three queued extractions above are now landed:

- [MainView+ComposerSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerSession.swift)
- [MainView+WorkspaceConfigurationState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceConfigurationState.swift)
- [MainView+ExportActions.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift)

What actually changed:

- moved template-editor display/session helpers out of [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift)
- moved workspace-slot snapshot save/switch/restore logic out of `MainView`
- moved photo-library permission, album refresh, and save-to-library actions out of `MainView`
- removed the leftover duplicate `requestPhotoLibraryPermission()` definition that initially blocked the build after extraction

Result:

- [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift) dropped again from about `3621` lines to about `2905` lines
- the three new extensions now own the targeted responsibilities cleanly enough for the project to build
- coordinator pressure is lower because `MainView` no longer mixes those flows directly with the view tree

One more follow-up extraction was safe enough to land immediately after that:

- [MainView+PermissionLifecycle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PermissionLifecycle.swift)

This keeps:

- first-launch permission preparation
- scene re-activation permission refresh
- primer-sheet permission request flow
- notification permission denial feedback

out of the main coordinator file as well.

Updated result after this extra slice:

- [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift) is now about `2842` lines

The work then continued with a higher-value cleanup that removed old dead infrastructure instead of only moving it around:

- deleted [MainView+ComposerWidgets.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerWidgets.swift)
- removed the no-longer-used literal-composer sheet from [MainView+ComposerPanels.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerPanels.swift)
- removed stale block-style composer item state and scrubber helpers from [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift)
- extracted [MainView+DerivedState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+DerivedState.swift)
- extracted [MainView+CoordinatorSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+CoordinatorSupport.swift)
- extracted [MainView+TemplateEditingActions.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplateEditingActions.swift)

Why this was worth doing:

- the old block-style composer path was no longer driving the current cursor-based UI
- keeping that dead path would make future refactors look much riskier than they really are
- removing it reduced both line count and mental branching without changing the live editing behavior

Updated result after this follow-up:

- [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift) is now about `1186` lines
- the coordinator file is now mostly view assembly, sheets, local draft state, and a few remaining bindings/actions

The work then kept going in the same direction:

- extracted [MainView+PresentationState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PresentationState.swift)
- extracted [MainView+LayoutSections.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift)
- extracted [MainView+UIPrimitives.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+UIPrimitives.swift)

Why these were worth doing:

- `MainView` no longer needs to host rename/help sheet plumbing inline
- sidebar/detail assembly is display-heavy and belongs outside the coordinator shell
- style primitives and `MainFieldSlot` definitions should not inflate the coordinator file

Updated result after these follow-ups:

- [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift) is now about `300` lines
- the main file now mostly contains state, lifecycle hooks, app-level alerts, and the root view entrypoint

Two final safe coordinator-shell follow-ups also landed:

- extracted [MainView+ModalAndLifecycle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ModalAndLifecycle.swift)
- extracted [MainView+Feedback.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Feedback.swift)

That left:

- the body-level sheet and alert wiring outside the main file
- lifecycle change handlers outside the main file
- only the state list and `body { mainScene }` shell inside [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift)

Updated result after those last follow-ups:

- [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift) is now about `112` lines

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- not yet manually verified:
  - workspace-slot switching while editor caret is active
  - real album reload after permission grant
  - save-to-library success/failure flow with a real imported photo

## Next Three Targets

1. access-control tightening
2. badge / output / workspace bindings
3. optional lightweight grouping of the remaining coordinator state

## Final Follow-Up In This Round

That optional grouping has now landed in a very small, behavior-preserving slice:

- added [MainView+StateModels.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift)
- kept `MainAlertState` and `MainPresentationState` there
- added `MainEditorSessionState` for:
  - active editing slot
  - per-slot display text
  - per-slot selection
  - per-slot module spans
- updated:
  - [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift)
  - [MainView+ComposerSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerSession.swift)
  - [MainView+TemplateEditingActions.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplateEditingActions.swift)
  - [MainView+LayoutSections.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift)

Why this was worth doing:

- `MainView` no longer keeps four separate editor-session `@State` fields at top level
- the remaining coordinator state now reads more like three clear buckets:
  - presentation
  - alerts
  - editor session
- this reduces the chance of future refactors scattering caret/session ownership again

Updated result after this last state-model follow-up:

- [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift) is now about `72` lines
- the file now mostly declares service ownership, coordinator state ownership, and `body`

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- still not manually verified:
  - caret preservation while inserting multiple modules
  - workspace-slot switching while a custom-region editor is active
  - real save-to-library success/failure feedback against a real imported photo

## Updated Next Three Targets

1. access-control tightening
2. badge / output / workspace bindings
3. manual regression coverage for caret routing, slot switching, and save feedback

## Coordinator Polish Follow-Up

One more very small coordinator-polish slice has now landed after the state grouping:

- updated [MainView+TemplatePanels.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift) so:
  - `MainTemplateSectionView` uses `@Binding var selectedPreset`
  - `MainBadgeSectionView` uses `@Binding var selectedBadgeName`
- updated [MainView+SetupPanels.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+SetupPanels.swift) so:
  - `MainAnchorSectionView` uses `@Binding var selectedAnchorID`
- updated [MainView+LayoutSections.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift) to stop hosting a few obvious inline action bodies
- added small action helpers in:
  - [MainView+CoordinatorSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+CoordinatorSupport.swift)
  - [MainView+TemplateEditingActions.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplateEditingActions.swift)
  - [MainView+PresentationState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PresentationState.swift)

What this improved:

- child panels now express ownership more like native SwiftUI views, receiving bound values instead of raw `Binding<T>` containers where a property wrapper is clearer
- `LayoutSections` reads more like view assembly and less like a place that also hides action implementation
- the same coordinator behavior remains intact because the moved callbacks still write through the same state and services

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- still not manually verified:
  - anchor switching while the inline editor is focused
  - slot switching while a custom-region editor is active
  - real save-to-library success/failure feedback against a real imported photo

## Refined Next Three Targets

1. access-control tightening for same-file-only helper types and methods
2. continue shrinking any remaining obvious local binding/callback logic around workspace and output assembly
3. manual regression coverage for caret routing, slot switching, anchor switching, and save feedback

## Access-Control Follow-Up

One more behavior-preserving pass tightened a few same-file-only implementation details:

- updated [MainView+WorkspaceControls.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceControls.swift) so:
  - `MainOperationGuideCategory` is now `fileprivate`
  - `MainOperationGuideSection` is now `fileprivate`
  - `MainOperationGuideTopic.category` and `MainOperationGuideTopic.sections` are now `fileprivate`
- updated [MainView+SetupPanels.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+SetupPanels.swift) so:
  - `MainPhotoMetadataSummaryView` is now `private`
  - `MainAnchorFactPillView` is now `private`
- updated [MainView+PreviewPanels.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift) so:
  - `MainPreviewHeaderView` is now `private`
  - `MainPreviewCanvasView` is now `private`
  - `MainPreviewSummaryView` is now `private`

Why this was worth doing:

- these helpers were implementation details, not cross-file surface area
- the file boundaries now communicate intent more honestly
- future refactors are less likely to treat these local helpers as reusable public building blocks by accident

Verification:

- first build caught a legitimate access-control mismatch inside the operation-guide file
- after tightening the related computed properties to `fileprivate`, the standard build passed again
- final result:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - only the existing Xcode destination-selection warning remained

## Derived-State Follow-Up

Another small cleanup pass moved a few pure display derivations out of layout assembly and back into [MainView+DerivedState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+DerivedState.swift):

- selected photo device-model text
- selected photo capture-date text
- anchor quick-fact view models
- `canExportCurrentCard`

This simplified [MainView+LayoutSections.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift) by removing extra inline closure logic from:

- photo section assembly
- anchor section assembly
- output section assembly

Why this was worth doing:

- `LayoutSections` reads more like a coordinator-side view composition file
- derived display logic is now easier to find beside the rest of the preview/template summary state
- there was no change to insertion routing, preview generation, export gating, or save flow

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- still not manually verified:
  - anchor switching while the inline editor is focused
  - workspace-slot switching while a custom-region editor is active
  - real save-to-library success/failure feedback against a real imported photo

## Updated Next Three Targets

1. continue selective access-control tightening only where the helper truly never crosses file boundaries
2. keep removing leftover inline assembly logic from `LayoutSections` when it is really derived state or action routing
3. run focused manual regression on caret routing, anchor switching, workspace-slot switching, and album save feedback

## Layout Action Follow-Up

One more tiny coordinator-cleanup slice removed a few remaining synchronous trigger closures from [MainView+LayoutSections.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift):

- output save now routes through `saveCurrentCardToAlbumAction()`
- permission request now routes through `requestPhotoLibraryPermissionAction()`
- notification request now routes through `requestNotificationPermissionAction()`
- permission primer confirmation now routes through `requestInitialPermissionsAction()`
- settings jumps now route through `openPhotoLibrarySettings()` and `openNotificationSettings()`

Those wrappers now live beside their real async/business counterparts in:

- [MainView+ExportActions.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift)
- [MainView+PermissionLifecycle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PermissionLifecycle.swift)

Why this was worth doing:

- `LayoutSections` now hides less task-launching detail in the middle of view assembly
- permission and export entrypoints are easier to locate beside the real action implementations
- the runtime behavior is unchanged because the wrappers still call the same async flows

## Operation-Guide Surface Tightening

The operation-guide file also got one more access-control pass:

- `MainOperationGuideCategory` remains file-local
- its local display helpers (`title`, `summary`, `iconName`, `topics`) are now explicitly `fileprivate`
- `MainOperationGuideTopic` keeps its cross-file enum surface, but its file-local display helpers are now also tightened where appropriate

Why this was worth doing:

- the help-center file now exposes less accidental reusable surface
- internal presentation metadata stays clearly scoped to the help-center implementation

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- review result:
  - no new correctness issue found in this slice
- still not manually verified:
  - anchor switching while the inline editor is focused
  - workspace-slot switching while a custom-region editor is active
  - real save-to-library success/failure feedback against a real imported photo

## Refined Next Three Targets

1. keep shrinking `LayoutSections` only when the code is obviously derived state or action routing
2. tighten access control on any remaining same-file-only helper methods after verifying there is no cross-file call site
3. run manual regression on caret routing, anchor switching, workspace-slot switching, and album save feedback

## Share-Extension Hardening And Target Slimming

The optimization focus later shifted from `MainView` decomposition toward iOS share-intake robustness and compile-surface discipline.

What changed:

- added app-group-backed shared intake persistence and shared configuration loading
- hardened share intake for:
  - partial success
  - duplicate URL deduplication
  - missing-file filtering before queue handoff
  - managed temporary-file cleanup on persistence failure
- refused the tempting `UIImage -> JPEG` fallback to avoid silent EXIF loss or binary mutation before MemoMark starts real processing
- extracted `ExternalPhotoIntakeRequest` into its own shared file so the request model no longer lives inside the main-app intake center
- introduced a synchronized-group exception set for `PhotoMemoShareExtension` and removed a large amount of app-only UI/service surface from that target

Why this was worth doing:

- the share extension is now much easier to reason about as its own entry surface
- target slimming reduces accidental coupling to the macOS calibration center
- future iOS/share regressions should be easier to isolate because the extension now compiles a much smaller shared core

Measured result:

- `PhotoMemoShareExtension.SwiftFileList` is now roughly `19` lines

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Newest next three targets:

1. manually validate system share with `1张 / 多张 / 部分失效 / 重复来源`
2. continue shrinking share-extension resources only where the dependency edge is clearly unnecessary
3. tighten the completion/failure feedback story for novice users after real share-flow validation
