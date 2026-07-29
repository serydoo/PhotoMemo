# iOS Root View Structure Refactor

Date: 2026-07-27
Status: Structural and UI-system milestone implemented
Primary loop: Engineering Loop
Risk: P2

## Objective

Reduce the maintenance cost and compile surface of
`PhotoMemoiOSV1View` without changing product behavior, visual hierarchy,
configuration truth, persistence, Renderer output, or the Apple Photos
lifecycle.

The current root source is approximately 3,933 lines and combines dependency
wiring, navigation, system presentation, page composition, transient UI state,
configuration actions, draft editing, bootstrap, and photo-picking flows.

The first milestone targets approximately 2,000–2,200 lines while leaving the
root responsible only for:

- dependency and environment wiring;
- compact and regular navigation hosting;
- system sheet, alert, and lifecycle attachment;
- adaptation between `ConfigurationSession` and focused presentation/actions.

Line count is a progress signal, not the architectural goal. A smaller file is
not accepted if responsibility is merely hidden in extensions or duplicated in
a second mutable session.

## Evidence And Historical Lessons

The retired `MainView` refactor successfully extracted display-heavy panels,
but the root continued to own state, dependencies, side effects, and binding
adaptation. A later workspace session mirrored root state and created a second
mutable coordination surface. That architecture has been retired and must not
be recreated.

Recent iOS extractions provide the preferred pattern:

- `EntryNavigationState` groups cohesive transient navigation state;
- `LogoAssetCoordinator` isolates a focused transformation;
- `ConfigurationLibraryActions` owns pure action decisions;
- `ConfigurationBackupRestoreCoordinator` coordinates one bounded workflow
  while the canonical persistence boundary remains unchanged.

## Ownership Boundaries

### Canonical truth

- `ConfigurationSession` remains the live configuration-editing truth.
- The durable configuration aggregate and its persistence coordinator remain
  the saved truth.
- Existing coordinators remain the only owners of their current side effects.
- SwiftUI surfaces project state and emit user intent.

### Allowed extracted state

Extracted value types may group transient UI-only state such as presentation,
focus, disclosure, feedback, and navigation selection. They must not duplicate
subjects, presets, output configuration, active identity, or persistence
receipts.

### Forbidden changes

- no new generic workspace/session/view-model layer;
- no second copy of `ConfigurationSession` state;
- no persistence writes from presentational views;
- no Renderer, Layout Engine, metadata, export, Share Extension, or PhotoKit
  behavior changes;
- no feature, copy, localization, or navigation redesign in the refactor;
- no restoration of retired `MainView`, Workspace, Composer, or import-first
  concepts.

## Visual And Container Contract

This refactor does not flatten the accepted interface.

The stable visual hierarchy remains:

```text
Page
└── One primary module card
    ├── ordinary content rows
    ├── spacing or dividers for light grouping
    └── nested cards only for independent objects, states, or actions
```

Memory Card remains the visual protagonist. Nested cards may be removed only
when they duplicate a title, state, border, or wrapper without establishing an
independent object or interaction boundary. Any such visual change requires a
separate bounded UI pass after the structural refactor.

## Implementation Plan

### Slice 1: Remove unreachable presentation remnants

Remove root-only UI helpers that have no runtime caller and were superseded by
the current page surfaces. Do not create replacement abstractions. Confirm each
symbol is unreachable across source and tests before deletion.

### Slice 2: Entry navigation composition

Extract compact Tab, regular sidebar, and destination switching into the
existing adaptive-navigation source while retaining `EntryNavigationState` as
the only navigation state.

### Slice 3: Configuration presentation composition

Extract the configuration page's pure presentation composition:

- page introduction;
- configuration summary;
- option list;
- preview/editor container placement.

Use focused `Presentation` input and `Actions` closures instead of a long list
of unrelated bindings. The extracted surface must not own configuration data or
perform persistence.

Acceptance:

- current visible hierarchy and actions remain unchanged;
- root source loses the extracted view composition;
- no new mutable source of truth is introduced;
- source contracts follow the semantic surface instead of requiring every
  token to remain in the root file.

### Slice 4: Transient presentation state

Group cohesive sheet, alert, rename, feedback, and backup-list presentation
state. Keep domain state and durable identity outside these value types.

### Slice 5: Configuration workflow coordination

