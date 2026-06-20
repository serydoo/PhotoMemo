# Template String as the Canonical Model

## Status

Accepted

## Date

2026-06-20

## Context

PhotoMemo evaluated whether the composer should adopt a richer editor document model.

Possible alternatives included custom document types, node trees, or richer editor-specific content structures.

However, the broader system already depends on template strings across:

- settings persistence
- renderer input
- export preparation
- batch configuration snapshots
- share extension configuration loading
- variable rendering

The project needed a clear decision on the canonical model before editor architecture evolved further.

## Decision

Template strings remain the canonical model for PhotoMemo content composition.

The editor may use projection logic for editing behavior, but:

- renderer remains string-based
- export remains string-based
- batch remains string-based
- settings remain string-based
- persistence remains string-based
- share extension configuration remains string-based

No richer document model is introduced as the system source of truth.

## Alternatives Considered

### Introduce ComposerDocument as the canonical model

Rejected.

The editor-specific complexity does not justify a project-wide migration of renderer, export, batch, settings, and persistence boundaries.

### Use both string and document models as peer sources of truth

Rejected.

That would create synchronization risk and long-term ambiguity about canonical ownership.

## Consequences

### Positive

- system-wide data flow stays simple
- renderer, export, batch, and persistence remain aligned
- editor improvements can remain local to the editor boundary

### Negative

- editor projection logic must bridge from strings instead of editing a richer native model
- some editor behavior remains more complex than the canonical data model

### Trade-offs

- PhotoMemo accepts editor-local projection complexity in exchange for keeping the rest of the system simpler

## Follow-up Work

- keep future editor architecture additive around the string boundary
- revisit this decision only if multiple downstream systems truly require a richer canonical model
