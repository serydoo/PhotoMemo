# MemoMark UI System Polish

Date: 2026-08-25

Status: Scoped Product Loop UI pass

## Decision Gate

- Primary loop: Product Loop — bounded existing-product and device-fit refinement.
- Evidence: the current iOS UI already has native disclosure controls and shared
  card/row primitives, but Configuration Center still nests multiple surfaces
  and uses status capsules for values that can be read as ordinary trailing
  content. Settings and subject editing also repeat explanations inside groups.
- Risk: P1. The change affects a primary configuration workflow, Dynamic Type,
  localization, accessibility, and compact/wide layout behavior, but does not
  change configuration semantics or the processing pipeline.
- Apple-native capabilities evaluated: `NavigationStack`, `Button` with a full
  row hit target, `Picker`, `Toggle`, `Form`-style grouped rows, semantic system
  colors, Dynamic Type text styles, and system accessibility traits.

## Audit Summary

The current UI uses the following presentation patterns:

- Level-1 preview/hero surfaces for the real Memory Card and MemoMark+.
- Repeated Level-2 card containers for summaries, detail panels, Settings
  sections, Subject detail, and option lists.
- Capsule-based result/status labels in Configuration Center, Home, and module
  pickers. Several of these communicate a current value rather than an active
  selection.
- Icon-backed rows with dividers already exist, but some rows still wrap a
  second bordered surface or expose a small trailing action instead of making
  the semantic row the interaction target.
- Fixed radius literals remain in preview-only and legacy-compatible surfaces;
  shared `ConfigurationUI` and `MemoMarkDesignTokens` are the intended owners.

The principal problems for this pass are:

1. Configuration Center Summary uses a bordered outer surface, a bordered inner
   surface, icon tiles, status capsules, and region chips at the same time.
2. The top Configuration Preview repeats status, explanatory copy, current
   configuration facts, and rename/reset actions in a dense panel.
3. Settings rows carry title, detail, icon tile, and chevron for every entry;
   the grouping boundary is correct, but the row grammar is heavier than the
   system Settings archetype.
4. Subject and destructive actions are visually treated like ordinary cards;
   editor fields should read as one grouped form and deletion should remain a
   separate destructive section.
5. Current values and accessibility values are not always the first thing a
   user sees or hears; descriptions sometimes compete with them.

## Bounded UI Pass

In scope:

- Add shared semantic spacing, surface, and row helpers without adding a second
  state model.
- Simplify Configuration Center Summary into one grouped surface with ordinary
  trailing values and native menus; preserve the real Memory Card Preview as the
  highest-weight visual surface.
- Remove non-interactive result/status capsules where plain text or a semantic
  trailing value is sufficient. Keep capsules only for genuine selection states
  such as the four-region selector and Preview-specific visual language.
- Make disclosure and navigation rows use a full 44-point row target and expose
  their current value through VoiceOver.
- Reduce repeated explanatory copy in Settings and Subject detail while keeping
  safety, destructive consequences, and recovery instructions explicit.
- Replace static editor clear affordances with native TextField behavior where
  the existing editor contract allows it.

Out of scope:

- Subject, Anchor, Preset, Snapshot, persistence, Renderer, Layout Engine,
  Metadata/EXIF, Live Photo, Share Extension, queue, batch, export, PhotoKit,
  commerce entitlement, and output-language semantics.
- A new navigation architecture, custom Toggle/Picker/Tab control, Glass
  recreation, new animation system, or automatic-save behavior.
- Reopening IA-002 or changing the Library → Interactive Memory Card → Object
  Inspector architecture.

## Increment Plan And Verification

1. Shared UI grammar and token adjustments → compile and focused contract tests.
2. Configuration Center Summary and Preview hierarchy → iOS build plus
   accessibility/localization contract checks.
3. Settings and Subject/Anchor form polish → iOS build, focused tests, and
   Dynamic Type/Reduce Motion source-contract checks.
4. Final review → `git diff --check`, full relevant test/build evidence, and
   explicit manual gaps for Dark Mode, VoiceOver, Dynamic Type, and four-language
   physical-device observation.

Success means the user can still select the same subject, anchor, preset,
region, output, and save action through the same state flow, while the visual
hierarchy makes the photo/Memory Card and current values primary.

## Settings Spacing Follow-Up — 2026-08-26

### Device Observation

Physical-device screenshots from iPhone 17 Pro Max show that the Settings
grouping itself is understandable in both expanded and fully collapsed states,
but the horizontal baselines are inconsistent:

- Disclosure titles and trailing summaries sit almost on the grouped surface
  edge.
- Expanded Settings rows already use the shared inner row inset, so their icon
  and text content is visually more deeply inset than the section title.
- Appearance and interface-language controls span wider than the row content
  and descriptions, making the controls look attached to the outer card rather
  than to the section's content column.

### Bounded Follow-Up

- Keep the existing Settings section grouping, expansion state, summaries,
  bindings, and interaction behavior unchanged.
- Apply the existing `ConfigurationUI.innerPanelPadding` to the shared
  disclosure header content, including title, trailing summary, and chevron.
