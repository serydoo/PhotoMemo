# Settings Content Hierarchy UI Pass

Date: 2026-07-25

## Decision Gate

- Primary loop: Engineering Loop.
- Evidence: the current iPhone settings screenshots show consistent section
  containers but five competing body patterns, long policy copy, equal visual
  weight for every feedback channel, and developer-oriented version wording.
- Risk: P2. This is a bounded SwiftUI content and presentation change with no
  persistence, commerce, navigation, renderer, export, or Apple Photos impact.
- Source of truth: existing settings actions, installed bundle version values,
  interface-language preference, and commerce batch limit remain canonical.
- Apple-native evaluation: retain SwiftUI `Picker`, `Button`, disclosure
  controls, system colors, SF Symbols, Dynamic Type, VoiceOver labels, and
  Reduce Motion behavior. No new framework or permission is required.

## Intended Outcome

Keep MemoMark+ unchanged and reduce the rest of the page to four explicit body
roles built from three visual families:

1. One concise Rich Text story for `为什么是时光记`.
2. Navigation rows for `使用与帮助`.
3. Label-and-value Info Cards for capability, privacy, and version facts.
4. A Contact List that prioritizes formal feedback before community channels.

The language picker remains the native segmented control with one supporting
sentence. Existing disclosure state and all destinations remain unchanged.

The final page order is:

`MemoMark+ -> 为什么是时光记 -> 使用与帮助 -> 能力与边界 -> 隐私与数据 -> 反馈渠道 -> 应用界面语言 -> 版本信息`

Commerce and brand establish the product first. Help and reference information
support the main workflow; feedback follows when that information is not
enough. The low-frequency language preference and installed-version facts form
the bottom utility group.

## Bounded Change Set

- Shorten the brand story while preserving its origin, Memory Engine meaning,
  local-first promise, and three existing value tags.
- Remove decorative icons and tint blocks from ordinary disclosure headings;
  retain the unchanged MemoMark+ mark and semantic status symbols inside rows.
- Make capability rows concise and remove internal validation or extension
  memory-pressure language from the user-facing page.
- Convert privacy prose into four checkmarked label-and-detail rows.
- Prioritize TestFlight and email feedback; place QQ, social accounts, and
  GitHub under community/developer channels with lighter supporting copy.
- Present the app name, `Version`, and `Build` without Xcode Cloud or internal
  product-version terminology.

Out of scope: MemoMark+, localization architecture, configuration persistence,
commerce behavior, new feedback destinations, hidden build metadata, and any
photo-processing behavior.

## Verification Plan

- Add focused source-contract tests before implementation.
- Run the focused settings contract suite and the existing settings disclosure
  contracts.
- Run an unsigned iOS build and `git diff --check`.
- Inspect on an available simulator or physical device for compact width,
  Dynamic Type, VoiceOver order, light/dark appearance, and disclosure behavior.
  Record unavailable manual evidence explicitly.

## Verification Result

- `V1SettingsDisclosureContractTests`: 8 passed, 0 failed after the EXIF and
  Settings-owned tutorial follow-up.
- `PhotoMemoiOS` unsigned generic iOS Debug build: passed.
- `git diff --check`: passed.
- Review found no configuration, commerce, renderer, export, PhotoKit, privacy,
  security, or performance boundary changes. MemoMark+ remains unchanged.
- Simulator and physical-device visual acceptance were not completed in this
  pass. Compact-width layout, Dynamic Type, VoiceOver order, light/dark
  appearance, and the final disclosure rhythm remain manual acceptance items.
- The signed follow-up build installed successfully on `iPhone7` (iPhone 17 Pro
  Max). Automatic launch was denied twice with CoreDeviceError 10002 because
  the device was locked; the installed app remains ready for manual launch
  after unlock.

## Follow-up Content Requirement

Implemented in the follow-up settings-content pass.

Place an input prerequisite at the top of `能力与边界`:

- Product intent: only images that retain readable original EXIF metadata can
  provide the complete capture facts required for MemoMark's full
  metadata-driven output.
- Proposed user-facing direction: `原始拍摄信息` / `保留原始 EXIF 的照片，才能完整呈现依赖真实拍摄信息的内容。`
- Do not publish `完美输出` as an unconditional production claim until tests
  define and verify behavior for complete EXIF, partial EXIF, missing EXIF,
  screenshots, edited exports, and images re-saved by social platforms.
- The final row must explain graceful degradation: photos without complete
  EXIF may still be accepted when supported, but unavailable capture facts
  cannot be reconstructed or presented as original metadata.

## Follow-up Help Navigation Requirement

Implemented in the follow-up interaction pass.

`使用与帮助 -> 查看使用教程` must remain inside the Settings presentation
context:

- Current problem: the existing action routes out of Settings and returns the
  user to the app Home page.
- Intended hierarchy: Settings opens `查看使用教程` as its own child page.
- Closing or leaving the tutorial must return to Settings with the Settings
  disclosure state and scroll context preserved.
- The tutorial child must not dismiss the Settings presentation, select Home,
  or reuse an application-level onboarding route whose completion owns the
  root page.
- Before implementation, locate the current `onShowWorkflow` owner and the
  Settings presentation boundary. Prefer a Settings-owned navigation
  destination; if the existing container cannot support a child push, use a
  Settings-owned sheet whose close action dismisses only that sheet.
- Verify opening, interactive back navigation, the explicit close action,
  repeated presentation, Dynamic Type, and VoiceOver focus restoration.
