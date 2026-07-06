# PI-17 Memory Provider Production Adoption Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest production adoption seam for the parity-proven and
carried `MemoryProvider[memory]` value.

## Non-Goal

PI-17 does not change Memory provider behavior, expand provider tokens, modify
renderer layout/drawing, alter export metadata, change share extension
behavior, change photo-library behavior, introduce new platform protocols, or
change platform contracts.

## Prerequisite

PI-14 proved Memory provider text parity.

PI-16 added an inert production carrier:

```text
ProductionMemoryResolver
    -> ExpressionContext[memory]
    -> ProductionMemoryPayload.productionExpressionContext
    -> RecordCard.productionExpressionContext
```

PI-16 explicitly did not consume the carried value in text lookup.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-17 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `ExpressionContextMetadataAdapter` | `ExpressionContext[location, model] -> MetadataContext` | Add one approved projection: `ExpressionContext[memory] -> MetadataContext[memory_summary]` | Yes | Low | Reuses the existing legacy compatibility adapter. |
| `CardTextBlockEngine.build(from:)` | Legacy base context plus approved model overlay | Overlay `RecordCard.productionExpressionContext` through the adapter before building lookup | Yes | Medium | This is the same text-resolution surface approved in PI-2 and used by PI-13D. |
| `MemoryProvider` | `MemoryExpressionContext -> ExpressionValue(memory)` | Change provider behavior or token support | No | Medium | PI-17 consumes the already-carried value only. |
| `ProductionMemoryResolver` | Produces carried `ExpressionContext[memory]` after PI-16 | Change resolver carrier behavior | No | Medium | Carrier was completed in PI-16. |
| `RecordCardBuildService` | Forwards production expression context after PI-16 | Add provider logic or lookup adoption | No | High | Build service remains forwarding-only. |
| `CardVariableProvider` | `RecordCard -> MetadataContext` | Teach legacy projection to read production expression context | No | High | Would make legacy projection own provider adoption policy. |
| `RecordCard` | Carries optional production `ExpressionContext` | Store additional provider-specific fields | No | Medium | Carrier already exists; no model expansion is required. |
| Renderer / Export / Share Extension | Rendered `RecordCard` and output services | Consume Memory provider output directly | No | High | Adoption belongs at text lookup, not rendering/export/share boundaries. |

## Approved Seam

PI-17 approves a memory-only production adoption seam:

```text
CardTextBlockEngine.build(from:)
    -> CardVariableProvider.build(from:)              // legacy base context
    -> MetadataProvider.expressionValue(.model)       // existing PI-13D overlay
    -> RecordCard.productionExpressionContext[memory] // carried provider value
    -> ExpressionContextMetadataAdapter
    -> MetadataContext[memory_summary]
    -> MetadataContextExpressionLookup
```

The renderer-facing dependency remains:

```text
TemplateVariableEngine.render(..., lookup: ExpressionLookup)
```

## Output Rule

Renderer output must remain unchanged.

PI-17 may replace only the legacy `memory_summary` value with the
parity-proven carried provider value.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `MemoryProvider`, `MemoryExpressionEngine`,
  `MemoryResultPresentationAdapter`, or provider token support
- Changes to `ProductionMemoryResolver`
- Changes to `RecordCardBuildService`
- Changes to `CardVariableProvider`
- Location provider production adoption
- Metadata subtokens beyond the already adopted `model`
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Tests Before Implementation Freeze

Implementation must add focused tests for:

1. Adapter projection:

```text
ExpressionContext[memory] -> MetadataContext[memory_summary]
```

2. Production text regression:

```text
RecordCard with {{memory_summary}}
    -> CardTextBlockEngine
    -> same visible text
```

3. Boundary protection:

```text
No MemoryProvider in CardTextBlockEngine / CardVariableProvider / Renderer
No RecordCardBuildService provider adoption
```

## Selection Rule

Consume carried provider-neutral values at the text-resolution seam, not at
production construction or rendering/export boundaries.

For PI-17, this is smaller than making `CardVariableProvider` read expression
values or passing lookup into renderers.

## Review Checklist

- Only `memory` is approved.
- `location` remains blocked.
- Provider output is projected through the legacy adapter.
- Renderer still depends only on `ExpressionLookup`.
- Renderer/export/share output remains unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Production memory authority: legacy MetadataContext[memory_summary] -> parity-proven MemoryProvider[memory] projected into legacy lookup
```