- Apply the same inset to the expanded interface preference content so both
  native Pickers and their explanatory text share the row content column.
- Preserve the full disclosure row hit target and the existing Dynamic Type /
  accessibility fallback from the shared header component.

### Verification Plan

- Run the iOS Debug build and focused Settings/UI contract checks.
- Confirm the diff only changes Settings presentation spacing and does not
  change Settings state or preference bindings.
- Install the verified build on the registered iPhone 17 Pro Max for manual
  expanded and fully collapsed observation.

## Settings Top Navigation Follow-Up — 2026-08-26

### Device Observation

The follow-up iPhone 17 Pro Max screenshots confirm that the section spacing
is now acceptable. A remaining issue is limited to the top navigation region:
the Settings `ScrollView` continues underneath the translucent navigation bar.
When the page is scrolled, the trailing part of an upper card or row remains
visible behind the `设置` title and `完成` toolbar, where it becomes blurred and
visually clipped.

### Bounded Follow-Up

- Keep the existing Settings content, scroll behavior, sheet presentation,
  title, and Done action.
- Give the Settings navigation bar an explicit visible system surface so
  scroll content cannot show through the title/toolbar region.
- Do not introduce a custom header or manual safe-area spacer; retain the
  platform navigation bar and its accessibility behavior.

### Verification Plan

- Build the iOS target for the registered physical device.
- Confirm the change is limited to the Settings navigation presentation.
- Install the build on iPhone 17 Pro Max and inspect both the initial top
  position and a mid-scroll position where content previously passed beneath
  the navigation bar.

## Getting Started Content Baseline Follow-Up — 2026-08-26

### Device Observation

The latest device screenshots show that the shared disclosure header inset is
correct, but the expanded `开始使用` introduction still starts at the outer
group edge. Its headline and supporting copy therefore do not share the
header's content baseline, while the action rows below already have their own
icon-and-title inset.

### Bounded Follow-Up

- Add the shared inner horizontal inset only to the Getting Started headline
  and supporting copy.
- Leave the four action rows at their existing row inset so their icon column,
  title column, divider alignment, and full-row hit targets do not move twice.
- Preserve all existing actions, sheets, localized copy, and state flow.

### Verification Plan

- Build the iOS target for the registered physical device.
- Confirm the source diff is limited to Getting Started presentation spacing.
- Install on iPhone 17 Pro Max and inspect the expanded Getting Started card
  alongside its action rows.

## Second UI System Polish Read-only Audit — 2026-08-26

### Source And Boundary

The user-provided audit document is treated as the second-round product/UI
specification. Its instructions govern presentation and verification only.
The existing MemoMark architecture, configuration semantics, persistence,
snapshot, renderer, metadata, Live Photo, Share Extension queue, batch
processing, output language, and MemoMark+ entitlement behavior remain out of
scope.

The first-round Settings device fixes are accepted baseline work:
group/header insets, Getting Started text margins, and the visible Settings
navigation-bar surface are not to be regressed.

### Current UI Audit Findings

#### 1. Surface and Group Grammar

- Settings now has the clearest grouped-form grammar, but its first-round
  corrections are local to Settings.
- Configuration currently renders multiple expanded sections with their own
  `RoundedRectangle` fill and stroke, while the page also has a separate
  section/header layer. The result is a repeated group-within-group surface
  pattern.
- Configuration's memory-expression preview and configuration-status view
  add further nested bordered surfaces inside the already grouped content.
- Home, Subject Overview, Anchor Detail, Progress, and Configuration each have
  related but separate card primitives (`V1TitledSectionCard`,
  `V1TitledSectionSurface`, `V1IOSHomeInsetGroup`, `v1CardChrome`, and local
  rounded containers). These are not interchangeable without checking their
  interaction and accessibility contracts.

#### 2. Current Value And Interaction

- Configuration section headers already expose effective values through
  `V1ConfigurationResultLabel`; this is a strong foundation to preserve.
- Configuration rows for `卡片内容` and `时间与地点` still present `编辑` as
  a blue trailing action beside a chevron. The audit's intended grammar is a
  full-row navigation value with the chevron carrying navigation, while the
  destination remains responsible for editing.
- The Configuration action footer correctly preserves explicit save semantics,
  but its saved state and status presentation need a separate review so the
  primary action remains clear without creating a persistent status card.
- Home preset browsing exposes a preset control and management menu; the
  browse/edit separation is not yet a documented, shared interaction pattern.

#### 3. Capsule, Button, And Color Inventory

- Actual capsule-based status surfaces remain in Home, MemoMark+ presentation,
  Settings expression guidance, Subject editing/status presentation, and
  related support views.
- Configuration uses several custom selection labels, bordered menu labels,
  navigation-row button styles, and a custom save-button style. Some are
  legitimate domain controls; others overlap with ordinary Current Value or
  system Menu semantics and need classification before removal.
- Fixed radius literals and direct font sizing remain across Configuration
  support views, Home, Progress, Subject/Anchor views, and editor previews.
  They include deliberate media/avatar/logo geometry as well as UI chrome that
  should move toward shared tokens. They must not be replaced mechanically.