Continue the existing coordinator pattern for activation, save, deletion, and
backup workflows where logic remains in the root. The root applies decisions
and injects existing persistence dependencies.

### Slice 6: Bootstrap and picker boundaries

Separate first-run/bootstrap and photo-picker orchestration only after the
configuration path is stable. Preserve cancellation, managed-file ownership,
and the current external-intake pipeline.

### Slice 7: UI system pass

After structural closure, perform a separately recorded UI pass covering:

- unnecessary container and repeated-heading removal;
- stable page rhythm and state identity;
- semantic color, spacing, border, Material, motion, and control-state tokens;
- Dynamic Type, VoiceOver, Reduce Motion, Increase Contrast, appearance,
  localization expansion, small iPhone, landscape, and iPad acceptance;
- continued quiet Home hierarchy without statistics or dashboard expansion.

## Verification

After each source slice:

1. run focused architecture and interaction contracts;
2. run `git diff --check`;
3. build `PhotoMemoiOS` for generic iOS with isolated DerivedData.

At milestone boundaries:

1. run the full `PhotoMemoTests` scheme on macOS;
2. run the unsigned generic iOS build;
3. inspect state ownership and dead-code references;
4. continue overwrite installation and primary-path checks on the named
   iPhone 17 Pro Max as ongoing release evidence rather than a per-extraction
   blocker.

## Success Criteria

- `PhotoMemoiOSV1View` reaches approximately 2,000–2,200 lines in the first
  milestone without behavior changes.
- No extracted production view exceeds approximately 600 lines without a
  documented reason.
- Root state wrappers materially decrease from the current baseline of 55.
- `ConfigurationSession` and the durable aggregate remain the only accepted
  configuration truths.
- Existing tests and builds pass; source-shape tests are updated toward
  semantic contracts when extraction changes file placement.
- The accepted large-card / necessary-small-card visual system remains stable.

## UI Acceptance Matrix

The following matrix is the standing product-level manual acceptance contract.
It continues across device and release milestones rather than blocking each
behavior-neutral extraction:

| Dimension | Required coverage |
| --- | --- |
| Device and layout | Small iPhone portrait, iPhone 17 Pro Max, landscape, iPad regular split |
| Appearance | Light, dark, Increase Contrast |
| Type | Default Dynamic Type and largest accessibility size |
| Assistive access | VoiceOver order, labels, headings, actions, and focus return |
| Motion | Default motion and Reduce Motion |
| Language | Simplified Chinese and English expansion |
| State stability | Idle, saving, processing, completed, and failure without primary-action movement |

Automated contracts establish source ownership, semantic styling, adaptive
layout, accessibility traits, tests, and build integrity. They do not replace
visual acceptance on the matrix above.

## Implemented Milestone 2

- Extracted the four-region editor and its configuration guide into the
  stateless `V1RegionEditorCluster`; draft mutation, focus order, preview
  refresh, module routing, and persistence remain in the root.
- Grouped rename, switch-confirmation, and local-backup presentation values
  into three focused value types. Root property wrappers decreased without
  moving domain truth or asynchronous persistence ownership.
- Removed the duplicate inner card chrome from Output sections while retaining
  one primary module card and its content spacing.
- Added semantic color, background, hairline, and motion roles; reduced Home
  header pills to quiet system emphasis; added heading traits to shared page
  and section titles.
- Audited bootstrap and photo-picker boundaries. They remain in the root for
  this milestone because cancellation, managed-file ownership, external
  intake, and lifecycle refresh are coupled and already have accepted owners.

## Implemented Milestone 3

- Extracted configuration-page presentation and grouped the photo-picker and
  Logo-optimization values in `V1MediaPickerPresentationState`. The root keeps
  the existing intake, queue, cancellation, and persistence calls; no second
  workflow owner was introduced.
- Completed the semantic UI token set for spacing, corner roles, strokes,
  Material, elevation, minimum touch size, and control states. Existing iOS
  values now route through equal-value roles rather than changing the accepted
  iPhone 17 Pro Max appearance.
- Shared card chrome responds to Increase Contrast, titled cards expose a
  contained VoiceOver hierarchy, and configuration, output, processing, and
  settings copy added during the pass is covered in Simplified Chinese and
  English. Home visual acceptance remains frozen pending device review.
- `PhotoMemoiOSV1View` is now approximately 3,371 lines. Presentation and
  transient-state boundaries are materially clearer, but the original
  2,000–2,200-line progress target is not claimed. Remaining size is primarily
  workflow application glue and should be reduced only in a separately bounded
  coordinator pass with persistence and intake regression coverage.
