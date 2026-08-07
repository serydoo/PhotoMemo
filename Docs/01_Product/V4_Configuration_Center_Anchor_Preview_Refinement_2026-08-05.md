# V4 Configuration Center Anchor Preview Refinement

- Date: 2026-08-05
- Primary loop: Product Loop
- Risk: P1
- Status: Implementation Complete; Physical Install Complete; Relaunch Pending
  Device Unlock; Visual Acceptance Pending

## Observation

Physical-device screenshots `IMG_6666.PNG` through `IMG_6669.PNG` show that
the Time Anchor and Memory Expression controls no longer hold the compact
trailing position used by the surrounding Configuration Center rows. Their
long subtitles, together with the Memory Expression detail inside the trailing
control column, cause the adaptive row to fall back from its horizontal form
to its vertical form.

The same screenshots show excess vertical space between the inline navigation
title and the first content in the Time Anchor, More Information, and Card
Content sheets. The Time Anchor editor also lacks the title treatment used by
the other configuration sheets.

## Intended Outcome

1. Restore the Memory Source subtitle to `你想围绕谁开展回忆。`.
2. Use the compact Time Anchor row subtitle `回忆对象重要时刻`.
3. Keep the Time Anchor and Memory Expression controls compact and trailing
   aligned at standard content sizes.
4. Remove the Memory Expression formula preview from the trailing control
   column and place it in a separate, compact panel below the complete Memory
   Expression row.
5. Let that panel show the real selected expression for `之前`, `当时`, and
   `之后`, derived from the existing `memoryDisplayDetail` value.
6. Add the inline sheet title `时间锚点` and the highlighted prompt
   `选择一个时间起点，让照片拥有时间答案。` to the shared add/edit Time
   Anchor editor.
7. Use a tighter, consistent title-to-content rhythm in the Time Anchor, More
   Information, and Card Content sheets.

## Follow-Up Physical Review

Screenshots `IMG_6670.PNG`, `IMG_6671.PNG`, and `IMG_6672.PNG` show a second
bounded presentation issue after the first pass:

- The Time Anchor navigation title is native and centered, but the blue bold
  prompt below it reads like a separate action banner rather than sheet
  context.
- More Information and Card Content have centered navigation titles but no
  matching subtitle, so the three configuration sheets do not share one visual
  hierarchy.
- The requested future-extension and advanced-user feedback ideas need to be
  expressed as quiet product copy, without exposing internal terms such as
  `模块` or addressing users as a community role.

Accepted follow-up treatment:

- Keep the native inline navigation titles.
- Add one shared centered `footnote` subtitle treatment with secondary color
  and system spacing below the Time Anchor and More Information titles. The
  fixed-region Card Content editor keeps a compact title-only header and uses
  its bottom behavior explanation instead, preserving input and keyboard
  viewport space.
- Time Anchor subtitle: `选择一个时间起点，让照片拥有时间答案。`
- More Information subtitle: `更多内容会根据实际需要逐步加入。`
- Card Content keeps the compact title-only editor header. Its bottom
  explanation is the source of truth for fixed-region behavior:
  `四个区域都可以自由组合文字和内容，修改会实时同步到上方预览；右下区域会写入照片说明。点“完成”后统一保存，收起键盘不会离开编辑页。`
- Preserve the existing sheet actions, data ownership, detents, and editor
  internals. This is presentation polish only.

## Scope And Ownership

In scope:

- Configuration Center SwiftUI composition and adaptive layout
- Memory Expression inline preview presentation
- Time Anchor sheet presentation
- localized product copy and accessibility copy
- source-contract tests and project-language documentation

Out of scope:

- Memory Engine calculations and expression ownership
- configuration persistence and transaction semantics
- Layout Engine and Renderer behavior
- export, PhotoKit, Share Extension, and Apple Photos lifecycle
- IA-002 Configuration Center architecture

The preview continues to consume the established presenter output. It does not
calculate time or author new expression text inside the view.

## Apple-Native Reuse

The implementation continues to use SwiftUI `Menu`, `NavigationStack`, sheet
detents, Dynamic Type branching, and VoiceOver semantics. No custom menu,
navigation bar, or modal container is introduced.

## Failure Modes

- A long selected value could make a control wider than the available row.
- Accessibility text sizes could become too dense if horizontal layout were
  forced universally.