- Domain colors such as orange, purple, green, and red are already used in
  several places. The second round must distinguish semantic domain color from
  decorative accent before consolidation.

#### 4. Text And Accessibility Risks

- Configuration section headers commonly combine title, subtitle, current
  value, and disclosure state. Several rows then repeat explanatory subtitles,
  so the page can over-explain before the user reaches the real control.
- Subject and Anchor editors still contain persistent edit/clear affordances
  and repeated management instructions; these need an explicit edit-state
  audit rather than unconditional removal.
- Existing Dynamic Type and VoiceOver fallbacks are present in several shared
  components, but the second round has not yet been physically verified at
  Default, Large, XXL, Accessibility Large, or across zh-Hans/en/ja/ko.
- Reduce Motion is handled in several disclosure paths. Reduce Transparency,
  dark-mode hierarchy, and material/surface fallbacks still require a planned
  verification pass.

#### 5. Share Extension And Architecture

- The Share Extension remains a lifecycle/controller-driven surface rather
  than a large SwiftUI editor. It should receive only a bounded visual audit;
  no new Subject, Anchor, Preset, Card Style, or Layout editing surface should
  enter the extension.
- No evidence from this audit authorizes changes to domain models, state
  ownership, persistence, renderer inputs, queue ownership, or navigation
  architecture.

### Second-round Implementation Order

#### Phase 1 — Configuration Center

1. Consolidate Configuration section headers around title, Current Value,
   disclosure state, and full-row navigation semantics.
2. Remove redundant `编辑` wording where the row already navigates to an
   editor, without changing the destination or state flow.
3. Reduce nested expanded-section surfaces while preserving the Memory Card
   Preview as the highest-weight MemoMark surface.
4. Review the configuration status presentation and explicit save footer as a
   single presentation slice; do not alter dirty/saving/saved semantics.

#### Checkpoint A

- iOS build and focused Configuration contracts pass.
- Current values remain visible and VoiceOver-readable.
- Subject, anchor, preset, output, and save actions still use the same state
  flow.
- Physical-device review covers collapsed and expanded Configuration sections.

#### Phase 2 — Subject And Anchor

- Separate browse/detail state from explicit edit state.
- Remove only static clear affordances that duplicate system TextField editing.
- Keep destructive deletion independent and semantically red.
- Preserve Anchor Type, Date, Name, and Today Preview hierarchy.

#### Phase 3 — Home And Preset

- Keep Subject Hero and current preset context primary.
- Move rename/delete/duplicate/reorder behind an explicit management path where
  current behavior permits it.
- Reduce auxiliary workflow explanation before reducing useful context.

#### Phase 4 — Progress

- Retain Just Completed as the primary recent result.
- Move history toward grouped timeline density without changing task/recovery
  state or retry behavior.

#### Phase 5 — Cross-cutting Verification

- Dark Mode and Reduce Transparency.
- Dynamic Type: Default, Large, XXL, Accessibility Large.
- VoiceOver row, picker, current-value, and disclosure semantics.
- zh-Hans, en, ja, and ko length adaptation.
- Share Extension, sheets, Preview, and tab/navigation surfaces.

### First Implementation Slice

The first code slice of the second round is Configuration section grammar. It
will be limited to the Configuration UI layer and shared presentation
primitives, with no domain or persistence files in scope. The first acceptance
target is:

`Section Header -> Current Value -> Chevron -> Grouped Rows -> Footnote`

where an editor row is a full-row navigation action and ordinary Current Value
text is not presented as an unnecessary blue capsule or an `编辑` duplicate.

## Configuration Disclosure Transition Follow-up — 2026-08-26

### Observed Device Evidence

The supplied 7.93-second iPhone screen recording shows that the final expanded
Configuration layout is correct, but closing an upper section while a lower
section moves upward can briefly make section titles visually collide. This is
an animation-only presentation defect; no incorrect final state or data-flow
failure was observed.

### Scope And Hypothesis

The affected surface is the Configuration section stack in
`V1ConfigurationOptionList`. Each expandable body currently combines an
opacity removal transition with an independent parent layout animation. During
closure, the outgoing body is still composited while the following section is
already moving into its space, which can expose a short-lived cross-section
overlap.

### Bounded Fix And Acceptance

Remove the cross-section opacity transition from expandable Configuration
bodies while retaining the existing reduce-motion-aware vertical layout
animation and all disclosure/state behavior. Verify repeated rapid open/close
interactions on the iPhone 17 Pro Max, including multiple simultaneously open
sections. No domain, persistence, renderer, export, or navigation changes are
authorized by this follow-up.

### Follow-up Result

The first bounded change removed the independent opacity transitions, but the
same overlap was still observed on the physical device. The issue therefore
cannot be attributed to the opacity transition alone. The next investigation
will isolate the layout-animation interval and inspect parent-stack and
section-boundary behavior before changing the animation ownership.

### Second Bounded Fix

