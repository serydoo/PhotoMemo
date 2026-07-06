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

Post-merge simulator smoke:

- Installed `PhotoMemoiOSV1.app` on iPhone 17 Pro simulator
  `95A87461-1623-469A-8F06-3159CC12B1CC`.
- Launched bundle `com.serydoo.PhotoMemo.iOS` successfully.
- Launch logs show the app in `running-active-Visible` state.
- First-run flow reached the system Photos permission dialog.
- Local sample inspection found that `/Users/rui/Downloads/IMG_0537.jpeg`
  has no GPS latitude / longitude, so it cannot serve as the Location Module
  acceptance fixture.
- Follow-up local acceptance used the Photos render
  `0194231B-1F96-4A84-A5D7-B32200353811_1_201_a.jpeg`; the real PhotoMemo
  metadata, Location provider, configuration adapter, and `ExpressionContext`
  lookup sources resolved `33.930355, 116.444153`.

## Known Issues

- Manual device acceptance was not performed in this release event.
- Full simulator interaction acceptance was not completed because this
  environment exposes the simulator through `simctl` screenshots/logs but not a
  foreground `Simulator.app` window for tapping the system Photos permission
  dialog.
- Location Module Product Acceptance remains blocked only for full manual
  interaction and real export validation.
- Historical snapshot flakiness remains tracked separately and was not treated
  as caused by this merge.
