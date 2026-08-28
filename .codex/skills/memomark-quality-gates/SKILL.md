---
name: memomark-quality-gates
description: Run an evidence-backed MemoMark quality gate for substantial UI or release work, covering accessibility, localization, performance, and physical-device fit. Use explicitly or when a task clearly needs a cross-cutting quality audit; do not trigger for ordinary single-control edits.
---

# MemoMark Quality Gates

This is a bounded audit skill, not a UI redesign or a release mutation tool.
Use it after a substantial UI/media change or before a release recommendation
when the task needs cross-cutting evidence. Keep findings separate from fixes.

## Preconditions

Read `PROJECT_CONSTITUTION.md`, `Docs/CURRENT_BRIEF.md`, the applicable current
specification, and the exact build or source revision under review. Identify
the affected owner, risk level, and acceptance device before testing.

## Gate Areas

### Accessibility

- VoiceOver labels, values, actions, and traversal order are meaningful.
- Controls have native semantics and adequate hit targets.
- Dynamic Type does not clip or silently hide user content.
- Reduce Motion, contrast, light/dark appearance, and focus/sheet behavior are
  considered where applicable.

### Localization

- String keys and format resources remain in parity across supported languages.
- User-facing wording follows the MemoMark product-language guide.
- Interface language, output language, preset output language, and task
  snapshot language are not conflated.
- Expansion, plural, date, calendar, timezone, and fallback behavior are
  verified for the affected surface.

### Performance

- State invalidation and body recomputation are bounded to the affected data.
- Preview changes do not repeat unnecessary metadata, image decoding, layout,
  or rendering work.
- High-resolution media is not retained beyond the owner’s lifecycle.
- Any performance claim includes a measurement or is marked `NOT VERIFIED`.

### Physical Device

- UI and Photos/media lifecycle acceptance uses the paired physical iPhone 17
  Pro Max and names the exact installed build.
- Simulator results may support isolated automation only; they do not replace
  required device evidence.
- Manual acceptance, automated tests, and production certification are reported
  as separate evidence classes.

## Output

Return a compact table:

| Gate | Status | Evidence | Risk or gap | Next action |
|---|---|---|---|---|

Use only `PASS`, `FAIL`, `NOT VERIFIED`, `BLOCKED`, or `N/A`. A compile or unit
test does not prove accessibility, device behavior, PhotoKit lifecycle, or
performance. Do not modify source or perform external release operations from
this audit unless the user separately authorizes a bounded implementation.
