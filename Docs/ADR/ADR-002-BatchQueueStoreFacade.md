# BatchQueueStore as a Stable Public Facade

## Status

Superseded by ADR-011

## Date

2026-06-20

## Context

`BatchQueueStore` accumulated multiple responsibilities, including execution, persistence, notification delivery, history handling, and recovery-oriented behavior.

The project needed better internal separation, but downstream code already depended on `BatchQueueStore` as the public queue boundary.

A full rewrite would have increased migration risk across UI, runtime, and background processing paths.

## Decision

MemoMark keeps `BatchQueueStore` as the stable public facade for the batch subsystem.

Internal responsibilities may be moved into focused supporting components, but the external queue boundary remains centered on `BatchQueueStore`.

This preserves a stable integration point while allowing internal architectural cleanup.

## Alternatives Considered

### Large rewrite of the batch subsystem

Rejected.

A large rewrite would increase regression risk across queue execution, recovery, notification, and persistence semantics.

### Split public ownership across several new queue entry points

Rejected.

That would spread queue coordination responsibilities and increase migration cost for existing callers.

## Consequences

### Positive

- callers retain a stable queue integration boundary
- internal responsibilities can be improved incrementally
- architectural cleanup becomes safer than a full subsystem rewrite

### Negative

- the public facade remains a critical coordination type
- some complexity remains concentrated at the facade boundary

### Trade-offs

- MemoMark accepts a stable facade with internal decomposition instead of replacing the public subsystem shape all at once

## Follow-up Work

- continue internal batch decomposition only when responsibilities are clear
- avoid introducing parallel public queue entry points without a new ADR

## Supersession Note

ADR-011 retains `BatchQueueStore` as a migration compatibility facade but no
longer treats it as the permanent queue architecture. The target durable owner
is an actor-backed queue runtime/ledger with immutable task commands and typed
events or outcomes. The facade remains active until callers and evidence have
migrated; this status does not authorize premature removal.
