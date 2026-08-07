# MemoMark Design System V1

Status: Frozen, refined by UI-17PM-018

Last updated: 2026-08-08

## Purpose

This document is the canonical product-interface design system for MemoMark.
It governs future UI evolution across the main app and Share Extension. It
does not authorize immediate visual rewrites of accepted surfaces.

The objective is consistency, not decoration. Every new surface should feel
like MemoMark because it follows the same hierarchy, restraint, ownership,
and action rules—not because it repeats a logo, icon, or custom color.

## Product Principle

MemoMark is Memory First, not Photo First.

```text
Memory Subject
-> Time Anchor
-> Configuration
-> Presentation And Layout Resolution
-> Renderer
-> Processing
-> Apple Photos
```

The Configuration Center edits Memory Engine Configuration Objects. It does
not directly edit Renderer internals. Renderer remains stateless and consumes
resolved presentation and layout input from accepted upstream owners.

The daily workflow remains:

```text
Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos
```

## Experience Principles

1. **One screen, one responsibility.** Each page answers one primary user
   question and exposes one primary action.
2. **Memory truth before decoration.** Identity, time, configuration, and
   processing state remain clearer than visual ornament.
3. **Typography before iconography.** Use title, subtitle, value, caption,
   spacing, and contrast to express hierarchy before adding symbols.
4. **One screen, one accent.** A page has one dominant blue action or state.
   Additional blue must earn a distinct interactive meaning.
5. **One card, one responsibility.** Keep accepted cards separate when they
   represent different objects or decisions. Do not merge cards merely to
   reduce their count.
6. **Remove before adding.** Prefer deleting redundant copy, icons, badges,
   cards, and actions before introducing another visual element.
7. **Apple-native by behavior.** Use semantic colors, system typography,
   native controls, Dynamic Type, VoiceOver, Reduce Motion, and platform
   lifecycle conventions.

## Screen Responsibilities

### Home

Home answers:

- Which Memory Subject is active?
- Which configuration is active?
- Do I want to choose photos and begin?

The sole primary action is `选择照片`. Do not add banners, statistics, recent
photos, recommendations, activities, dashboards, or new feature launchers.

### Configuration Center

The Configuration Center edits the active configuration aggregate and shows
the real Renderer Result produced from accepted configuration, presentation,
layout, and renderer boundaries.

It is not a photo preview, subject introduction, Workspace, Dashboard, or
direct Renderer editor. Preserve the accepted object hierarchy and these
responsibilities:

- memory expression;
- card layout and content;
- configuration persistence.

The sole primary action is `保存当前配置` or its current state-equivalent.

### Memory Subject

Memory Subject owns user-authored subject identity, relationship, and time
anchors. It is product data and memory truth—not a settings page and not a
Renderer configuration surface.

Preserve the accepted separation:

- basic information;
- time anchors.

Memory Subject detail is the current visual reference for quiet hierarchy,
text-first fields, balanced separators, and restrained actions.

### Share Extension

Share confirms what will be processed, how the accepted configuration applies,
and where the result returns. It is not a feature page or explanatory guide.

Preserve the frozen structure in
`Docs/04_DesignSystem/MemoMarkShareDesignV1.md`. The sole primary action is
`生成时光记录`.

### Processing

Processing reports execution state and history. It is not a Dashboard and does
not add statistics or decorative animation.

Keep the hierarchy:

```text
Current Task
-> History
```

Actions such as viewing Apple Photos remain secondary and must not compete
with the current task state.

## Information Hierarchy

### Level 1: Section

A major section may use one SF Symbol when it improves scanning. The icon is
supporting context, not the section identity.

Examples:

- Memory Subject;
- configuration;
- card layout.

### Level 2: Cell

Cells default to text-first presentation. Do not add an icon by default.

Examples:

- Logo 标识;
- position display;
- border style;
- card content.

Existing accepted icons are not removed in bulk. Reduce them only through a
scoped visual pass with before-and-after evidence.

### Level 3: Field

Fields use labels and values without decorative icons.

Examples:

- nickname;
- relationship;
- birthday;
- dedicated form of address.

### System Status Symbols

Retain SF Symbols that carry standard system meaning:

- checkmark;
- plus;
- minus;
- ellipsis;
- chevron;
- destructive or warning symbols when required by context.

## Button System

Only interactive controls belong to the Button System. Informational phrases
such as `Apple Photos` or `本地优先` are labels, badges, or status content—not
Secondary Buttons unless they perform an action.

