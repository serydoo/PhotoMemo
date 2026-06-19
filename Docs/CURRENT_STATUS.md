# PhotoMemo Current Status

Last updated: 2026-06-19

## Current Stage

PhotoMemo is currently in a combined refinement stage:

- Product-wise, it is still a **local-first template calibration center**
- Engineering-wise, it is moving from a large prototype-style `MainView` toward a more maintainable coordinator structure
- Capability-wise, the project has already crossed the MVP foundation line:
  - real EXIF import
  - anchor calculation
  - preview rendering
  - export to new image
  - save back to Photo Library
  - background queue and permission foundation

According to `Docs/DEVELOPMENT_PLAN.md`, the project is between:

- Phase 2: Template Calibration Center
- Phase 5: Render Fidelity And Metadata Hardening

## What Was Completed In This Round

### 0. Project-local Swift/iOS skills were added for the next PhotoMemo phase

The project-local skills folder now also includes:

- `activitykit`
- `background-processing`
- `ios-simulator`
- `photokit`
- `swift-testing`
- `swiftui-patterns`

Why these were added:

- `photokit` directly supports photo-library permission, picker, and save-back work
- `background-processing` matches the share-intake and batch/export direction
- `activitykit` prepares for iPhone progress surfaces like Dynamic Island / Lock Screen
- `swiftui-patterns` helps keep `MainView` and the future iPhone UI aligned with modern state/composition rules
- `swift-testing` gives a better path for new Swift-native tests
- `ios-simulator` helps future iPhone regression, privacy, push, and location validation

These were installed into:

- `Source control path`: `/Users/rui/Desktop/PhotoMemo/.codex/skills`

Important current-session note:

- the skills are already present in the project and readable on disk
- but an already-open Codex session may not auto-refresh its built-in skill registry
- in practice, a restart or a fresh session is the stable way to make them appear as normal installed skills

### 0.1 iPhone background-status groundwork was added

The latest iPhone-facing slice also adds a lightweight intermediate status layer:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoBackgroundStatusService.swift`

What it does:

- observes `BatchQueueStore`
- resolves the most relevant external/background job snapshot
- normalizes progress, phase title, retryability, and status text into one stable model

Why this matters:

- future iPhone progress surfaces should not couple directly to `BatchQueueStore`
- the next Dynamic Island / Lock Screen / iPhone shell work can build on this snapshot service instead of re-deriving queue state ad hoc

### 0.2 iPhone now has a dedicated background-status entry without polluting the main editor

The latest follow-up iPhone slice also adds:

- a top-right background-status entry in `PhotoMemoiOSHomeView`
- a dedicated sheet:
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift`

Behavior choice for this slice:

- the main iPhone editor remains focused on template calibration and preview
- background progress is not pushed back into the main editing content area
- users can open a separate sheet to check queue status, failure summaries, and retry failed items

### 0.3 iPhone background-status updates are now live, and active jobs get extra background run time

The latest follow-up after that also tightens the iPhone shell behavior:

- `PhotoMemoiOSHomeView` now directly observes both:
  - `BatchQueueStore`
  - `PhotoMemoBackgroundStatusService`
- the background-status sheet now reads live queue state instead of only receiving a one-time snapshot payload
- iPhone app runtime now owns:
  - `PhotoMemoiOSBackgroundExecutionService`
- when the app moves to the background while `BatchQueueStore` is still processing, PhotoMemo now requests a standard iOS background task window so the current batch has a better chance to keep progressing before suspension

Why this matters:

- the iPhone background-status entry is no longer just structurally present; it now reflects queue changes in real time
- the app is better aligned with the intended workflow of “share photo -> leave the foreground -> let PhotoMemo continue for a while”
- this improves reliability without turning the main calibration UI into a progress dashboard and without changing the underlying import-render-export behavior

### 0.4 iPhone background-status sheet is now closer to a formal control center

The latest follow-up also upgrades the dedicated iPhone background-status sheet:

- adds a clearer processing-focus card:
  - current photo
  - task state
  - latest update time
- adds a per-job configuration card:
  - template
  - anchor
  - description-writing mode
  - save destination summary
- adds a current-job recent-records card so users can see which photos are:
  - currently running
  - failed
  - queued
  - completed

Why this matters:

