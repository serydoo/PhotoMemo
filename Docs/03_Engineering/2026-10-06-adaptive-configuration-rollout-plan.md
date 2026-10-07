# MemoMark Adaptive Configuration Rollout Plan

> Current checkpoint (2026-10-07): the owner provisionally accepts the small-phone landscape UI and authorizes source synchronization. The current implementation reserves the rail region, supports contextual preview collapse, unifies panel/header alignment and uses icon-only navigation selection. Earlier observations below are chronological evidence. Small-phone two-pane exploration is superseded; native Duo integration and the comprehensive keyboard/accessibility matrix remain open. See [source checkpoint](2026-10-07-landscape-source-checkpoint.md).

Date: 2026-10-06
Status: Execution roadmap
Baseline: MemoMark 2.3.6 (124), `main` at `06eebcd2`
Toolchain at planning time: Xcode 27.0 / iPhoneOS SDK 27.0

2026-10-07 execution update: the live selected toolchain is Xcode 27.2
(27B5028f), iPhoneOS SDK 27.2. `ArrangementView` and reserved-region queries
are present in SwiftUICore with 27.1 availability; the research-only probe
typechecks for an iOS 18 deployment target. This advances declaration/compile
verification only, not Duo runtime acceptance. Phase 1 physical acceptance
remains the active product gate. See
`2026-10-07-post-2.3.6-research-execution-plan.md` for the combined content/form
research execution and current evidence.

## 1. Goal

Deliver one coherent Configuration Center presentation system across ordinary
iPhone, iPhone landscape, iPad, macOS, and iPhone Duo without duplicating product
logic or turning MemoMark into a per-photo editor.

The rollout follows one product rule:

`Configuration First -> Preview Feedback -> Apple Photos Share Workflow`

The daily workflow remains:

`Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos`

Device posture, orientation, window size, or fold state may change presentation
geometry only. They must not change durable configuration truth, Memory Engine
truth, Layout Engine output truth, Renderer behavior, PhotoKit ownership, Live
Photo pairing, EXIF preservation, batch semantics, or export semantics.

## 2. Architecture Boundary

The frozen Configuration Center information architecture remains:

`Library -> Interactive Memory Card -> Object Inspector`

The rollout may change:

- navigation chrome;
- page composition;
- pane placement;
- preview/editor proportions;
- safe-area and reserved-region handling;
- toolbar placement and priority;
- platform-native desktop/tablet presentation behavior.

The rollout may not silently change:

- configuration schema or persistence contracts;
- Configuration Session ownership;
- production snapshot semantics;
- Memory Engine / Presentation Engine semantic ownership;
- Layout Engine or Renderer output truth;
- Share Extension intake contract;
- PhotoKit asset ownership or Live Photo lifecycle;
- commerce entitlements or batch accounting.

## 3. Target Presentation Model

| Environment | Target presentation |
| --- | --- |
| iPhone portrait | System bottom navigation with Home / Configuration / Progress. |
| iPhone landscape | Trailing floating three-destination rail over a full-width content viewport. |
| iPad compact / multitasking | Same adaptive hierarchy with graceful single-column or compressed two-pane fallback. |
| iPad wide | Configuration-first two-region presentation: stable preview companion + inspector/editor. |
| iPhone Duo fully open | Same wide presentation family as iPad, enhanced by iOS 27.1 adaptive region APIs. |
| iPhone Duo book pose | Preview and configuration occupy stable logical regions separated by available-space / reserved-region rules. |
| iPhone Duo tabletop pose | Preview dominates the upper region; configuration controls occupy the lower region when platform geometry supports it. |
| macOS | Same information hierarchy and preview/inspector relationship, expressed with native desktop sidebar/toolbar/inspector/window behavior. |

## 4. Rollout Strategy

The rollout is intentionally sequential. Each phase must pass its acceptance gate
before the next phase becomes the active implementation scope. This prevents a
single UI refactor from simultaneously destabilizing iPhone, iPad, macOS, Duo,
media processing, and configuration persistence.

---

## Phase 0 — Baseline Freeze and Evidence Capture

### Objective

Create a trustworthy pre-refactor baseline so every later visual or behavioral
change can be compared against MemoMark 2.3.6 (124).

### Work

- Record current `main`, toolchain, deployment target, active schemes, and dirty
  working-tree boundaries.
- Preserve all current Configuration Center screenshots for portrait iPhone,
  landscape iPhone, iPad, and macOS.
