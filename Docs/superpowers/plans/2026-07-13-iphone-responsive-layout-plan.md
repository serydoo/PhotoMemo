# MemoMark iPhone Responsive Layout Implementation Plan

## Overview

Implement the iPhone Responsive Layout Contract in small, verifiable slices.
The foundation constrains page content to the real viewport; later slices adapt
only the horizontal groups proven to overflow.

## Phase 1: Contract Foundation

- [x] Add shared viewport and readable-width layout metrics/modifier.
  - Acceptance: a vertical scroll child cannot enlarge its page beyond the
    current viewport, and landscape content has a shared maximum width.
  - Verify: focused responsive layout contract tests.
- [x] Add source-level coverage for every production page root.
  - Acceptance: all audited vertical page roots use the shared contract or a
    documented native container such as `List`/`Form`.
  - Verify: focused architecture tests.

## Phase 2: Primary Tab Surfaces

- [x] Constrain Home, Output, Settings, Task, and Configuration Center shells.
  - Acceptance: 375, 393, 402, and 440 pt portrait widths retain visible card
    bounds and controls.
  - Verify: focused tests, simulator build, screenshots.
- [x] Adapt overflowing Home and Task horizontal groups.
  - Acceptance: required labels/actions remain readable without horizontal page
    expansion.
  - Verify: compact-width screenshots and action regression tests.

## Phase 3: Secondary Surfaces

- [x] Constrain Subject, local-library, module, welcome, workflow, settings
  sheets, and background-status surfaces.
  - Acceptance: sheet content remains safe at the smallest supported width and
    at large Dynamic Type.
  - Verify: simulator navigation and screenshot evidence.
- [x] Audit Share Extension UIKit constraints.
  - Acceptance: no hard width assumes a Pro Max viewport; 20-item processing
    semantics remain unchanged.
  - Verify: Share Extension build and existing intake tests.

## Phase 4: Verification And Evidence

- [x] Build and run focused contract checks after each slice.
- [x] Capture 375, 393, and 440 pt Home containment evidence.
- [x] Install on iPhone 15 Pro and iPhone 17 Pro Max for final manual review.
- [x] Update `Docs/CURRENT_STATUS.md`, `HANDOFF.md`, and Reliability records.
- [ ] Complete dual-device page-by-page visual and interaction acceptance.

## Risks And Mitigations

- Existing child intrinsic widths can defeat a simple `maxWidth` modifier.
  Use a viewport-relative outer frame, not only flexible inner frames.
- Native `List` and `Form` already own their width. Do not wrap them in a second
  scrolling container.
- The Configuration Center preview has frozen geometry. Constrain only its page
  shell and peripheral controls unless evidence proves the preview itself clips.
- Landscape and large Dynamic Type may need vertical fallbacks. Prefer
  `ViewThatFits` over device-specific branching.