- users no longer need to infer everything from one hero string and a failure list
- the sheet now behaves more like a real mobile-side background control center while still staying outside the main editor
- this also creates a cleaner stepping stone before any future ActivityKit / Dynamic Island integration

### 0.5 ActivityKit-ready bridge groundwork now exists without forcing a widget target yet

The latest follow-up also adds a dedicated bridge layer for future Live Activity work:

- shared display titles were normalized in `BatchProcessing` for:
  - `BatchJobState`
  - `BatchJobLaunchSource`
- added a Live Activity payload model:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoBackgroundLiveActivityPayload.swift`
- added a bridge service:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityBridgeService.swift`
- iPhone app runtime now owns that bridge service so future ActivityKit driver code can consume one stable source instead of re-deriving queue state again

What this bridge does:

- converts `PhotoMemoBackgroundStatusService` output into ActivityKit-ready attributes and content-state payloads
- tracks the current projected job and any obsolete job IDs that a future ActivityKit driver should end
- keeps Live Activity preparation separated from the main editor and from the raw queue model

Why this matters:

- the next Dynamic Island / Lock Screen slice can focus on the actual ActivityKit lifecycle and widget presentation
- PhotoMemo avoids coupling future Live Activity code directly to `BatchQueueStore`
- this keeps the current iteration small and build-safe while still moving the iPhone roadmap forward

### 0.6 App-side Live Activity driver is now wired, with a safe fallback when presentation is not fully available yet

The latest follow-up after that takes one more small step:

- adds an app-side driver:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityDriverService.swift`
- the driver now:
  - observes `PhotoMemoiOSLiveActivityBridgeService`
  - restores any existing PhotoMemo activities on launch
  - requests a new Live Activity for an active external job
  - updates the activity while progress changes
  - ends the activity when the job becomes terminal or obsolete
- `PhotoMemoiOS` target now declares:
  - `NSSupportsLiveActivities = YES`

Safety choice for this slice:

- if the current environment can compile ActivityKit but still cannot successfully request a Live Activity, the driver disables repeated request attempts instead of spamming the pipeline with the same failure over and over

Why this matters:

- the iPhone app now has a real ActivityKit lifecycle driver, not only payload preparation
- the next slice can focus on the widget / Lock Screen / Dynamic Island presentation side instead of redoing app-side lifecycle work
- the current implementation still keeps risk controlled because it fails closed when full presentation support is not ready

### 0.7 Live Activity presentation and widget-extension wiring are now buildable end to end

The latest follow-up first added a presentational shell:

- `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoLiveActivityPresentation.swift`

What it contains:

- a `Widget` definition for the PhotoMemo Live Activity presentation
- Lock Screen layout
- Dynamic Island compact / minimal / expanded regions
- shared icon, tint, and status helpers that read from the new ActivityKit-ready payload

This line then moved past the project-wiring blocker:

- `Source/PhotoMemo/PhotoMemoWidgetExtension/PhotoMemoWidgetExtensionBundle.swift`
- `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`
- `Source/PhotoMemo/ShareExtension-Info.plist`
- `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`

What was resolved:

- the share extension plist now includes the base bundle keys Xcode expects, so the embedded extension no longer collapses to a `(null)` bundle identifier
- `PhotoMemoiOS` now embeds both:
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`
- the new widget extension target now builds cleanly and hosts:
  - `PhotoMemoLiveActivityWidgetDefinition`
  - shared Live Activity payload/presentation files

Why this matters:

- the UI/presentation side for Live Activities is no longer just a shell inside the app target; it now has a real extension target and real embedded product output
- PhotoMemo's iPhone line has crossed from “ActivityKit groundwork only” into “project can build app + share extension + widget extension together”
- the next Live Activity slice can focus on runtime behavior and device validation instead of re-fighting `xcodeproj` embed wiring

### 1. Addy Osmani skills installed for future development workflow

The following skills are now installed in local Codex:

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

Recommended usage pattern for future work:

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

### 2. MainView refactor continued in controlled slices

`MainView.swift` is still large, but it has been meaningfully reduced and split into focused subviews.

