# PI-15 Memory Provider Production Adoption Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Determine whether the parity-proven `MemoryProvider[memory]` value has a
small approved production adoption seam after PI-14 proved output parity.

## Non-Goal

PI-15 does not implement Memory provider adoption, introduce a production
Expression carrier, change `RecordCard`, change `RecordCardBuildService`,
change `CardVariableProvider`, change renderer output, alter export metadata,
change share extension behavior, or change platform contracts.

## Prerequisite

PI-14 proved the parity gate for Memory:

```text
Given the same frozen production Memory input
ProductionMemoryResolver.module.renderedText
    ==
MemoryProvider[memory].resolvedText
```

That proof shows text equivalence. It does not by itself approve a production
adoption path.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-15 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `CardTextBlockEngine.build(from:)` | `RecordCard -> CardVariableProvider.build(from:) -> MetadataContextExpressionLookup` | Overlay `MemoryProvider[memory]` the same way PI-13D overlays `MetadataProvider[model]` | No | High | `CardTextBlockEngine` has `RecordCard`, but not the `MemoryExpressionContext` required by `MemoryProvider`. |
| `RecordCard.memoryModule` | Production `MemoryModule.renderedText` | Convert existing module text into `ExpressionValue(memory)` at text lookup time | No | Medium | This would not be provider adoption; it would bypass `MemoryProvider` and create a second production expression source. |
| `ExpressionContextMetadataAdapter` | `ExpressionContext -> MetadataContext` | Add `memory -> memory_summary` projection | No | Medium | Projection is useful only after an approved production `ExpressionContext[memory]` source exists. |
| `RecordCardBuildService.baseCard` | `SelectedPhoto + BatchConfigurationSnapshot -> ProductionMemoryPayload -> RecordCard` | Run `MemoryProvider` during production construction and store the value in legacy context | No | High | Crosses production construction and makes the build service own provider adoption policy. |
| `RecordCard` | Legacy card model plus optional `memoryResult` / `memoryModule` | Store `ExpressionContext` or `MemoryExpressionContext` on the card | No | High | Requires a model carrier decision and may affect renderer/export/share boundaries. |
| `ProductionMemoryResolver` | `SelectedPhoto + ConfigurationSnapshot -> ProductionMemoryPayload` | Emit provider-produced `ExpressionValue(memory)` with the payload | No | High | Changes resolver output contract and requires a new production expression carrier decision. |
| `CardVariableProvider` | `RecordCard -> MetadataContext[memory_summary]` | Teach legacy projection to call `MemoryProvider` | No | High | Would make legacy projection own provider orchestration and require missing provider input. |
| Renderer / Export / Share Extension | Rendered `RecordCard` and output services | Consume provider output directly | No | High | Crosses renderer/export/share boundaries rather than the text lookup seam. |

## Scan Conclusion

PI-15 approves no implementation seam.

The Memory provider parity proof is real, but the approved PI-2 / PI-13D text
lookup seam does not currently have the canonical provider input required to
run `MemoryProvider`:

```text
MemoryProvider requires:
MemoryExpressionContext(subject, snapshot, captureDate)

CardTextBlockEngine currently has:
RecordCard(metadata, context, memoryResult?, memoryModule?)
```

Using `RecordCard.memoryModule.renderedText` at the text lookup seam would
preserve text, but it would not be Memory provider adoption. It would create a
parallel production expression source that bypasses the provider contract.

Running `MemoryProvider` earlier in `RecordCardBuildService` is possible in
principle, because production construction has access to
`ProductionMemoryPayload`. However, there is no approved carrier for storing
provider-produced expression values across the production card boundary, and
adding one would change production model ownership.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `MemoryProvider`, `MemoryExpressionEngine`,
  `MemoryResultPresentationAdapter`, or provider token support
- Changes to `ProductionMemoryResolver`
- Changes to `ExpressionContextMetadataAdapter`
- Changes to `CardVariableProvider`
- Changes to `RecordCard`
- Changes to `RecordCardBuildService`
- Location provider production adoption
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Follow-Up Before Implementation

Memory provider production adoption needs a separate carrier/source decision:

```text
Production Expression Value Carrier
```

That follow-up must answer one question:

```text
Where can production-owned ExpressionValue output live without making Renderer,
CardVariableProvider, or RecordCardBuildService own provider policy?
```

Until that question is answered, Memory provider production adoption remains
blocked despite PI-14 parity.

## Selection Rule

Do not adopt a provider at a seam that lacks the provider's canonical input.

For PI-15, the smallest safe architectural surface is to stop after the scan:
parity is proven, but no approved production carrier exists for the provider
value.

## Review Checklist

- No implementation seam is approved by PI-15.
- Memory provider parity remains recorded and reusable.
- Memory provider output does not become production authority.
- `location` remains blocked.
- `CardVariableProvider`, `RecordCard`, `RecordCardBuildService`, Renderer,
  Export, Share Extension, and Photo Library behavior remain unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Memory provider production adoption: parity proven -> blocked pending production expression value carrier
```
