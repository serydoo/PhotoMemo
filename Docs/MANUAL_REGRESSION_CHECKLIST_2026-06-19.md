# PhotoMemo Manual Regression Checklist

Date: 2026-06-19

## Purpose

This checklist is for the current high-risk refactor stage, especially after the `MainView` coordinator cleanup and the inline custom-region editor changes.

Use it when:

- refactor slices have landed
- build passes
- there is still no dedicated automated test target
- we need to verify the real editor and export experience by hand

## Recommended Test Order

1. custom-region caret and module insertion
2. anchor switching
3. workspace-slot switching
4. album permission and save feedback
5. preview/export parity spot check

## Baseline Setup

Before running the checklist:

- launch the latest local build
- prepare at least one real photo with intact EXIF capture date
- make sure the machine can access the system photo library
- if possible, test once with photo-library permission already granted and once from a fresh or denied state

Suggested build command:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

## 1. Custom-Region Caret And Module Insertion

### 1.1 Direct typing into each region

- Open `个性化区域`.
- Click into `左上区域`.
- Type a short phrase such as `今天`.
- Repeat once for `右上区域`, `左下区域`, and `右下区域`.

Expected:

- each region can be focused independently
- typed text stays in the region that was clicked
- no text silently falls back into `右下区域`

### 1.2 Insert EXIF module at caret

- Click into one region and place the caret at the beginning.
- Click one item from `识别数据`.
- Move the caret to the middle of the same line.
- Click another EXIF module.
- Move the caret to the end.
- Click one more EXIF module.

Expected:

- each module inserts exactly at the visible caret position
- inserted content displays as human-readable module labels rather than raw `{{token}}`
- surrounding typed text remains intact

### 1.3 Insert smart module at caret

- In the same region, type text before and after existing modules.
- Place the caret between two text fragments.
- Click one item from `智能数据`.

Expected:

- the smart module appears at the current caret location
- the existing text on both sides remains unchanged
- no implicit area switch happens during insertion

### 1.4 Delete around modules

- Put the caret immediately after a visible module label.
- Press delete/backspace.
- Repeat once with the caret immediately before a module.

Expected:

- deleting near a module removes the module as a whole unit, not partial label characters
- adjacent ordinary text is not accidentally removed

### 1.5 Replace mixed text + module selection

- Select a range that includes:
  - normal typed text
  - at least one module
- Type replacement text or insert another module.

Expected:

- the replacement behaves naturally
- no duplicated module labels remain behind
- the resulting content still renders correctly in preview

## 2. Anchor Switching

### 2.1 Switch between different anchors

- Import one real photo.
- Select an existing birthday-like anchor.
- Observe the `时间锚点` summary and right-side preview.
- Switch to a non-birthday anniversary-style anchor.
- Switch to a future countdown-style anchor.

Expected:

- quick facts update immediately
- preview content and smart result text update together
- no stale anchor summary remains visible

### 2.2 Anchor switching while editor focus is active

- Click into one custom region so the caret is active.
- Without manually clearing focus, switch the selected anchor.
- Then click one smart module button.

Expected:

- anchor data updates correctly
- the current editing slot remains usable
- module insertion still goes into the intended region

### 2.3 Under-one-year age wording

- Use a photo and anchor combination where the age result is under one year if available.

Expected:

- no awkward `0岁...` wording appears
- the result should stay in the improved under-one-year style

## 3. Workspace-Slot Switching

### 3.1 Switch between the three slots

- In the right-side workspace panel, switch among the three configuration slots.
- Observe left-side fields and right-side preview each time.

Expected:

- template, anchor, logo, supplemental content, and album selection refresh together
- the right-side preview stays synchronized with the active slot
- active-slot highlighting is always correct

### 3.2 Switch slots while editor caret is active

- Click into one custom region and place the caret in the middle of existing content.
- Switch to another workspace slot.
- Switch back.

Expected:

- no stale editor content from the previous slot leaks into the next one
- the restored slot shows its own saved editor content
- editor session refresh stays aligned with the active slot

### 3.3 Unsaved slot fallback

- Use one slot that has not been explicitly saved, if available.
- Switch away and back.

Expected:

- the slot falls back to its expected default skeleton
- it does not unexpectedly inherit another slot's customized state

### 3.4 Rename and restore default

- Rename the current slot.
- Save current configuration.
- Use `恢复当前默认`.

Expected:

- restoring default resets the configuration snapshot
- the custom slot name can remain according to the current product rule
- template and editor state refresh cleanly after restore

## 4. Album Permission And Save Feedback

### 4.1 Granted state

- Run with photo-library permission already granted.
- Check whether the permission section hides when both required permissions are already granted.

Expected:

- the left-side permission block does not keep occupying space after authorization
- album options can be loaded normally

### 4.2 Denied state

- If possible, test from a denied photo-library permission state.
- Trigger save or album loading.

Expected:

- PhotoMemo does not pretend the system will re-show the native prompt automatically
- the UI clearly routes the user to system settings instead

### 4.3 Album list refresh

- Grant permission, then reopen or re-activate the app if needed.
- Open the output section and inspect album choices.

Expected:

- the album list loads successfully after authorization
- a no-longer-existing album selection falls back safely to `自动存入 PhotoMemo`

### 4.4 Save to library success

- Import a real photo.
- Confirm the preview is visible.
- Choose either automatic album or a specific album.
- Click `存入系统相册`.

Expected:

- a success alert appears
- the saved image lands in the expected album
- the original photo is not modified in place
- the output is a new image

### 4.5 Save failure feedback

- If a controlled failure can be reproduced safely, trigger one.

Expected:

- a failure alert appears
- the message is understandable
- the app does not stay stuck in `正在存入系统相册...`

## 5. Preview And Export Parity Spot Check

### 5.1 Preview reflects current template state

- Change template preset.
- Change custom-region text.
- Change anchor.
- Change badge/logo.

Expected:

- the preview updates after each meaningful change
- there is no stale content from the previous template state

### 5.2 Saved image matches preview directionally

- Save one generated image after checking the preview carefully.
- Compare:
  - custom text
  - inserted modules
  - badge/logo
  - anchor-derived results

Expected:

- the saved result follows the same content structure as preview
- no obvious mismatch appears between preview and final output

## 6. High-Risk Bug Signals

If any of the following appears, treat it as a regression worth fixing before more UI work:

- content inserts into `右下区域` without explicit selection
- anchor switch updates summaries but not preview
- slot switch leaves old editor content in the new slot
- module deletion breaks surrounding text
- save button stays stuck in loading state
- album list does not refresh after permission is granted
- preview and exported result disagree on visible content

## 7. Suggested Recording Format

For each run, record:

- build date or commit context
- test photo used
- which checklist sections passed
- exact failure step if one occurs
- screenshot if the failure is visual

Suggested shorthand:

- `PASS`
- `FAIL`
- `NOT RUN`

## 8. Current Priority

At the current repository stage, the most important manual checks are:

1. caret routing during module insertion
2. anchor switching while editor focus is active
3. workspace-slot switching while editor focus is active
4. real save-to-library success/failure feedback