Recent extracted files:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+MemoryProgress.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+SetupPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`

MainView line-count trend observed in this refactor stream:

- `5706`
- `5096`
- `4885`
- `4614`
- `4529`
- `4314`
- `4164`
- `3974`
- `3648`
- `3496`
- `2905`
- `2842`
- `1186`
- `467`
- `300`
- `228`
- `112`
- `72`

Current result:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now acting more like a coordinator
- its remaining coordinator state is now partially grouped through `MainPresentationState`, `MainAlertState`, and `MainEditorSessionState`
- template setup, logo setup, photo import summary, anchor setup, live preview shell, and multiple editor/panel regions have been extracted
- composer session state, workspace configuration lifecycle, and export/save actions have now also been split into dedicated `MainView+*.swift` files
- dead block-style composer helpers and their unused widget file have now been removed instead of being kept as stale compatibility code
- some dead UI helpers were removed after extraction to prevent stale code from remaining in `MainView`

### 3. Template-calibration UI structure is more stable

Completed structural extractions now cover:

- template section
- template rename sheet
- custom content section
- logo section
- photo section
- anchor section
- preview/detail display shell
- inline custom-region editor
- variable library panels
- field editor wrappers
- output / permission panels

This means future MainView work should prioritize:

- any lingering state-heavy editing helpers that still live inline
- any remaining preview-adjacent helper logic that is still coupled to coordinator code
- any permission/scene lifecycle actions that still sit beside unrelated coordinator code

### 4. Immers-style white border direction has already been integrated

Product/UI decisions already established in this workstream:

- only borrow the bottom white-bar design language from Immers
- keep PhotoMemo content centered on memory + smart modules, not generic EXIF-only filler
- unify the old badge semantics toward `Logo 标识`
- for `immersWhite`, when no custom logo is selected, use a classic Apple mini logo fallback
- horizontal layout was tuned to better match the reference direction while still staying consistent with PhotoMemo

Key related files:

- `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Models/TemplatePreset.swift`
- `Source/PhotoMemo/PhotoMemo/Models/Template.swift`
- `Source/PhotoMemo/PhotoMemo/Models/TemplateItem.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Template/BadgePickerView.swift`

### 5. Permission and content wording refinement started

Latest refinement work now also covers:

- denied photo-library permission no longer pretends the system prompt can be re-shown; the UI now guides the user toward System Settings
- birthday-style smart text suppresses awkward under-one-year wording like `0岁8个月`
- the `补充信息` section now uses a single card and treats the checkbox as custom batch-description mode; when it is off, PhotoMemo falls back to the rendered right-bottom content

### 6. Multi-configuration workspace controls are now in progress

Latest MainView work now also adds a real right-side configuration workflow:

- three persisted local configuration slots
- one active slot at a time
- right-side save / restore-default actions instead of the old toolbar-only save entry
- a right-side operation-guide menu and sheet
- dismissible helper cards for anchor, smart-module, and supplemental-content guidance

Behavior expectations for this slice:

- switching slots should refresh the left-side configuration state and right-side preview together
- unsaved slots should fall back to `模板 1 / 2 / 3` default skeletons
- the active slot should remain aligned with the batch queue's default configuration snapshot

### 7. Workspace naming and help-center navigation were refined

The latest follow-up refinement now also adds:

- custom naming for each of the three configuration slots
- a dedicated rename sheet for the active slot
- a grouped right-side help-center menu instead of a flat operation-guide list
- a formal split-view help center with category navigation and topic detail panes

Important behavior choices:

- slot renaming changes only the workspace slot label, not the template name
- restoring a slot to its default skeleton clears the saved snapshot but keeps the custom slot name
- already-dismissed inline tips remain removable from the left side, while the full explanation stays available inside the help center

### 8. Left-side clutter and output controls were reduced further

The latest cleanup pass now also does the following:

- memory-progress guidance is dismissible like the other helper cards
- the personalized-region guidance is dismissible instead of being hard-coded inline text
- the supplemental-content area is truly reduced to a single card
- the permission block no longer occupies the sidebar after both permissions are granted
- the help center no longer keeps a separate permission topic after the permission flow is already understood
- the output area now focuses on album selection plus save-to-library, without the extra metadata-validation buttons

### 9. Dead validation UI paths were cleaned out of MainView

The latest internal cleanup pass now also removes:

- the no-longer-reachable metadata-validation sheet flow from `MainView`
- the old metadata debug view file that was only serving that removed flow
- the collapsed-permission-summary branch that no longer matters now that the whole permission block hides after authorization

This keeps the UI simplification aligned with the actual coordinator code instead of only hiding old actions visually.

### 10. Custom-region editing moved closer to visual module composition

The latest refinement slice now also does the following:

- the extra top control/help block under `个性化区域` is gone from the left side
- the old inline raw-token editing path was removed from `MainView`
- manual text is now added and edited as its own literal chip inside the same single-line module flow
- `识别数据` and `智能数据` keep acting as direct insert buttons into the explicitly selected region
- user-facing help copy in the editor/help center no longer leans on raw `{{token}}` syntax
- the `补充信息` and `输出` section explanations now use dismissible guide cards, with the fuller explanation still preserved in the right-side help center

Behavior expectations for this slice:

- tapping a region still defines the only valid insertion target
- inserted EXIF / smart modules should remain human-readable instead of exposing raw tokens
- users should be able to keep composing around modules without switching to a separate text-entry sheet
- the template section should show human-readable default-output summaries instead of raw template tokens

### 11. Custom-region editing now favors cursor-based inline composition

The latest follow-up slice now also does the following:

- the four custom regions no longer require a separate “添加文字 / 编辑文字” action
- users can click directly into a region and type their own short phrase inline
- EXIF and smart-module buttons now insert into the current text cursor position instead of inserting as separate manual-text chips
- inserted modules are shown as human-readable inline labels such as `〔年岁〕`, so the editor no longer exposes raw `{{token}}` syntax during normal editing
- the right-side help-center wording for the custom-region topic now reflects the new cursor-first editing model

Behavior expectations for this slice:

- clicking a region should place or restore the caret inside that region
- clicking a module button should insert that module exactly at the current caret or selected text range
- users should be able to continue typing before or after an inserted module without opening any extra sheet
- the underlying template still persists real raw tokens, so preview/render/export behavior should remain on the existing pipeline

### 12. Inline module visuals were restored closer to block-style editing

The latest follow-up slice now also does the following:

- inline module labels inside the four custom regions are rendered with block-like highlighted styling instead of appearing as plain text only
- deletion near a module now expands to the full inline module label, so backspace/delete behaves closer to removing one whole block
- editor-side display mapping now also covers common composite tokens such as `camera_summary`, avoiding mixed output like one readable label plus one raw token

Behavior expectations for this slice:

- a module inserted at the caret should look visually distinct from ordinary typed text
- when the caret is immediately next to a module, delete/backspace should remove the whole module display label in one action
- display-only labels must still map back to the original raw template tokens before preview/render/export

### 13. Share-intake persistence and fallback hardening advanced again

The latest iOS-readiness slice focused on making the external intake path safer for novice users without changing the main calibration UI.

Completed in this round:

- added a shared album-selection helper:
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAlbumSelection.swift`
- removed the share-extension snapshot path's dependence on `PhotoAlbumOption` constants from the photo-library export layer
- strengthened `ExternalPhotoIntakeStore` so persistence failure now cleans up managed inbox copies instead of leaving orphaned temporary files behind
- deduplicated repeated URLs before persisting or queueing external-intake requests
- `PhotoMemoAppRuntime.flushExternalRequests()` now filters out missing source files before enqueuing, so stale requests degrade into smaller valid batches instead of failing later at import time
- `PhotoMemoShareExtensionIntakeService` now:
  - accepts partial success instead of treating one provider failure as a whole-share failure
  - reports imported / skipped / failed counts back to the share UI
  - tries a safer fallback path using file URLs or raw image data when direct file representation is unavailable
  - does **not** fall back to `UIImage -> JPEG` rewriting, to avoid silently stripping EXIF or changing the source photo bits during intake

