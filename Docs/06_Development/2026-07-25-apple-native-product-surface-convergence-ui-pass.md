# Apple Native Product Surface Convergence UI Pass

Date: 2026-07-25

## Observed Current Behavior

Evidence comes from ten light-mode, default-text-size screenshots captured on
an iPhone 17 Pro Max on 2026-07-24.

- Home simultaneously presents product identity, development background,
  Memory Subject, configurations, feedback, and photo processing.
- Task presents dashboard-style counters, an empty current-task card, and a
  processing diagnostic row at the same time.
- Output uses `已保存` for configuration persistence, which can be mistaken for
  a completed Photo Library transaction.
- Configuration Center preserves the real Memory Card preview, but numbered
  configuration panels and four equally prominent actions compete with it.
- Settings repeats product narrative already presented by Welcome and Home.
- Hard-coded light surfaces and unconditional animations remain outside the
  shared system-surface and reduced-motion contracts.

## Intended Outcome

- Make the existing Apple Photos lifecycle easier to understand without
  changing its behavior.
- Keep Home focused on the current Memory Subject, current Preset, and one
  secondary in-app photo-picking convenience.
- Present processing as a recovery and result-confirmation surface, not a
  dashboard.
- Distinguish configuration persistence from Photo Library save completion.
- Preserve `Library -> Interactive Memory Card -> Object Inspector` while
  translating engineering language into user-facing memory expression.
- Reduce repeated explanation, nested card chrome, and non-semantic visual
  weight while preserving all production capabilities.

## Scope

In scope:

- Home, Configuration Center, Output, Processing, Settings, Welcome, and shared
  main-app surface behavior.
- User-facing state and configuration-persistence language.
- Reduced Motion, Dark Mode surfaces, and Launch Screen appearance.
- Focused source contracts and presenter tests.

Out of scope:

- IA-002 architecture, Renderer, Layout Engine, Metadata, Export, PhotoKit,
  Share Extension structure, commerce policy, and persistence contracts.
- Photo Library scanning, output history management, AI memory creation, or a
  new navigation architecture.
- Dark Mode, Dynamic Type, VoiceOver, iPad, or Share lifecycle claims without
  simulator or physical-device evidence.

## Verification Plan

- Add focused source and presenter contracts before each behavior slice.
- Run focused tests after every bounded page change.
- Run the complete unsigned test suite and required Debug build.
- Capture simulator evidence for light, dark, and accessibility text sizes.
- Record physical-device, VoiceOver, iPad, and Apple Photos Share evidence as
  remaining acceptance when it cannot be completed in this pass.

## Manual Acceptance Questions

- Can a user identify the current Memory Subject, active Preset, and next action
  on Home without reading product history?
- Can a user distinguish pending handoff, active processing, completion, and
  configuration persistence?
- Does Configuration Center still begin from the real Memory Card?
- Are destructive and secondary configuration actions visually subordinate to
  save?
- Do Dark Mode and Reduce Motion preserve system expectations?

## Closure

- Home now prioritizes the active Memory Subject, Preset, and one photo-picking
  action. Development narrative and repeated feedback no longer occupy the
  primary product surface.
- Processing no longer presents dashboard counters or an import-first action.
  It reports the real queue phase and real completed/total counts without
  fixed-time estimates.
- Output configuration persistence is explicitly named `输出设置已保存`, so it
  cannot be confused with a committed Photo Library save.
- IA-002 remains unchanged. Configuration Center now removes numbered visual
  headings, translates regions into `记录 / 时间 / 拍摄信息 / 记忆内容`, keeps
  Save as the sole prominent action, and moves configuration management into a
  secondary menu.
- Settings explanatory sections start collapsed. Interactive Memory Card
  transitions honor Reduce Motion, common UI surfaces use semantic colors,
  card shadows are quieter, and Launch Screen uses the system grouped
  background.
- Focused Apple-native and Configuration Center contract suites passed. The
  `PhotoMemoiOS` simulator build, including Share and Widget extensions,
  passed against the iOS 27 SDK. The complete macOS test suite passed 1,054
  tests with 1 existing skip and 0 failures; the required unsigned macOS Debug
  build and `git diff --check` passed.
- Simulator visual capture remains incomplete: iOS 27 and iOS 26.5 simulator
  boots both stalled in CoreSimulator LaunchServices/Data Migration before a
  stable install-and-launch cycle. No simulator data was erased. Light, Dark,
  accessibility text size, VoiceOver, iPad, physical-device, and Apple Photos
  Share acceptance therefore remain explicit manual evidence items.

## Continued Evidence Pass

- CoreSimulator migration eventually completed on the dedicated iPhone 15 Pro
  and iPhone SE 3 QA devices, but SpringBoard remained at a black screen or
  Apple boot screen. System screenshots proved that MemoMark had not reached
  installation or launch, so this is environment evidence rather than an app
  failure and cannot support a visual acceptance claim.
- Source inspection found two concrete Dynamic Type risks: Home constrained
  its Preset list to `count * 92` points and Processing constrained history
  rows to exactly 78 points. Home now uses natural content height and
  Processing uses a 78-point minimum, allowing accessibility text to expand.
- Focused contracts passed for content-driven row height, Dynamic Type layout,
  narrow-width fallbacks, Reduce Motion, VoiceOver labels on configuration
  actions, regular/compact iPad navigation, Share Extension lifecycle
  separation, and file-first Share intake.
- Dark Mode, maximum Dynamic Type, VoiceOver traversal, iPad rendering, and the
  complete Apple Photos Share lifecycle still require a working simulator UI
  or physical device. They remain manual evidence items, not inferred passes.

- A final generic iOS simulator build regenerated `PhotoMemoiOS.app`, but the
  Xcode Beta build service stopped making progress during post-build cleanup.
  The command was interrupted after its App product existed and must not be
  counted as an additional passing build. The already recorded iOS build pass
  remains the valid automated iOS build evidence for this UI pass.