- Parsing the phase preview could hide content if the presenter output changes.
- Tightening sheet margins could reduce useful spacing inside editor cards.

Mitigations:

- Keep the existing accessibility-size vertical fallback.
- Give the normal-size trailing control a bounded width and truncation.
- Split only on the presenter's established `｜` separator and preserve every
  non-empty line.
- Adjust only scroll-content top margins; preserve component-internal spacing.

## Verification Plan

- Source-contract tests for approved subtitles and removal of the old trailing
  preview/sheet path
- Source-contract tests for the inline three-phase panel, real presenter data,
  design tokens, smaller typography, bounded menu size, and trailing alignment
- Source-contract tests for the shared Time Anchor add/edit sheet title,
  highlighted prompt, and compact scroll-content margin
- Source-contract tests for compact More Information and Card Content margins
- focused tests, full `PhotoMemoTests`, localization lint and key symmetry,
  `git diff --check`, and the required unsigned project build
- signed device build, overwrite install, and launch on the online iPhone 15 Pro
- final visual acceptance by the user on the physical device; no simulator
  visual acceptance is required for this pass

## Follow-Up UI Specification: Button And Sheet Consistency Audit

- Date: 2026-08-05
- Primary loop: Product Loop
- Risk: P1
- Evidence: physical-device screenshots `IMG_6674.PNG`, `IMG_6676.PNG`,
  `IMG_6677.PNG`, `IMG_6678.PNG`, `IMG_6679.PNG`, and `IMG_6680.PNG`
- Status: Implementation and automated verification complete; physical-device
  install and launch complete; manual visual acceptance pending

### Observed Differences

The Configuration Center currently presents three different trailing-control
behaviors in one compact information list:

- Logo and Time Anchor use the default row expansion and occupy the available
  `128pt` trailing column.
- Memory Expression opts out of row expansion and adds a separate `112pt`
  frame, making its control visibly narrower.
- Other sheets also contain full-width selectors for choices whose meaning
  applies to the whole row, such as Time Supplement.

The three related sheets also mix hard-coded `14pt`/`10pt`/`13pt` values with
the existing `ConfigurationUI` and `MemoMarkDesignTokens` values. Their title
and subtitle hierarchy is now shared, but their inner panel padding, row
rhythm, selector height, and corner-radius sources are not yet one system.

### Accepted Rules

1. `Compact trailing control`: configuration-row and compact sheet selectors
   use a `128pt` trailing column, a `44pt` minimum touch height, the shared
   compact-control corner radius, and the shared selector typography. Long
   values truncate or scale inside this bound.
2. `Full-width inline selector`: selectors whose label and value describe the
   entire row use the full available width and the same `44pt` minimum touch
   height. This includes Time Supplement and is intentionally not the same
   semantic class as a compact trailing control.
3. `Native action`: toolbar `完成` remains an Apple-native confirmation action;
   the anchor editor's prominent `保存` remains a primary action with the
   shared minimum touch target. These actions are not width-matched to menus.
4. `Sheet chrome`: the three configuration sheets use inline native titles,
   the shared centered footnote subtitle, the same subtitle inset rhythm, the
   same horizontal content inset, a visible drag indicator, and token-backed
   detents appropriate to content density. Sheet height is not forced to be
   identical when the content differs.
5. `Inner card grammar`: sheet panels use one semantic panel surface, one
   inner-panel corner radius, `12pt` content padding, `12pt` divider insets,
   and `44pt` minimum interactive rows. Nested editor fields may use the
   smaller control radius, but no target sheet may add a new literal radius.

### Scope And Verification

The implementation is limited to the Configuration Center controls, the Time
Anchor, More Information, and Card Content sheets, their shared iOS support
components, design tokens, source-contract tests, and this state record. The
Memory Engine, renderer, export, PhotoKit, persistence, and share lifecycle
remain untouched. Verification is focused and full tests, localization lint,
`git diff --check`, unsigned and signed builds, and overwrite installation to
the paired iPhone 15 Pro. No simulator visual validation is part of this pass.

### Global Sheet Inventory Boundary

The repository inventory found `32` SwiftUI sheet entry points, `17` explicit
detent policies, `15` explicit drag-indicator policies, and no
`fullScreenCover`. These surfaces do not belong to one visual or transactional
class. The accepted system therefore standardizes roles rather than forcing a
single container:

- compact configuration editors use the shared configuration title rhythm and
  a compact-height plus large detent;