The disclosure animation is now owned by the complete Configuration option
stack. Per-section implicit animations were removed, and each conditionally
rendered expanded body uses an identity transition so SwiftUI cannot retain an
outgoing copy while the following section is repositioned. The 0.2-second
animation and Reduce Motion behavior remain unchanged at the list level.

## Card Content Editor Surface Follow-up — 2026-08-26

The `卡片内容` row continues to open the existing V1 card-content editor. The
next UI-only slice will reduce the editor's repeated card treatment without
changing its interaction contract. The active editing context remains visible,
the four region editors remain independently editable, region navigation,
module insertion, deletion, keyboard dismissal, preview refresh, and `完成`
remain unchanged. Only the redundant material context surface and the
instruction-card surface are candidates for de-emphasis; the grouped editing
surface and actual text/module controls stay intact.

## Card Content Editor Region Selector And Footnote Follow-up — 2026-08-26

Device screenshots show that the four-region selector is functionally present
but undersized relative to the available header space, making the spatial
control look incidental. The selector will be enlarged and given clearer
selection geometry without changing its `CardRegion` routing or accessibility
labels.

The bottom usage explanation is complete but visually too prominent for a
secondary editor footnote. Its information will remain intact while heading,
step text, marker size, and vertical spacing are reduced. The editor regions,
module chips, text fields, preview refresh, and completion behavior are out of
scope for this slice.

## Card Content Editor Consolidated Pass — 2026-08-26

The follow-up screenshots show that isolated selector enlargement is not the
right final treatment. The editor will receive one consolidated presentation
pass with these boundaries:

- reduce top context and region-row vertical spacing;
- replace the tall spatial 2x2 selector with a horizontal four-region control;
- keep inserted module chips visually distinct from candidate insertion
  actions;
- reduce the toolbar `模块` action to a lightweight tool action;
- retain the bottom usage guidance as a low-emphasis Footnote and remove only
  the line that repeats the visible `完成` action.

The following remain frozen: CardRegion selection and focus routing, text and
TextKit editing, module insertion and deletion, insertion markers, preview
refresh, keyboard dismissal, completion/dismissal, persistence, renderer
inputs, and output behavior.

## Subject And Anchor Surface Follow-up — 2026-08-26

The next phase begins with the active iOS Subject configuration flow. Its
`基础资料` and `时间锚点` sections currently use an outer titled card while
their contents already contain grouped field surfaces or individual anchor
rows. This creates the same nested-card hierarchy that was just removed from
the Card Content editor.

The bounded change is presentation-only: retain both section titles and
subtitles as plain section headers, preserve all inner field/anchor surfaces,
and leave subject save, anchor add/edit/delete, rollback, validation, and
selection behavior untouched.

### Time Anchor Sheet Follow-up

Inside the time-anchor editor, the type/date field group and the “今天的时间
答案” result preview have distinct semantic jobs and remain surfaced. The
`设置后会怎样？` guidance is secondary explanatory copy and will be removed
from the full panel chrome, reduced to a low-emphasis Footnote, and kept
complete. The primary save action and all anchor mutations remain unchanged.

### Time Anchor Field Group Follow-up

After the Footnote reduction, the remaining redundant surface is the separate
Name panel. The next slice places Name after Type and Date inside the same
field group, producing the stable hierarchy `Type -> Date -> Name -> Today
Preview -> Save`. The existing binding, generated-title behavior, validation,
and editing transaction remain unchanged.

## Configuration Surface Follow-up — 2026-08-26

The next bounded slice targets the expanded `布局与内容` group only. Its
configuration status presentation is currently a rounded status card nested
inside the already grouped surface, which gives a transient state the same
visual weight as an interactive card. Convert it to a plain, full-width status
row after the existing divider. Preserve every status case, color, icon,
accessibility value, and save-state behavior. No other nested surfaces or
configuration semantics are changed in this slice.

## Time Anchor List Follow-up — 2026-08-26

The time-anchor list currently gives every anchor row its own rounded panel,
while the add action owns another rounded panel below it. Consecutive anchors
therefore read as a stack of separate cards instead of one editable collection.

The bounded change is to use one grouped surface with hairline dividers. Each
row keeps its existing tap-to-configure, context-menu delete, optional leading
swipe-delete affordance, accessibility actions, and time-answer presentation.
The add action and the maximum-five note move into the same group without
changing anchor creation, deletion confirmation, validation, persistence, or
the subject configuration state flow.

## Subject Identity Field Group Follow-up — 2026-08-26

The identity editor still presents “照片中的称呼” and the four identity
fields as two consecutive grouped surfaces. They belong to one identity
configuration context, so the repeated outer boundaries add visual weight and
vertical whitespace without adding meaning.

The bounded change is to merge them into one grouped surface with a single
hairline divider. The field order, bindings, focus progression, clear actions,
expression-subject source selection, avatar flow, validation, and draft sync
remain unchanged.

## Subject / Anchor UI Automation Follow-up — 2026-08-26

