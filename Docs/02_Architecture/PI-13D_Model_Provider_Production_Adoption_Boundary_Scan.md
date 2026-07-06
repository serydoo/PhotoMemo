# PI-13D Model Provider Production Adoption Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest production adoption seam for `MetadataProvider[model]`
after PI-13C proved parity with the current legacy production lookup value.

## Non-Goal

PI-13D does not adopt Location or Memory provider output, change provider token
support, change platform contracts, change renderer layout/drawing, alter
export metadata, change share extension behavior, or change photo-library
behavior.

## Prerequisite

PI-13C proved the required parity gate for `model`:

```text
Given the same production input
legacy MetadataContext lookup[model] == MetadataProvider[model]
```

That proof allows a model-only production adoption seam to be considered. It
does not approve other metadata, location, or memory tokens.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-13D | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `ExpressionContextMetadataAdapter` | `ExpressionContext[location] -> MetadataContext[location_display]` | Add one approved projection: `ExpressionContext[model] -> MetadataContext[model]` | Yes | Low | Keeps provider output projection in the existing legacy compatibility adapter. |
| `CardTextBlockEngine.build(from:)` | `CardVariableProvider.build(from:) -> MetadataContextExpressionLookup` | Build the existing legacy base context, overlay approved provider projection, then use the same lookup | Yes | Medium | This is the text-resolution boundary already approved in PI-2; output must remain unchanged. |
| `MetadataProvider` | `PhotoMetadata -> ExpressionValue(model)` | Change provider behavior or token support | No | Medium | PI-13D consumes the existing provider only. |
| `CardVariableProvider` | `RecordCard -> MetadataContext` | Teach legacy variable projection to call `MetadataProvider` | No | High | Would make legacy projection own Expression adoption policy. |
| `RecordCard` | Legacy card model | Store `ExpressionContext` on the card | No | High | Requires a model carrier decision and may cross export/share boundaries. |
| `RecordCardBuildService` | `SelectedPhoto + BatchConfigurationSnapshot -> RecordCard` | Produce provider values during card construction | No | High | Crosses production construction and share/export paths before the minimal text seam is proven. |
| `TemplateVariableEngine` | `ExpressionLookup` | Change token resolution behavior | No | High | PI-2 already isolated lookup capability; token rules remain unchanged. |
| `RecordCardRenderer` / Export | `RecordCard` | Pass provider lookup into renderer/export | No | High | Would cross rendering/export boundaries instead of text resolution boundary. |

## Approved Seam

PI-13D approves a model-only production adoption seam:

```text
CardTextBlockEngine.build(from:)
    -> CardVariableProvider.build(from:)            // legacy base context
    -> MetadataProvider.expressionValue(.model)     // parity-proven provider value
    -> ExpressionContext[model]
    -> ExpressionContextMetadataAdapter
    -> MetadataContext[model]
    -> MetadataContextExpressionLookup
```

The renderer-facing dependency remains:

```text
TemplateVariableEngine.render(..., lookup: ExpressionLookup)
```

The provider value may replace only the legacy `model` value because PI-13C
proved output parity for that token.

## Output Rule

Renderer output must remain unchanged.

The implementation must include a regression proving that a template using
`{{model}}` resolves to the same text before and after the adoption seam.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `MetadataProvider` behavior or token support
- Location provider production adoption
- Memory provider production adoption
- Metadata subtokens such as `camera_summary`, `lens`, or
  `capture_date_display`
- Changes to `PhotoMetadata.locationDisplay`
- Changes to `CardVariableProvider`
- Changes to `RecordCard`
- Changes to `RecordCardBuildService`
- Changes to `TemplateVariableEngine`
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Tests Before Implementation Freeze

Implementation must add focused tests for:

1. Adapter projection:

```text
ExpressionContext[model] -> MetadataContext[model]
```

2. Production text regression:

```text
RecordCard with {{model}}
    -> CardTextBlockEngine
    -> same visible text
```

3. Boundary protection:

```text
No changes to RecordCardBuildService / CardVariableProvider / Renderer
```

## Selection Rule

Adopt the parity-proven provider value at the smallest text-resolution surface,
not at production construction or renderer/export boundaries.

For PI-13D, extending the existing legacy compatibility adapter by one
parity-proven token is smaller than introducing a production expression carrier,
teaching `CardVariableProvider` about providers, or changing `RecordCard`.

## Review Checklist

- Only `model` is approved.
- `location` and `memory` remain blocked.
- Provider output is projected through the legacy adapter.
- Renderer still depends only on `ExpressionLookup`.
- Renderer/export/share output remains unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Production model authority: legacy MetadataContext[model] -> parity-proven MetadataProvider[model] projected into legacy lookup
```
