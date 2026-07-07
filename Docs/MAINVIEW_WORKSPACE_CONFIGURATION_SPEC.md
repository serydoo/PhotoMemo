# Spec: MainView Workspace Configurations And Operation Guide

## Objective
Add a real multi-configuration workflow to MemoMark's calibration UI and reduce left-panel clutter with dismissible guidance and a right-side operation guide.

This slice turns the user's requested "3 个按钮" into three real local configuration slots. Each slot can persist the full calibration state, including:

- template and custom region content
- selected anchor
- selected logo / badge
- supplemental content and description-writing mode
- album destination
- a custom slot name used only for workspace organization

The right side becomes the home of:

- the active configuration switcher
- save / restore-default actions for the active slot
- an operation guide entry point

This keeps the left side focused on editing and the right side focused on "which configuration is currently driving the preview."

## Assumptions
1. The initial three slots should map to `模板 1 / 模板 2 / 模板 3` as their default skeletons when the user has not saved custom content yet.
2. `Immers 白边` remains selectable within any slot, but it is not one of the three default empty-slot skeletons.
3. The current single saved configuration should be migrated into the active slot on first run of this feature so the user does not lose today's work.
4. The operation guide can ship first as a sheet opened from a menu, which satisfies the user's "二级菜单" intent without overcomplicating the layout.
5. Dismissible section hints should target the most confusing areas first: time anchors, smart modules, and supplemental content.
6. Slot renaming should change only the workspace slot label, not the underlying template name, so users can organize scenarios without altering template semantics.

## Tech Stack
- Swift 5
- SwiftUI
- Xcode project: `Source/PhotoMemo/PhotoMemo.xcodeproj`

## Commands
- Build: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- Git status: `git -C /Users/rui/Desktop/PhotoMemo status --short`

## Project Structure
- `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift` -> local configuration persistence
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` -> state routing, slot selection, slot save/apply logic
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceControls.swift` -> right-side configuration panel, operation guide, dismissible helper cards
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+*.swift` -> section-level UI receiving current state from `MainView`

## Code Style
Keep configuration-slot persistence in `SettingsService` and slot-application behavior in `MainView`. Keep the new right-side controls display-oriented.

```swift
let snapshot = slot.snapshot ?? defaultWorkspaceConfigurationSnapshot(for: slotID)
applyWorkspaceConfigurationSnapshot(snapshot)
```

## Testing Strategy
- Primary verification is project build success with `xcodebuild`
- There is currently no separate automated test target in the Xcode project
- Manual verification focus:
  - switching among the three slots refreshes left-side fields and right-side preview together
  - an unsaved slot falls back to its default template skeleton
  - saving writes the current editing state into the active slot
  - restoring default clears the custom snapshot for the active slot
  - slot renaming persists across relaunches and does not reset when restoring slot defaults
  - operation-guide menu opens the corresponding grouped help-center sheet
  - dismissing section hints keeps the main UI cleaner on later launches

## Boundaries
- Always:
  - keep the real preview/render/export pipeline intact
  - preserve explicit slot routing for custom region insertion
  - keep the app local-first
  - run a build after edits
- Ask first:
  - expanding beyond three fixed slots in this round
  - converting the guide sheet into a larger navigation subsystem
  - changing background queue semantics beyond following the current active configuration snapshot
- Never:
  - revert unrelated user changes
  - make the three buttons cosmetic-only
  - split configuration state away from the actual batch/export defaults

## Success Criteria
- MemoMark has three real local configuration slots with one active slot at a time
- Each configuration slot can be given a custom user-facing name without changing template names
- The right side contains the configuration switcher and save actions instead of the old toolbar-only save button
- Switching slots refreshes the active calibration state and preview coherently
- Unsaved slots fall back to default template skeletons
- Key left-side explanatory text appears as dismissible helper cards
- A right-side grouped help center provides the detailed usage help that was previously scattered across the editor
- Build succeeds after the change

## Open Questions
- Should section-hint dismissal sync across all slots permanently, or eventually move under an app-wide "show tips again" reset?
