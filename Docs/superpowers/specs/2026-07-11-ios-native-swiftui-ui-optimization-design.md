# MemoMark iOS Native SwiftUI UI Optimization Design

Date: 2026-07-11
Status: Proposed for review

## 1. Goal

Improve the current MemoMark iOS interface by adopting native SwiftUI
interaction and presentation capabilities where they reduce custom gesture,
focus, navigation, accessibility, and state-management risk.

The optimization must preserve the current product structure, information
content, visual direction, Memory Workflow, and real-time Configuration Center
preview behavior. This is a system-polish pass, not a UI redesign.

## 2. Product And Architecture Constraints

This design follows the frozen Configuration Center architecture:

```text
Library -> Interactive Memory Card -> Object Inspector
```

It also preserves the production relationship:

```text
ConfigurationSession
    -> Memory / region mutation
    -> real Interactive Memory Card preview
    -> existing configuration persistence and apply path
```

The following rules are mandatory:

1. Keep MemoMark local-first and Apple Photos-native.
2. Preserve the current UI content and overall visual style.
3. Do not reopen IA-002 Configuration Center architecture.
4. Do not change Renderer, Metadata, Export, Share Extension, Photo Library, or
   Layout Engine behavior as part of this UI optimization.
5. Do not create a second source of configuration truth.
6. Do not delay Configuration Center preview updates behind an Apply button.
7. Prefer native SwiftUI behavior only where it preserves current semantics.
8. Keep custom interactions where they express MemoMark-specific Memory Card
   behavior rather than generic platform behavior.

## 3. Explicitly Frozen Scope

### 3.1 Home “My Configurations” area

The Home configuration list is excluded until its existing functional bugs are
resolved and independently verified.

Do not modify:

- Home configuration row layout
- Home configuration row custom swipe behavior
- configuration selection from Home
- Home save, rename, delete, or local-library entry behavior
- Home configuration persistence wiring
- `V1HomeMemoryPresetRow`
- its reveal-state presenter or gesture state

Future adoption of native `swipeActions` in this area requires a separate
design and regression pass after the current bugs are closed.

### 3.2 Configuration Center preview core

Do not modify:

- `ConfigurationCenterTopPreviewSection`
- Interactive Memory Card visual composition
- preview sizing, pinning, scaling, positioning, or layout
- preview region rendering
- `ConfigurationCenterPreviewCompositionHelper` behavior
- region mutation semantics
- module-to-region routing
- current four-region selection behavior
- renderer/export preview fidelity contracts

The preview remains a real Memory Card calibration surface, not a redesigned
editor canvas.

### 3.3 Configuration delivery and persistence

Do not modify:

- configuration snapshot structure
- production apply timing
- configuration repository ownership
- batch snapshot behavior
- current persistence or recovery architecture
- current configuration identity and revision semantics

## 4. Optimization Strategy

Use a conservative shell-first strategy:

```text
Keep domain state and callbacks
    -> replace generic custom UI shell with native SwiftUI
    -> preserve mutation timing
    -> preserve current visual tokens
    -> verify preview and persistence regressions
```

Native components are implementation tools, not a reason to restructure the
product. Existing callbacks, coordinators, presenters, and session ownership
remain authoritative unless a later approved engineering review proves a
specific duplication should be removed.

## 5. Visual Direction

The existing MemoMark visual direction remains:

- minimal white surfaces
- restrained system colors
- continuous rounded corners
- compact semantic labels
- SF Symbols
- clear hierarchy through typography and spacing
- no decorative expansion
- no dashboard or workbench language

Native `List`, `Form`, `Section`, `Menu`, `Picker`, `DatePicker`, toolbar,
dialogs, search, and swipe actions may be styled to fit this direction. Native
adoption must not cause a broad visual jump from the current card-based UI.

The preferred pattern is hybrid:

- retain meaningful MemoMark cards and preview surfaces
- use native interaction behavior inside or around them
- avoid converting every screen wholesale into default `Form` styling

## 6. Time Anchor Optimization

Time Anchors are the first and clearest optimization target because their
current custom swipe implementation duplicates system list behavior while the
underlying Memory semantics are already established.

