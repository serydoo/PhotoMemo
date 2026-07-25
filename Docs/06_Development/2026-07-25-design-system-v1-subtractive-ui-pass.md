# MemoMark Design System V1 Subtractive UI Pass

## Decision Gate

- Primary loop: Product Loop
- Observed scenario: The accepted surfaces are structurally mature, but Configuration Center secondary rows still repeat decorative icons and accent-colored support values, while Processing presents `查看相册` as a competing solid-blue action.
- Objective: Apply the frozen Design System through a bounded subtractive pass without changing information architecture, navigation, state, or product behavior.
- Scope: Configuration Center option rows and Processing photo-library navigation only. Home, Share Extension, and Memory Subject were reviewed and remain unchanged.
- Ownership: Configuration objects, processing state, Renderer, Layout, Export, PhotoKit, and Share lifecycle ownership remain unchanged.
- Apple-native capabilities: Continue using SwiftUI semantic colors, SF Symbols for system actions, Dynamic Type, VoiceOver, and native Button/Menu behavior.
- Risk: P2. Failure modes are reduced scanability, loss of meaningful identity imagery, ambiguous affordance, or accessibility-label regression.

## Visual Decisions

- Preserve the Memory Subject avatar and Logo preview because they display real object/content identity rather than decoration.
- Remove decorative leading icons from Time Anchor, Memory Display, Border Style, Location Display, and Card Content rows.
- Preserve row titles, subtitles, values, menus, chevrons, touch targets, and accessibility labels.
- Render supporting row details and selection chevrons with secondary hierarchy instead of repeated accent blue.
- Restyle `查看相册` as a secondary system control with semantic fill, border, and text; remove its primary-action shadow.
- Do not change Home, Share Extension, or Memory Subject in this pass.

## Verification Plan

- Add source contracts that fail while decorative row icons and the solid-blue album action remain.
- Run focused Apple-native product surface contracts.
- Build `PhotoMemoiOS` for a generic iOS Simulator with code signing disabled.
- Run `git diff --check` and review for state, accessibility, architecture, and unrelated-file changes.
- Treat simulator or signed-device screenshots as manual visual acceptance evidence rather than infer them from compilation.

## Verification Result

- The focused `AppleNativeProductSurfaceContractTests` suite passed all 17 tests.
- The generic iOS Simulator Debug build for `PhotoMemoiOS` passed with code signing disabled.
- `git diff --check` passed, and the final source review found no state-flow, accessibility-label, or architecture ownership changes.
- Manual simulator or physical-device visual acceptance was not completed; visual fidelity remains an explicit acceptance item.

## Continuation: Processing, Output, And Region Content

- Observed behavior: Processing completion repeats green through the task dot,
  status pill, percentage, progress bar, and step states. Output repeats section
  titles and uses blue, pink, and green icons across secondary rows. Region
  Content still presents four secondary-row icons and a separate explanation
  card after the editable list.
- Intended outcome: Preserve one clear completion signal, keep percentage while
  work is active but remove redundant `100%` at completion, and make Output and
  Region Content typography-first without weakening controls or state meaning.
- Scope: `V1TaskPageSurface`, `V1OutputPageSurface`, `V1RegionEditorCard`, the
  Region Content sheet composition, and focused source-contract tests.
- Product boundaries: Processing state, configuration drafts, smart-module
  composition, description-writing policy, Renderer, Export, PhotoKit, and
  Share behavior remain unchanged.
- Verification: Add failing source contracts first, run focused contract suites,
  build the signed iOS app including extensions, install and launch on `iPhone7`,
  then leave final visual acceptance to the user.

### Continuation Verification Result

- The combined Processing, Output, Region Content, configuration option, and
  symbol-contract selection passed all 32 focused tests.
- `git diff --check` passed. The signed `PhotoMemoiOS` Debug build, including
  Share Extension and Widget validation, succeeded for physical `iPhone7`.
- Installation on `iPhone7` succeeded. Automated launch was denied only because
  the device was locked; final unlocked-device visual acceptance remains with
  the user.