- Record current preview behavior for Classic White, Minimal, GlassCard, and
  FilmMark in portrait and landscape media.
- Capture current configuration state continuity through rotate, background /
  foreground, preview collapse, style switching, and navigation switching.
- Confirm the current release-level tests/builds before broad layout work.

### Acceptance gate

- current iOS/macOS builds are reproducible;
- current responsive-layout tests have a known baseline;
- no unclassified pre-existing failure is attributed to the adaptive rollout;
- existing dirty work is identified and protected.

### Exit condition

Only after the baseline is captured do wide-screen structural changes begin.

---

## Phase 1 — Ordinary iPhone Landscape Navigation

### Objective

Validate the first Duo-inspired spatial rule on real hardware without touching
the Configuration Center's business structure.

### Current implementation

The former fixed 64pt compact sidebar has been replaced in the current working
tree by a trailing floating rail containing Home, Configuration, and Progress.

### Remaining work

- Physical iPhone 17 Pro Max visual review.
- Tune rail horizontal inset, vertical centering, capsule material, selected
  state, shadow, and icon size only after device evidence.
- Verify that rail overlay never hides a required trailing control or text field.
- Verify rotation preserves the selected destination and Configuration Session.
- Verify portrait returns to the normal bottom tab presentation without state
  reconstruction.
- Verify dark mode, Dynamic Type, VoiceOver, Reduce Motion, keyboard, and sheets.

### Automated gate

- `AdaptivePageLayoutTests` pass;
- `IPhoneResponsiveLayoutContractTests` pass;
- generic iPhoneOS Debug build succeeds;
- signed physical-device build succeeds;
- `git diff --check` passes.

### Product gate

The rail feels lighter than a sidebar and does not make an ordinary landscape
iPhone look like a compressed desktop application.

### Exit condition

Freeze the rail interaction contract before extracting shared wide-presentation
primitives.

---

## Phase 2 — Shared Adaptive Presentation Foundation

### Objective

Separate "what the Configuration Center is showing" from "how available space
arranges it" so iPad, macOS, and Duo can share one hierarchy without sharing
identical chrome.

### Architecture direction

Introduce a presentation-level abstraction around the existing
`MemoryCardEditorPageSurface` / Configuration Center composition. The abstraction
must accept the existing preview and inspector/editor content and decide only
their spatial arrangement.

Preferred responsibilities:

- available-space classification;
- preview/editor axis selection;
- stable region minimum sizes;
- preview visibility/collapse presentation;
- navigation presentation mode;
- safe-area / future reserved-region accommodation.

Forbidden responsibilities:

- loading or saving configuration;
- generating Memory Engine text;
- calculating renderer geometry;
- controlling PhotoKit asset lifecycle;
- changing Live Photo pair state;
- writing device-family flags into persistence.

### Compatibility rule

iOS 18 remains the deployment baseline. Existing size-class / `AnyLayout` paths
remain the fallback until the iOS 27.1 path is available and proven.

### Tests

- no `UIDevice.model`, physical screen-size, or device-name branching;
- no hinge-angle-driven primary layout decision;
- same configuration/session identity across arrangement changes;
- preview state survives axis changes;
- focus and keyboard state do not reset merely because pane geometry changes;
- production output snapshot remains independent of presentation geometry.

### Exit condition

The shared foundation can present the same Configuration Center in single-column
and two-region modes without duplicating configuration logic.

---

## Phase 3 — iPad Wide Configuration Center

### Objective

Use iPad as the first real large-screen consumer of the shared adaptive
presentation foundation.

### Wide-mode layout

- Configuration/Inspector is the primary working region.
- Real Memory Card preview is a stable companion region rather than a long-page
  header that scrolls away unpredictably.
- Preview width and editor width use bounded minimum/ideal ranges rather than a
  fixed percentage tied to physical device size.
- The frozen Library -> Interactive Memory Card -> Object Inspector hierarchy is
  preserved.

### Multitasking fallback

- narrow Stage Manager / Split View windows may collapse to the proven iPhone-like
  single-column presentation;
- do not keep a two-pane layout when either pane becomes functionally unusable;
- editor controls retain minimum 44pt hit targets and readable text geometry.

### iPad-specific validation

- hardware keyboard focus and tab order;
- pointer hover and context menus where already applicable;
- Stage Manager resizing;
- portrait/landscape resize continuity;
- maximum Dynamic Type;
- VoiceOver navigation order;
- sheet/popover anchor behavior;
- preview collapse and restoration.