### 6.1 Anchor list

Replace only the generic row-action shell with native SwiftUI behavior:

- use a native list-capable row container where it can preserve current row
  appearance and spacing
- expose trailing `删除` through `.swipeActions`
- use `Button(role: .destructive)`
- set `allowsFullSwipe: false`
- keep row selection and configuration callbacks unchanged
- ensure only anchors that currently satisfy `canDelete` expose deletion
- preserve the rule that at least one Time Anchor remains

The system owns swipe resistance, settling, action reveal, accessibility, and
gesture competition. MemoMark continues to own deletion rules.

### 6.2 Delete confirmation

Tapping the destructive swipe action does not immediately delete the anchor.
It stages the selected anchor ID and presents a native `confirmationDialog`.

The dialog must:

- identify the anchor by its visible title when practical
- explain that the current preview will switch to another retained anchor
- provide a destructive confirmation action
- provide a cancel action
- leave all state unchanged when canceled

After confirmed deletion:

1. remove the anchor through the existing mutation path
2. select a deterministic valid fallback anchor when the deleted anchor was
   active
3. synchronize the selected subject into the existing session
4. refresh the preview immediately
5. close any editor presenting the deleted anchor

### 6.3 Real-time preview editing

Time Anchor editing keeps real-time preview updates.

Changes to these fields must continue updating the current
`ConfigurationSession` immediately:

- anchor date
- anchor type
- anchor title
- expression style
- active Time Anchor selection

No Apply button or delayed commit layer is introduced. Existing session APIs,
including Time Anchor selection and subject synchronization, remain the live
preview path.

### 6.4 Cancel rollback transaction

Real-time preview and cancel semantics are reconciled with a small editor
transaction owned by the presentation layer.

When editing starts, capture:

- the original anchor value
- the original active anchor ID
- whether the anchor existed before the editor opened

During editing, the live session continues to receive changes and the preview
continues to refresh.

On `完成`:

- retain current values
- clear the editor transaction snapshot
- keep the currently selected valid anchor
- dismiss the editor

On `取消`, interactive dismissal, or explicit close without completion:

- restore the original anchor value
- restore the original active anchor ID when still valid
- remove a newly created temporary anchor
- synchronize the restored subject through the same existing session path
- allow the preview to return immediately to its original state
- clear the transaction snapshot

Rollback is not a second persistent model. It is a short-lived copy used only
to restore the live session after canceling an editor interaction.

### 6.5 Native editor controls

Keep current information and field order while standardizing interaction:

- native `DatePicker` for anchor date
- native menu-style `Picker` for anchor type
- native `TextField` with `@FocusState`
- `submitLabel` and `onSubmit` where a clear next/done action exists
- native toolbar or bottom confirmation actions for `取消` and `完成`
- `.interactiveDismissDisabled` only while rollback safety cannot be
  guaranteed; otherwise interactive dismissal must execute the same rollback
  path as Cancel

Do not restyle the editor into an unrelated full-screen workflow.

## 7. Memory Subject Optimization

Memory Subject remains the object edited by the Configuration Center. Its
identity, anchors, avatar, relationship fields, and behavior remain unchanged.

Allowed improvements:

- standardize sheet navigation and cancellation behavior
- use `@FocusState` instead of broad tap gestures for text fields
- improve keyboard next/done behavior
- use native `PhotosPicker` for avatar selection as already established
- preserve the existing crop interaction because it is domain-specific
- use native confirmation dialogs for destructive object operations
- provide `ContentUnavailableView` only for real empty states
- improve accessibility labels, hints, and value announcements

The existing subject draft-session boundary remains authoritative. Saving the
subject continues to reconcile the draft into the live session through the
existing flow. No automatic persistence side channel is added.

## 8. Configuration Center Peripheral Optimization

The Configuration Center structure and preview are frozen, but its surrounding
generic controls can be polished.

### 8.1 Navigation and toolbar

- use native toolbar placements for cancel, done, and contextual actions
- keep current navigation titles and hierarchy
- avoid hiding system navigation bars unless the current custom chrome has a
  documented product purpose
- retain current Configuration Center page chrome where changing it would
  alter preview pinning or available space