The UI polish pass now has a dedicated regression path in the existing
`MemoMarkDeviceQA` XCTest target. The test uses stable accessibility identifiers
to reach the Subject overview and editor, verifies the identity and time-anchor
groups are exposed, checks that anchor row frames do not overlap, and opens and
saves an anchor editor. It runs against an isolated iOS Simulator state; no
production data, renderer behavior, or PhotoKit output is used by this UI check.

The test intentionally keeps XCTest/XCUITest because it exercises the running
Apple UI hierarchy. Swift Testing remains the preferred framework for new
non-UI unit tests.

The changed application sources pass the iOS Simulator Debug build and the
relevant Swift sources pass parser validation. The UI-test target is wired into
the shared `MemoMarkDeviceQA` scheme, but execution in this session was blocked
before compilation by an unresponsive CoreSimulator/Xcode asynchronous
preparation service during simulator system-data migration. No UI-test pass is
claimed until that service completes normally.

## Home Preset Browse-State Follow-up — 2026-08-26

The Home Preset area still exposes management affordances inside every browse
row: each preset owns a separate rounded card, a persistent more-actions menu,
and trailing swipe actions for save and delete. This makes a content-first Home
surface read like a management list and repeats the same container treatment
that was already removed from Settings and Subject / Anchor groups.

The bounded pass is to keep one grouped surface for the preset collection and
show only identity, summary, and selected state in each browse row. Rename,
backup, and delete move to the current-preset management menu in the section
header; delete keeps its existing confirmation alert. Preset selection,
unsaved-change protection, persistence, backup, deletion, and configuration
snapshot behavior remain unchanged.

Implementation and delivery evidence: `V1HomePageSurface.swift` now renders
the preset collection as one grouped browse surface and centralizes management
actions in the current-preset header menu. The signed `PhotoMemoiOS` Debug
build passed, installed successfully, and launched on the paired physical
`iPhone 17 Pro Max` (`863C2747-6742-5E93-B715-6F89DBF90B31`). The source parser
check and `git diff --check` also passed. Per the project device policy, no
simulator build or simulator visual verification was used for this delivery;
manual visual acceptance remains with the device review.

## Home Subject Hero Information Hierarchy Review — 2026-08-26

The Home `记忆对象` card is intentionally one primary content surface, but its
contents currently combine three semantic layers: subject identity (display
name and dedicated salutation), configuration state (the number of configured
time anchors), and the current time answer for the anchor selected by the
active preset. The next bounded review should clarify those layers without
adding a second state model or changing the anchor-selection semantics.

The count should communicate configured data accurately. `已设置 2 个时间
锚点` is more precise than a bare `已配置锚点`, while `2 个重要日子` remains
the warmer content-facing alternative. The current time answer should remain
the card's distinctive MemoMark content and become easier to scan, but should
not become a second full card inside the Subject Hero. A lighter answer row,
divider, or restrained tint can preserve its emphasis while following the One
Surface Less rule.

The Home card should not repeat nickname, relationship, and salutation as
separate fields. Identity remains primary, the anchor count remains a concise
setup summary, and the selected anchor's live answer remains the single
dynamic result. Existing full-card navigation to the Subject detail flow and
the underlying `selectedTimeAnchorID` / calendar calculation behavior remain
unchanged. No code change is made by this review entry.

## Home Subject Hero Presentation Pass — 2026-08-26

The Subject Hero presentation pass is implemented in
`V1IOSSubjectOverviewSupport.swift`. The salutation and configured-anchor
count no longer use non-interactive Capsule surfaces; they are now a quiet
metadata line. The selected anchor's current answer remains visible, but its
inner bordered rounded surface was removed so the Home section has one clear
primary card. The answer value was raised from caption sizing to a readable
subheadline while the existing hourly calendar refresh, anchor selection,
fallback order, accessibility label, and full-card navigation remain intact.

Verification: the changed Swift source passed frontend parsing,
`git diff --check` passed, and a signed `PhotoMemoiOS` Debug build succeeded,
installed, and launched on the paired physical `iPhone 17 Pro Max`
(`863C2747-6742-5E93-B715-6F89DBF90B31`). No simulator build or simulator
visual verification was used. Final visual acceptance remains a manual device
check of the Home Subject Hero in normal and compact width states.

## Home-First Verification Order — 2026-08-26

The next review order is intentionally adjusted from the original cross-cutting
sequence. Dark Mode, Share Extension presentation, VoiceOver, Dynamic Type,
Reduce Transparency, and four-language visual adaptation are deferred to the
final verification pass. The immediate Product Loop remains Home / Preset,
followed by Progress; the deferred platform and localization checks are then
handled together against the settled surfaces.

The Home `记忆对象` section is confirmed as a single primary Subject Hero
card. This is an intentional content surface: it provides the current memory
subject, avatar, relationship/context values, important-date summary, and the
entry point to its detail flow. It should not be flattened merely to satisfy
the One Surface Less principle. The Home page may still contain other
semantically separate surfaces, such as the grouped Preset collection and
supporting usage guidance; “唯一的一个卡片” applies to the `记忆对象`
module itself, not to the entire Home page.

## Home Supporting Information De-emphasis Pass — 2026-08-26

