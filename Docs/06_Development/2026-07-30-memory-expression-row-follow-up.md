# Memory Expression Row Follow-up

Date: 2026-07-30

## Decision Gate

- Primary loop: Product Loop
- Risk: P2, because this is a bounded responsive-layout refinement with no
  change to selection semantics, persistence, or output behavior.
- Observed scenario: on the smaller iPhone screenshot, the `记忆表达` row
  reflows vertically while the wider iPhone keeps the title and selection
  capsule on one line. The extra height makes the small-screen configuration
  card feel uneven.
- Scope: the `记忆表达` row in `V1ConfigurationOptionList` and its focused
  source contract. The native `Menu`, selected-value binding, accessibility,
  Memory Engine, renderer, export, and other rows remain unchanged.
- Source of truth: the configuration view owns presentation-only width; the
  existing adaptive row still controls the accessibility-size fallback.
- Apple-native capability evaluated: keep `ViewThatFits` and the native
  `Menu`; only the horizontal trailing width budget is adjusted for this row.
- Verification: focused contract test, unsigned generic iOS Debug build, and
  `git diff --check`. Physical-device visual acceptance remains separate.

## Accepted Pass

- Normal text sizes keep `记忆表达` title and selector on one line on the
  smaller supported iPhone width when the row can fit.
- Accessibility text sizes and genuinely insufficient widths still use the
  existing vertical layout.
- Other configuration rows retain their current horizontal width budget.
