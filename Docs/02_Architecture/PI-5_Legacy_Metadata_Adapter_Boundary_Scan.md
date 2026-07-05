# PI-5 Legacy Metadata Adapter Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Integration

## Mission

Identify the smallest legacy adapter seam for projecting approved Expression
Language output into the existing V1 `MetadataContext` template path without
changing renderer, export, share, preview, or provider behavior.

## Non-Goal

PI-5 does not migrate production rendering, replace `CardVariableProvider`,
remove `MetadataContext`, add new platform contracts, expand provider tokens,
change `TemplateVariableEngine`, modify Export, change Share Extension
behavior, or alter Photo Library behavior.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-5 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| Legacy metadata adapter | `ExpressionContext -> MetadataContext` | Standalone adapter projects one approved semantic token into one legacy key | Yes | Low | Validates a compatibility bridge without wiring production or changing legacy storage. |
| `MetadataContext` model | Dictionary-backed legacy values | Add `ExpressionContext` initializer or mutation API | No | Medium | Would make the legacy container aware of platform storage and blur ownership. |
| `MetadataContextExpressionLookup` | `MetadataContext` | Teach lookup to alias Expression tokens to metadata keys | No | Medium | Would mix lookup capability with legacy projection policy. |
| `CardVariableProvider` | `RecordCard -> MetadataContext` | Merge `ExpressionContext` during production context build | No | High | Crosses production card construction and legacy compatibility behavior. |
| `RecordCard` | Card model + legacy context | Store `ExpressionContext` on the production card | No | High | Expands model ownership and production renderer input. |
| `RecordCardBuildService` | Photo + snapshot -> `RecordCard` | Build provider outputs during production card creation | No | High | Crosses production, batch, export, and provider orchestration. |
| `TemplateVariableEngine` | `MetadataContext` / `ExpressionLookup` | Rewrite templates or token resolution rules | No | High | Changes platform-wide template behavior instead of adding a compatibility adapter. |
| Renderer text lookup | `ExpressionLookup` after PI-2 | Renderer consumes provider tokens directly | No | Medium | Renderer dependency is already isolated; PI-5 is legacy projection only. |

## Recommended Seam

PI-5 will validate legacy compatibility projection at:

```text
ExpressionContext
    -> ExpressionContextMetadataAdapter
    -> MetadataContext[location_display]
```

with one approved projection:

```text
ExpressionValue(
    token: .location,
    resolvedText: "河南 · 商丘"
)

↓

MetadataContext[location_display] == "河南 · 商丘"
```

This seam is the smallest architectural surface because the adapter consumes
the already-completed Expression Language output and produces a legacy
`MetadataContext` copy for existing template consumers. It does not make
`MetadataContext` the source of truth and does not connect production rendering.

## Canonical Projection

PI-5 approves one projection only:

```text
ExpressionToken("location") -> MetadataContext.Key.locationDisplay
```

Raw coordinate projections such as `latitude`, `longitude`, and `altitude`
remain future work because the current Location Provider compiler only freezes
the canonical `location` token.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionLookup`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider` token support
- Raw coordinate projection
- Memory or Metadata provider projection
- Changes to `MetadataContext` storage semantics
- Changes to `MetadataContext.build(from:)`
- `CardVariableProvider` migration or cleanup
- `TemplateVariableLibrary` migration
- `TemplateVariableEngine` behavior changes
- `RecordCard` or `RecordCardBuildService` migration
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or preview behavior

## Selection Rule

Choose the seam with the smallest architectural surface, not the seam that
connects the most production behavior.

For PI-5, a standalone adapter is smaller than changing `CardVariableProvider`,
`RecordCard`, `TemplateVariableEngine`, or production build services because it
proves the compatibility bridge while keeping legacy and Expression ownership
separate.

## Review Checklist

- Adapter consumes `ExpressionContext`.
- Adapter produces a `MetadataContext` projection or copy.
- Adapter projects only `location -> location_display`.
- Adapter does not mutate `ExpressionContext`.
- Adapter does not make `MetadataContext` own Expression semantics.
- Adapter does not read `PhotoMetadata`, `PhotoMetadataReader`, Provider
  internals, Renderer, Export, Share Extension, or Photo Library behavior.
- Platform contracts remain unchanged.
- Renderer and production output remain unchanged.
- The architectural delta remains exactly one line:

```text
Legacy metadata compatibility projection: ExpressionContext[location] -> MetadataContext[location_display]
```
