# PI-14 Memory Provider Production Parity Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest proof surface for determining whether
`MemoryProvider[memory]` is output-identical to the current frozen production
Memory value.

## Non-Goal

PI-14 does not adopt Memory provider output in production, change production
lookup source, modify `CardVariableProvider`, alter `RecordCardBuildService`,
change renderer output, modify export metadata, change share extension
behavior, expand provider token support, or change platform contracts.

## Prerequisite

PI-13B established the token-level parity gate:

```text
Provider-produced values may enter production authority only token by token.
```

PI-13D completed the first production adoption using a parity-proven metadata
token. That does not approve Memory or Location production adoption.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-14 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `MemoryProviderTests` | Existing provider contract tests | Add a focused parity proof comparing production Memory payload text with `MemoryProvider[memory]` for the same production input | Yes | Low | Test-only proof; does not change production source authority. |
| `ProductionMemoryResolver` | `SelectedPhoto + ConfigurationSnapshot -> ProductionMemoryPayload` | Use as the current frozen production Memory authority in the parity proof | Yes | Low | Read-only test consumer; no production code change. |
| `MemoryProvider` | `MemoryExpressionContext -> ExpressionValue(memory)` | Change provider behavior or token support | No | Medium | PI-14 must prove current provider parity, not alter it. |
| `CardVariableProvider` | `RecordCard -> MetadataContext[memory_summary]` | Teach legacy projection to call `MemoryProvider` | No | High | Would make legacy projection own provider adoption policy. |
| `RecordCardBuildService` | Production card construction | Produce or store provider values during production build | No | High | Crosses production construction before parity proof and adoption seam approval. |
| `ExpressionContextMetadataAdapter` | `ExpressionContext -> MetadataContext` | Add `memory -> memory_summary` projection | No | Medium | A projection may be considered only after parity is proven and a separate adoption scan approves it. |
| `CardTextBlockEngine.build(from:)` | Legacy base context plus approved model overlay | Overlay Memory provider output | No | High | This would be production adoption, not parity proof. |
| Renderer / Export / Share Extension | Rendered `RecordCard` and output services | Consume Memory provider output | No | High | Would cross rendering/export/share boundaries. |

## Approved Seam

PI-14 approves a test-only parity proof:

```text
SelectedPhoto + frozen ConfigurationSnapshot
    -> ProductionMemoryResolver
    -> ProductionMemoryPayload.module.renderedText

same production input
    -> MemoryExpressionContext
    -> MemoryProvider.expressionValue(.memory)
```

The proof may compare only resolved text:

```text
ProductionMemoryPayload.module.renderedText
    ==
MemoryProvider[memory].resolvedText
```

## Output Rule

Production renderer output must remain unchanged.

PI-14 may not change production source authority. A passing parity proof only
allows a later Boundary Scan to decide whether Memory provider production
adoption has an approved implementation seam.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `MemoryProvider`, `MemoryExpressionEngine`,
  `MemoryResultPresentationAdapter`, or provider token support
- Changes to `ProductionMemoryResolver`
- Changes to `CardVariableProvider`
- Changes to `RecordCard`
- Changes to `RecordCardBuildService`
- Changes to `ExpressionContextMetadataAdapter`
- Location provider production adoption
- Memory provider production adoption
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Tests Before PI-14 Freeze

PI-14 must add one focused parity proof:

```text
Given the same frozen production Memory input
When production Memory resolver and Memory provider both resolve memory text
Then the resolved text is identical
```

It must also preserve the existing provider boundary tests proving that
`MemoryProvider` does not cross production or renderer seams.

## Selection Rule

Prove Memory provider parity before approving Memory provider adoption.

For PI-14, the smallest safe surface is a test-only proof because
`ProductionMemoryResolver` and `MemoryProvider` already share the same
engine-and-presentation lifecycle, but production authority has not yet been
approved to move.

## Review Checklist

- Only a parity proof is approved.
- Memory provider output does not become production authority in PI-14.
- `location` remains blocked.
- `CardVariableProvider`, `RecordCardBuildService`, Renderer, Export, Share
  Extension, and Photo Library behavior remain unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Memory provider production adoption: blocked -> parity proof approved
```
