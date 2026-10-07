# iPad adaptive observation — 2026-10-07

## Scope and decision gate

Product Loop; owner explicitly authorizes autonomous iPad/simulator exploration. Baseline e83c7e70, 2.3.6(124). Risk P2 for observation; any navigation/focus implementation is P1 and requires a bounded specification and physical iPhone regression evidence. No renderer, metadata, export, Photos or durable configuration changes.

Apple-native capability: existing NavigationSplitView for navigation, AnyLayout for configuration preview/editor arrangement. Evaluate available content width after sidebar and keyboard; preserve one ConfigurationSession and canonical UIKit input geometry.

## Build evidence

Current MemoMarkiOS Debug simulator build exited0. Derived data /tmp/MemoMark-iPadResearch; log /tmp/MemoMark-iPadResearch-build.log. Info.plist readback2.3.6/124. Existing actor-isolation warnings in MemoMarkRenderedImageArtifactGuard remain; not zero-warning. No production Swift source modified.

## Environment observations

iPad Pro11 M5, UDID4A18A2A3-F11D-45B9-AC1C-B5973253C6D1, iOS27.0: device inventory became Booted, but screenshot showed Apple startup progress. Progress changed between captures; install/launch command remains waiting, no MemoMark screen observed. AX initially failed unknown interface orientation0; landscape command acknowledged, but subsequent screenshots timed out. bootstatus and launchctl probes also did not complete promptly.

Backup iPad Pro13 M5, UDID2AB4C4B7-CA9C-4A0E-BBF9-ADB05F9E550D, iOS26.4: boot command completed, bootstatus returned SimError405 (Unable to boot device in current state: Booted); screenshot timed out, installation did not complete promptly. Shutdown requested to reduce load. Do not erase existing simulator data.

Screenshots/manifest retained locally: /tmp/MemoMark-iPadResearchEvidence. No private corpus injected or uploaded. Simulator startup is an environment blocker; app installation, launch and visual audit are NOT VERIFIED.

## Source findings requiring runtime confirmation

- AdaptiveNavigationShell uses balanced NavigationSplitView for regular horizontal layouts. MemoryCardEditorPageSurface independently chooses equal-width HStack whenever both size classes are regular and preview visible. Actual available editor width is not an input to that decision. Hypothesis: sidebar plus preview can constrain controls in narrow iPad windows; NOT a visually confirmed defect.
- Preview is kept in the same AnyLayout subtree when collapsed; this supports inspection-state continuity by design but does not certify focus/navigation continuity across entry-shell branches.
- AdaptivePageLayout limits readable column width720. Broadening text to consume all big-screen space would conflict with current readable-width policy; evaluate preview and controls separately.

## Next bounded audit

1. Recover a single simulator to interactive SpringBoard; install exact built package and record runtime build.
2. Capture Home/Configuration/Progress, landscape and portrait, sidebar expanded/collapsed.
3. Expand four style and expression controls; collapse/reopen preview; verify independently scrollable settings and reachable save/more.
4. Enter Card Content; record selected region, literal text, token selection and focus before/after rotation and keyboard.
5. Check narrow windows and large text. Choose layout using actual pane capacity without changing input line boxes.
6. Consolidate all verified findings into one UI pass before product edits; build/focused tests and physical iPhone regression remain separate.

Duo remains unavailable until >=27.1 runtime is installed. Baguette0.2.3 exposes hinge poses closed/open/flat and angle control; command availability is confirmed, actual Duo operation remains NOT VERIFIED.

Recovery closure: both explicit per-device shutdown commands exited0; backup install/launch ended SimError405 with server-died/Shutdown evidence. Outstanding simulator command processes from this audit were terminated; no erase/reset used. Local Simulator.app at the older conventional Xcode path was absent, so that GUI recovery attempt did not open an app. Runtime/device visual audit remains blocked.


## Recovery and observed iPad results (supersedes environment blocker)

123 orphan iOS27 runtime processes had PPID1 after all devices were shut down. TERM sent to exact runtime path;41 unresponsive survivors stopped. Host responsiveness recovered. Single iPad Pro13/iOS26.4 bootstatus finished in53seconds; current package installed and launch returned PID28552. Input and AX later succeeded. Baguette heal reported no Device Hub shadowing. Landscape AX coordinates are in native portrait display coordinates; use returned frames, not upright screenshots for CLI input. Discard AX reads explicitly rejected during rotation.