Why this matters:

- it stays aligned with the "ExternalIntake is pure temporary storage" decision
- it reduces invisible failure modes before the real import/render/export pipeline starts
- it keeps metadata-retention priorities ahead of convenience fallbacks

Verification for this round:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning on macOS build
- not yet manually verified:
  - real Photos share-sheet input that provides only `loadItem` data and not file representation
  - multi-photo share where one or more items disappear before the host app flushes the request
  - user-facing wording and timing of the share-extension success/partial-success message on device

### 14. Share-extension compile surface was reduced to a small shared core

The latest architecture slice focused on trimming `PhotoMemoShareExtension` so it only compiles what the share-intake pipeline actually needs.

Completed in this round:

- added a synchronized-group target-exception set in:
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
- excluded clearly app-only files from the share-extension target, including:
  - main app shells
  - `Views/*`
  - renderers
  - queue / export / permission services
  - unused engines and helper extensions
- extracted `ExternalPhotoIntakeRequest` into its own shared file:
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
- this removes the previous coupling where `ExternalPhotoIntakeStore` depended on `ExternalPhotoIntakeCenter.swift` just to see the request model
- refined the share-extension success message so partial-success feedback only shows the non-zero skipped / failed counts

Current result:

- the share-extension target now compiles against a much smaller shared core
- the generated `PhotoMemoShareExtension.SwiftFileList` is now `19` lines, down from the previous much broader compile surface that still included:
  - `MainView`
  - preview/template/anchor views
  - app entry shells
  - queue/export/permission services

