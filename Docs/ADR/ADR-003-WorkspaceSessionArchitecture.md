# Incremental Workspace Session Migration

## Status

Accepted

## Date

2026-06-20

## Context

`MainView` historically contained workflow coordination, state management, lifecycle handling, and editor responsibilities.

The project needed a clearer workspace architecture for long-term maintainability and future iOS portability.

However, a full rewrite of the editor flow would have carried high regression risk because preview, template editing, permission flows, and export coordination are tightly connected.

## Decision

MemoMark introduces a workspace session architecture through:

- `WorkspaceSessionController`
- `WorkspaceState`
- `WorkspaceAction`
- `WorkspaceEnvironment`

Migration into this architecture happens incrementally.

`MainView` remains the root view shell while workflow responsibilities move in controlled slices rather than through a big-bang rewrite.

## Alternatives Considered

### Rewrite MainView completely

Rejected.

The workflow is too cross-cutting for a safe large rewrite.

### Leave all workflow coordination in MainView permanently

Rejected.

That would preserve a brittle long-term architecture and make future state ownership harder to reason about.

## Consequences

### Positive

- architecture can improve without breaking the existing workflow in one large step
- state ownership and workflow boundaries can be clarified gradually
- regression risk is lower than a full rewrite

### Negative

- migration requires a temporary coexistence period between old and new boundaries
- contributors must tolerate some duplication while the migration is incomplete

### Trade-offs

- MemoMark accepts a longer migration timeline in exchange for safer behavioral preservation

## Follow-up Work

- migrate cohesive workflow slices one at a time
- update or add ADRs if the workspace boundary changes materially beyond incremental migration