The Subject Hero is accepted as the Home's primary content surface. The
remaining supporting surfaces currently give two non-primary information types
more weight than their semantics require: the header's non-interactive
`本地优先 / Apple Photos` facts use Capsules, and the `怎么记录` guidance uses
a bordered rounded card. The next bounded slice converts the header facts to a
quiet inline fact row and the workflow guidance to an external Footnote-like
block. The interactive MemoMark+ badge, Settings button, Preset management
menu, workflow copy, and all processing callbacks remain unchanged.

## Progress History Density Pass — 2026-08-26

The Progress surface keeps the current task / Just Completed result as the
primary status surface. Its saved-history area will move from one bordered
card containing recent rows to a compact date-grouped timeline. Rows remain
the existing saved-job presentations and preserve Photo Library navigation;
the grouping is presentation-only and does not change task state, recovery,
retry behavior, filtering, or persistence. The four interface languages will
receive localized `Today` / `Yesterday` group labels, with locale-aware dates
for older groups. No simulator verification is permitted; the acceptance
target is the signed physical iPhone 17 Pro Max build.

## Progress Latest Completion Precision Pass — 2026-08-26

The latest completed result keeps its visual priority but separates state from
result content. `刚刚完成` and its saved-result explanation move to a Plain
Section header outside the result surface. The result surface retains the
configuration name, the card-style preset, the processed photo count, the
completion timestamp, and the Apple Photos action. The preset label is made
explicit as a style, and the photo count is made explicit as the number of
photos processed in this job. The nested Apple Photos action background is
removed while the full-row action and album destination remain unchanged.
No task-state, recovery, retry, history, persistence, or photo-library
behavior changes are in scope.

The latest completion header also uses the same three-point title-to-subtitle
spacing as the Recent Saves section header. The status pill remains aligned to
the header's top edge, while the title and explanation now share one text
stack. This is a bounded typography correction within the existing width pass;
no content or interaction behavior changes.

## Progress Photo Library Action Copy Pass — 2026-08-26

The completed-result action keeps opening the system Photos app. Its visible
action copy now describes the actual behavior as viewing in Photos, while the
secondary line continues to name the saved album when available. Accessibility
copy makes the sequence explicit: open Photos first, then view the named
destination. No PhotoKit data model, saved-asset identifiers, album behavior,
URL routing, or in-app viewer was added in this pass.

## Home, Configuration, And Progress Naming Closure Pass — 2026-08-26

The final comparison of the three primary iOS surfaces found two remaining
presentation inconsistencies. Classic White was still projected through older
`基础白` / Basic White localization keys in Home and Configuration Center,
while Progress already used the formal preset display name. The Subject Hero
also showed a warm `重要日子` count but exposed a different `时间锚点` meaning
through its accessibility label.

This closure pass uses `TemplatePreset.classicWhite.displayName(for:)` as the
single presentation source for the preset name, and adds a localized important
day count format whose visible and accessibility values are identical. Legacy
localization keys remain available for stored-data compatibility, but are no
longer selected by the active primary surfaces. The existing completed-job
history filtering is retained: when the current task is already completed,
its job remains represented by the primary result surface and is excluded only
from the inline history presentation; persisted history is untouched.

No configuration aggregate, preset persistence, task state, history data,
anchor selection, calendar calculation, or processing behavior changes.

## Share Extension Presentation Closure Pass — 2026-08-26

The physical-device Share screenshots show a stable minimal handoff surface,
but the confirmation summary currently presents the memory-subject text under
the `配置` label, while the formal saved preset title is available as a
fallback. The summary rows also use a vertical label/value treatment that
makes the card unnecessarily tall, and the current processing stage has the
same secondary visual weight as the static processing assurances.

This bounded pass will keep the Share Extension limited to the current
configuration, save destination, photo count, confirmation, and error states.
It will correct the summary presentation contract to show the current preset,
rename the destination label to `保存到`, compact the summary into native
grouped rows, give the dynamic processing stage a distinct primary text
hierarchy, and combine each summary row's accessibility label/value without
changing the underlying snapshot, intake, durable queue, background
processing, notification, or `completeRequest` behavior. The confirmation
action copy will describe starting the recording/processing handoff rather
than promising immediate generation; the submitted state and automatic
completion timing remain unchanged.

The existing preview implementation remains out of the normal confirmation
surface because the audit requires a minimal Share boundary. Its currently
unreachable path and unused titled-card helpers are noted as maintenance debt
and are not expanded in this pass.

Risk: P1 for primary handoff comprehension and accessibility; P2 for density
and copy refinement. Apple-native UIKit controls, semantic system colors,
Dynamic Type, VoiceOver row values, and the existing local-first Photos
handoff were evaluated. Verification is source/resource lint, signed
`PhotoMemoiOS` build, and manual physical iPhone 17 Pro Max review across
confirming, submitted, error, long localized text, Dynamic Type, VoiceOver,
and reduced-transparency states. Simulator and automated UI verification are
not in scope by explicit product direction.

### Implementation And Device Delivery — 2026-08-26

