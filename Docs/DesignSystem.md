# MemoMark Design System V1

Status: Frozen

Last updated: 2026-07-25

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

One card owns one product object, decision, or status group.

Accepted examples:

- Home: Memory Subject and configuration remain separate;
- Configuration Center: expression, layout/content, and save remain separate;
- Memory Subject: basic information and time anchors remain separate.

Do not create a new card when content belongs to an accepted card. Do not merge
accepted cards when their responsibilities differ.

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
