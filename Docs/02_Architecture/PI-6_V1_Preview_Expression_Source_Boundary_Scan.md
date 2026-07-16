# PI-6 V1 Preview Expression Source Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest V1 preview seam for sourcing an approved preview value
from Expression Language instead of a preview-local rendered string, without
changing renderer, production, export, share, or configuration-center behavior.

## Non-Goal

PI-6 does not migrate production rendering, replace `RecordCard`, change
`CardVariableProvider`, modify `TemplateVariableEngine`, alter Export, change
Share Extension behavior, modify Photo Library behavior, change
Configuration Center module insertion, or add new platform contracts.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-6 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| V1 preview location module | `V1PreviewCompositionEngine.moduleDisplayText(.location)` returns preview-local rendered text | Build a preview `ExpressionContext` from sample facts and read `.location` | Yes | Low | Validates preview consumption of Expression Language while preserving output text and templates. |
| `V1PreviewCompositionContext` | Subject + capture-date facts | Store `ExpressionContext` on the context model | No | Medium | Expands preview context ownership and risks making expression storage part of UI state. |
| `ConfigurationCenterPreviewCompositionHelper` | Local module projection for inserted modules | Replace helper location projection too | No | Medium | Separate insertion/composition surface; should not be bundled with V1 preview engine migration. |
| `PhotoMemoiOSModuleCatalog` | Template tokens for module catalog | Migrate module catalog to expression tokens | No | Medium | Catalog already emits `{{location_display}}`; changing it would alter configuration semantics. |
| `CardVariableProvider` | `RecordCard -> MetadataContext` | Merge preview expression values during card variable projection | No | High | Crosses legacy production compatibility and renderer/export behavior. |
| `RecordCardBuildService` | Photo + snapshot -> `RecordCard` | Build preview/provider outputs during production card creation | No | High | Production convergence is outside PI-6. |
| Renderer text lookup | `ExpressionLookup` after PI-2 | Renderer consumes preview expression values directly | No | Medium | Renderer dependency is already isolated; PI-6 is preview value sourcing only. |

## Recommended Seam

PI-6 will validate V1 preview expression sourcing at:

```text
V1PreviewCompositionEngine.moduleDisplayText(.location)
    -> preview sample facts
    -> LocationExpressionProvider
    -> ExpressionContext[location]
```

The rendered preview output remains:

```text
示例省 · 示例市
```

The important change is source ownership:

```text
preview-local rendered string
    ↓
provider-produced ExpressionValue in ExpressionContext
```

This seam is the smallest architectural surface because it changes only the
location module's preview value source inside `V1PreviewCompositionEngine`.
It does not change template tokens, renderer text lookup, production card
construction, or Configuration Center inserted-module behavior.

## Canonical Token

PI-6 approves one preview token only:

```text
location
```

The legacy template token remains:

```text
location_display
```

The bridge between canonical Expression token and legacy template token remains
the PI-5 adapter responsibility. PI-6 does not change catalog tokens.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionLookup`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider` token support
- Changes to `ExpressionContextMetadataAdapter`
- Raw coordinate preview sourcing
- Memory or Metadata preview sourcing
- Changes to `V1PreviewCompositionContext` storage
- Changes to `ConfigurationCenterPreviewCompositionHelper`
- Changes to `PhotoMemoiOSModuleCatalog`
- Changes to `CardVariableProvider`, `RecordCard`, or
  `RecordCardBuildService`
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production preview behavior

## Selection Rule

Choose the seam with the smallest architectural surface, not the seam that
removes every preview sample value at once.

For PI-6, migrating only `V1PreviewCompositionEngine`'s location module source
is smaller than changing the Configuration Center helper, module catalog,
legacy production projection, or renderer call sites.

## Review Checklist

- V1 preview location display comes from `ExpressionContext[location]`.
- V1 preview output text remains unchanged.
- V1 preview template token remains `{{location_display}}`.
- No `PreviewExpressionContext` model is introduced.
- No production, renderer, export, share, photo-library, or configuration
  insertion behavior changes.
- Platform contracts remain unchanged.
- The architectural delta remains exactly one line:

```text
V1 preview location source: preview-local string -> ExpressionContext[location]
```
