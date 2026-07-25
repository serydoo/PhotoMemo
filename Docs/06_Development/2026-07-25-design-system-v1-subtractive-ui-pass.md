# MemoMark Design System V1 Subtractive UI Pass

## Decision Gate

- Primary loop: Product Loop
- Observed scenario: The accepted surfaces are structurally mature, but Configuration Center secondary rows still repeat decorative icons and accent-colored support values, while Processing presents `查看相册` as a competing solid-blue action.
- Objective: Apply the frozen Design System through a bounded subtractive pass without changing information architecture, navigation, state, or product behavior.
- Scope: Configuration Center option rows and Processing photo-library navigation only. Home, Share Extension, and Memory Subject were reviewed and remain unchanged.
- Ownership: Configuration objects, processing state, Renderer, Layout, Export, PhotoKit, and Share lifecycle ownership remain unchanged.
- Apple-native capabilities: Continue using SwiftUI semantic colors, SF Symbols for system actions, Dynamic Type, VoiceOver, and native Button/Menu behavior.
- Risk: P2. Failure modes are reduced scanability, loss of meaningful identity imagery, ambiguous affordance, or accessibility-label regression.

## Visual Decisions

- Preserve the Memory Subject avatar and Logo preview because they display real object/content identity rather than decoration.
- Remove decorative leading icons from Time Anchor, Memory Display, Border Style, Location Display, and Card Content rows.
- Preserve row titles, subtitles, values, menus, chevrons, touch targets, and accessibility labels.
- Render supporting row details and selection chevrons with secondary hierarchy instead of repeated accent blue.
- Restyle `查看相册` as a secondary system control with semantic fill, border, and text; remove its primary-action shadow.
- Do not change Home, Share Extension, or Memory Subject in this pass.

## Verification Plan

- Add source contracts that fail while decorative row icons and the solid-blue album action remain.
- Run focused Apple-native product surface contracts.
- Build `PhotoMemoiOS` for a generic iOS Simulator with code signing disabled.
- Run `git diff --check` and review for state, accessibility, architecture, and unrelated-file changes.
- Treat simulator or signed-device screenshots as manual visual acceptance evidence rather than infer them from compilation.

## Verification Result

- The focused `AppleNativeProductSurfaceContractTests` suite passed all 17 tests.
- The generic iOS Simulator Debug build for `PhotoMemoiOS` passed with code signing disabled.
- `git diff --check` passed, and the final source review found no state-flow, accessibility-label, or architecture ownership changes.
- Manual simulator or physical-device visual acceptance was not completed; visual fidelity remains an explicit acceptance item.

## Continuation: Processing, Output, And Region Content

- Observed behavior: Processing completion repeats green through the task dot,
  status pill, percentage, progress bar, and step states. Output repeats section
  titles and uses blue, pink, and green icons across secondary rows. Region
  Content still presents four secondary-row icons and a separate explanation
  card after the editable list.
- Intended outcome: Preserve one clear completion signal, keep percentage while
  work is active but remove redundant `100%` at completion, and make Output and
  Region Content typography-first without weakening controls or state meaning.
- Scope: `V1TaskPageSurface`, `V1OutputPageSurface`, `V1RegionEditorCard`, the
  Region Content sheet composition, and focused source-contract tests.
- Product boundaries: Processing state, configuration drafts, smart-module
  composition, description-writing policy, Renderer, Export, PhotoKit, and
  Share behavior remain unchanged.
- Verification: Add failing source contracts first, run focused contract suites,
  build the signed iOS app including extensions, install and launch on `iPhone7`,
  then leave final visual acceptance to the user.

### Continuation Verification Result

- The combined Processing, Output, Region Content, configuration option, and
  symbol-contract selection passed all 32 focused tests.
- `git diff --check` passed. The signed `PhotoMemoiOS` Debug build, including
  Share Extension and Widget validation, succeeded for physical `iPhone7`.
- Installation on `iPhone7` succeeded. Automated launch was denied only because
  the device was locked; final unlocked-device visual acceptance remains with
  the user.

## Directional Region, Footer, Output, And Settings Correction

- Observed behavior: Region Content still exposed engineering labels `区域 A–D`
  and generic semantic summaries. The Configuration footer grouped status and
  more actions on the left. Output kept both section titles inside their cards,
  while Settings repeated thumbnails, tonal row icons, colored labels, and
  checkmarks beneath its section-level icons.
- Intended outcome: Name card positions `左上、左下、右上、右下`; describe the
  left-top default as action plus device information and the right-bottom
  default as smart-module output. Keep status left, save centered, and more
  actions right. Promote Output titles and explanations outside their cards,
  and make Settings content typography-first while preserving the MemoMark+
  entry and one icon per top-level disclosure section.
- Scope and ownership: User-facing SwiftUI presentation and presenter copy only.
  Region identity, configuration persistence, module composition, Renderer,
  Export, PhotoKit, commerce behavior, and Share lifecycle remain unchanged.