### 8.2 Selection controls

- retain native `Picker` and `Menu` for Preset, Time Anchor, expression style,
  location display, and other finite selections
- use checkmarks and disabled states supplied by the system
- preserve existing binding setters so selection continues to mutate the
  current session immediately
- do not bind controls directly to a duplicate local source of truth

### 8.3 Keyboard and focus

- use `@FocusState` for editable fields
- keep `.scrollDismissesKeyboard(.interactively)` where scrolling editors need
  it
- remove page-wide `simultaneousGesture(TapGesture)` only after focused-field
  behavior proves equivalent
- provide toolbar Done actions when the keyboard has no natural submit path
- ensure tap-to-select Memory Card regions is not intercepted by keyboard
  dismissal gestures

### 8.4 Dialogs and sheets

- use `confirmationDialog` for destructive or multi-choice actions
- use `alert` for blocking failures requiring acknowledgement
- use native presentation detents where current sheet height is not coupled to
  preview geometry
- keep existing detents when changing them could alter editor usability
- route every dismiss path through the same completion or rollback semantics

### 8.5 Feedback and accessibility

- add restrained `sensoryFeedback` only to meaningful completed actions,
  selection boundaries, or destructive confirmations
- do not generate feedback on every real-time field edit
- expose semantic labels and values for icon-only controls
- maintain Dynamic Type readability without forcing the preview itself to
  become a system text layout
- respect Reduce Motion and avoid new custom animation dependencies

## 9. Module Library Optimization

The module library is a generic selection surface and can use more native
SwiftUI without changing module insertion behavior.

Allowed improvements:

- retain native `List` and `Section`
- add `.searchable` when the module count justifies search
- group modules using existing semantic categories
- use `ContentUnavailableView.search` or equivalent for empty search results
- retain existing `onSelectModule` callback
- dismiss only after the existing insertion path succeeds
- preserve explicit selected-region routing

Do not change:

- which modules exist
- module semantic output
- smart-variable behavior
- insertion destination
- region mutation and preview composition

## 10. Local Configuration Library Optimization

The local configuration library may be polished independently from the frozen
Home configuration list.

Allowed improvements:

- retain native `NavigationStack`, `List`, and `Section`
- keep `ContentUnavailableView` for the empty library
- move secondary row operations into native swipe actions or a context menu
- keep one obvious primary restore action visible
- use destructive confirmation for backup deletion
- add `.refreshable` only if it invokes the existing refresh callback and does
  not duplicate toolbar refresh state
- use `fileImporter`, `fileExporter`, and `ShareLink` when import/export
  functionality is approved and ready

This optimization must not modify the frozen Home row or change backup versus
live-configuration deletion semantics.

## 11. Share Experience

The Apple Photos Share Extension is included in the UI optimization scope. Its
workflow remains:

```text
Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos
```

The current Share Extension is UIKit-based. This design does not require a
SwiftUI rewrite. Native UIKit and SwiftUI may coexist; the decision must be
based on lifecycle safety, extension memory limits, and regression risk rather
than framework uniformity.

### 11.1 Share UI goals

- preserve the current confirmation, processing, received, failure, and
  handoff-failure states
- preserve the current preview, configuration summary, output destination,
  status explanation, and primary action content
- align typography, spacing, card surfaces, symbols, button roles, and status
  colors with the main MemoMark iOS interface
- use native system controls and configurations for buttons, progress,
  scrolling, Dynamic Type, and accessibility
- make the primary next action and current processing state immediately clear
- keep failure recovery and cancel behavior explicit

### 11.2 Share behavior frozen during UI optimization

Do not change:

- `PhotoMemoShareExtensionIntakeService`
- maximum supported photo count of 20
- 21-photo rejection behavior and copy contract
- item-provider filtering and observation
- Live Photo probing or still-image fallback
- RAW/ProRAW/DNG routing
- source-file readiness and identity recovery
- App Group handoff request identity
- shared configuration snapshot resolution
- queue admission, diagnostics, or evidence events
- `completeRequest`, `cancelRequest`, or host-app opening semantics
- processing route or Apple Photos save-back behavior

