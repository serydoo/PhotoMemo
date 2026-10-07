# Small-phone landscape source checkpoint — 2026-10-07

## Accepted scope

Product Loop, observation-led UI refinement. Owner explicitly accepts the current small-phone landscape direction provisionally and authorizes GitHub synchronization. Version remains 2.3.6 (124); this source checkpoint follows released source baseline `06eebcd23b495bb7d7c89ad37924ada16870ee0c` and does not establish a new App Store release.

- Reserve the trailing navigation region within NavigationStack using safeAreaInset; content uses the remaining safe width.
- Keep three destinations and root-owned selection/session state. Selected floating-navigation icons use accent color without a blue background tile.
- Add a separate contextual preview toggle and reuse existing Save/More actions in the side region. Save has a 36pt visual circle within a 46pt touch region. Short side regions can scroll.
- Compact-height card editing can collapse/reopen the preview; portrait retains existing automatic preview visibility. Keep the accepted small-phone editor structure. Simultaneous complete preview/editor presentation on Duo remains a separate future slice.
- Align landscape expanded-panel edges; place time-expression choices and a bounded, vertically centered example side by side when width/type size allow. Preserve vertical fallback and input geometry.
- Match landscape Home and Progress page-heading alignment and spacing, preserving portrait presentation.

## Verification and review

Final signed generic iPhoneOS Debug build succeeded: `/tmp/MemoMarkLandscapeSync-build.log`. Focused macOS-host tests passed: 69 passed, 0 failed, 0 skipped, `/tmp/MemoMarkLandscapeSync.xcresult` (preview visibility, adaptive page layout, iPhone responsive contracts). The research measurement-report unit tests also passed (4/4). These host tests do not substitute for physical iOS visual acceptance.

Signed package installed/launched on the paired iPhone 17 Pro Max during this pass. Physical captures inspected: Home heading `/tmp/MemoMarkLandscapeWholePass-home.png`; final icon-only navigation `/tmp/MemoMarkRailIconSelection.png`. Owner subsequently accepted the small-phone direction provisionally. Captures, build products, xcresult and device identifiers remain local.

Five-axis review: visibility transitions and action disabling reuse existing ownership; layout changes remain in UI surfaces; no new dependencies, network flows or media processing; ordinary typography and TextKit attachment/caret geometry remain intact; optional inset defaults preserve other hosts. No blocking source-review finding. Navigation/preview tests and signed build cover the bounded source checkpoint, not full production certification.

## Remaining gates

Native Duo arrangement/reserved-region integration, wider iPad/macOS presentation, both landscape directions with keyboard/draft/IME/focus continuity, system sheets, all four languages, VoiceOver, large Dynamic Type and Reduce Motion require their own complete acceptance. A1 visual direction is provisionally accepted; its comprehensive reliability/accessibility matrix remains open. Do not treat this checkpoint as approval to bypass those gates or as new HDR/Live Photo capability evidence.

## Synchronization boundary

Include the eleven affected iOS UI files, three related test files, adaptive/landscape specifications, post-2.3.6 research plan, five explicitly selected ExternalDesignStudies research files, routing brief and this scoped state record. Preserve unrelated release, Outreach, research, config and private assets outside the commit. No version bump, Store/TestFlight mutation or renderer/export/schema change.