- Verification plan: Run focused presentation and source contracts, a signed
  physical-device build including extensions, install and launch on `iPhone7`,
  and leave final visual acceptance to the user.

### Correction Verification Result

- Thirty-nine focused presentation, settings, symbol, and Design System
  contracts passed after the final dead-parameter cleanup.
- `git diff --check` passed. The signed `PhotoMemoiOS` Debug build succeeded,
  including Share Extension and Widget embedded-binary validation.
- Installation and automated launch on physical `iPhone7` both succeeded.
  Final visual acceptance remains with the user on the running device.

## Home Configuration Actions And Destructive Language

Status: Completed in this pass without changing deletion or persistence behavior.

### Screenshot Evidence

- `IMG_1725.jpeg`: The selected configuration row places Rename, More, and
  Selection controls across too much horizontal space. The `上次修改` value is
  truncated before the complete saved time can be read.
- `IMG_1724.jpeg`: The current anchored `Menu` appears visually oversized and
  disconnected from the compact row. Save and Delete do not yet express a
  sufficiently clear normal-versus-destructive hierarchy.
- The screenshots are local review evidence only and must not be added to the
  repository.

### Frozen Outcome For The Next Unified Pass

- Keep the three actions and their behavior, but regroup them into a tighter
  trailing action cluster aligned closer to the right edge. Remove redundant
  horizontal gaps before changing typography or hiding saved-time content.
- Give the configuration identity and `上次修改` line the reclaimed width. At
  the normal iPhone width shown in the evidence, the complete compact saved
  date and time should display whenever the localized value reasonably fits.
- Replace or restyle the current More presentation as one deliberate
  Apple-native action surface. Preserve a compact source anchor, clear row
  labels, native dismissal, Dynamic Type, VoiceOver, and an explicit
  destructive confirmation before deletion.
- Establish one global destructive rule: every user-facing Delete action uses
  the destructive role and red semantic treatment wherever the platform
  surface supports it. Confirmation actions must also be red; supporting copy
  remains neutral and must state the actual data consequence.
- Audit Home configuration actions, Configuration Center menus, Memory Subject
  deletion, local configuration library actions, Processing history actions,
  Share-related cleanup surfaces, swipe actions, alerts, menus, and confirmation
  dialogs together. Do not fix deletion color one screen at a time.

### Boundaries And Verification

- Scope is presentation and interaction hierarchy only. Configuration identity,
  save/delete semantics, backup retention, selection state, persistence, and
  Renderer/Export/PhotoKit behavior must remain unchanged.
- Add contracts for trailing-cluster spacing, saved-time width priority, native
  destructive roles, red destructive treatment, and confirmation copy before
  implementation.
- Verify narrow widths, Simplified Chinese and English copy, accessibility text
  sizes, VoiceOver labels/order, swipe/menu/alert parity, signed build, and
  physical-device visual acceptance as one consolidated UI pass.

### Completion Result

- Home configuration and time-anchor More menus now expose delete entry points
  with the native destructive role. Swipe entry points retain non-full-swipe
  confirmation behavior and semantic red tint.
- Configuration reset, configuration deletion, Memory Subject deletion, Time
  Anchor deletion, and local-backup deletion retain centered native alerts;
  every final mutation uses the destructive role and neutral supporting copy
  states the actual consequence.
- Share has no user-facing destructive action in its current confirmation-only
  workflow. Internal preview cleanup is lifecycle housekeeping rather than a
  user deletion command.
- Output Memory Write copy now comes from stable Simplified Chinese and English
  resources selected by the interface-language preference. Resolved smart
  module output and user-entered text remain untranslated.
- Thirty-nine focused presenter and Apple-native source contracts passed. The
  broader build and test result is recorded in the repository status chronicle.

## Output And Processing Titled-Card Unification

- Observed behavior: Output section titles remain outside their content cards.
  Processing uses a title inside Current Task but an external Recent Tasks
  heading with a decorative gear icon and a separately aligned More button.
  Existing-album refresh sits above the album Picker rather than in its control
  row.
- Intended outcome: Reuse one titled-card hierarchy matching Configuration
  Center: title and explanatory text share the card header, content lives in an
  inner group, and an optional trailing action occupies the same position as
  the Memory Source collapse control. Current Task places its status pill there;
  Recent Tasks places More there and removes the decorative leading icon.
- Existing Album keeps its label but places the album Picker and one compact,
  vertically centered native refresh control on the same row. Loading state,
  disabled state, VoiceOver wording, and reload behavior remain unchanged.
- Scope is SwiftUI composition only. Queue state, history limits, output target,
  album loading, persistence, Renderer, Export, and PhotoKit ownership remain
  unchanged.
- Verification: Add source contracts first, test empty/active/history variants,
  narrow widths and accessibility text, build the signed app with extensions,
  then install and visually accept on physical `iPhone7`.

### Titled-Card Typography And Accessory Alignment Follow-Up