Why this matters:

- iOS share flow is now less coupled to the macOS calibration UI
- future extension-specific bugs become easier to isolate
- future share-flow testing is less likely to be blocked by unrelated UI/service regressions

Verification for this round:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning on macOS build
- not yet manually verified:
  - real share-sheet behavior after the new target slimming on device
  - whether any third-party share source relies on a file path or raw data shape not yet seen in manual testing

## Behavior Rules Preserved During Refactor

These behaviors were intentionally preserved and should not be reverted:

- variable insertion must target an explicitly selected custom region
- no implicit fallback that silently inserts into the right-bottom region
- template switching, restoring defaults, and template rename must refresh composer editing state
- preview-side template calibration must stay connected to the real render/export chain

## Verification Status

Recent verification command:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Status:

- build passes
- only Xcode destination-selection warning observed
- no new compile error from the latest MainView extraction rounds
- there is still no separate automated test target in the current Xcode project, so refactor validation is currently build-first plus manual regression checks

## Current Technical Debt

### Coordinator shell is now thin, but needs semantic cleanup

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now down to about `72` lines, which is a strong coordinator-shell result.

The remaining debt is no longer raw file size. It is now about whether the remaining state is grouped at the right boundary and whether access control / ownership are as clear as the new structure suggests.

### Multi-config and in-app guidance still need a dedicated design slice

The newly requested three-slot configuration system and right-side operation guide are both product-shaping changes. They should be implemented as a dedicated state/persistence redesign instead of being mixed into small UI tweaks.

### Manual UI regression checks are still needed

Builds are passing, but some refactor rounds were verified mainly by compilation and structure review. Manual checks remain important for:

- template rename flow
- anchor selection flow
- photo import flow
- logo fallback behavior on `immersWhite`
- preview/export visual parity

## Recommended Next Steps

### Near-term

1. Tighten access control now that the `MainView` coordinator shell has settled
2. Revisit badge / output / workspace bindings and move any obviously local binding logic beside the related panels
3. Run a deliberate manual check for:
   - template switching
   - template rename
   - anchor selection
   - photo import
   - live preview rendering after import
   - white-border logo fallback

### Product hardening

1. Continue preview/export parity work
2. Continue metadata-retention validation
3. Harden failed-task retry and library save feedback

### Architecture

1. Keep reducing macOS-only assumptions where practical
2. Preserve future iOS migration room
3. Avoid adding new feature surface faster than the real processing chain can support

## Best Entry Files For A New Session

Read in this order:

1. `README.md`
2. `AI_CONTEXT.md`
3. `HANDOFF.md`
4. `AGENTS.md`
5. `Docs/CURRENT_STATUS.md`
6. `Docs/DEVELOPMENT_PLAN.md`

Then inspect:

- `git status`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- the newest `MainView+*.swift` extraction files

## 2026-06-19 Follow-Up

