# PI-16 Production Expression Value Carrier Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest production-owned carrier for provider-produced
`ExpressionValue` output after PI-15 blocked Memory provider adoption pending a
carrier/source decision.

## Non-Goal

PI-16 does not adopt Memory provider output into template lookup, change
renderer output, change export behavior, alter share extension behavior,
modify `CardVariableProvider`, expand provider token support, introduce new
platform protocols, or change platform contracts.

## Prerequisite

PI-14 proved Memory provider output parity.

PI-15 concluded that Memory provider adoption remains blocked because the
approved text lookup seam does not have a carrier for provider-produced values:

```text
Memory provider production adoption:
parity proven -> blocked pending production expression value carrier
```

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-16 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `ProductionMemoryResolver` | `SelectedPhoto + ConfigurationSnapshot -> ProductionMemoryPayload` | Build an inert `ExpressionContext[memory]` beside the existing Memory payload | Yes | Medium | Resolver has the canonical Memory input and can use `MemoryProvider` without changing renderer output. |
| `ProductionMemoryPayload` | `subject + snapshot + result + module` | Carry optional provider-neutral `ExpressionContext` | Yes | Low | Internal app-side payload; not a platform contract and not a renderer dependency. |
| `RecordCard` | Legacy card model plus optional Memory result/module | Carry optional production `ExpressionContext` without consuming it | Yes | Medium | This is the smallest boundary that lets future text lookup adoption access provider-neutral values without changing renderer APIs. |
| `RecordCardBuildService` | `ProductionMemoryPayload -> RecordCard` | Forward the inert production expression context onto `RecordCard` | Yes | Medium | Forwarding only; build service must not construct provider values itself. |
| `CardTextBlockEngine.build(from:)` | Legacy context plus approved model overlay | Consume `RecordCard` production expression values | No | High | That is Memory provider adoption and needs a later scan. |
| `ExpressionContextMetadataAdapter` | `ExpressionContext -> MetadataContext` | Add `memory -> memory_summary` projection | No | Medium | Projection is only useful after a later adoption seam is approved. |
| `CardVariableProvider` | `RecordCard -> MetadataContext` | Read or build production expression values | No | High | Would make legacy projection own provider policy. |
| Renderer / Export / Share Extension | Rendered `RecordCard` and output services | Consume production expression context | No | High | Would cross rendering/export/share boundaries. |

## Approved Seam

PI-16 approves carrier-only implementation:

```text
ProductionMemoryResolver
    -> MemoryProvider.expressionValue(.memory)
    -> ExpressionContext[memory]
    -> ProductionMemoryPayload.productionExpressionContext
    -> RecordCard.productionExpressionContext
```

The value must remain inert in PI-16:

```text
CardTextBlockEngine
    -> no memory provider lookup adoption
```

## Output Rule

Renderer output must remain unchanged.

PI-16 may create and carry provider-produced expression values, but it may not
use them as production lookup authority.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `MemoryProvider`, `MemoryExpressionEngine`,
  `MemoryResultPresentationAdapter`, or provider token support
- Changes to `ExpressionContextMetadataAdapter`
- Changes to `CardVariableProvider`
- Changes to `CardTextBlockEngine` Memory lookup behavior
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Tests Before Implementation Freeze

Implementation must add focused tests for:

1. Resolver carrier:

```text
ProductionMemoryResolver
    -> ProductionMemoryPayload.productionExpressionContext[memory]
```

2. Build-service forwarding:

```text
RecordCardBuildService
    -> RecordCard.productionExpressionContext[memory]
```

3. Boundary protection:

```text
No CardVariableProvider / Renderer / Export / Share adoption
No CardTextBlockEngine memory lookup adoption
```

## Selection Rule

Carry provider-neutral values at the production payload/card boundary before
using them at the text lookup seam.

For PI-16, this is smaller than adding a renderer input, teaching legacy
projection to call providers, or bypassing `MemoryProvider` with
`MemoryModule.renderedText`.

## Review Checklist

- Provider-produced Memory value is carried but not consumed.
- `RecordCardBuildService` forwards only; it does not own provider policy.
- `CardVariableProvider` remains legacy-only.
- Renderer/export/share output remains unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Production expression value carrier: absent -> inert ExpressionContext on production payload/card
```