Implemented in the existing Share Extension UIKit surface:

- The `当前配置 / Current Configuration / 現在の設定 / 현재 구성` row now
  projects the saved Preset title rather than the memory subject nickname.
- The destination row now reads `保存到 / Save To / 保存先 / 저장 위치` while
  continuing to use the existing selected-album snapshot and resolver.
- Summary rows now use a compact horizontal label/value grammar with one
  consistent divider treatment. Long values remain multiline-capable.
- Summary rows are exposed as one VoiceOver element each, combining the
  semantic label and current value.
- Normal confirmation, receiving, and submitted stages use the primary
  system label hierarchy; static processing assurances remain secondary.
- The normal confirmation action now reads `开始记录 / Start Recording /
  記録を開始 / 기록 시작`. Submission, automatic dismissal, retry, and error
  actions retain their existing state flow.

The implementation does not change the configuration snapshot, PhotoKit
behavior, intake validation, durable queue, background processing,
notification, output, or `completeRequest` responsibilities. The preview
path remains intentionally hidden from the minimal confirmation surface.

Verification completed: four localization resources passed `plutil -lint`,
`git diff --check` passed, and the signed `PhotoMemoiOS` Debug build for the
physical iPhone 17 Pro Max succeeded. The app was installed in place and
launched successfully as `com.serydoo.PhotoMemo.iOS` using device ID
`863C2747-6742-5E93-B715-6F89DBF90B31`. No simulator or automated UI test was
used. Manual Share confirmation/submission and accessibility acceptance remain
with the device review.

## Share Summary Alignment Correction — 2026-08-26

The follow-up physical-device screenshots exposed a layout regression in the
compact Share summary: the divider had been placed in the same horizontal
stack as the row content, value labels were visually oversized and right
distributed, and the three rows therefore appeared to have different
alignment and rhythm.

The correction keeps each summary row as a vertical container with a stable
horizontal title/value row and an independent full-width divider row. The
title column uses one measured width for all three labels, values start from
the same column and remain multiline-capable for localized or long album and
preset names, and the summary value typography now uses the existing module
title scale rather than the larger value scale. Vertical margins and baseline
alignment are shared across every row.

This is presentation-only. The current Preset, selected album, photo count,
snapshot, intake, queue, processing, notification, and Share Extension
completion behavior are unchanged.

Verification: the signed `PhotoMemoiOS` Debug build succeeded after the
correction, the app was installed and launched on the paired physical iPhone
17 Pro Max (`863C2747-6742-5E93-B715-6F89DBF90B31`), and the existing resource
and diff checks remained clean. No simulator or automated UI test was used by
explicit product direction.

## Configuration Center Bottom Action Coverage — 2026-08-26

The long Configuration Center surface exposed a visual layering issue at its
fixed bottom action area. The action footer was correctly attached through the
bottom safe-area inset, but its full-width Material background created a broad
blurred strip across the page. This reduced the visibility of adjacent
configuration content and made the footer compete with the system navigation
surface.

The footer now presents the existing Save and More controls inside a bounded,
centered action cluster. Only the cluster carries the Material or opaque
Reduce Transparency surface; the surrounding bottom area stays visually open.
The safe-area inset remains the ownership boundary for the fixed action, and
the editor scroll content retains its existing bottom clearance. The change is
limited to presentation chrome and shared layout tokens; save behavior, menu
actions, confirmations, state transitions, persistence, and all other main
surfaces remain unchanged.

Physical-device installation and launch succeeded after the change. The
captured device screenshot was not used for visual sign-off because the phone
was showing an existing system recording/accessibility overlay and was not
navigated to the target Configuration Center position. Manual visual
acceptance of the bounded footer remains to be performed on the device; no
simulator or automated UI test is in scope.

## Share Summary Row Rhythm Decision And Implementation — 2026-08-26

The row-rhythm follow-up is implemented with the existing Share design-token
system. Each summary value row now has a shared 36pt minimum content height
and uses vertical centering for its title/value pair. The minimum is
deliberate rather than a hard clip: Dynamic Type, localization, and genuinely
long Preset or album values can still expand the row when wrapping is needed.

No state or processing code changed. The signed physical-device build passed,
was installed, and was launched on the paired iPhone 17 Pro Max. No simulator
or automated UI test was used by explicit product direction.

## Share Summary Optical Text Lift — 2026-08-26

The next physical-device review confirms that the summary row geometry is
uniform, but the glyphs still read slightly low inside the shared content
area. This is a font-metrics issue rather than a row-height issue, most
visible in the secondary title labels and the emoji-bearing destination value.

The correction keeps the row height and divider positions unchanged, while
using the row's layout margins to lift the title/value pair by approximately
2pt within the content area. It remains Auto Layout based, so wrapped
localized text and Dynamic Type can continue to expand the row without
clipping or transform-related layout side effects. No Share state or
processing behavior is in scope.

## Card Content Editor Interaction And Height Boundary — 2026-08-26