### Primary

- one per page or decision surface;
- solid system accent fill;
- white foreground;
- approximately 56 points high when used as the page-level action;
- visually dominant without a competing blue action.

Examples: `选择照片`, `生成时光记录`, `保存当前配置`.

### Secondary

- performs a real supporting action;
- low-emphasis system fill or border;
- accent-colored label;
- never competes with Primary.

### Text

- blue text without a decorative background;
- used for lightweight actions such as edit, rename, or view all.

### Destructive

- red text or a native destructive role;
- no decorative filled background by default;
- requires native confirmation when the consequence is irreversible.

## Color System

Use semantic system colors. Do not introduce raw colors when a semantic token
expresses the same role.

### One Screen One Accent

Before adding blue, identify the screen's primary accent owner. Any additional
blue must be interactive, selected, or semantically necessary and must remain
visually subordinate.

- Home: photo selection owns primary emphasis.
- Configuration Center: configuration save owns primary emphasis.
- Share: record generation owns primary emphasis.
- Processing: current task state owns hierarchy; Apple Photos navigation is
  secondary.

Color never acts as the only carrier of state. Pair it with text, shape, or a
system symbol.

## Typography

Use Apple system typography and Dynamic Type. Prefer semantic text styles over
fixed point sizes in runtime surfaces.

Hierarchy:

- page title;
- section title;
- primary value;
- body or subtitle;
- caption and support text.

Rules:

- use weight before color to increase importance;
- keep support copy short and secondary;
- do not use oversized decorative headings;
- allow localization and accessibility text to expand vertically;
- do not truncate memory truth merely to preserve a fixed row height.

Share-specific typography tokens remain defined in
`Docs/04_DesignSystem/MemoMarkTypographyTokens.md` and runtime
`MemoMarkDesignTokens.Typography`.

## Cards And Separators

### Surface Hierarchy

MemoMark uses four visual levels. A lower level must not be wrapped in an
additional card merely to make a section look complete.

1. **Page:** semantic system background, page title, introduction, and section
   spacing. The page provides the broadest grouping.
2. **Section:** title, optional subtitle, and optional trailing action placed
   directly on the page background. A section is navigation and information
   hierarchy, not automatically a card.
3. **Content surface:** a grouped set of related rows or controls. It may use a
   quiet inset background, hairline, or rounded group when this improves
   scanning and touch comprehension.
4. **Semantic card:** a distinct product object, rendered result, durable
   status, entitlement, task, or bounded decision that must read as one unit.

The default composition is therefore:

```text
Page
-> Section title and optional action
-> Content surface or semantic cards
```

Avoid this composition unless the outer card itself represents a real object:

```text
Page
-> Section card
-> Inner card
-> Row or control
```

### Card Admission Rule

One card owns one product object, decision, result, entitlement, or status
group. A section heading alone is never sufficient reason to create a card.

Before adding a card, identify its semantic owner. If the answer is only “this
is a section” or “this needs visual separation,” use spacing, typography, a
grouped content surface, or a separator first.

Accepted examples:

- Home: the active Memory Subject object, each saved Preset, and a current task
  remain semantic cards; `记忆对象` and `我的预设` remain page-level section
  headings rather than additional outer cards.
- Configuration Center: the real Renderer preview remains the primary semantic
  card; `记忆来源` and `卡片布局与内容` use section headings with grouped inner
  content surfaces.
- Settings: MemoMark+ entitlement remains a semantic card; disclosure groups
  use page-level headings and reveal grouped inner content without another
  outer card.
- Memory Subject: `基础资料` and `时间锚点` are page-level section headings in
  both reading and editing flows. The identity summary, editable field group,
  and each time-anchor row retain their own content or object surfaces because
  they represent durable memory truth; the section wrapper does not add a
  second card around them.
- Processing and Share: real task, result, destination, and execution-state
  groups remain cards when the boundary helps the user understand consequence
  or lifecycle state.

Do not create a new card when content belongs to an accepted card. Do not merge
accepted cards when their responsibilities differ. Do not remove a card from
Renderer output, the Memory Subject identity summary or anchor rows, Preset,
entitlement, task, result, or status surfaces merely to reduce card count.

Horizontal row separators use:

- a semantic low-contrast separator color;
- a physical-pixel or approved `0.5` point hairline;
- symmetric leading and trailing content insets;
- accessibility-hidden decoration.

System `List` separators and vertical structural dividers retain native or
surface-specific behavior.

## Spacing And Shape