This round added a dedicated inline-composer display engine:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerDisplayEngine.swift`

Purpose:

- stop treating every visible `〔...〕` label as a real token
- track real inserted modules by span instead of regex-only text matching
- keep module-aware selection/deletion behavior aligned across macOS and UIKit

Related notes kept for the next session:

- optimization log:
  - `Docs/OPTIMIZATION_LOG_2026-06-19.md`
- competitor and product-direction notes:
  - `Docs/COMPETITOR_NOTES_2026-06-19.md`
- iOS readiness audit:
  - `Docs/IOS_READINESS_2026-06-19.md`
- manual regression checklist:
  - `Docs/MANUAL_REGRESSION_CHECKLIST_2026-06-19.md`

MainView re-review result for this follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `3621` lines
- the next most valuable extractions are:
  - composer session state
  - workspace configuration lifecycle
  - export/save actions

## 2026-06-19 External Intake Foundation Follow-Up

The latest infrastructure slice now also does the following:

- adds a shared app-container helper:
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift`
- adds a persisted intake inbox:
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- updates `ExternalPhotoIntakeCenter` so external image requests are no longer in-memory only
- updates settings, permission-primer state, and batch-queue persistence to read/write through a shared defaults entry point
- updates app runtime activation flow so persisted intake requests are automatically flushed on launch/activation without adding any progress UI back into the main screen

Behavior expectations for this slice:

- external intake requests should survive app relaunch instead of being lost with process memory
- the default batch configuration snapshot used for background intake should stay aligned with the current saved workspace configuration
- the main UI should remain a calibration center only; no queue/progress panel should reappear

## 2026-06-19 External Intake Cleanup Follow-Up

The latest follow-up now also does the following:

- teaches `ExternalPhotoIntakeStore` to clean up only the managed source files that PhotoMemo copied into the shared `ExternalIntake` inbox
- wires that cleanup into safe terminal paths:
  - after a task completes successfully
  - when a queued/running job is explicitly cancelled

Behavior expectations for this slice:

- shared intake files should no longer accumulate forever after successful background processing
- failed tasks should still retain their managed source files so retry remains possible
- original user-selected files outside the managed intake inbox must never be deleted by this cleanup path

## 2026-06-19 External Intake Orphan Cleanup Follow-Up

The latest follow-up now also does the following:

- exposes the currently referenced managed source URLs from `BatchQueueStore`
- runs an orphaned managed-intake cleanup scan during app-side external-intake refresh
- removes inbox child files/directories that are no longer referenced by any pending request or persisted batch task

Behavior expectations for this slice:

- a previously interrupted app session should not leave unmanaged `ExternalIntake` directories accumulating forever
- queued, running, or failed-for-retry managed sources must remain intact while still referenced by queue state

## 2026-06-19 Share Extension Skeleton Follow-Up

The latest follow-up now also does the following:

- adds a minimal iOS share-extension intake service that writes incoming shared images into the existing shared `ExternalIntake` inbox
- adds a minimal share-extension view controller and extension plist/entitlement files
- wires a real `PhotoMemoShareExtension` target into the Xcode project
- keeps the main iOS app entry isolated behind a compilation condition so the extension target can compile cleanly without conflicting `@main` app entrypoints

Behavior expectations for this slice:

- the repository now contains a real compilable share-extension target rather than only “future-ready” architecture
- shared images can be persisted into the same intake pipeline foundation already used by the app runtime
- the main calibration-center UI remains unchanged; this slice is project/runtime groundwork only

## 2026-06-19 Strict Temporary Intake Follow-Up

The latest follow-up now also does the following:

- tightens the shared `ExternalIntake` copies into a strict temporary-file policy
- cleans managed intake source files on all terminal outcomes, including failed tasks
- marks failures that have lost their managed temporary source as non-retryable
- trims persisted terminal job history before saving queue state

Behavior expectations for this slice:

- managed intake files should not linger as a long-term cache after success, cancellation, or failure
- retry should remain available only for failures whose source is still genuinely available
- queue history should stop growing without bound across long-term usage

## 2026-06-19 Partial Failure Semantics Follow-Up

The latest follow-up now also does the following:

- refines batch-result semantics so small failure counts are treated as exceptions instead of making the whole batch feel like a total failure
- updates failure summaries and completion notifications to prefer “mostly completed, with exceptions” language when most photos succeeded
- hides retry actions for failures that no longer have a real recoverable source under the strict temporary-file policy

Behavior expectations for this slice:

- when a large batch finishes with only one or a few failures, users should still feel that the batch fundamentally completed
- failure handling remains explicit, but it no longer overstates the impact of isolated exceptions