The card-content editor is a direct editing surface for four visible regions.
The prior `正在编辑区域` context block and its horizontal region navigator
duplicate the information already present in the vertically scrollable editor
fields. This pass removes that visual navigation layer while retaining the
transient focused-region state required for TextKit focus, module insertion,
keyboard reveal, and preview synchronization.

The editor Sheet previously offered the system `.large` detent, which allowed
it to cover the configuration page's top preview when fully expanded. The
editor now uses the existing custom overlay presentation with an explicit
adaptive top boundary, so its top edge stops below the configuration page's
preview instead of relying on a system detent. The header remains fixed, while
the editor content and module candidates continue to scroll within the
remaining space.
This is a presentation-boundary change only: the real preview, draft mutation,
TextKit command buses, module insertion/deletion, keyboard dismissal, completion
return, persistence, renderer, and Share workflow remain unchanged.

The boundary is intentionally adaptive for smaller iPhones and Dynamic Type:
it uses the available height fraction with a minimum top boundary, and removes
the keyboard-covered bottom area from the editor viewport. The physical
acceptance target is the paired iPhone 17 Pro Max, with the lower-height
behavior reviewed through the same adaptive rule. No simulator or automated UI
verification is in scope by explicit product direction.

## Card Content Editor Preview Gap And Module Caret Preservation — 2026-08-26

The physical-device review confirmed that the editor boundary was correct, but
the gap above the editor could be reduced to better match the accepted compact
reference while keeping the configuration preview visible on shorter iPhones.
This pass tightens the adaptive boundary from `0.20`/`168pt` to `0.16`/`136pt`
without changing the editor's fixed header or keyboard-aware viewport.

The same review identified a focus regression: opening the inline module
candidate surface dismisses the keyboard, and a subsequent SwiftUI update can
replace `UITextView.selectedRange` before the selected module is inserted. The
TextKit session now retains the last valid insertion selection and uses it as
the command boundary after keyboard dismissal or redraw. Region routing,
module insertion, draft projection, preview refresh, and persistence remain
unchanged.

The signed physical-device build succeeded, was installed and launched on the
paired iPhone 17 Pro Max, and a new screenshot confirms the tighter top gap
with the keyboard visible. Source/resource checks also passed. No simulator or
automated UI test was used by explicit product direction.

The first implementation slice keeps the existing Home/Progress card anatomy
but allows important user-controlled names and processing descriptions to grow
to two lines at ordinary text sizes (and the existing larger allowance at
accessibility sizes). The Configuration Center's compact selection label and
subject value now use the same non-clipping principle, so a long current value
can expand vertically instead of being forced into a single line. Share was
reviewed but deliberately left unchanged in this slice because its summary
alignment pass is already closed and its UIKit rows already support multiline
values.

## Dynamic Type And Reduce Transparency Consolidation — 2026-08-26

The remaining non-deferred accessibility/layout slice is limited to existing
presentation constraints. The Share Extension already uses zero-line UIKit
labels with content-size-category scaling and its summary rows remain
multiline-capable, so no Share structure change is required here. The residual
risk is the few main-app rows that still constrain user-facing status/action
text to one line, plus two Material-backed surfaces that do not yet provide an
opaque fallback when Reduce Transparency is enabled.

This slice keeps the current typography and hierarchy, widens only the
relevant action/status text constraints, and switch the Configuration footer
and transient Home feedback banner to their existing opaque semantic surfaces
under `accessibilityReduceTransparency`. Dark Mode, VoiceOver traversal and
label audits remain explicitly deferred. No data, navigation, renderer,
PhotoKit, Share-processing, or persistence behavior is in scope.

## Cross-Screen Small-Height And Long-Text Adaptation — 2026-08-26

The next bounded polish pass reviews the four principal iOS surfaces together:
Home, Configuration Center, Progress, and Share, with the Card Content Editor
included where it affects the small-screen keyboard viewport. The observed
risk is not a missing feature but loss of hierarchy when a Preset name, album
name, status value, or localized string becomes longer: important values can
be forced into a single line, trailing controls can compete with the title, or
row rhythm can diverge between the main surfaces.

The intended outcome is a resilient first-view layout across shorter iPhones,
Dynamic Type, and the four shipped localizations. Text may wrap when the
content requires it; controls remain tappable and readable; cards keep their
shared horizontal margins; and bottom actions remain reachable above the safe
area. No Memory Engine, renderer, PhotoKit, Share queue, persistence, or
navigation-order behavior is in scope. Dark Mode and VoiceOver remain deferred
to the previously agreed final pass; Reduce Transparency is covered by the
consolidation slice below.

The implementation is limited to existing SwiftUI/UIKit presentation code and
shared UI tokens. The first slice audits and, where evidence requires it,
adjusts Home and Progress list typography because those surfaces display user-
controlled names and processing metadata. Configuration and Share are reviewed
for regressions rather than mechanically changed. Acceptance is based on
source-level responsive constraints, resource/diff checks, a signed physical
device build/install/launch on the paired iPhone 17 Pro Max, and manual review
of the resulting screens. No iOS Simulator or automated UI test is in scope by
explicit product direction.
