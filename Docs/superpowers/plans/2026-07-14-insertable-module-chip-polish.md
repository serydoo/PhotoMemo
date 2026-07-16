# Insertable Module Chip Polish Implementation Plan

> **For agentic workers:** Execute inline as one focused UI task. Do not delegate or broaden the scope.

**Goal:** Polish the production iOS inserted-module chip removal control while preserving all Configuration Center behavior.

**Architecture:** Keep the existing view and callback flow unchanged. Add one file-local SwiftUI `ButtonStyle` so pressed state, touch sizing, Reduce Motion, and visual treatment remain isolated inside the production `V1RegionEditorCard`.

**Tech Stack:** SwiftUI, iOS Configuration Center, Xcode build verification

---

### Task 1: Add the focused remove-button style

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift`

- [x] Replace the remove icon's `.buttonStyle(.plain)` with a file-local button style.
- [x] Keep the existing chip icon, title, fill, outline, and removal callback.
- [x] Add a stable 24-point control frame and an explicit VoiceOver action label.
- [x] Use a restrained pressed-state scale only when Reduce Motion is disabled.

### Task 2: Verify the production target

- [x] Run the generic iOS Debug build with code signing disabled.
- [x] Run the Share Extension generic iOS Debug build.
- [x] Run `git diff --check` and inspect the focused diff.
- [x] Build, install, and launch on the compact MemoMark QA iPhone SE 3
  simulator. The app launch passed, but a fresh-install Photos permission sheet
  blocked the target editor surface; pressed-state and VoiceOver inspection
  remain manual verification items.

### Task 3: Make the module hierarchy visibly native

- [x] Add the native `plus` SF Symbol to the add-module command.
- [x] Replace the accent-filled Capsule with a semantic system-fill rounded
  rectangle.
- [x] Keep module symbol, title, and removal action in distinct accent, primary,
  and secondary visual roles.
- [x] Rebuild, sign, install, and launch the updated App on `TestDeviceA`.

### Task 4: Add causal module feedback

- [x] Trigger native selection feedback when the user chooses a module from the
  module library.
- [x] Trigger native selection feedback when the user removes an inserted
  module.
- [x] Keep sheet presentation, search, scrolling, literal-text editing, and
  configuration changes silent.
- [x] Rebuild, sign, install, and launch the tactile-feedback build on
  `TestDeviceA`.
- [x] Confirm on `TestDeviceA` that module insertion produces perceptible native
  selection feedback.

### Task 5: Clarify module-library actions

- [x] Use the app accent hierarchy for module-row symbols.
- [x] Add the native trailing `plus.circle.fill` affordance without changing
  the row action.
- [x] Move the Done command to the confirmation toolbar position.
- [x] Rebuild, sign, install, and launch the module-library polish build on
  `TestDeviceA`.
- [x] Confirm on `TestDeviceA` that the module-row action hierarchy is visible.

### Task 6: Strengthen the composition result

- [x] Separate the composition result from editing controls with a native
  divider.
- [x] Add the semantic `text.quote` SF Symbol to the result label.
- [x] Promote resolved content from caption-secondary styling to subheadline
  primary styling without changing the resolved value.
- [x] Rebuild, sign, install, and launch the result-hierarchy build on
  `TestDeviceA`.

### Task 7: Distinguish literal-text objects

- [x] Apply one shared local style to existing and transient literal text
  fields.
- [x] Use semantic system background, a continuous corner, and the existing
  faint hairline.
- [x] Preserve focus, cursor, width calculation, insertion, and synchronization
  behavior.
- [x] Rebuild, sign, install, and launch the literal-object build on `TestDeviceA`.
- [x] Confirm on `TestDeviceA` that literal text and module objects are visually
  distinct.

### Task 8: Clarify expanded-object state

- [x] Apply a restrained selected background to expanded disclosure headers.
- [x] Promote the expanded icon and chevron into the accent hierarchy.
- [x] Expose expanded/collapsed state to accessibility.
- [x] Disable disclosure animation when Reduce Motion is enabled.
- [ ] Rebuild, sign, install, and launch the expanded-state build on `TestDeviceA`.
