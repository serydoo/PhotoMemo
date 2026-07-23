# Share Extension Compact Half-Sheet UI Pass

Date: 2026-07-21

## Observed Current Behavior Before This Pass

- Share Extension requested a preferred height of 680pt.
- The confirming state still uses engineering-oriented copy such as
  `检测到可处理照片`, `这次会如何处理`, `默认风格`, and `结果去向`.
- Preview content is hidden on the normal path, but the content hierarchy was
  still too close to one large module.
- Successful handoff enters a received state and waits for a second user tap to
  close the extension.

## Intended Outcome

- Request a compact preferred height of about 440pt so the system can present a
  half-screen-like Share Extension surface.
- Use Apple-native, outcome-first language: `已准备好`, `本次分享`, and
  `生成时光记录`.
- Show `本次分享` as one compact module with photo count, memory subject, and
  album destination.
- Add an independent `后台处理` module with four SF Symbol assurances:
  original photo unchanged, capture information retained, notification on
  completion, and continued batch sharing.
- Keep `今天的照片，也是未来的回忆。` as a plain left-aligned secondary
  message, without a functional Card background.
- After successful intake and handoff, briefly show `已开始处理`, then close
  the extension automatically.

## Scope And Boundaries

- In scope: Share Extension UIKit layout, copy, summary projection, and
  post-handoff dismissal timing.
- Out of scope: queue processing semantics, renderer behavior, metadata/export
  behavior, Main App architecture, and Photo Library ownership.
- The system Share Sheet remains the owner of the final presentation height;
  `preferredContentSize` is only a compact-height request.

## Verification Plan

- Focused source-contract tests for copy, preferred height, summary rows, and
  automatic successful dismissal.
- Focused workflow-summary tests for memory subject and raw album display.
- Unsigned generic iOS and automatically signed device builds.
- Physical-device install attempt on the connected `iPhone7` target, with
  device availability and signing limitations reported explicitly.

## Verification Results

- Focused macOS tests passed for `PhotoMemoShareWorkflowSummaryTests` and
  `ShareExtensionControllerSplitContractTests`.
- Unsigned generic iOS Debug build passed for `PhotoMemoiOS`.
- Automatically signed iPhone7 Debug build passed for `PhotoMemoiOS`,
  including the embedded Share Extension and Widget Extension.
- `git diff --check` passed.
- The signed `PhotoMemoiOS.app` was installed successfully over the existing
  app on the paired `iPhone7` device without clearing data.
- Launch verification was attempted, but CoreDevice reported that the device
  was locked. Physical Apple Photos -> Share -> MemoMark visual acceptance is
  still pending.

## Screenshot Follow-Up

- Updated the primary action to use `.systemBlue` with `.white` foreground,
  matching the reference iOS Share action treatment.
- Moved the content scroll region down to a `36pt` top inset while keeping the
  bottom action area anchored in place.
- Split the lower content into two functional Cards, `本次分享` and
  `后台处理`; the memory closing message now flows directly in the page as
  secondary text. The fixed footer leaves only the blue primary action.
- Changed the summary from a right-aligned table into vertical `照片`, `配置`,
  and `相册` groups with native separators.
- Replaced the four text checkmarks with `checkmark.circle.fill`, `camera.fill`,
  `bell.fill`, and `arrow.right.circle.fill` attachments.
- Updated the Hero subtitle to `生成 N 条新的时光记录`.
- Focused controller contract tests passed.
- Signed generic iOS build passed and the updated `PhotoMemoiOS.app` was
  installed successfully on `iPhone7`.
- Manual Apple Photos -> Share -> MemoMark visual acceptance remains pending.