Evidence directory /tmp/MemoMark-iPadResearchEvidence:08-config.png (portrait),09-landscape.png,11-card.png,12-keyboard.png,13-card-portrait.png,14-sidebar-hidden.png, corresponding successful AX JSON.

Verified observations:
- Portrait with sidebar: configuration preview and inspector share detail width; expression fifth option is outside visible viewport. Horizontal-scroll reachability remains unverified; do not call it inaccessible.
- Landscape with sidebar: all five expression options and four card input rows visible.
- Keyboard: preview top is cropped in landscape and portrait; full output preview expectation not met.
- Rotation to portrait retains left-upper field focused and same existing text/token value. Does not prove inserted draft/undo/IME continuity.
- Hiding sidebar increases input width238.5pt->403.5pt, retains focus and four40pt input line boxes.

## Bounded UI pass and first increment

User identifies excessive sidebar width. Product Loop, P2 first increment in AdaptiveNavigationShell.swift: apply native navigationSplitViewColumnWidth(ideal:240) to sidebar List. Current native default consumes about320pt, including four short destinations; preferred240pt returns80pt to detail. Keep min/max unset so platform, localization and accessibility may negotiate. Apple's API is a preference, not guaranteed width. Do not replace sidebar, change selection/session owners, input geometry or renderer. Source:https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(min:ideal:max:) .

Consolidated subsequent pass: use actual content capacity for preview/inspector arrangement; keep full card visible when keyboard shrinks available height; ensure expression picker fit/fallback. These need specifications and evidence before implementation. First increment verification: incremental simulator build, install exact candidate, capture sidebar expanded in portrait/landscape and measure; preserve iPhone navigation, physical regression status separately. No added tests for static preferred-width modifier.


Owner amendment: large screens must use trailing/right-side navigation in portrait and landscape, reusing current compact landscape floating rail and referencing Duo. Left sidebar width trial compiled successfully but was withdrawn before installation because it no longer matches owner direction; production source restored exactly. Research scope is now trailing navigation/action arrangement, capacity, safe regions and state continuity. Do not proceed with narrowing the left sidebar.

## Unified right-side navigation and action specification

Owner confirms both groups must move together: page navigation and contextual configuration actions. Product Loop; P1 because changing the navigation container can affect editor identity, navigation state and accessibility. This is UI placement work only; Configuration Session, durable configuration, Memory Engine, input line boxes and Renderer/export contracts retain ownership.

- iPad/full-width large-window portrait and landscape use the existing right-side floating rail family. Ordinary compact phone portrait retains bottom tabs; compact phone landscape retains the accepted rail. Narrow iPad windows are classified by available capacity, not device orientation alone.
- Place Home/Configuration/Progress in the navigation group. Place preview visibility, save and more in a separate contextual group below, on the same physical right-side axis. Contextual actions appear only where applicable; existing card-editor save suppression stays intact. Settings remains reachable through its existing entry.
- Center the complete combined group vertically in the available safe viewport; do not individually pin either group to the top. On short windows or keyboard-reduced height, retain reachable actions through the existing vertical scroll fallback. Do not enlarge icons to fill an iPad.
- Reserve right-side content space at the host boundary using the existing safeAreaInset rather than overlaying controls on the preview or fields. Keep the existing 56pt rail column/46pt control geometry for the first trial, including >=44pt interaction targets. Selected state remains confined around the icon. These are current MemoMark values, not claimed Apple constants.
- Physically right is a product requirement, including RTL. SwiftUI trailing alone is not sufficient to prove physical-right placement; isolate rail physical placement from the content's semantic reading direction and verify an RTL locale. Do not globally force the whole app LTR.
- Preserve one selected-tab owner and the same configuration/editing state across rotation and resize. Do not instantiate a second editor for the new rail. Verify focused field, draft text and token values before/after rotation; keyboard/IME and undo acceptance remain separate.
- Preview and inspector arrange according to actual remaining width/height after reserving controls. Full output preview uses proportional fit; scroll belongs to the inspector. Keyboard-related preview cropping observed in baseline is a separate issue that must not be concealed by the navigation change.

