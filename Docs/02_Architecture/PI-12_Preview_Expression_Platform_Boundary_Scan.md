# PI-12 Preview Expression Platform Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest preview seam for adopting Expression Platform in the
Configuration Center preview without changing UI controls, production,
renderer, export, share extension behavior, or platform contracts.

## Non-Goal

PI-12 does not add Inspector controls, change production snapshots, connect
production rendering, modify renderer/template lookup, expand provider tokens,
alter export, change share extension behavior, or change photo-library
behavior.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-12 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `ConfigurationCenterPreviewCompositionHelper.moduleDisplayText(.location)` | Hardcoded preview string | Build preview sample facts, run Location provider, and read `ExpressionContext[location]` | Yes | Low | This is the remaining preview-local Location string in the Configuration Center helper. |
| `ConfigurationCenterPreviewCompositionHelper.insertModule` | Optional expression configuration after PI-11 | Pass configuration into location preview source | Yes | Low | Uses existing carrier without adding UI controls. |
| `V1PreviewCompositionEngine` | Already sources location from `ExpressionContext` after PI-6 | Rework V1 preview source again | No | Medium | Already migrated; changing it would expand PI-12 scope. |
| `ConfigurationCenterRegionBindingAdapter` | Module insertion forwarding | Add preview-specific provider logic | No | Medium | Binding remains insertion plumbing only. |
| `LocationExpressionProvider` | Explicit typed input | Let provider read module configuration directly | No | Medium | Adapter remains outside provider. |
| `CardVariableProvider` / production path | Legacy metadata context | Adopt preview expression values in production | No | High | Production Lookup Integration is a later PI. |
| Renderer / template path | Resolved text lookup | Read module configuration during rendering | No | High | Renderer receives resolved text only. |

## Approved Seam

PI-12 may modify only the Configuration Center preview location source:

```text
ConfigurationCenterPreviewCompositionHelper.insertModule(...)
    -> moduleDisplayText(.location, expressionConfiguration)
    -> preview sample facts
    -> LocationConfigurationAdapter
    -> LocationExpressionProvider
    -> ExpressionContext[location]
```

Default preview output must remain:

```text
河南 · 商丘
```

Configured preview output may reflect the supplied provider-neutral module
configuration, but only through the Location adapter and provider pipeline.

## Out Of Scope

- New platform protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionLookup`, or `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider`, `LocationConfigurationAdapter`,
  `LocationResolver`, or `LocationFormatter`
- Changes to `ConfigurationSession`
- Changes to `ConfigurationSnapshot`
- Changes to `MemoryBlock`, `MemoryTokenBlock`, or `MemoryExpression`
- Changes to `MemoryBlockInspectorView` or Inspector controls
- Changes to `V1PreviewCompositionEngine`
- Changes to `CardVariableProvider`, `RecordCard`, or
  `RecordCardBuildService`
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production behavior

## Selection Rule

Adopt Expression Platform at the preview value source, not at rendering or
production boundaries.

For PI-12, migrating the Configuration Center helper's location preview value
is smaller than changing the V1 preview engine again, production lookup,
renderer lookup, snapshots, or UI controls.

## Review Checklist

- Only the approved Configuration Center preview location source is modified.
- Default location preview output remains unchanged.
- Configured location preview output is produced through
  `LocationConfigurationAdapter` and `LocationExpressionProvider`.
- No production, renderer, export, share, photo-library, or platform contract
  behavior changes are introduced.
- The architectural delta is:

```text
Configuration Center preview location source: hardcoded string -> ExpressionContext[location]
```