- Observed behavior: Configuration Center card headings use a smaller type pair
  than Output and Processing. Long Output explanations make the left title feel
  top-heavy. Processing Recent Tasks More lacks the Configuration Center More
  control background, while album refresh lacks sufficient accent emphasis.
- Intended outcome: Keep Configuration Center typography as the shared
  card-heading standard and align Home, Output, and Processing to it;
  center titles against multi-line explanations while retaining the
  accessibility-size stack; match Recent Tasks More to the Configuration Center
  semantic color, circular background, and touch target; use accent blue for
  album refresh without changing loading behavior.
- Home removes decorative heading icons from Memory Subject and My
  Configuration, then adds one concise explanatory phrase to each card header.
- Functional navigation chevrons use the shared accent color across Home,
  Configuration Center, Memory Subject, Output-adjacent settings, Processing,
  and Settings. More controls remain secondary to preserve one-screen accent
  hierarchy.
- Home configuration rows group Rename, More, and Selection into one compact
  trailing cluster, reclaiming width for the complete last-saved timestamp.
- Memory Subject display and editing adopt the same titled outer-card and
  content inner-card hierarchy as Configuration Center. The former floating
  identity hero moves into Basic Information, while its Edit action becomes a
  blue text-and-chevron accessory in the outer card header.
- Settings keeps Application Interface Language collapsed by default, exposes
  the current language as its summary, and reveals the segmented picker and
  explanation only at the next disclosure level.
- Scope remains presentation-only: Configuration Center, Output, Processing,
  shared iOS view support, and source-contract tests.
- Verification: focused architecture contracts, signed iPhone7 build, install,
  launch, and manual visual acceptance.

## Share Nested-Card And Output Control Follow-Up

- Primary loop: Product Loop. Screenshot `IMG_1733.png` shows the Share
  confirmation surface still using single-layer cards after Configuration
  Center, Output, Processing, and Memory Subject adopted titled outer cards with
  responsibility-specific inner cards.
- Observed behavior: `本次分享` and the dynamic processing status sit directly
  inside their outer surfaces; the three summary rows use independent stacks
  whose dividers participate in row layout, weakening the shared leading edge.
  On Output, `添加自定义内容` uses the full regular information-row padding even
  though it is a compact secondary toggle, making that control visually heavy.
- Intended outcome: keep Share confirmation semantics unchanged while placing
  summary rows and processing status inside dedicated inner surfaces. Preserve
  one shared leading edge for `照片`, `配置`, and `相册`, and keep the dynamic
  processing title in the outer-card header. Tighten only the custom-content
  toggle row; retain its native switch, wording, and accessibility behavior.
- Ownership and risk: P2 presentation-only work in Share UIKit composition and
  Output SwiftUI spacing. Configuration snapshots, intake/handoff, background
  processing, album selection, memory-write resolution, Renderer, Export, and
  PhotoKit behavior remain unchanged. No Apple capability replaces the native
  UIKit/SwiftUI controls already in use.
- Verification: add source contracts for nested Share surfaces, aligned rows,
  and compact custom-content spacing; run focused Share and Apple-native UI
  tests, a no-sign build, then install a signed build on physical `iPhone7` for
  manual visual acceptance.

### Memory Subject Basic-Information Alignment

- Display and Edit keep the same field order: object identity first, followed
  by nickname, relationship, and dedicated address. The display summary uses
  the remaining width beside the avatar instead of hugging its leading edge.
- Display fact rows reduce excess vertical padding to the compact editor-row
  rhythm. This is presentation-only; subject data, expression-subject source,
  persistence, and anchor behavior remain unchanged.

### Share Primary-Action Symbol Selection

- The accepted Share primary-action symbol is the native `sparkles` SF Symbol.
  It uses the existing foreground color and an 8-point title gap without
  changing the shared 184-by-40 action size, 12-point corner radius, bottom
  placement, action semantics, or accessibility label.

### Output Write Hierarchy And Recent-Task Action Contrast

- Screenshot evidence `IMG_1734.jpeg` shows custom-content explanation, default
  write naming, resolved output, and generation guidance reading as one dense
  block. The accepted hierarchy adds a dedicated `默认写入内容` row whose value
  explains that current smart-module output is written into the generated
  photo's description for Apple Photos search, keeps custom text explicitly
  supplemental, and places the compact `写入预览` before the final custom-text
  switch. The final row states that user text is appended to the generated
  photo description without replacing smart-module output.
- Screenshot evidence `IMG_1735.jpeg` shows the Recent Tasks More symbol losing
  contrast inside its neutral circular surface. Keep the secondary surface and
  40-point target, but treat the functional ellipsis as accent blue, consistent
  with other navigation and refresh actions.
- Scope is P2 presentation and copy only. Memory-module resolution, custom-text
  concatenation, queue history, sheet presentation, and persistence remain
  unchanged. Verify presenter contracts, Apple-native surface contracts, iOS
  build, and physical-device installation.
