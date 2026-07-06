# PI-11 Configuration Persistence Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest persistence seam that lets provider-neutral Expression
Module Configuration travel with an inserted module instance through the
Configuration Center draft store without changing UI, preview output,
production, snapshots, renderer, or platform contracts.

## Non-Goal

PI-11 does not add Inspector controls, persist configuration to disk, change
`ConfigurationSnapshot`, connect Location configuration to preview or
production provider calls, alter renderer/template lookup, modify export,
change share extension behavior, or change photo-library behavior.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-11 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `ConfigurationCenterPreviewCompositionHelper.insertModule` | `IOSInsertableModule` | Accept optional `ExpressionModuleConfiguration` and attach it to `IOSInsertedModule` | Yes | Low | Smallest insertion point that creates the inserted module instance. |
| `ConfigurationCenterRegionEditCoordinator.insertModule` | `IOSInsertableModule` | Forward optional configuration to preview helper | Yes | Low | Keeps coordinator as the same thin mutation path. |
| `ConfigurationCenterRegionBindingAdapter.insertModule` | `IOSInsertableModule` | Forward optional configuration to coordinator | Yes | Low | Enables future UI callers without changing current UI behavior. |
| `ConfigurationCenterRegionDraftStore` | `[IOSInsertedModule]` by active configuration ID | Add storage-specific configuration APIs | No | Medium | Store already preserves whole `IOSInsertedModule` values; no new store abstraction is needed. |
| `IOSInsertedModule` | Optional `ExpressionModuleConfiguration` after PI-9 | Make the configuration required | No | High | Would break legacy module insertion and preview defaults. |
| `ConfigurationSnapshot` | Frozen production memory snapshot | Persist expression module configuration in production snapshot | No | High | Snapshot adoption is a later boundary after draft insertion is stable. |
| `MemoryBlock` / `MemoryExpression` | Codable content model | Store expression configuration in content blocks | No | High | Would cross Memory Language ownership. |
| Renderer / template path | Resolved text lookup | Read configuration during rendering | No | High | Renderer receives resolved text only. |

## Approved Seam

PI-11 may modify only the module insertion chain:

```text
ConfigurationCenterRegionBindingAdapter.insertModule(...)
    -> ConfigurationCenterRegionEditCoordinator.insertModule(...)
    -> ConfigurationCenterPreviewCompositionHelper.insertModule(...)
    -> IOSInsertedModule.expressionConfiguration
    -> ConfigurationCenterRegionDraftStore.regionInsertedModules
```

The inserted module's preview value and composed preview text must remain
unchanged.

## Persistence Definition

For PI-11, persistence means:

```text
An ExpressionModuleConfiguration supplied during module insertion remains
attached to the resulting IOSInsertedModule stored under the active region
configuration ID.
```

PI-11 does not claim disk persistence, snapshot persistence, production
persistence, or renderer adoption.

## Out Of Scope

- New platform protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionLookup`, or `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider`, `LocationConfigurationAdapter`,
  `LocationResolver`, or `LocationFormatter`
- Changes to `ConfigurationSnapshot`
- Changes to `ConfigurationSession`
- Changes to `MemoryBlock`, `MemoryTokenBlock`, or `MemoryExpression`
- Changes to `MemoryBlockInspectorView` or Inspector controls
- Changes to `V1PreviewCompositionEngine`
- Changes to `CardVariableProvider`, `RecordCard`, or
  `RecordCardBuildService`
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production behavior

## Selection Rule

Persist configuration at the point where the inserted module instance is
created.

For PI-11, forwarding optional configuration through the existing insertion
chain is smaller than introducing store-specific APIs, snapshot fields,
Inspector controls, or preview/provider wiring.

## Review Checklist

- Only the approved insertion chain is modified.
- Existing module insertion works with no configuration.
- Configured insertion stores the configuration on `IOSInsertedModule`.
- Preview output remains unchanged.
- No snapshot, renderer, provider, UI control, export, share, or production
  behavior changes are introduced.
- The architectural delta is:

```text
Expression module configuration persistence: insertion input -> stored inserted module instance
```
