# Memory Engine Foundation

## Status

Accepted

## Date

2026-06-20

## Context

MemoMark has already stabilized its metadata pipeline, variable catalog, editor projection, and export reliability layers.

However, memory-oriented values are still spread across existing components:

- `AnchorEngine` computes anchor-relative results
- `CardVariableProvider` decides how some of those values become user-facing strings
- `memory_summary` currently depends on ad-hoc story and anchor-summary fallback logic

The product is no longer only a metadata overlay tool.

MemoMark now needs a dedicated domain boundary for memory semantics so future memory-facing variables can evolve without pushing business meaning into renderer, export, or UI layers.

The project also needs this boundary to remain:

- local-first
- offline
- deterministic
- fully testable

## Decision

MemoMark introduces a dedicated `MemoryEngine` domain layer.

Its initial boundary is intentionally narrow and foundation-only.

The Memory Engine is responsible for:

- consuming canonical metadata capture time
- consuming user-defined anchor context
- producing normalized memory variables
- formatting memory-oriented output strings for the variable pipeline

The initial foundation is built from:

- `MemoryContext`
- `MemoryCalculationResult`
- `MemoryVariableProvider`

The Memory Engine integrates into the existing variable pipeline without changing renderer, export, batch, or UI responsibilities.

The resulting architectural direction is:

`PhotoMetadata -> MemoryEngine -> CardVariableProvider / TemplateVariableEngine -> Renderer / Export`

Boundary rules:

- metadata remains the source of truth for photo time
- memory variables are derived, never stored as a second metadata source
- renderer consumes resolved strings only
- export consumes resolved strings only
- batch does not own memory semantics
- no AI, cloud, or timeline UI responsibilities enter this layer

## Alternatives Considered

### Keep memory logic inside `CardVariableProvider`

Rejected.

That keeps memory semantics mixed with variable wiring and makes future memory expansion harder to test and reason about.

### Expand `AnchorEngine` into the full memory domain

Rejected.

`AnchorEngine` should remain focused on anchor-relative calculations and existing smart-anchor behavior. The product needs a broader memory boundary than anchor formatting alone.

### Introduce a richer memory document or workflow subsystem now

Rejected.

That would exceed the scope of the current foundation and create unnecessary abstraction before real use cases demand it.

## Consequences

### Positive

- memory semantics gain a dedicated, testable domain boundary
- `memory_summary` and future memory variables can evolve without leaking logic into renderer or export
- MemoMark's product philosophy now has a concrete implementation boundary

### Negative

- the variable pipeline now depends on one additional domain component
- contributors must distinguish metadata variables from memory-derived variables

### Trade-offs

- MemoMark accepts one focused domain layer in exchange for cleaner long-term ownership of memory logic
- some short-term duplication with existing anchor terminology remains until future memory work decides what should stay anchor-specific

## Follow-up Work

- expand memory variables conservatively through the new Memory Engine boundary
- keep renderer, export, and batch free of memory business logic
- evaluate future memory-oriented release work such as richer anniversaries and timeline-style summaries without moving UI concerns into the domain layer
