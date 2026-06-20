# PhotoMemo Design System

Last updated: 2026-06-20

## Purpose

This document defines the baseline UI system for PhotoMemo.

The goal is consistency, not decoration.

PhotoMemo should feel:

- Apple-native
- calm
- light
- trustworthy
- photo-first

All future UI work should align with this document unless a deliberate visual decision replaces it.

## Design Principles

1. Photo first.

UI should support the photo, not compete with it.

2. One screen, one job.

Each screen should answer a clear user question.

3. Preview is the truth.

If preview and final result disagree, preview is wrong.

4. Prefer fewer surfaces.

If two cards can become one, merge them.

5. Reduce reading.

Short labels beat explanatory paragraphs.

6. Use hierarchy, not visual noise.

Clarity should come from spacing, size, and contrast before using more color.

## Layout Grid

Use a simple 8-point spacing system.

### Spacing Scale

- `4` for micro spacing inside compact text groups
- `8` for chip-level spacing and tight control grouping
- `12` for compact cards and small clusters
- `16` for default section interior spacing
- `24` for major card padding and section separation
- `32` only for page-level breathing room when needed

Preferred rhythm:

- inside cards: `8` or `12`
- between controls: `8` or `10`
- between sections: `16` or `24`

Avoid introducing one-off values unless there is a strong reason.

## Corner Radius

Current UI already clusters around these values.

These should become the standard:

- `16` for compact previews and small icon containers
- `18` for inset cards, pills, configuration rows, and secondary panels
- `24` for primary section cards and major group containers

Avoid mixing too many corner sizes on one screen.

Default rule:

- small component: `16`
- standard component: `18`
- large container: `24`

## Typography

PhotoMemo should use Apple system typography and clear hierarchy.

### Recommended Type Scale

- Page title: `.system(size: 28...32, weight: .semibold)`
- Section title: `.headline` or `.title3.weight(.semibold)`
- Primary value: `.subheadline.weight(.medium)` or `.headline`
- Secondary body: `.subheadline`
- Support text: `.caption`
- Dense support text: `.caption2`

### Typography Rules

- never use oversized decorative headings
- keep support text muted and short
- avoid multiple emphasis styles in the same sentence
- use font weight for importance before adding color

## Color System

Current baseline:

- background: very light neutral gray-blue
- surface: white
- border: subtle black with low opacity
- accent: desaturated blue-gray

### Current Baseline Tokens

- Background: `246 / 247 / 249`
- Surface: `255 / 255 / 255`
- Border: `black.opacity(0.05)`
- Accent: `111 / 125 / 166`

### Color Rules

- color should guide, not decorate
- use accent mainly for active state, success emphasis, and selection
- avoid large flat accent blocks
- keep contrast strong enough for trust and readability

## Iconography

Use SF Symbols as the default icon system.

### Icon Sizes

- `14-16` for inline helper icons
- `18-20` for standard action icons
- `24-28` for key status or hero context icons

### Icon Rules

- do not mix many icon weights in one row
- avoid using icons without labels for important decisions
- use icons to reinforce meaning, not replace wording

## Cards and Containers

PhotoMemo currently relies heavily on cards.

That is acceptable, but cards must be disciplined.

### Primary Card

Use for:

- section groups
- major configuration surfaces
- preview framing

Visual traits:

- white surface
- subtle border
- soft shadow
- `24` radius

### Inset Card

Use for:

- summaries
- supporting content
- grouped controls inside larger sections

Visual traits:

- low-contrast fill
- no heavy shadow
- `18` radius

### Pill / Chip

Use for:

- active state
- quick facts
- compact status

Visual traits:

- capsule or soft rounded shape
- concise text only

## Buttons

PhotoMemo should use only a small button vocabulary.

### Primary Button

Use for:

- generate
- save
- main forward action

Style:

- bordered prominent
- one per decision zone when possible

### Secondary Button

Use for:

- edit
- manage
- rename
- switch supporting action

Style:

- bordered

### Plain Button

Use for:

- row selection
- low-friction state change

Rule:

- never rely on plain buttons alone for destructive or high-stakes actions

## Motion and Feedback

PhotoMemo should feel responsive, not animated for its own sake.

Use motion for:

- save success
- configuration switching
- progress updates
- sheet presentation

Avoid:

- decorative motion
- repeated bouncing or playful transitions
- animations that obscure whether processing is actually happening

## Content Rules

### Labels

- use user language
- keep labels concrete
- avoid system-internal nouns

### Help Text

- if help text becomes necessary, keep it short
- if a section needs multiple paragraphs, the UI probably needs simplification

### Duplication

- do not repeat configuration names in multiple cards
- do not restate information that is already obvious from context
- do not show both a summary card and a source card when one is enough

## Screen-Level Guidelines

### Main App

- should feel like a configuration center
- photo import remains available but secondary
- avoid making it feel like the daily working surface

### Share Extension

- should feel like a natural continuation of Apple Photos
- should minimize decisions
- should center preview, configuration, save

### Background Status

- should stay secondary
- should never dominate the main product surface

## Implementation Notes

Current code already reflects part of this system through:

- `MinimalPalette`
- `MinimalCardGroupBoxStyle`
- `MinimalInsetCard`

Next UI work should consolidate around these documented rules instead of adding new ad-hoc values.

## Review Checklist

Before shipping any UI change, ask:

- Does this reduce or increase reading?
- Does this reduce or increase scrolling?
- Is the main action obvious?
- Is preview still the clearest element?
- Is any card duplicated?
- Is any label written for developers instead of users?