UI state must remain a projection of the existing `ViewState`; the UI must not
invent a parallel Share workflow state machine.

### 11.3 Share implementation direction

The recommended first pass retains the existing view controller and improves
its presentation incrementally:

- keep the lifecycle owner as `PhotoMemoShareExtensionViewController`
- extract pure presentation values only where this simplifies testing
- use native `UIButton.Configuration`, `UIActivityIndicatorView`, system
  backgrounds, content-size categories, and accessibility traits
- preserve the existing horizontal preview scroll behavior
- keep the current bottom primary action safe-area placement
- avoid embedding a large SwiftUI hierarchy until real-device evidence proves
  extension launch time, memory, and cancellation behavior remain safe

A later `UIHostingController` migration is allowed only as a separate slice
after behavior tests cover every existing `ViewState` transition and signed
device evidence establishes equivalent extension lifecycle behavior.

### 11.4 Share feedback and failure presentation

- processing state disables duplicate submission
- received state clearly communicates successful handoff rather than completed
  Apple Photos save-back
- failed state retains title, message, and actionable suggestion
- unsupported or excessive input remains a friendly terminal explanation
- progress must not imply determinate completion when only an indeterminate
  stage is known
- VoiceOver must announce state transitions without repeatedly reading the
  entire screen
- system feedback may mark accepted handoff or terminal failure, but must not
  fire for every imported item

## 12. Task Experience

The Task screen is included in UI optimization while its queue, diagnostics,
and background-processing semantics remain unchanged. It remains a supporting
status surface, not a Dashboard or Task Center product concept.

### 12.1 Task UI goals

- preserve the current overview, active task, pipeline stages, recent tasks,
  recovery message, and Apple Photos link
- maintain the current branded card visual language
- improve scanning, state hierarchy, progress accessibility, empty states, and
  sheet navigation with native system behavior
- keep real status facts authoritative and avoid decorative progress

### 12.2 Native Task improvements

- use native `ProgressView` for real determinate or indeterminate progress
- use `ContentUnavailableView` for a genuinely empty task history when it can
  preserve the current start-processing action
- use native `List` or `Section` inside the recent-task sheet when this does not
  change the main page card layout
- use `.refreshable` only when backed by an existing idempotent refresh action
- use native toolbar dismissal and presentation detents for task details
- use `LabeledContent` for compact fact/value rows where it matches the current
  visual hierarchy
- remove broad keyboard-dismiss gestures from the Task screen when the screen
  contains no editable field
- use accessibility values for counts, progress, status, and duration
- use `monospacedDigit` for changing numeric measurements

### 12.3 Task behavior frozen during UI optimization

Do not change:

- `PhotoMemoBackgroundJobSnapshot`
- queue state transitions
- recovery semantics
- recent-job retention
- diagnostics event collection or parsing
- job identity and configuration revision evidence
- active versus completed task classification
- start-processing routing
- Apple Photos link routing
- notification scheduling
- background execution or cancellation policy

The Task UI remains a pure projection of existing snapshot, overview, summary,
and diagnostic presentation data.

## 13. Settings, Output, And Supporting Screens

These screens may adopt native SwiftUI selectively while preserving their
current information architecture and MemoMark vocabulary.

### 13.1 Settings

- retain meaningful branded overview cards
- use `LabeledContent`, `Link`, `Toggle`, `Picker`, and `Section` for system-like
  settings rows
- avoid converting the entire page to an unstyled default Form in one change
- replace custom URL actions with `Link` when no custom preflight is required
- keep support, release, privacy, and workflow content unchanged

### 13.2 Background status

- retain current processing facts and diagnostics semantics
- use native progress presentation where it accurately represents real state
- use native refresh where refresh is user-triggered and idempotent
- keep this sheet consistent with the optimized Task screen without merging
  their responsibilities
- do not create dashboard language or a permanent Task Center workflow

### 13.3 Output

- keep output policy and album behavior unchanged
- retain native `Picker`, `Toggle`, and `TextField`
- improve focus, submit, validation, and disabled-state presentation
- use alerts for actionable failures and inline secondary text for guidance
- do not change export, save-back, Live Photo, metadata, or album semantics