## 2026-06-19 Share Extension Warning Cleanup

The latest follow-up now also does the following:

- moves the share-extension plist outside the synchronized `PhotoMemo/` group root
- points `PhotoMemoShareExtension` at the new external plist path
- removes the previous share-extension `Info.plist` bundle-resource warning during build verification

## 2026-06-19 Share Extension Slimming Follow-Up

The latest follow-up now also does the following:

- extracts a lightweight shared batch-configuration snapshot reader:
  - `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
- moves the share-extension intake flow away from the full `SettingsService` dependency
- keeps the extension reading only the minimum persisted configuration inputs it needs to enqueue shared photos consistently

Behavior expectations for this slice:

- the share extension should now rely on a smaller, clearer configuration boundary
- future target slimming can focus on removing additional unnecessary app-only compile dependencies without changing the user-visible flow

## 2026-06-19 Refactor Completion

This follow-up successfully landed the three extractions that were queued in the previous note:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerSession.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceConfigurationState.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`

What moved out of `MainView.swift`:

- editor display text / selection / module-span session state
- workspace-slot save, switch, restore-default, and snapshot application flow
- photo-library permission prompt, album reload, and save-to-library actions

Updated structure result:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `2905` lines
- build succeeds again after removing the leftover duplicate legacy method definition
- the coordinator file is now meaningfully less responsible for low-level editing and save-flow mechanics

One more safe follow-up extraction has already landed after that:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PermissionLifecycle.swift`

That file now owns:

- first-appearance permission refresh
- active-scene permission refresh
- primer-sheet permission request flow
- notification permission request feedback

Latest line-count result after this extra slice:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `2842` lines

This workstream then continued with a more aggressive but still behavior-preserving cleanup:

- removed the no-longer-used block-style composer item state, chip widgets, literal-composer sheet, and scrubber helpers
- extracted `MainView+DerivedState.swift`
- extracted `MainView+CoordinatorSupport.swift`
- extracted `MainView+TemplateEditingActions.swift`

Latest line-count result after that cleanup:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `1186` lines

The refactor then continued with two more coordinator-focused extractions:

- extracted `MainView+PresentationState.swift`
- extracted `MainView+LayoutSections.swift`

That moved:

- rename-sheet / help-center sheet presentation and local draft state
- sidebar/detail assembly and section-level view composition

Latest line-count result after that follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `467` lines

One final light cleanup also landed immediately after:

- extracted `MainView+UIPrimitives.swift`

That moved:

- `MainFieldSlot`
- palette and card/chip style primitives
- small shared layout wrappers used by the main editor flow

Latest line-count result after this step:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `300` lines

The coordinator shell then kept shrinking in two small, safe follow-ups:

- extracted `MainView+ModalAndLifecycle.swift`
- extracted `MainView+Feedback.swift`

That moved:

- anchor sheet / rename sheet / help sheet / alert wiring
- onAppear / onChange lifecycle routing
- alert presentation helper and local preview stub

Latest line-count trend after these last follow-ups:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `228` lines
- then around `112` lines
- and after grouping the remaining editor session state, around `72` lines

Verification for this completion slice:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- not yet manually verified:
  - permission primer -> authorize -> album refresh flow
  - switching workspace slots while custom-region editor caret is active
  - save-to-library success and failure alerts against a real photo

One more light state-ownership follow-up has now landed:

- added `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`
- grouped the remaining editor-session fields into `MainEditorSessionState`
- moved `focusedField`, display texts, selections, and module spans under that single coordinator-facing state model

Latest result after this follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now about `72` lines
- the coordinator shell now mostly declares service/state ownership and forwards `body` to `mainScene`
- the earlier `MainPresentationState` / `MainAlertState` grouping is now joined by `MainEditorSessionState`, which makes the remaining state easier to reason about without changing editor behavior

Verification for this extra slice:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- not yet manually verified:
  - workspace-slot switching while editor caret is active
  - live caret preservation while repeatedly inserting EXIF / smart modules
  - save-to-library success and failure alerts against a real photo

Next three most valuable areas after this slice:

1. selective access-control tightening after the refactor settles
2. badge/output/workspace bindings that can move beside their related panels
3. manual regression coverage for caret routing, slot switching, and export feedback now that the coordinator shell is structurally stable
