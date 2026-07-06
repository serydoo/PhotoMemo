# Expression Platform Main Merge

Date: 2026-07-06

Commit: `35baa64c`

## What

Expression Platform and the Location Module Feature were merged into `main`.

This makes the provider-based expression baseline, renderer text-lookup
integration, Location provider adoption, Object Inspector `位置显示` experience,
configuration persistence, and production render consumption part of the main
repository line.

## Why

The original product goal was:

```text
Insert Location display
-> choose display format
-> preview result
-> export the same result
```

The merged work completes that loop through existing platform capability rather
than by adding renderer-owned Location behavior.

## Scope

Included:

- Expression Platform contracts and ADR-007.
- Canonical provider pipeline for Location, Memory, Metadata, and model-like
  values.
- Renderer text resolution through `ExpressionLookup`.
- Location display configuration through Object Inspector product language.
- Preview, persistence, production render, export, and Share intake carrier
  integration for saved Location display configuration.
- Release and feature gates:
  - `Expression_Platform_RC_Merge_Readiness_Review.md`
  - `Location_Module_Feature_Completion_Gate.md`

Not included:

- New platform contracts.
- Renderer layout, typography, drawing, or color redesign.
- Photo Library save-back behavior changes.
- Layout Engine work.
- Manual device acceptance.

## Verification

Passed before merge to `main`:

- Focused Location display / preview tests.
- Focused save / production / boundary tests.
- Focused shared snapshot tests.
- `PhotoMemo` Debug build.
- `PhotoMemoiOSV1` generic iOS Simulator build.
- `PhotoMemoShareExtension` generic iOS Simulator build.

## Known Issues

- Manual device acceptance was not performed in this release event.
- Historical snapshot flakiness remains tracked separately and was not treated
  as caused by this merge.
