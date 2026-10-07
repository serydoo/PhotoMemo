# Duo-Driven Adaptive Configuration Layout

> Current checkpoint (2026-10-07): the owner provisionally accepts the small-phone landscape UI and authorizes source synchronization. The current implementation reserves the rail region, supports contextual preview collapse, unifies panel/header alignment and uses icon-only navigation selection. Earlier observations below are chronological evidence. Small-phone two-pane exploration is superseded; native Duo integration and the comprehensive keyboard/accessibility matrix remain open. See [source checkpoint](2026-10-07-landscape-source-checkpoint.md).

Date: 2026-10-06
Status: Accepted direction; implementation begins with the bounded iPhone landscape navigation slice.

## Objective

Use iPhone Duo's fully expanded presentation as the new reference for MemoMark's
future wide-screen spatial grammar, while preserving MemoMark's product identity
as a Configuration Center rather than turning it into an image editor.

The canonical daily workflow remains:

`Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos`

The app UI exists to establish and maintain the configuration that this automatic
processing path consumes. The real Memory Card preview is feedback for that
configuration, not a separate editing canvas or the primary product workflow.

## Decision Gate

- Primary loop: Product Loop, bounded cross-device interface refinement.
- Affected owner: Presentation Feature / Configuration Center shell only.
- Frozen architecture: `Library -> Interactive Memory Card -> Object Inspector`.
- Source of truth: `PROJECT_CONSTITUTION.md`, `Docs/CURRENT_BRIEF.md`,
  `APPLE_PLATFORM_EXPERT.md`, current production source, and the September 2026
  cross-surface/macOS review records.
- Apple capability evaluated: SwiftUI size classes, native navigation containers,
  materials, safe areas, accessibility, and the iOS 27.1 Duo presentation APIs.
- Current toolchain boundary: the local machine is on Xcode/iPhoneOS SDK 27.0;
  iOS 27.1-only Duo APIs must not enter the compiling production path until a
  27.1 toolchain is available and their exact declarations are verified.
- Risk: P2 for the first landscape-navigation slice; P1 for later replacement of
  established iPad/macOS navigation and wide Configuration Center presentation.

## Product Model

The design must preserve these statements:

1. Configuration is the primary task.
2. Preview is immediate configuration feedback and must continue to reflect the
   real presentation/rendering pipeline.
3. Sending a photo to MemoMark is the normal processing action; users should not
   be required to re-enter a visual editor for each photo.
4. Fold state, orientation, window size, and device family may change only the
   Presentation geometry. They must not change Memory Engine truth, durable
   configuration, Layout Engine output truth, Renderer behavior, PhotoKit
   lifecycle, Live Photo pairing, EXIF handling, or export semantics.

## Cross-Device Presentation Grammar

### Ordinary iPhone portrait

- Keep the three primary destinations in the system bottom tab presentation:
  Home, Configuration, Progress.
- Do not copy Duo's vertical bar into the normal portrait phone layout.

### Ordinary iPhone landscape

- Replace the current fixed-width leading compact sidebar with a trailing,
  floating vertical navigation rail.
- The rail contains only the three primary destinations: Home, Configuration,
  Progress.
- The rail floats over the page edge rather than owning a permanent 64pt column.
- Settings remains a utility destination opened from the existing contextual
  entry; it is not promoted to a fourth equal primary button.
- This is a Duo-inspired presentation, not a claim that an ordinary iPhone has
  Duo's available width.

### iPhone Duo expanded / iPad wide presentation

- Treat Duo fully expanded as the new visual reference for the future wide
  Configuration Center.
- Configuration remains the dominant working surface; preview occupies a stable
  companion region and may be enlarged when space permits.
- Navigation can move to a vertical edge presentation when the platform provides
  sufficient width and the native APIs support it.
- The eventual implementation should prefer capability/available-space decisions
  over device-name or hinge-angle branches.
- iOS 27.1 `ArrangementView`, reserved-region handling, vertical system bars, and
  related Duo APIs are implementation candidates once the 27.1 SDK is available.

### macOS

- The September 2026 wide Configuration Center work remains useful functional
  evidence, but its current long `ScrollView + LazyVStack` composition is not a
  visual structure that must be preserved.
- macOS should converge on the same configuration-first spatial grammar as Duo
  and iPad while retaining native desktop affordances such as inspector,
  keyboard shortcuts, pointer behavior, and window resizing.
- Do not mechanically reproduce an iPhone rail on macOS; preserve the shared
  hierarchy and interaction semantics rather than identical chrome.

## First Implementation Slice

Scope:

- rename the internal compact-landscape navigation mode to describe its actual
  presentation rather than a sidebar;
- replace the 64pt leading `EntryCompactSidebar` with a trailing floating rail;
- keep the destination state binding unchanged so orientation changes preserve
  the selected destination and Configuration Session state;
- retain the ordinary iPhone portrait `TabView` and regular-width
  `NavigationSplitView` paths unchanged;
- add source-contract coverage for the three-button floating rail and for removal
  of the fixed compact sidebar host.

Out of scope:

- iOS 27.1-only Duo APIs;
- macOS page restructuring;
- iPad wide Configuration Center restructuring;
- durable preference for left/right rail placement;
- Renderer, Layout Engine, media pipeline, PhotoKit, Share Extension, persistence,
  commerce, or configuration-schema changes.

## Verification

For this first slice:

1. focused adaptive-layout and responsive-layout contract tests;
2. generic iPhoneOS Debug build;
3. `git diff --check`;
4. signed physical-device build/install/launch when practical;
5. manual landscape review on the paired iPhone 17 Pro Max for reachability,
   overlap, selected-state clarity, rotation continuity, Dynamic Type, VoiceOver,
   Reduce Motion, and light/dark appearance.

The physical visual review remains a separate acceptance gate; a successful
build does not certify the final rail size, offset, material, or touch feel.