Use the existing token owners before introducing new values:

- `ConfigurationUI` for main-app configuration surfaces;
- `MemoMarkDesignTokens` for Share Extension surfaces.

Prefer the existing 4/8/12/16/24 spacing rhythm. Corner radius follows
component hierarchy and existing tokens; do not invent a new radius for a
single use.

Section titles align with the content column they govern. Removing an outer
card must not also remove the section title, trailing action, minimum touch
target, Dynamic Type reflow, or the inner content boundary users rely on.

## Elevation And Shadow

Elevation is functional, not decorative. Most page sections and grouped
content surfaces use no shadow. Semantic cards may use the existing restrained
card chrome when separation from the system background is necessary.

Primary bottom actions use the shared `MemoMarkDesignTokens.Layout` shadow
tokens. The accepted compact treatment is:

- accent shadow opacity: `0.04`;
- blur radius: `6` points;
- vertical offset: `2` points.

Do not define a stronger local primary-action shadow in a page-specific button
style. Pressed, disabled, and restrained states may reduce or remove elevation;
they must not increase it. Sheets and system menus should rely on native
presentation depth rather than adding custom page shadows.

## Card Content Editor

The Card Content editor is a fixed four-region editing surface, not a set of
expandable cards or a second preview page:

- `左上`, `左下`, `右上`, and `右下` remain visible in a stable order;
- each region has one continuous combination input for literal text and
  insertable content;
- the top `＋模块` action opens candidates inside the current editor context;
  it does not present a competing half-height module sheet;
- Renderer remains the only complete visual preview while editing;
- edits update the preview immediately, while `完成` commits all four regions
  together through the existing configuration save path;
- the keyboard toolbar and keyboard-edge button only dismiss the keyboard;
  they never dismiss the editor, clear the draft, or change the active region;
- the bottom explanation is the behavioral source of truth: `四个卡片区域都可以
  自由组合文字和内容，修改会实时同步到上方预览；卡片右下会写入照片说明。
  点“完成”后统一保存，收起键盘不会离开编辑页。`
- region labels use `卡片左上 / 卡片左下 / 卡片右上 / 卡片右下`; only
  `卡片右下` carries `输出到照片说明，便于检索` because it is the photo-
  description source.

Do not add a second region summary, a duplicate composed-result preview, or a
per-region save action. Keep the editor's title compact because its vertical
space is reserved for the four inputs, candidate context, and keyboard-safe
scroll viewport.

## Settings Composition

Settings follows the same surface hierarchy as the main app:

- entitlement and purchase state may remain a distinct semantic card;
- disclosure titles sit directly on the page background;
- expanded rows form one quiet grouped content surface;
- collapsed disclosure headings keep a minimum 44-point target;
- chevrons, summaries, Dynamic Type reflow, VoiceOver expanded/collapsed state,
  and Reduce Motion behavior remain intact;
- disclosure groups must not become card-inside-card stacks.

## Motion And Feedback

Use motion only to explain state changes such as save completion, selection,
progress, and system presentation.

Respect Reduce Motion. Avoid decorative bouncing, looping animation, or motion
that obscures whether processing actually succeeded.

## Accessibility

Every UI change must preserve:

- Dynamic Type and content-driven height;
- VoiceOver labels, values, hints, and logical traversal;
- sufficient contrast in light and dark appearances;
- Reduce Motion behavior;
- localization expansion;
- compact-width and iPad adaptation where applicable;
- native control roles and minimum practical hit targets.

Automated contracts and builds do not replace simulator or signed-device visual
and accessibility verification.

## Change Discipline

This freeze does not authorize a repository-wide icon deletion, color rewrite,
or card consolidation. Existing accepted surfaces evolve through bounded UI
passes with recorded observations, intended outcomes, affected files, and
verification evidence.

Before approving a UI PR, ask:

1. Did it add another blue element? Can hierarchy work without it?
2. Did it add another icon? Can text express the meaning?
3. Did it add another card? Does an accepted card already own the content?
4. Did it add another Primary Button? A page may have only one.
5. Does it preserve one screen, one responsibility?
6. Does it preserve configuration, presentation, layout, Renderer, and export
   ownership boundaries?
7. Was the relevant compact, Dynamic Type, VoiceOver, and appearance behavior
   verified or explicitly left unverified?

## Exceptions

An exception requires a scoped product reason, an identified owner, and visual
verification. It must not be justified only by preference, another app's
screenshot, or the availability of an SF Symbol.