### Duo adaptation boundary

Apple's official guidance supports side controls to preserve vertical content space, shared navigation/toolbar/tab regions, symbol representations with accessible titles, grouping and overflow. It does NOT require a right vertical bar in every state: the inner display in portrait returns to horizontal bars. A native Duo adapter must be validated separately; never show native bars and a duplicate custom rail together. Always-right in every Duo pose remains a MemoMark product requirement whose native/custom implementation needs runtime evidence, not a claim of automatic system support. Reserved display regions and available scene geometry must govern content placement; do not choose layout by hinge angle alone.

Sources: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo and https://developer.apple.com/videos/play/tech-talks/111462/ . SDK compile probes are available; an eligible Duo runtime/device is still unavailable locally, so no Duo visual acceptance is recorded.

### Ordered implementation and acceptance

1. Audit navigation-style callers and footer/preview visibility so the new large-window rail cannot create duplicate controls. Record a bounded policy change; retain the old sidebar until references and state transitions are reviewed.
2. Reuse the current floating host for regular-width windows. Test phone portrait, phone landscape and large-window navigation policy; build the exact candidate.
3. Install locally to the recovered iPad simulator. Capture Home/Configuration/Progress portrait and landscape, and configuration rail with preview open/closed. Compare both groups' alignment, content reservation and action reachability.
4. Exercise editor rotation, keyboard, narrow window, larger text and RTL. Verify unchanged input geometry and draft/state continuity. Record failures before broadening the change.
5. Run signed paired-iPhone regression separately. Duo runtime acceptance remains open; simulator navigation checks do not certify Photos or Live Photo fidelity.

Current closure: research/specification complete for the two right-side groups; production navigation has not yet been changed or installed. The withdrawn left-width candidate's successful build is not verification of this right-side design.


## First right-rail implementation increment

Regular horizontal size class now selects the existing floating rail rather than the sidebar; compact portrait remains bottom tabs. Updated the existing regular-width policy test name/expectation. No session, input, renderer, export or durable state changes. Exact MemoMarkiOS simulator build passed (exit0), installed without container erase and launched PID42850 on iPad13/iOS26.4. Standalone compiled policy check passed all four width/height combinations; this does not claim the complete Swift Testing suite ran. Landscape Home screenshot18 and portrait Home screenshot20 show the rail on the right, centered vertically, without the former left sidebar. Screenshot17 was captured during launch and is black; exclude it from acceptance evidence.

Remaining: Configuration and Progress screenshots, contextual action-group reachability, editing rotation/keyboard, RTL physical-right placement, accessibility and physical-iPhone regression. Existing trailing inset is not yet proven physically right in RTL. Duo remains unverified. No GitHub sync or release performed for this increment.


## Contextual-control follow-up

Configuration portrait AX22 revealed duplicate top-toolbar save/more and header preview actions alongside the rail. Consolidated ConfigurationPageSurface toolbar/footer visibility and MemoryCardEditorPageSurface header toggle around the navigation-style policy; rail mode now supplies the sole copies. Final simulator rebuild passed exit0. Physical-right host placement isolates LTR geometry around the safe-area inset while restoring inherited content layout direction inside the destination; RTL runtime verification remains required. Configuration baseline screenshot22 predates this correction and is retained as defect evidence.


## Final candidate observed checks

Simulator candidate launch PID44558. AX25 and screenshot25-final-config-landscape confirm exactly one save, more and preview-collapse action, all in the rail; no duplicate header/toolbar copies. AX26 confirms preview collapse changes the rail action to expand while save remains present. Progress landscape screenshot27 and portrait screenshot28 captured; AX27 discovered0 nodes and is not used as accessibility acceptance. Latest signed physical-device build passed exit0; install/launch evidence recorded separately below. No complete IME/undo, keyboard preview-fit, accessibility/RTL runtime or Duo acceptance claimed.

Physical iPhone17ProMax 00008150-000A043136A1401C: signed candidate installed successfully without container erase; devicectl launch succeeded. This confirms delivery only, not manual visual, keyboard, VoiceOver or Photos acceptance.
