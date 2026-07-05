# Provider-Based Expression Architecture

## Status

Accepted

## Date

2026-07-06

## Context

PhotoMemo's legacy expression path mainly uses `MetadataContext` to carry
template variables. As Location, Memory, Weather, People, AI, and future
capabilities enter the system, continuing to expand `MetadataContext` would mix
semantic ownership, presentation policy, preview data, and renderer
responsibility into one legacy adapter.

Phase 0 through Phase 4-D on the Location Expression branch validated a new
path with code and tests: domain facts can be resolved inside a Canonical
Provider lifecycle, compiled into provider-neutral `ExpressionValue`, and then
stored in `ExpressionContext`.

## Decision

PhotoMemo adopts Provider-Based Expression Architecture.

Every Canonical Provider compiles domain facts into provider-neutral expression
values through this pipeline:

```text
Builder
-> Context
-> Resolver
-> Resolution
-> Formatter
-> ExpressionValue
-> ExpressionContext
-> Renderer
```

`ExpressionContext` is the stable input language for the expression system.
Renderer consumes resolved expression values only. Renderer must not own
Provider logic, Resolver logic, Formatter logic, fallback policy, presentation
selection, or domain semantics.

## Validation

This decision is accepted after engineering validation through the phased
Location Expression work:

- Phase 0: Expression and Location skeleton boundaries
- Phase 1: `LocationContextBuilder`
- Phase 2: `LocationFormatter`
- Phase 3: deterministic `LocationResolver`
- Phase 4-B: provider-neutral `ExpressionValue`
- Phase 4-C: token-addressable `ExpressionContext`
- Phase 4-D: `LocationExpressionProvider` compiles Location domain output into
  `ExpressionValue` and stores it in `ExpressionContext`

The validation proves the platform boundary:

```text
Domain facts
-> Canonical Provider lifecycle
-> Expression Language
```

## Alternatives Considered

### Continue expanding MetadataContext

Rejected.

That would turn a legacy adapter back into the central semantic model and make
new semantic fields bypass Canonical Provider ownership.

### Let Renderer resolve domain meaning

Rejected.

Renderer should draw resolved expression values. It should not read domain
context, run fallback, select presentation, reverse geocode, or understand
Location, Memory, Weather, People, or AI semantics.

### Build separate Preview and Production pipelines

Rejected.

Preview and production may use different `ExpressionContext` sources, but they
must not own separate expression models or rendering logic.

## Consequences

### Positive

- Semantic token ownership has a canonical Provider boundary.
- Resolver, Formatter, Provider, ExpressionContext, and Renderer boundaries are
  testable and reviewable.
- Preview and production can share one expression language.
- Future Memory, Weather, People, AI, and Metadata Providers can reuse the same
  lifecycle instead of inventing new token systems.

### Negative

- `ExpressionContext` and `MetadataContext` will coexist during migration.
- Legacy adapter work is required before the current renderer path can consume
  new expression values.
- Provider API evolution must stay incremental to avoid premature abstractions
  around multi-token output or renderer integration.

### Trade-offs

- PhotoMemo accepts an explicit expression language layer in exchange for
  stable provider ownership and renderer independence.
- Location is the first validation case, but future Location enhancements such
  as reverse geocoding, POI, landmark, and raw coordinate token output remain
  feature work outside the platform decision.

## Follow-up Work

- Continue platform integration from a platform-oriented branch instead of
  expanding the `codex/地址模块` branch indefinitely.
- Keep Location feature enhancements on dedicated Location branches after the
  platform baseline is accepted.
- Evaluate an `ExpressionLookup` protocol before renderer integration so
  renderer code can depend on lookup behavior rather than concrete
  `ExpressionContext` storage.
