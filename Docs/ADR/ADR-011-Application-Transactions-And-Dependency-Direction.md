# ADR-011: Application Transactions And Dependency Direction

## Status

Accepted

## Date

2026-08-29

## Context

MemoMark's product pipeline and data contracts are mature, but runtime
responsibilities are distributed across large UI, queue, processing, and
PhotoKit types. Several objects simultaneously own observable state, durable
truth, orchestration, platform side effects, and recovery behavior.

The product owner authorized a behavior-preserving redesign of the internal
core architecture. Existing feature behavior, configuration compatibility,
memory truth, media fidelity, original-photo protection, renderer/layout
contracts, and Photo Library idempotency remain mandatory.

The project needs a durable dependency rule that allows current facades to be
replaced without creating a second production path or applying a generic
architecture template mechanically.

## Decision

MemoMark adopts a transaction-centered dependency architecture:

```text
Presentation -> Application Transactions -> Domain Kernel
Platform Adapters -> Application Ports -> Domain Kernel
Composition Root constructs the graph and owns no product behavior.
```

The decision has these rules:

1. Domain types own deterministic product meaning and state-transition policy.
   They do not depend on UI or Apple platform side-effect frameworks.
2. Application transactions accept immutable commands and return typed results,
   receipts, or events. They orchestrate one user-meaningful or recovery-
   meaningful operation.
3. Protocols are introduced only for external effects or independently
   replaceable durable stores. Internal deterministic types are not mocked.
4. Actor-backed repositories/ledgers own cross-task durable mutable state.
   SwiftUI observable objects own presentation projections only.
5. Heavy media, metadata, render, export, and file work do not inherit
   `@MainActor` merely because the composition root or caller is UI-bound.
6. State lifetimes are explicit: durable truth, editing draft, immutable
   production snapshot, runtime request, presentation projection, and platform
   resource cannot be peer sources of truth.
7. Existing facades remain compatibility seams during additive migration, but
   they are not permanent architectural constraints. They may be removed after
   callers, tests, recovery behavior, and physical-device evidence move to the
   accepted target path.
8. Compile-time modules are introduced only after source dependencies are
   one-way and acyclic.

This ADR supersedes ADR-002's permanent interpretation of
`BatchQueueStore` as the public queue architecture. During migration,
`BatchQueueStore` remains the compatibility facade. The target durable queue
authority is an actor-backed queue runtime/ledger; task executors consume
immutable commands and cannot mutate the queue store directly.

ADR-001's single snapshot authority, ADR-006's Memory Engine ownership,
ADR-007's Provider/Expression ownership, ADR-008 and ADR-010's geometry/artifact
contracts, and ADR-009's single durable configuration aggregate remain binding
behavior and data decisions. Their current concrete types may be migrated when
the same authority and compatibility are proven.

## Alternatives Considered

### Keep Current Facades Permanent And Only Split Files

Rejected. It reduces file size without resolving mixed state, side-effect,
actor, and recovery ownership. `BatchTaskProcessor` would still mutate the UI-
observable queue store and PhotoKit transactions would remain inseparable from
receipt persistence.

### Big-Bang Rewrite Into New Modules

Rejected. It would create parallel truth, obscure feature parity, and put
configuration data, PhotoKit idempotency, Live Photo pairing, and queue recovery
at unacceptable risk.

### Generic Clean Architecture With Protocols For Every Type

Rejected. It would add indirection and mock internal logic instead of isolating
real external effects. MemoMark uses concrete deterministic domain types and
narrow capability ports.

### Keep All Runtime Work On MainActor

Rejected. Main-actor isolation is correct for UI projections, but it is not an
ownership model for media decoding, metadata, rendering, file persistence,
queue execution, or PhotoKit recovery.

### Split Into Swift Packages Immediately

Rejected. Current dependency cycles must be removed in source first. Premature
packages would convert architectural work into project-file and access-control
work without proving better ownership.

## Consequences

### Positive

- durable state machines become testable independently of media execution and
  SwiftUI;
- PhotoKit and filesystem failure paths gain deterministic protocol seams;
- UI roots and feature views shrink without creating one umbrella ViewModel;
- actor isolation follows mutable-state ownership instead of convenience;
- feature parity can be migrated one transaction at a time;
- future compile-time modules have a concrete dependency direction.

### Negative

- compatibility facades and new transaction owners coexist temporarily;
- some APIs become asynchronous when durable state moves behind actors;
- schema and event adapters are required during migration;
- tests must distinguish domain policy, transaction orchestration, adapter
  behavior, and physical Apple-framework evidence.

### Trade-offs

- MemoMark accepts a longer additive migration in exchange for retaining one
  production path and one source of truth throughout the work.
- Concrete facade stability is traded for stronger long-term ownership, while
  user behavior and durable compatibility remain stable.
- Compile-time modularity is delayed until the dependency graph is honest.

## Follow-up Work

- implement RFC-002 in independently verified slices;
- freeze schema, queue transition, presentation artifact, and receipt fixtures;
- establish the composition/application transaction foundation;
- migrate configuration, queue, Photo Library, media, and presentation owners
  in that risk order;
- mark compatibility ADRs and facades superseded only when their runtime path is
  actually removed;
- require a superseding production certification before declaring completion.

## Implementation Note — 2026-08-30

The batch queue's production durable authority has moved to
`BatchQueueDurableLedger`. `BatchQueueStore` remains the main-actor
compatibility/presentation facade, while runtime mutations commit through the
actor before projection. A startup-only synchronous adapter completes legacy
receipt reconciliation before first actor use; it does not operate as a
parallel runtime writer. The Photo Library receipt lifecycle is likewise
owned by the shared `PhotoLibrarySaveReceiptLedger`; its sole synchronous
capability is attaching a PhotoKit placeholder identifier to an already
durable pre-commit intent inside `performChanges`. Compile-time module
enforcement, physical-device interruption evidence, and superseding production
certification remain follow-up work. Static-photo and Live Photo transaction
owners share a narrow `PhotoLibraryTransactionGateway` for Apple-framework
mechanics while retaining their distinct resource and product-error semantics.
