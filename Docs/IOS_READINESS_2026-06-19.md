# PhotoMemo iOS Readiness Audit

Date: 2026-06-19

## Verdict

PhotoMemo is **not yet at "add an iOS target and immediately ship a working build" readiness**, but it **is already at a practical "start iOS development now with a focused adaptation sprint" stage**.

Short version:

- codebase readiness: **moderately good**
- engineering-target readiness: **not ready yet**
- product-interaction readiness: **partially ready**

If we define "can start iOS at any time" as:

- create an iOS target
- wire the current shared code in
- spend 1 to 3 focused work rounds on platform adaptation
- then begin iterative iOS UI work

then the answer is **yes**.

If we define it as:

- create an iOS target today
- build immediately with little or no adaptation

then the answer is **no**.

## What Is Already In Good Shape

### 1. Main editor architecture is much closer to iOS-friendly SwiftUI

The MainView refactor work has already reduced the risk substantially:

- `MainView.swift` is now a thin coordinator shell
- view assembly, derived state, presentation state, export actions, permission lifecycle, and editor session are already split into `MainView+*.swift`
- the current structure is much easier to map onto iPhone/iPad layouts than the old giant file

Key files:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PermissionLifecycle.swift`

### 2. Core data flow is mostly platform-agnostic

These parts already look reusable for iOS:

- EXIF reading
- anchor calculation
- template variable system
- record-card building
- photo-library save logic
- queue/configuration snapshot logic

Key files:

- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
- `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`
- `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift`

### 3. Some platform abstraction already exists

There is already real cross-platform groundwork instead of pure macOS-only code:

- `SelectedPhoto` uses `PlatformImage` with `NSImage` / `UIImage` switching
- `PermissionCenter` already has macOS and UIKit branches
- `MainView+ComposerEditor.swift` already has macOS and UIKit editor implementations
- `MainView+LayoutSections.swift` already switches between `NavigationSplitView` and `NavigationStack`

Key files:

- `Source/PhotoMemo/PhotoMemo/Models/SelectedPhoto.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PermissionCenter.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`

### 4. Photo import/export pipeline is conceptually portable

- `fileImporter` is already used for selecting a preview photo
- export-to-temporary-file already exists as a non-macOS fallback path
- save-to-Photo-Library uses `Photos` APIs that are relevant on iOS too

Key files:

- `Source/PhotoMemo/PhotoMemo/Views/Main/PhotoImporterView.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`

## Main Blockers Right Now

### 1. There is no iOS target in the Xcode project yet

This is the single clearest blocker.

Current project settings are macOS-only:

- `SDKROOT = macosx`
- `MACOSX_DEPLOYMENT_TARGET = 27.0`
- only one app target exists

Key file:

- `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`

Impact:

- we cannot actually compile the app for iPhone/iPad yet
- current iOS readiness is architectural, not build-ready

### 2. App lifecycle still has macOS-only external intake assumptions

The main app entry still depends on macOS-only pieces for desktop-style file opening:

- `@NSApplicationDelegateAdaptor`
- `PhotoMemoAppDelegate`
- `application(_:open:)`
- `openFile` / `openFiles`
- direct `NSAppearance` setup

Key files:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoApp.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift`

Impact:

- iOS will need a different intake story:
  - document picker
  - share extension or share sheet intake later
  - scene/openURL based routing

### 3. Export UX is still desktop-first

`RecordCardExportService` still contains a macOS-only save panel path:

- `NSSavePanel`

The non-macOS branch currently falls back to temporary-file export, which is a good lower-level primitive, but not a complete iOS user flow by itself.

Key file:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`

Impact:

- iOS still needs a product-level decision for:
  - save directly to Photos only
  - share sheet export
  - Files export

### 4. Some UI structures are iPad-friendly, but not yet iPhone-ready

Examples:

- `NavigationSplitView` help center and workspace UI
- wide right-side workspace panel assumptions
- multi-column help center layout
- some desktop-like menu/button spacing choices

Key files:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceControls.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`

Impact:

- iPad should be much easier than iPhone
- iPhone will need a deliberate navigation and sheet strategy, not just compile fixes

## Medium-Risk Areas To Revisit Before Real iOS Work

### 1. Inline editor interaction parity

The code already includes a UIKit implementation, which is excellent.

But this area is still high risk for actual iOS usability:

- caret placement
- module insertion at cursor
- whole-module deletion behavior
- selection replacement across text + modules

Key file:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`

### 2. Permission wording and settings routing

The infrastructure is reusable, but some current copy is macOS-specific, especially around the photo permission re-prompt behavior and Settings navigation.

Key files:

- `Source/PhotoMemo/PhotoMemo/Services/PermissionCenter.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`

### 3. Background / external intake product shape

PhotoMemo's long-term direction includes external intake and background processing.

That direction still makes sense on iOS, but the actual implementation shape will differ:

- iOS share flows
- foreground/background limits
- extension strategy
- task continuation constraints

Key files:

- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`

## iOS Readiness Scorecard

### Ready or close to ready

- shared metadata pipeline
- shared anchor logic
- shared template logic
- shared card building
- shared Photo Library save service
- shared configuration-slot model
- shared SwiftUI coordinator architecture

### Needs a targeted adaptation pass

- app entry
- platform-specific permission wording
- export UX
- help center / workspace layout on compact width
- inline editor live interaction validation on UIKit

### Not ready yet

- iOS target and build settings
- iOS-specific intake strategy
- iPhone-first navigation/layout pass

## Practical Conclusion

PhotoMemo already has enough shared architecture to **start iOS work now without rewriting the app**.

The repository is **not blocked by fundamental architectural mistakes**.

The real gap is:

- platform target setup
- intake/export UX decisions
- compact-width interaction adaptation

So the right conclusion is:

- **yes, there is a real foundation for an iOS version**
- **no, it is not yet a one-click iOS build**

## Best Next Step If iOS Work Starts

Recommended order:

1. create an iOS app target while keeping the current macOS target intact
2. get the shared code compiling under the new target without redesigning UI yet
3. isolate app-entry and intake differences
4. make `MainView` usable on iPad first
5. then do a separate compact-width/iPhone interaction pass

## Suggested First iOS Sprint

### Slice 1

- add iOS target
- keep shared sources compiling
- stub platform entry differences

### Slice 2

- make the main calibration flow usable on iPad
- import one photo
- render preview
- save back to Photos

### Slice 3

- verify UIKit inline editor behavior
- fix caret/module insertion differences

### Slice 4

- redesign help center / workspace / preview flow for iPhone

## Bottom-Line Recommendation

PhotoMemo is **iOS-preparable now**, but **not iOS-ready today**.

The repository has enough shared foundation that starting an iOS branch would be reasonable right now.

But before claiming “随时开发 iOS 版本”, we should honestly say:

- the foundation exists
- the first sprint should be platform enablement
- the biggest remaining work is target setup plus mobile interaction adaptation