### Exit condition

iPad wide mode demonstrates the intended future Duo/macOS spatial hierarchy on a
shipping Apple large-screen environment before platform-specific Duo APIs are
introduced.

---

## Phase 4 — macOS Configuration Center Convergence

### Objective

Replace the current "wide long page" bias with the same configuration-first
spatial hierarchy proven on iPad, while keeping Mac-native interaction.

### Preserve from the September work

- functional Configuration Center coverage;
- clickable/savable configuration flow;
- persistent preview capability;
- native inspector concepts;
- window resizing;
- keyboard navigation/focus;
- VoiceOver;
- native save and configuration lifecycle semantics.

### Change

- retire the assumption that `ScrollView + LazyVStack` is the canonical Mac
  spatial structure;
- give preview and inspector/editor stable sibling regions in sufficiently wide
  windows;
- allow narrow Mac windows to reflow rather than horizontally compress the entire
  Configuration Center;
- use native macOS toolbar/sidebar/inspector behavior instead of copying the
  iPhone floating rail.

### Mac acceptance

- window resizing from minimum supported width to large desktop width;
- keyboard-only completion of the main configuration flow;
- focus does not jump during preview updates;
- VoiceOver order matches the visual hierarchy;
- save/activate/freeze semantics remain unchanged;
- no AppKit-specific view owns product/business state.

### Exit condition

iPad and macOS share the same conceptual Preview + Inspector composition while
retaining platform-native navigation and input behavior.

---

## Phase 5 — Xcode 27.1 Toolchain Gate

### Objective

Move from "Duo-ready adaptive architecture" to verified Duo-native APIs only when
the SDK can compile and validate them.

### Required before code changes

- install or select Xcode 27.1;
- confirm iPhoneOS 27.1 SDK;
- build the unchanged project first;
- inspect actual SwiftUI declarations in the installed SDK;
- verify availability annotations and minimum deployment behavior;
- keep Xcode 27.0 / iOS 18 fallback source compiling where the project requires
  it.

### APIs to evaluate

- `ArrangementView` for two logical content regions;
- reserved-region geometry for crease/camera avoidance;
- iOS 27.1 vertical system navigation/toolbar behaviors;
- toolbar priority, overflow, and compression behaviors;
- hinge change APIs only for nonessential interaction polish, not primary layout.

### Exit condition

Every adopted 27.1 symbol is verified against the installed SDK rather than
implemented from documentation memory or community examples.

---

## Phase 6 — iPhone Duo Native Presentation

### Objective

Make MemoMark feel deliberately designed for Duo while preserving exactly the
same Configuration Session and processing truth used on ordinary iPhone.

### Fully open

- use the shared wide Configuration Center presentation;
- large real Memory Card preview and configuration inspector coexist naturally;
- system navigation/toolbar presentation takes advantage of Duo width where
  appropriate;
- avoid unnecessary custom chrome when iOS 27.1 can provide the behavior.

### Book pose

- keep preview and configuration in stable logical regions;
- treat the crease as a separation boundary rather than drawing content beneath
  it and masking later;
- preserve text-input focus and current configuration selection while folding or
  unfolding;
- never rebuild durable state because posture changed.

### Tabletop pose

- prefer preview / Live Photo inspection in the upper visual region;
- place configuration controls in the lower interactive region when available
  space and Apple APIs support the arrangement;
- maintain identical card content and output truth to fully-open mode;
- do not reload the Live Photo pair solely because the device posture changes.

### Hinge policy

Hinge angle is not a layout source of truth. If later used, it may drive only
optional lightweight preview effects such as restrained depth/material response.
Such effects must respect Reduce Motion and must not affect output, persistence,
accessibility semantics, or media state.

### Exit condition

Fold/unfold/posture transitions preserve the same session, same authored content,
same preview truth, and same eventual output while presenting them in a more
appropriate spatial arrangement.

---

## Phase 7 — Toolbar and Action Hierarchy Cleanup

### Objective

Use the new large-screen layouts to make action priority clearer without changing
what actions mean.

### Priority model

- highest frequency / always visible: Save;
- high priority: activate / set as next-processing configuration where relevant;
- lower frequency: create/reset/delete/import/export/diagnostic utilities in
  menus, overflow, contextual actions, or platform-native secondary locations;
- destructive operations remain explicit and bounded.

### Rule

Do not duplicate the same action in multiple persistent places merely because
more screen space is available.