- Focused responsive, Apple-native, and background integration contracts pass.
  The complete serialized `PhotoMemoTests` scheme exits successfully with one
  environment-gated skip, the unsigned `PhotoMemoiOS` Debug build passes, and
  `git diff --check` passes. Manual device acceptance remains governed by the
  matrix in this document and is not inferred from automation.

## Compact-Device Responsive Pass

Primary loop: Product Loop

Observed scenario: the accepted interface was tuned on iPhone 17 Pro Max, while
compact width, short height, keyboard presentation, localization expansion, and
accessibility Dynamic Type can create horizontal competition or inaccessible
bottom actions.

Risk: P1. The pass may affect the primary configuration workflow, keyboard
reachability, and accessibility, but must not change configuration, rendering,
export, Share Extension, or Apple Photos behavior.

### Frozen baseline

- iPhone 17 Pro Max portrait at default Dynamic Type remains the first layout
  candidate, with the same Memory Card ratio, typography, card hierarchy,
  control styling, copy, and actions.
- Responsive decisions use container proposals, size classes, Dynamic Type,
  safe areas, and system keyboard behavior. They never branch on a device model,
  physical resolution, or `UIScreen.main.bounds`.
- Fallback order is current horizontal layout, natural wrapping, vertical
  composition, native Menu for secondary choices, then vertical scrolling.
- Memory Card preview remains aspect-fit to the renderer contract. No crop,
  stretch, renderer-specific small-screen layout, or second business page is
  introduced.

### Implemented boundaries

- Configuration footer participates in the bottom safe area instead of
  overlaying editable content; the editor remains vertically scrollable and
  dismisses the keyboard interactively.
- Configuration rows, Memory Source heading, region-composer heading, Home
  header, Time Anchor category/name fields, Subject anchor summaries, Output
  target selection, Settings language choice, and Processing status copy gain
  bounded compact or accessibility fallbacks.
- Module chips remain at their current size in an independent horizontal
  scroll region. Touch targets added by this pass are at least 44 points while
  preserving their existing visual size where applicable.
- Time Anchor retains its 390-point initial sheet candidate and now permits a
  large detent; its content scrolls in short-height and keyboard environments.

### Evidence plan

1. Source contracts for no device-model branching, aspect-fit preview,
   safe-area footer, vertical fallbacks, Dynamic Type, and 44-point actions.
2. Focused responsive and configuration contracts, followed by the full test
   suite and unsigned generic iOS build.
3. Simulator functional matrix on iPhone 17 Pro Max and iPhone SE (3rd
   generation), including default and accessibility Dynamic Type, portrait,
   landscape, and launch screenshots where the simulator is healthy.
4. Continue physical-device keyboard, VoiceOver, contrast, and primary-flow
   acceptance as release evidence; simulator behavior is not device performance
   evidence.

## Implemented Milestone 4

- Completed the separately bounded workflow-coordination pass. Configuration
  deletion, active-selection persistence, local backup/restore orchestration,
  save payload construction, and preview-draft adaptation now live in focused
  stateless coordinators or adapters. The root still applies durable receipts
  and owns the existing persistence dependencies.
- Extracted subject, welcome/settings, local-library, and editor system
  presentations into independent SwiftUI modifiers without moving domain state
  or introducing a second session owner.
- Extracted root lifecycle and field observation into
  `V1RootChangeObservationModifier`. It collects `onAppear`, scene phase,
  horizontal size class, selected configuration/subject, output fields, Logo,
  and photo-picker changes. It receives existing state through bindings and
  invokes injected root actions; it owns no repository, persistence, IO,
  `State`, or `StateObject` dependency.
- `PhotoMemoiOSV1View` is now approximately 2,639 lines, down from 3,371 at the
  preceding milestone. The earlier 2,000–2,200 estimate remains a progress
  signal rather than a reason to manufacture another abstraction; further
  extraction requires a new evidence-backed boundary.
- Focused root-structure, persistence, configuration-library, apply, and
  subject-selection contracts pass. Two UI source-shape contracts were updated
  to follow their new presentation-modifier owners; the complete test scheme
  and unsigned generic iOS build then pass. Physical-device visual and
  accessibility acceptance remains pending and is not inferred from this
  structural work.