- dense content editors keep a higher content-specific detent and keyboard or
  preview interaction policy;
- browsing, explanation, and module-selection sheets keep native List or
  medium/large presentation behavior;
- object and local-library management may remain large;
- Apple photo pickers and share controllers remain fully system-owned.

The More Information sheet intentionally keeps `List(.insetGrouped)` and its
Apple-managed section geometry. Time Anchor and Card Content use shared chrome
only for their custom panels. Toolbar confirmation actions, primary save
actions, compact selectors, and full-width selectors remain separate control
roles. No presentation policy is applied to system controllers merely for
visual similarity.

## Follow-Up Observation: Sheet Surface Continuity

- Date: 2026-08-05
- Primary loop: Product Loop
- Evidence: latest physical-device comparison of More Information and Card
  Content sheets
- Status: implemented and automatically verified; physical-device install and
  launch complete; manual visual acceptance pending

The intended character of these configuration sheets is refined, compact,
short, and visually continuous. The current More Information sheet has a
visible color and surface break between the shared title/subtitle area and the
native `List(.insetGrouped)` content below. On the physical device, the two
areas read as separate surfaces joined together rather than one coherent sheet.

The Card Content sheet is the accepted visual reference for this aspect: its
outer sheet background and the surrounding area of the inner cards remain
continuous, without an obvious top-to-content color boundary. A later bounded
implementation pass should remove the segmented feeling from More Information
while preserving its compact information hierarchy.

This record does not yet choose between replacing `List`, changing list
background behavior, changing the shared subtitle background, or changing the
sheet-level background. Those options remain open until the remaining
physical-device observations are collected and reviewed as one UI pass.

## Follow-Up Observation: Compact Row Rhythm

- Date: 2026-08-05
- Primary loop: Product Loop
- Evidence: latest physical-device review of the Configuration Center and its
  subordinate configuration sheets
- Status: implemented and automatically verified; physical-device install and
  launch complete; manual visual acceptance pending

Rows with trailing controls should share one visually concise control width
across the Configuration Center and its subordinate menus. The trailing
control should be vertically centered against the row's complete content block,
including any restrained supporting text or preview, so rows do not appear
top-heavy or misaligned when their information density differs.

The goal is a consistent compact rhythm rather than mechanically identical row
heights. A row without supporting preview content may be slightly taller when
needed to preserve balance and touch comfort. A row with supporting text or a
preview should keep that secondary content brief and subordinate instead of
growing into a second visual section or making the trailing control feel
detached.

Card Content must return to its earlier compact presentation rather than use
the current revised inner layout as the basis for further visual polish. Its
four customizable regions should remain four clear, single-row entries. Any
per-region preview should be selectively shortened or omitted where it does
not materially help recognition, preserving the earlier one-row-per-region
scan pattern and avoiding tall, card-like rows. The later implementation pass
must identify the prior implementation and screenshot baseline before editing,
then retain only those newer consistency changes that do not compromise the
earlier compact character.

This is an acceptance direction, not yet a fixed measurement or truncation
rule. Exact control width, row height, alignment, and preview omission behavior
will be settled after the remaining physical-device observations are recorded
and the earlier Card Content design is recovered from repository history and
available screenshots. The current revised Card Content layout is explicitly
not the accepted visual baseline.

## Corrective Implementation Outcome

The physical-device feedback was implemented as one bounded correction while
preserving the newly accepted sheet titles and subtitles:

- More Information now uses the same continuous sheet canvas pattern as Card
  Content: `ScrollView`, the shared sheet background, and one shared compact
  entry panel. The former native `List(.insetGrouped)` surface boundary was
  removed. The `更多信息` title, explanatory subtitle, native `完成` action,
  compact detent, and all existing selection bindings remain unchanged.
- Card Content returns to one horizontal row per region at ordinary Dynamic
  Type sizes. Its right-side resolved-text preview uses the shared `128pt`
  compact column and tail truncation, so long content no longer causes the row
  to become a two-level layout. Accessibility Dynamic Type sizes continue to
  use a vertical layout and may grow naturally without truncating the title,
  subtitle, value, or detail.
- The `卡片内容` title and the newly added subtitle remain in place. Existing
  expansion, module editing, keyboard handling, detents, background
  interaction, and minimum touch-target behavior were not reverted.

Verification evidence:

- the focused `V1ConfigurationOptionListContractTests` suite passed with `14`
  tests after first demonstrating the current regressions;
- the complete test suite passed with `1,287` tests, `1` existing skip, and no
  failures;
- localization syntax, `git diff --check`, the required unsigned Debug build,
  and the unsigned generic iOS build passed;
- signed MemoMark `2.0.2 (69)` was overwrite-installed and launched on
  `IPhone5`, an online iPhone 15 Pro, without uninstalling the app or clearing
  its data; the app process was confirmed running;
- simulator visual verification was not performed, following the product
  owner's instruction. Final visual acceptance remains with the product owner
  on the physical device.

## Physical-Device Correction: Compact Controls And Row Rhythm

- Date: 2026-08-05
- Primary loop: Product Loop
- Evidence: `IMG_2540.jpeg`, `IMG_6689.PNG`, and `IMG_6690.PNG`
- Risk: P1
- Status: implemented and automatically verified; physical-device overwrite
  install and launch complete; manual visual acceptance pending

`IMG_2540.jpeg`, captured from MemoMark `2.0.2` on iPhone 17 Pro Max, is the
accepted reference for Configuration Center card-row height, typography,
compact selector padding, and trailing alignment. iPhone 15 Pro should adapt
to its narrower width without replacing that compact visual grammar.

The latest physical-device build incorrectly translated the `44pt` touch
target and shared `128pt` trailing-column metric into the visible size of every
selector. This created three regressions visible in `IMG_6689.PNG` and
`IMG_6690.PNG`:

- selector backgrounds became visibly too tall and made rows feel uneven;
- fixed-width trailing columns left unnecessary empty space inside short
  selectors;
- `ViewThatFits` moved ordinary-size Memory Expression and Logo controls onto a
  separate full-width line when the horizontal candidate was considered too
  wide.

Accepted correction rules:

- restore the `2.0.2` compact selector typography and visual padding;
- selector backgrounds size to their content up to a bounded maximum rather
  than filling the trailing column;
- at ordinary Dynamic Type sizes, card controls remain at the right edge and
  do not move to a separate line; vertical layout remains available only for
  accessibility Dynamic Type sizes;
- when a selector has a detail or preview below it, the selector and detail
  form one trailing block and that complete block is vertically centered
  against the left heading block;
- when no detail appears below a selector, its compact visual height remains
  unchanged and the selector itself is vertically centered;
- More Information follows the same compact row grammar for Location Display,
  Time Display, and Time Supplement while retaining the newly accepted
  continuous sheet background, title, and subtitle;
- preserve today's accepted language, the separate Memory Expression preview,
  the Time Anchor and Card Content sheet titles/subtitles, and all underlying
  bindings and configuration behavior.

Implementation outcome:

- `V1CompactSelectionLabel` again uses the `2.0.2` compact caption typography
  and `9pt` horizontal / `6pt` vertical visual padding. Its background no
  longer expands to the shared trailing-column width or to a visible `44pt`
  height.
- Ordinary Dynamic Type sizes now use an explicit horizontal row in both the
  Configuration Center and More Information. The former ordinary-size
  `ViewThatFits` vertical fallback was removed; only accessibility Dynamic
  Type sizes use the vertical layout.
- The trailing alignment frame is bounded from `72pt` through the shared
  `128pt` maximum while the selector itself remains intrinsic-width and
  trailing-aligned. A selector and any detail beneath it remain in one
  trailing `VStack`, centered as a complete block by the row's centered
  `HStack`.
- More Information now keeps Location Display, Time Display, and Time
  Supplement as three compact rows with right-side selectors at ordinary
  sizes. Its continuous background, title, subtitle, bindings, and compact
  sheet behavior remain intact.
- Card Content retains the recovered one-row-per-region ordinary-size layout,
  the shared bounded right preview column, and an untruncated vertical layout
  for accessibility sizes.

Verification evidence:

- focused Configuration Center source-contract tests passed before the full
  verification run;
- the complete macOS test run passed with `1,288` tests, `1` existing skip,
  and `0` failures (`1,289` total);
- `git diff --check`, both localization syntax checks, the required unsigned
  Debug build, and the signed iPhone Debug build passed;
- the signed app was overwrite-installed and launched on the paired `IPhone5`
  iPhone 15 Pro without uninstalling the app or clearing its data; the running
  `PhotoMemoiOS` process was confirmed;
