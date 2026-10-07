# Duo and ordinary iPhone landscape: verified design follow-up

> Current checkpoint (2026-10-07): the owner provisionally accepts the small-phone landscape UI and authorizes source synchronization. The current implementation reserves the rail region, supports contextual preview collapse, unifies panel/header alignment and uses icon-only navigation selection. Earlier observations below are chronological evidence. Small-phone two-pane exploration is superseded; native Duo integration and the comprehensive keyboard/accessibility matrix remain open. See [source checkpoint](../../Docs/03_Engineering/2026-10-07-landscape-source-checkpoint.md).

Date: 2026-10-07. Scope: Configuration Center presentation, not output layout.

## Current evidence

Ordinary iPhone screenshots supplied by the owner show a rail overlapping the
page, configuration rows stretched across a broad column, and a card-content
preview consuming nearly all landscape height. Portrait editing still exposes
all four fields. No evidence here certifies Duo hardware fit.

The local Xcode 27.2 / iPhoneOS 27.2 SDK declares ArrangementView,
GeometryProxy.reservedRegions and EnvironmentValues.toolbarVerticalEdge with
27.1 availability. The capability probe typechecks; production adoption is not
yet completed.

## Verified sources

- Apple, [Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111463/): geometry and reserved regions guide layout; native containers adapt to the fold; arrangements separate primary and secondary surfaces. Division and occlusion are different kinds of unavailable space. Geometry is queried in the relevant view coordinate system.
- Apple, [Raise the bar with iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111462/): native navigation, tabs and toolbars share the vertical bar; item representation and overflow are system responsibilities. A custom rail is not a substitute for this integration.
- Apple, [Design for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111466/): usable geometry can justify asymmetric displacement; preserve relationships among controls that work as a unit.
- [iPhone Duo by Examples](https://github.com/artemnovichkov/iPhone-Duo-by-Examples), retrieved directly with GitHub API: default branch main, SHA `3b9206e11595e0438e3f4d4d280bc234fe816ef8`, last pushed 2026-09-20. Inspected `SplitArrangementExample.swift` and `VerticalToolbarExample.swift`. The split demo documents primary-only fallback when two panes do not fit on the allowed axis, uses splitArrangementAxis rather than device names, and reads toolbarVerticalEdge inside the presented navigation content. This is illustrative code, not MemoMark device certification.

## Decisions for MemoMark

1. Ordinary-phone fallback rail reserves its measured width with safeAreaInset.
   Use system safe areas once, plus modest content separation. Do not reserve a
   matching empty rail on the opposite edge simply to center the whole screen.
2. Available space is a page-container concern. Readable text/input width and
   full-output aspect fit remain inner-content concerns. Expanding the outer
   container must not stretch every secondary control to its full width.
3. Configuration is the primary surface; preview is immediate feedback.
   Ordinary landscape can place full preview alongside independently scrolling
   editing controls when both fit. Full preview does not require full screen
   width or a permanently large top strip.
4. Do not adopt ArrangementView without an explicit primary-only fallback.
   Hiding preview silently would violate the owner's requested visible output.
   Specify a bounded preview/review affordance for insufficient space, keyboard
   and accessibility sizes before production integration.
5. Duo should use native TabView/NavigationStack/toolbar participation rather
   than reproduce the custom fallback rail. toolbarVerticalEdge is a readout
   from the actual navigation presentation, not a model identifier or a root
   switch that can safely be assumed to exist before a bar is installed.
6. Book/tabletop/flat layouts use active reserved regions and native arrangement
   semantics. Hinge angle may drive effects, never configuration truth or the
   principal page layout. Do not cache geometry across rotation/fold changes.
7. Keep the existing TextKit session and one editor scroll owner. Do not solve
   height starvation by nesting another vertical scroll view or scaling input
   text and attachment geometry.

## Implementation and acceptance sequence

- A1a: rail space reservation; existing destination and preview behavior intact.
- A1b: explicit two-pane geometry, preview height budgets and narrow/keyboard/
  accessibility fallback; physical iPhone inspection before acceptance.
- A2: bounded secondary-menu layout; concise options use intrinsic/readable
  sizing, retaining native menus/popovers and minimum interaction targets.
- A4: native Duo navigation and ArrangementView integration with 27.1 runtime
  guards, reserved-region behavior and a testable fallback. SDK compile evidence
  and ordinary iPhone evidence must remain separate from Duo device evidence.

Do not manufacture a fifth presentation style or change renderer, export,
Live Photo, EXIF, Photos, durable presets or Configuration Session ownership.
