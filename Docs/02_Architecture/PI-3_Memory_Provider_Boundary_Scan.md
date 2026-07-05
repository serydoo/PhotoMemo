# PI-3 Memory Provider Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Integration

## Mission

Identify the smallest Memory provider compilation seam for validating a second
canonical provider without changing platform contracts or production renderer
behavior.

## Non-Goal

PI-3 does not redesign Memory Engine, add new platform protocols, modify
`ExpressionToken`, `ExpressionValue`, `ExpressionContext`, or
`ExpressionLookup`, connect production Renderer, migrate Export, change Share
Extension behavior, alter `RecordCard`, or replace legacy metadata projection.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-3 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| Memory expression compiler | `MemoryExpressionContext -> MemoryExpressionEngine -> MemoryResultPresentationAdapter -> MemoryModule.renderedText` | Provider compiles `MemoryModule.renderedText` into one `ExpressionValue` | Yes | Low | Validates a second canonical provider while consuming existing Memory domain and presentation pipeline. |
| `MemoryExpressionEngine` | `MemoryExpressionContext` | Engine emits `ExpressionValue` directly | No | High | Would make Decision/Memory Engine own Expression Language and violate existing `MemoryResult` contract. |
| `MemoryResult` | Structured semantic result | Add rendered text or token fields to `MemoryResult` | No | High | `MemoryResult` is frozen as semantic, not presentation or expression storage. |
| `MemoryResultPresentationAdapter` | `MemoryResult + MemoryExpressionContext` | Adapter emits `ExpressionValue` | No | Medium | Would couple Presentation adapter to platform Expression Language instead of keeping Provider as compiler. |
| `CardVariableProvider` | `RecordCard -> MetadataContext` | Replace memory variable projection | No | High | Legacy metadata projection remains production compatibility and is not the second-provider validation seam. |
| `RecordCardBuildService` | `SelectedPhoto + BatchConfigurationSnapshot` | Production provider integration | No | High | Crosses production, export, batch, and renderer behavior. Deferred. |
| Renderer text lookup | `ExpressionLookup` after PI-2 | Renderer consumes `.memory` directly | No | Medium | Renderer consumption is not PI-3; PI-3 validates provider compilation only. |

## Recommended Seam

PI-3 will validate Memory provider compilation at:

```text
MemoryExpressionContext
    -> MemoryExpressionEngine.generateResult(...)
    -> MemoryResultPresentationAdapter.makeModule(...)
    -> MemoryModule.renderedText
```

and compile the completed domain presentation into:

```text
ExpressionValue(
    token: .memory,
    resolvedText: MemoryModule.renderedText
)
```

This seam is the smallest architectural surface because Memory domain decision
and presentation behavior already exist and are already covered by Memory
tests. The Provider only compiles the completed Memory output into Expression
Language.

## Canonical Token

PI-3 approves one token only:

```text
memory
```

Subtokens such as `memory_age`, `memory_anchor`, `memory_subject`,
`days_since`, or `baby_age` remain future provider expansion work.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionLookup`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `MemoryResult` semantic contract
- Direct `ExpressionValue` output from `MemoryExpressionEngine`
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or preview behavior
- `RecordCard` or `RecordCardBuildService` migration
- `CardVariableProvider` removal or metadata projection cleanup

## Selection Rule

Choose the seam with the smallest architectural surface, not the smallest line
count.

For PI-3, provider compilation after `MemoryResultPresentationAdapter` is
smaller than changing Memory Engine or production build services because it
validates the second provider without altering frozen Memory semantics or
existing renderer/export behavior.

## Review Checklist

- Provider consumes existing Memory pipeline output.
- Provider does not implement Memory calculation rules.
- Provider does not format Memory text itself.
- Provider supports only the approved `memory` token.
- Provider returns `nil` for unapproved Memory subtokens.
- Platform contracts remain unchanged.
- Renderer and production output remain unchanged.
- The architectural delta remains exactly one line:

```text
Memory expression compilation: MemoryModule.renderedText -> ExpressionValue
```