- simulator validation was intentionally not performed. Final visual
  acceptance remains with the product owner on the physical device.

## Final Active-V1 Subordinate Editor Audit

- Date: 2026-08-06
- Primary loop: Product Loop
- Evidence: compact-control contract audit of the active V1 Configuration
  Center, Time Anchor editor, and reachable Memory Subject editor
- Risk: P1
- Status: implemented, automatically verified, and overwrite-installed;
  physical-device visual acceptance pending

The final active-flow audit found two remaining layouts that could still move
or distort controls at ordinary larger Dynamic Type sizes:

- the Time Anchor add/edit sheet used `ViewThatFits` for both the custom-name
  row and the anchor-category row, allowing the Save action or category menu
  to move below its heading before accessibility sizes;
- the Memory Subject editor placed its compound expression-subject selector in
  the narrow column beside a fixed `130pt` avatar, leaving about `165pt` on an
  iPhone 15 Pro and making the visible control grow vertically.

The bounded correction keeps the existing data and transaction behavior:

- the Time Anchor editor now branches explicitly on Dynamic Type. Ordinary
  sizes keep the name field and Save action in one centered row, and keep the
  compact category selector plus selected date as one right-side block. Only
  accessibility sizes use vertical layouts;
- the category menu reuses `V1CompactSelectionLabel`, so its visible
  background remains intrinsic and compact while the effective touch target
  remains at least `44pt`;
- the Memory Subject editor keeps the object name and avatar together at the
  top, then presents expression-subject configuration as a separate row with
  explanation on the left and an intrinsic compact selector on the right;
- the expression-subject selector uses the shared `72pt...128pt` trailing
  alignment bound at ordinary sizes and moves below its heading only at
  accessibility sizes.

Final verification evidence:

- the related Configuration Center, responsive-layout, Time Anchor, subject
  overview, and design-freeze contract suites passed;
- the complete macOS test result passed with `1,289` total tests, `1,288`
  passed, `1` existing skip, and `0` failures;
- `git diff --check`, both localization syntax checks, the required unsigned
  Debug build, and the signed iPhone Debug build passed;
- the signed app was overwrite-installed on the paired `IPhone5` iPhone 15 Pro
  without uninstalling the app or clearing its data;
- automatic relaunch was requested three times but iOS rejected every request
  because the device remained locked. No simulator validation was performed;
  final visual acceptance remains with the product owner on the physical
  device.

## 2026-08-06 Physical-Device Subject Detail Density Pass

### Decision Gate

- Primary loop: Product Loop
- Observed scenario: `IMG_6717.PNG`, `IMG_6718.PNG`, `IMG_6720.PNG`, and
  `IMG_6721.PNG` from iPhone 15 Pro, plus `IMG_2547.jpeg` and
  `IMG_2548.jpeg` from iPhone 17 Pro Max
- Risk: P1 because this pass changes a primary configuration workflow and
  must preserve editing, persistence, Dynamic Type, and VoiceOver behavior
- Affected ownership: iOS Memory Subject presentation, Home preset metadata,
  localization resources, and scoped source contracts
- Unaffected ownership: IA-002, `MemorySubject` persistence shape, Memory
  Engine, Presentation Engine, Layout Engine, Renderer, Export, PhotoKit,
  avatar optimization/cropping, and original-photo safety

### Observed Current Behavior

- Subject Time Anchor rows use `76pt` as a minimum height with `14pt` vertical
  padding even though the ordinary state contains only a title, date, and
  short type value. The rows therefore appear unnecessarily open on both
  iPhone 15 Pro and iPhone 17 Pro Max.
- The trailing anchor category is rendered as plain secondary text. It has the
  same visual grammar as the date and does not make the five anchor types easy
  to scan.
- The Home preset row shows a selected preset's saved timestamp without a
  visible saved-state word, so the timestamp can be mistaken for an anchor or
  capture time.
- The Memory Subject identity header places the name on the left and reserves
  `130pt` for the avatar on the right, while also presenting expression-subject
  source in the same card. The result is unused space, duplicated identity
  emphasis, and an unnecessary wrap even on an iPhone 17 Pro Max.
- The four identity fields use a heading plus a separately rounded input for
  every value. This is taller and more visually layered than Apple's native
  Contacts-style identity entry.

### Intended Outcome

- Ordinary Time Anchor rows use content-driven height with a compact `64pt`
  floor; Accessibility Dynamic Type may expand without a fixed cap.
