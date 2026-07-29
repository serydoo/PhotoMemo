# Memory Expression Picker Polish

Date: 2026-07-30

## Decision Gate

- Primary loop: Product Loop
- Risk: P2, because this is a bounded visual refinement of the iOS
  Configuration Center and does not change selection semantics or persistence.
- Observed scenario: on the physical iPhone 15 Pro, the `记忆表达` row falls
  back to the vertical compact layout and its selection capsule expands across
  the entire inner panel, making it visually heavier than `时间锚点`.
- Scope: `V1ConfigurationOptionList` and its focused source contract test,
  plus this state record. Memory Engine, configuration persistence, renderer,
  export, Share Extension, and the native `Menu` presentation remain out of
  scope.
- Source of truth: the configuration view owns presentation-only geometry;
  `MemoryAnchorExpressionStyle` and the existing binding continue to own the
  selected value.
- Apple-native capability evaluated: keep SwiftUI `Menu` for selection. The
  change separates the visible capsule width from its system interaction and
  does not introduce a custom popover or picker.
- Verification: focused contract test, unsigned generic iOS Debug build,
  `git diff --check`, and manual visual acceptance on iPhone 15 Pro and iPhone
  17 Pro Max.

## Accepted Pass

- `记忆表达` keeps its native `Menu` and retains the existing control layout
  and accessibility behavior.
- The visible selection capsule uses its intrinsic content width after the
  row reflows vertically, while the trailing group remains aligned to the
  panel's trailing edge.
- Other selection capsules keep their existing width behavior.