### Exit condition

The user can understand "what changes the configuration" and "what saves/applies
it" at a glance on every supported form factor.

---

## Phase 8 — State Continuity and Media Integrity Verification

### Objective

Prove that adaptive presentation did not become a hidden media or persistence
refactor.

### State matrix

Verify across portrait, landscape, iPad narrow/wide, macOS narrow/wide, Duo
fully-open/book/tabletop:

- selected primary destination;
- selected configuration;
- subject/time-anchor selection;
- current style;
- authored card text/modules;
- current inspector disclosure;
- editor scroll position where expected;
- focused field / keyboard behavior;
- preview orientation and visibility;
- unsaved dirty state;
- save/activate lifecycle state.

### Media matrix

Verify:

- JPEG/HEIC static photos;
- RAW/DNG conversion path;
- Live Photo still/motion pair;
- portrait and landscape source photos;
- EXIF/time/location preservation;
- Share Extension intake;
- batch queue processing;
- designated album save;
- final notification;
- preview/output parity for Classic White, Minimal, GlassCard, and FilmMark.

### Invariant

For the same photo + saved configuration, output must be identical regardless of
device posture, window size, or which configuration UI arrangement was visible.

---

## Phase 9 — Accessibility, Localization, and Performance Gate

### Accessibility

- VoiceOver order follows visual hierarchy;
- all persistent interactive targets meet touch-size requirements;
- maximum Dynamic Type reflows rather than clips;
- Reduce Motion disables nonessential geometry transitions/effects;
- keyboard focus remains visible and predictable on iPad/macOS;
- selected states are not communicated by color alone.

### Localization

Validate zh-Hans, English, Japanese, and Korean in every navigation and wide-pane
configuration state, including toolbar overflow and compact/narrow fallbacks.

### Performance

- posture/resize changes do not cause photo re-import or production snapshot
  regeneration;
- Live Photo preview does not recreate its player/pair unnecessarily;
- expensive preview rendering remains bounded and cancellable;
- window resizing does not trigger persistence writes;
- no new repeated GeometryReader feedback loop is introduced.

### Exit condition

No P0/P1 issue remains in accessibility, localization, responsiveness, media
integrity, or state continuity.

---

## Phase 10 — Release Preparation

### Release gates

- iOS and macOS production builds succeed;
- focused architecture/responsive suites pass;
- full release suite passes or every pre-existing exception is explicitly
  classified;
- `git diff --check` passes;
- physical iPhone 17 Pro Max acceptance passes;
- iPad acceptance passes;
- macOS keyboard/focus/window acceptance passes;
- Duo simulator/device acceptance passes when Apple tooling/hardware is
  available;
- App Store screenshots/preview assets reflect the final navigation and
  Configuration Center hierarchy.

### Rollout policy

Do not block ordinary iPhone improvements on Duo-only polish. The shipping app
must continue to provide the current iOS 18-compatible presentation path while
newer systems receive adaptive enhancements behind availability/capability gates.

---

## 5. Explicitly Deferred Work

The first adaptive release should not be expanded to include:

- external-display-first Configuration Center behavior;
- Scene Accessory product features;
- persistence of a user-selected rail side;
- hinge-driven decorative effects beyond a small research prototype;
- new configuration schema fields for device/posture;
- per-device saved layouts;
- redesign of Memory Engine, Renderer, Layout Engine, PhotoKit, or Share
  Extension ownership.

These remain optional later phases only after the core adaptive Configuration
Center is stable.

## 6. Recommended Execution Order

The active sequence is:

`Phase 0 baseline -> Phase 1 iPhone landscape -> Phase 2 shared presentation ->`
`Phase 3 iPad -> Phase 4 macOS -> Phase 5 Xcode 27.1 gate -> Phase 6 Duo ->`
`Phase 7 actions -> Phase 8 state/media -> Phase 9 accessibility/performance ->`
`Phase 10 release`

Do not run structural iPad, macOS, and Duo rewrites in parallel. Shared
presentation primitives should be proven on one platform before the next platform
consumes them.

## 7. Current Next Action

The current active gate is Phase 1 physical iPhone landscape acceptance.

After that passes, the next coding task is not a Mac rewrite and not a Duo-only
view. It is Phase 2: extract the shared adaptive Preview + Inspector presentation
foundation from the existing Configuration Center and
`MemoryCardEditorPageSurface`, preserving the current iOS 18 fallback.