- The trailing type becomes a lightweight native marker that reuses the
  existing type-derived semantic tint without repeating its SF Symbol or the
  visible `类型：` prefix. Ordinary-size labels are deliberately compact:
  `生日/出生`, `恋爱`, `结婚`, `目标`, and `自定义`. VoiceOver continues to
  announce the complete category as `类型，<完整类别>`.
- Selected Home presets show `<日期时间> 保存` in Chinese and the equivalent
  localized saved-state wording in English.
- The edit surface no longer repeats the object name in a separate identity
  header. It follows Contacts-style vertical hierarchy: a centered avatar and
  its `添加照片` or `编辑` action first, then the standalone Memory Expression
  Subject card, then the four-row identity form. `对象名称` appears only in
  its editable row.
- Identity entry becomes one continuous four-row Contacts-style form with
  inline placeholder guidance: `对象名称`, `昵称`, `与我的关系`, and
  `专属称呼`. Optional empty values remain absent from the read-only subject
  overview and appear there only after the user enters content.
- `对象名称` is the sole required identity field. Its row carries a red
  required marker; attempting to complete editing with only whitespace keeps
  the draft open and presents a clear alert. The first-run configuration uses
  the same field name and validation rule. The other three fields remain
  optional.
- Avatar editing follows Apple Contacts interaction grammar without copying
  screenshot geometry: an empty avatar offers `添加照片`; an existing avatar
  offers `编辑`, which directly reopens photo selection, plus a separate
  destructive minus control at the avatar's top-right. Selection continues
  through the existing picker, crop, and derivative pipeline. Deletion clears
  the display, badge, and preview references as one draft change.
- Memory Expression Subject selection moves out of the identity header into a
  separate compact card. The default trailing value is `默认 · 对象名称`.
  Its menu lists `对象名称`, `昵称`, `与我的关系`, and `专属称呼` together
  with each current value; optional empty sources remain visible as
  `未填写` but cannot be selected.

### Apple-Native Reuse

- Reuse SwiftUI `TextField`, `Menu`, `Label`, semantic colors, Dynamic Type,
  and VoiceOver rather than introducing a custom form engine. Existing SF
  Symbol category colors remain the source of the compact text-marker colors,
  while the list row itself does not repeat the icons.
- Preserve the existing `PhotosPicker`, crop sheet, avatar derivative pipeline,
  field focus order, and `44pt` minimum interaction targets.

### Failure Modes And Controls

- Risk: compact rows reduce the delete or configuration hit area. Control:
  retain full-row content shapes and existing accessibility actions.
- Risk: a long type name crowds the anchor title. Control: use one canonical
  compact type label, a trailing marker at ordinary sizes, and a vertical
  fallback at Accessibility Dynamic Type sizes. Preserve the complete type in
  VoiceOver so visual shortening does not remove meaning.
- Risk: a placeholder-only form hides field meaning from VoiceOver. Control:
  keep explicit accessibility labels for all four fields.
- Risk: removing the duplicate identity heading also removes an incidental
  preview of the edited name. Control: keep the form bound directly to the
  existing `displayName` state and preserve the same draft-session sync and
  save validation; no second display-name copy is introduced.
- Risk: avatar deletion removes files before the draft is committed and makes
  Cancel unable to restore the original. Control: treat deletion as a draft
  reference change and defer any owned-file cleanup until a committed state
  can be proven; do not delete files directly from the view.
- Risk: first-run and later editing accept different identity truth. Control:
  share the same trimmed non-empty requirement and cover both completion
  paths with focused contracts.
- Risk: localized resources diverge. Control: lint both resources and verify
  symmetric keys with no duplicates.

### Bounded Implementation And Verification Plan

1. Add source contracts for compact anchor height, native type identity,
   saved-time wording, live object-name provenance, the continuous four-row
   form, required-name feedback, avatar actions, and the standalone Memory
   Expression Subject card; confirm the current source fails them.
2. Implement the Time Anchor row and Home preset metadata changes, then run the
   focused contracts.
3. Implement the identity header and Contacts-style field rows without
   changing state ownership or persistence, then rerun the focused contracts.
4. Run localization lint and key symmetry, `git diff --check`, the complete
   test suite, and the required unsigned builds.
5. Build a signed device app and overwrite-install it on the requested physical
   device without uninstalling or clearing data. Do not use a simulator.
