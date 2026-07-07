# Editor Projection Engine

## Status

Accepted

## Date

2026-06-20

## Context

Editor-specific logic for composer behavior had accumulated close to `MainView`.

That logic included:

- display text projection
- module span generation
- selection normalization
- caret adjustment
- chip deletion range handling
- projection synchronization

These behaviors are necessary for editing, but they are not part of renderer, export, batch, or persistence boundaries.

The project needed a cleaner editor-specific architecture without changing the canonical template model.

## Decision

MemoMark extracts an `EditorProjectionEngine` for editor-only projection behavior.

This engine is responsible for:

- generating display text from template strings
- generating and sanitizing module spans
- normalizing selections
- adjusting caret positions
- computing chip deletion and replacement ranges
- synchronizing projection state from raw template input

Projection concepts remain editor-specific and are not exposed as dependencies of renderer, export, batch, or persistence systems.

## Alternatives Considered

### Leave projection logic inside MainView-oriented helpers

Rejected.

That weakens separation of concerns and keeps editor-specific behavior coupled to broader view coordination.

### Introduce a richer editor document model

Rejected.

The architecture decision for canonical content remains string-based, and a richer model would exceed the required boundary cleanup.

## Consequences

### Positive

- editor-specific behavior is isolated behind a clearer boundary
- MainView-related code becomes less responsible for projection mechanics
- renderer, export, and batch remain protected from editor-only concepts

### Negative

- the editor subsystem now depends on one more dedicated engine
- contributors must understand the distinction between canonical strings and projected editor state

### Trade-offs

- MemoMark accepts a dedicated editor projection layer in exchange for preserving clean downstream boundaries

## Follow-up Work

- keep future composer behavior changes routed through the editor projection boundary
- avoid leaking projection-only types into non-editor subsystems
