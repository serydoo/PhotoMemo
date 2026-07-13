# MemoMark iPhone Responsive Layout Contract

Date: 2026-07-13
Status: Implemented and contract-tested; final clean-install device acceptance pending

## 1. Objective

Make every MemoMark iPhone surface remain visually complete and operable across
all iPhone sizes supported by the current iOS 18 deployment target. The first
reported failure is the Home page rendering a 440-point-wide content cluster on
an iPhone 15 Pro whose viewport is 393 points wide, which moves outer card
corners and header content outside the visible area.

This work converts that device-specific symptom into one repository-wide rule:

```text
iPhone viewport
-> safe-area-aware page width
-> bounded scroll content
-> adaptive rows
-> visible card bounds and controls
```

## 2. Assumptions

1. iPhone is the target of this slice; iPad and macOS are recorded but not
   redesigned.
2. Portrait and landscape orientations declared by the iOS target remain
   supported.
3. Existing content, navigation, configuration identity, preview behavior,
   Renderer, Export, Share intake, and Apple Photos behavior remain unchanged.
4. The current native white-card visual direction remains unchanged.
5. The Home configuration row may be contained or reflowed for width safety,
   but its selection, rename, save, delete, swipe, and persistence semantics are
   frozen.

## 3. Supported Width Matrix

The production contract covers these logical viewport classes:

- 375 pt: smallest supported portrait class, including iPhone SE and mini
- 390/393 pt: standard compact iPhone class, including iPhone 15 Pro
- 402 pt: current standard Pro class
- 430/440 pt: Pro Max class, including the verified iPhone 17 Pro Max
- landscape safe-area widths: readable content remains centered and bounded

The 320 pt class is retained as a stress-analysis boundary but is not a current
iOS 18 hardware release target.

## 4. Layout Invariants

### INV-UI-001 Viewport containment

Every vertical scrolling page must bind its root content width to the current
scroll viewport. A child with a large intrinsic width must not enlarge the page
beyond the viewport.

### INV-UI-002 Visible chrome

At every supported portrait width, the complete left and right bounds of every
top-level card, including continuous corners, stroke, and shadow origin, remain
inside the safe visible content area.

### INV-UI-003 Adaptive horizontal groups

Horizontal groups containing multiple semantic controls must either compress
without truncating required meaning or provide a vertical/compact fallback.
Fixed-size identity artwork and icons may remain fixed when the surrounding
text and controls can reflow.

### INV-UI-004 Operable controls

Primary actions, destructive actions, navigation controls, segmented choices,
and text fields remain visible and tappable at supported widths and with larger
Dynamic Type sizes.

### INV-UI-005 Readable landscape width

Landscape pages must not stretch card text across the entire display. General
page content is centered within one shared maximum readable width; the frozen
Configuration Center preview may continue using its existing geometry rules.

### INV-UI-006 No domain side effects

Responsive layout changes must not modify configuration data, renderer output,
media processing, persistence, task state, or Share Extension transport.

## 5. Surface Coverage

The audit and validation include:

- Home and bottom primary action
- Configuration Center shell, side navigation, inspectors, and module surfaces
- Output and album controls
- Task overview, current task, history, and diagnostics sheets
- Memory Subject overview, configuration, anchor, avatar, and local library
- Settings, welcome, workflow, and first-run surfaces
- background status and Share Extension presentation

## 6. Implementation Direction

1. Add one shared SwiftUI page-width modifier that constrains vertical scroll
   content to its viewport and caps landscape readable width.
2. Apply it to page roots rather than adding device-name checks.
3. Use `ViewThatFits`, layout priority, wrapping, or compact alternate rows only
   where a real horizontal group cannot fit the smallest supported width.
4. Keep fixed dimensions for icons and domain artwork when they do not determine
   the page width.
5. Add source-level and pure-metric contract tests before changing page code.

## 7. Verification Commands

Build:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

iOS simulator build and focused tests use the `PhotoMemoiOS` and
`PhotoMemoTests` schemes with an available iOS simulator destination.

Static verification:

```bash
git diff --check
```

Manual evidence uses the connected iPhone 15 Pro and iPhone 17 Pro Max, plus
simulator screenshots for additional supported width classes when available.

## 8. Success Criteria

1. The Home cards and header remain fully visible on both 393 pt and 440 pt
   devices.
2. Every vertical page root passes the viewport-containment contract.
3. No audited horizontal group forces a supported iPhone page wider than its
   viewport.
4. The iOS build passes and focused responsive contract tests pass.
5. Device evidence confirms no regression in Home actions, configuration
   editing, output controls, task presentation, or Share processing.

## 9. Boundaries

- Always: preserve frozen product architecture and business callbacks.
- Ask first: visual redesign, navigation restructuring, or iPad-specific work.
- Never: use `UIScreen.main.bounds`, device-model branching, arbitrary per-model
  constants, or changes to Renderer/Export to compensate for UI layout.
