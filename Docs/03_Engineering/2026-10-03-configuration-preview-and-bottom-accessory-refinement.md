# Configuration Preview And Bottom Accessory Refinement

## Decision before implementation

Primary loop: Product Loop.

Observed evidence: the owner-provided October 3 iPhone screenshots show two
remaining presentation issues in the otherwise accepted Configuration Center.
First, the deliberately rendered alternate-orientation preview remains visible
behind the active card and exposes partial image/footer/text fragments. The
existing left/right 44pt edge controls already communicate orientation
switching, so the duplicate peek now reads as clipping residue rather than a
useful affordance. Second, the compact iPhone Configuration Center presents its
own bottom `safeAreaInset` action surface directly above the system tab bar,
creating two independent bottom chrome layers.

Intended outcome:

- Keep the active preview large, preserve orientation switching and portrait
  inspection gestures, but remove the duplicate alternate-card rendering.
- On iOS 26+, let the outer `TabView` own Configuration Center save actions via
  SwiftUI `tabViewBottomAccessory`, so the action surface participates in the
  system tab-bar lifecycle instead of competing with it.
- While the Configuration Center accessory is visible, keep the tab bar in its
  expanded form instead of allowing automatic minimization to compress the
  primary save action into inline accessory geometry. Other tabs retain the
  system automatic minimization behavior.
- Keep the current page-owned `safeAreaInset` footer as the iOS 18-25 fallback.
- Keep compact-landscape/iPad sidebar behavior unchanged: regular workspaces
  continue to use the existing toolbar configuration actions.
- Preserve Card Content editing: no save accessory is shown while the inspector
  owns the editor, and its preview/keyboard behavior remains unchanged.

## Ownership and boundaries

Scope is presentation-only:

- `AdaptiveNavigationShell.swift`
- `MemoMarkConfigurationCenterView+Pages.swift`
- `ConfigurationPageSurface.swift`
- `MemoryCardEditorPageSurface.swift`
- `ConfigurationActionFooter.swift`
- `ConfigurationPreviewBackground.swift`
- `MemoryCardPreviewSection.swift`
- focused architecture/presentation tests

The canonical configuration owner remains `ConfigurationSession` and the
existing root lifecycle state. No Preset schema, processing snapshot, Renderer,
Layout Engine, Photos, EXIF, Live Photo, export, StoreKit entitlement, or
persistence behavior changes.

Apple-native capability evaluated: SwiftUI `tabViewBottomAccessory` is
available from iOS 26.0. Use it only for `.bottomTabBar`. Deployment remains
iOS 18, so the current `safeAreaInset` footer remains the explicit degradation
path on iOS 18-25. The iOS 26.1 `isEnabled` overload is preferred where
available to preserve TabView identity while hiding the accessory; iOS 26.0
uses conditional accessory content. SwiftUI `tabBarMinimizeBehavior` is also
available from iOS 26.0 and is set to `.never` only while the configuration
accessory is visible; otherwise it remains `.automatic`.

## Risk

P1 because the change touches the primary Configuration Center save workflow
and bottom navigation/accessibility. Failure modes to prevent:

- losing save or more-actions access on supported OS versions;
- showing save actions on Home/Progress or during Card Content editing;
- recreating configuration state while the tab accessory appears/disappears;
- retaining old footer spacing after adopting system accessory geometry;
- changing preview orientation/zoom semantics while removing the alternate
  visual layer.

## Verification plan

- source-contract tests for native accessory ownership, fallback behavior and
  active-preview-only rendering;
- existing preview orientation/viewport and configuration action tests;
- iOS generic-device build;
- focused test suite first, then broader affected architecture tests;
- `git diff --check`;
- paired physical iPhone visual/touch/VoiceOver validation remains the final
  acceptance for accessory placement and preview appearance.

## Closure evidence

- Production preview now renders only the active orientation. The existing
  44pt left/right controls, accessibility orientation action, portrait
  compact/full inspection gesture, and app-local orientation preference remain
  unchanged. The alternate-card peek constants and duplicate canvas are gone.
- Compact iPhone navigation now adopts `tabViewBottomAccessory` on iOS 26+.
  iOS 26.1+ uses the native `isEnabled` path; iOS 26.0 uses conditional
  accessory content. While configuration actions are visible the tab bar uses
  `.never` minimization, returning to `.automatic` on other tabs. iOS 18-25
  continues to use the existing page `safeAreaInset` footer. Sidebar/regular
  workspace toolbar behavior is unchanged.
- The system-accessory path suppresses the duplicate page footer and reduces
  the editor's legacy manual bottom padding because the system now owns the
  accessory avoidance geometry.
- Preview disclosure chrome now derives title, chevron and accessibility value
  from explicit `previewIsVisible` state rather than inferring state from a
  localization-key string.
- Focused macOS-host regression:
  `ConfigurationOptionListContractTests`,
  `IPhoneResponsiveLayoutContractTests`, and
  `FilmMarkPresentationSpecificationTests` passed 126/126 with 0 failures and
  0 skips. Result:
  `/tmp/MemoMarkUIRefineTestsClosure/Logs/Test/Test-MemoMarkTests-2026.10.03_23-50-53-+0800.xcresult`.
- Generic iOS `MemoMarkiOS` Debug build passed with signing disabled at
  `/tmp/MemoMarkUIRefineBuildClosure`. Reported actor-isolation warnings in
  `MemoMarkRenderedImageArtifactGuard` are pre-existing and outside this UI
  slice. `git diff --check` passed.
- Paired physical iPhone 17 Pro Max was discovered and targeted, but the signed
  destination build could not begin because iOS reported that the device must
  be unlocked to enable Development Services. No install, uninstall, container
  reset, Photos write, or other device mutation occurred. Physical visual,
  touch, Dynamic Type and VoiceOver acceptance therefore remains open.

## 2026-10-04 physical-device delivery attempt

Owner authorized delivery of the current working tree to the paired iPhone 17 Pro Max. Live CoreDevice identification matched [local paired device identifier] / iPhone18,2. Exact-device Xcode destination preparation timed out. Signed generic iOS Debug build passed (exit 0), strict codesign verification passed, and package version is 2.3.5 (122). Artifact: `/tmp/MemoMarkPhoneDelivery20261004/Build/Products/Debug-iphoneos/MemoMarkiOS.app`; build log: `/tmp/MemoMarkPhoneDelivery20261004Generic.log`. Installation command produced no receipt while developer services were stalled; a separate ddiServices query timed out after 20 seconds. The stalled install CLI was terminated. Installation and launch remain unverified; owner asked to unlock and reconnect USB before retry. No uninstall or container reset was performed. Manual preview/accessory acceptance remains open.

### Retry closure — 2026-10-04 04:46 CST

After owner requested continuation, developer disk image services returned compatible/isUsable=true. The previously verified current-worktree signed Debug artifact overwrite-installed successfully (devicectl exit 0), normal launch with --terminate-existing succeeded, and device app readback confirmed MemoMark 2.3.5 (122). Post-launch process inspection confirmed MemoMarkiOS PID 1063 and Widget extension processes alive. No uninstall, container reset, or Photos operation was performed. This closes build/install/launch delivery evidence; preview appearance, accessory touch behavior, Dynamic Type and VoiceOver manual acceptance remain open.
