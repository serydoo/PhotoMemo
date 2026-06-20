# Single Source of Truth for Batch Configuration

## Status

Accepted

## Date

2026-06-20

## Context

PhotoMemo constructs runtime batch configuration snapshots for preview, export, background intake, and share-extension-driven processing.

Snapshot construction previously existed in more than one place.

That created a risk that default templates, anchors, album identifiers, or description-writing settings could diverge across entry points.

The project needed one authoritative place to build runtime batch configuration snapshots.

## Decision

PhotoMemo uses `BatchConfigurationSnapshotProvider` as the single source of truth for runtime batch configuration snapshot construction.

This provider is responsible for:

- supplying default values
- loading shared configuration inputs
- building runtime snapshot values
- converting stored configuration into the snapshot shape used by processing flows

Other components may request snapshots, but they should not reconstruct default batch configuration independently.

## Alternatives Considered

### Keep duplicated implementations

Rejected.

Multiple construction paths create configuration drift risk between the main app and other runtime entry points.

### Move snapshot construction into each consumer

Rejected.

That would spread default semantics across preview, batch, and extension boundaries, making future maintenance harder.

## Consequences

### Positive

- default configuration logic is centralized
- share extension and main app read the same architectural decision
- future changes to batch defaults have one clear modification point

### Negative

- one provider becomes a critical dependency for snapshot construction
- future contributors must preserve this boundary instead of adding local shortcuts

### Trade-offs

- PhotoMemo accepts a more explicit provider boundary in exchange for lower configuration drift risk

## Follow-up Work

- keep new snapshot-related changes routed through the provider
- record any future snapshot format decision in a new ADR if the architecture changes again
