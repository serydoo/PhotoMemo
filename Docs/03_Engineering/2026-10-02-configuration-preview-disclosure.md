# Configuration Center preview disclosure

## Decision before implementation

Product Loop, P2: owner-provided build 116 screenshots show the fixed preview occupying most of the configuration viewport even when reviewing output settings. Add a quiet text and chevron button to the right of the Configuration Center title. Default visible; hiding removes the entire preview height and does not leave a placeholder.

Scope: iOS root presentation state, configuration page/header, preview container, layout summary and four-language strings. Apple capabilities: SwiftUI Button, adaptive header layout, accessibility labels/value, 44pt minimum target, Reduce Motion-aware short animation. ConfigurationSession, durable presets, snapshots, Renderer/Layout, Photos, EXIF and export contracts remain unchanged.

The root owns the temporary collapsed choice for this app lifetime, including tab switches. Restart defaults to visible. Card content editing temporarily shows the preview without mutating the choice; leaving editing restores the choice. The preview subtree stays mounted so hiding does not reset its inspection state. Existing photo zoom remains independent. Hidden preview is excluded from hit testing and accessibility. The layout summary must not refer to an invisible preview.

Risks: retained blank height, misleading summary, reset inspection state, inaccessible toggle, title collision at large text sizes, disrupted editing preview. Verification: focused state/localization tests, macOS test host, signed iPhone build/install/launch, physical screenshots/manual disclosure acceptance. No simulator UI or build. Screenshot indexing/publication work is paused for this slice.

## Evidence

Implemented the title action, zero-height hidden preview with hit-testing/accessibility exclusion, root-owned ephemeral choice, editing visibility override, adaptive title layout and four-language copy. macOS consumers keep their visible-preview default.

- Focused macOS test host: 44 passed, 0 failed, 0 skipped. `/tmp/MemoMarkPreviewDisclosureTestsFixed.xcresult` includes the three new state/localization tests and ConfigurationOptionList contracts. The first attempt failed because the new test omitted `@testable import MemoMark`; the repaired run passed.
- Signed iPhone build: succeeded at `/tmp/MemoMarkPreviewDisclosureDevice`; strict signature verification passed. Exact app: 2.3.5 (116).
- Overwrite installation and launch succeeded on paired physical iPhone 17 Pro Max; existing container retained.
- `git diff --check` and Codex governance validator passed.
- Build reports existing actor-isolation warnings in MemoMarkRenderedImageArtifactGuard, outside this change.
- Manual touch, large Dynamic Type, VoiceOver, Reduce Motion and iPad visual acceptance remain NOT VERIFIED. Desktop iPhone Mirroring screen control was unavailable in this session (ScreenCaptureKit -3811). Automated install/launch/screenshot does not establish these acceptance gates.

No version bump, commit, GitHub sync or App Store mutation. App Store screenshot indexing remains paused pending visual acceptance of this UI change.


## Physical screenshot follow-up: heading rhythm

Owner screenshots IMG_5944 through IMG_5947 show the new action but subtitle touching the preview across all four styles. The original header minimum height does not protect a taller title row from compression. This is a continuation of the same bounded UI pass: group title/subtitle on the leading side, align the action to the title baseline, use a vertical fallback for accessibility sizes, preserve the heading's intrinsic vertical size, and use existing ConfigurationUI.contentSpacing (16pt) between header and visible preview. Hidden state keeps zero inter-item preview spacing. No photo, render geometry or input-control changes. Rebuild and repeat physical installation; spacing acceptance requires a fresh device screenshot.

The adaptive preview/editor container uses SwiftUI AnyLayout so split/collapsed layout changes preserve subtree identity. Update the old source contract to assert both layout choices instead of obsolete helper names.

Follow-up validation: 137 passed / 0 failed / 0 skipped across preview state/localization, option-list, iPhone-responsive-layout and Apple-native-surface contracts (`/tmp/MemoMarkPreviewDisclosureSpacingTests.xcresult`, macOS host). Final signed physical iPhone build and strict signature verification passed; overwrite install and launch succeeded again for 2.3.5 (116). Final build log: `/tmp/MemoMarkPreviewDisclosureSpacingDeviceBuild.log`. Owner screenshots verified presence of the first title action and reproduced heading spacing failure; fresh spacing/collapse/editing visual acceptance remains pending. The automatic post-install capture showed SpringBoard and is not App UI evidence.