### 13.4 Welcome and guidance

- preserve current content and Apple Photos -> Share -> MemoMark workflow
- use native paging or navigation only if it does not change onboarding state
- avoid decorative redesign unrelated to clarity or accessibility

## 14. Areas That Should Remain Custom

The following interactions communicate MemoMark-specific product meaning and
should not be replaced merely because a native container exists:

- Interactive Memory Card composition
- card-region selection and semantic highlighting
- preview pinning behavior
- region/module composition display
- avatar crop gestures
- branded memory and subject summary cards
- renderer-faithful preview content
- Share Extension preview-card presentation where UIKit lifecycle constraints
  make the existing implementation safer
- Task overview cards that communicate MemoMark-specific processing meaning

Custom UI is acceptable where it represents the product. Generic system
behavior should not be custom where native SwiftUI already provides it safely.

## 15. State And Data-Flow Rules

Every optimization must preserve this ownership model:

```text
View interaction
    -> existing Binding / callback / presenter
    -> ConfigurationSession or current flow draftSession
    -> existing mutation helper
    -> real-time preview update
    -> existing save/apply path when explicitly completed
```

Forbidden data-flow changes:

- introducing a second observable session for generic UI polish
- storing authoritative anchor state only inside a row view
- debouncing or batching preview updates without a separate approved design
- bypassing existing coordinators for persistence
- writing directly to renderer or export models from UI controls
- using Cancel to dismiss without restoring a real-time editing transaction

## 16. Error Handling

- destructive confirmation cancel paths are no-ops
- rollback failure must keep the editor open and display an actionable error
- invalid fallback-anchor resolution must never produce a random UUID or an
  unowned selection
- native controls must expose current disabled reasons through nearby text or
  accessibility hints when the reason is not obvious
- persistence errors remain owned by the existing save/apply flow
- UI polish must not reinterpret a persistence failure as success

## 17. Implementation Slices

Implementation should proceed as isolated, reviewable slices.

### Slice UI-001: Time Anchor transaction and native actions

- add editor snapshot and rollback semantics
- preserve real-time session synchronization
- replace Time Anchor custom swipe with native swipe actions
- add destructive confirmation
- verify active-anchor fallback

### Slice UI-002: Focus and keyboard normalization

- standardize `@FocusState`, submit behavior, and interactive keyboard dismissal
- remove broad tap gestures only where regression tests and manual checks pass
- cover subject and Configuration Center peripheral editors

### Slice UI-003: Configuration Center native peripheral controls

- normalize picker, menu, toolbar, dialog, and sheet behavior
- preserve preview and region mutation code byte-for-byte where practical
- add accessibility and restrained sensory feedback

### Slice UI-004: Module and local-library surfaces

- add native search and empty search state to the module library if warranted
- reorganize local-library row actions without changing persistence callbacks
- add backup deletion confirmation

### Slice UI-005: Supporting-screen system polish

- selectively improve Settings, Output, background-status, and guidance
  screens
- retain branded cards and current information hierarchy
- avoid broad `Form` conversion

### Slice UI-006: Task surface system polish

- preserve existing task projections and queue semantics
- normalize native progress, empty state, recent-task sheet, toolbar, and
  accessibility behavior
- verify active, completed, failed, recovered, and empty task presentations

### Slice UI-007: Share Extension presentation polish

- retain the existing UIKit lifecycle owner for the first pass
- normalize system controls, Dynamic Type, accessibility, state transitions,
  and visual consistency
- preserve all intake, handoff, diagnostics, limit, and completion contracts
- require signed-device Share evidence before accepting the slice

The Home “My Configurations” area remains excluded from all seven slices.

## 18. Testing Strategy

### 18.1 Time Anchor behavior tests

Cover:

- editing each field updates the live preview session immediately
- completing retains edited values
- canceling restores the original anchor and preview
- interactively dismissing executes the same rollback as Cancel
- canceling a newly created anchor removes it
- canceling restores the prior selected anchor
- confirmed deletion removes the anchor
- canceled deletion changes nothing
- deleting the active anchor selects a deterministic retained anchor
- the final anchor cannot be deleted
- full swipe cannot execute deletion

### 18.2 Configuration Center regression tests

Cover:

- selected region remains explicit
- module insertion still targets the selected region
- Time Anchor selection still updates Memory display
- expression-style selection still refreshes preview
- region mutations still update preview through the existing helper
- cancel/complete sheet paths do not duplicate session updates

### 18.3 Manual iOS verification

Verify on simulator and, when practical, device:

- light and dark appearance
- Dynamic Type
- VoiceOver labels and action order
- Reduce Motion
- keyboard avoidance and interactive dismissal
- sheet swipe dismissal rollback
- list scrolling versus swipe-action gesture behavior
- half swipe, reverse swipe, rapid repeated swipe, confirmation cancel, and
  confirmation accept
- preview refresh during rapid DatePicker, Picker, and text changes
- no visible preview jump caused by surrounding UI changes

### 18.4 Build verification

Run the relevant targeted tests first, followed by the required project build:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

The iOS scheme should also be built for the iOS Simulator before closing a UI
slice.

### 18.5 Task UI verification

Cover:

- empty task state
- active determinate and indeterminate progress
- completed, failed, canceled, and recovered summaries
- recent-task sheet ordering and dismissal
- Apple Photos link routing
- Dynamic Type and VoiceOver progress announcements
- no mutation of queue or diagnostics state from presentation-only actions

### 18.6 Share UI verification

Cover every existing Share `ViewState`:

- confirming
- processing
- received
- failed with title, message, and suggestion
- handoff failed

Also verify:

- 1-photo and 20-photo accepted flows
- 21-photo rejection
- mixed still and Live Photo presentation
- configuration-not-ready presentation
- repeated primary-button taps while processing
- host cancellation and extension dismissal
- successful App Group handoff and host-app opening behavior
- Dynamic Type, VoiceOver, and constrained extension height
- memory and launch behavior on a signed physical device

Share UI acceptance requires the existing runtime evidence gates to remain
valid. Simulator appearance alone is insufficient.

## 19. Acceptance Criteria

The optimization is accepted only when:

1. Current UI content and MemoMark visual identity remain recognizable and
   consistent.
2. Home “My Configurations” code and behavior remain untouched.
3. Configuration Center preview composition and layout remain unchanged.
4. Configuration changes still refresh the real preview immediately.
5. Time Anchor Cancel restores the exact pre-edit state and preview.
6. Time Anchor deletion requires confirmation and cannot execute through full
   swipe.
7. Current configuration apply and persistence behavior remain unchanged.
8. No module is inserted into an implicit fallback region.
9. Native SwiftUI adoption reduces custom interaction state rather than adding
   another abstraction layer.
10. Targeted tests and relevant macOS/iOS builds pass.
11. Any behavior not manually verified is explicitly recorded at handoff.
12. Task UI remains a projection of existing queue and diagnostics facts.
13. Share UI preserves the 20-photo limit, all current lifecycle states, App
    Group handoff, and extension completion/cancellation behavior.
14. Signed-device Share evidence shows no lifecycle, memory, or handoff
    regression.

## 20. Non-Goals

- Home configuration bug fixes
- Home configuration swipe migration
- Configuration Center architecture redesign
- Memory Card visual redesign
- preview fidelity or renderer changes
- new Presets or modules
- batch-oriented workflow expansion
- persistence architecture changes
- export, metadata, Share processing, or Photo Library behavior changes
- Share Extension intake or lifecycle architecture replacement in the first
  optimization pass
- queue, diagnostics, or background-processing behavior changes
- broad terminology changes
- speculative iOS 27-only visual effects that reduce compatibility or clarity

## 21. Design Decision

MemoMark will use native SwiftUI for generic platform interactions while
preserving custom UI for Memory Card semantics and renderer-faithful preview.

The approved optimization boundary is:

```text
Native interaction shell
    + existing MemoMark visual language
    + unchanged ConfigurationSession ownership
    + real-time preview
    + cancel rollback
    + confirmed destructive actions
```

This produces system-consistent behavior without reopening the frozen
Configuration Center architecture or risking the current production pipeline.
