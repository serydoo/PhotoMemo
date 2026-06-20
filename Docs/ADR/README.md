# PhotoMemo ADR System

## What ADR Means

ADR stands for Architecture Decision Record.

An ADR captures a durable architecture decision, the context that led to it, the alternatives that were considered, and the consequences of choosing it.

An ADR is not a task log and not an implementation guide.

## Why PhotoMemo Uses ADR

PhotoMemo is intended to be maintained for many years.

The project already has strong implementation and handoff notes, but long-term maintenance also requires a stable record of architectural intent.

PhotoMemo uses ADR so future contributors can understand:

- why a boundary exists
- why one model was kept and another was rejected
- why a migration is incremental instead of a rewrite
- what trade-offs were accepted on purpose

## Architecture vs Documentation vs Implementation

Architecture defines the system boundaries, responsibilities, and durable technical decisions.

Documentation explains the product, plans, current state, operating context, and historical changes around the codebase.

Implementation is the concrete Swift, SwiftUI, service, rendering, export, and persistence code that executes those decisions.

In short:

- ADR explains why a major architectural choice exists
- other docs explain project context and change history
- code explains how the decision is implemented

## What Should Have An ADR

Create an ADR when a change modifies a meaningful architecture boundary or permanent technical direction.

Examples:

- introducing a new stable facade
- changing the canonical data model
- defining whether a subsystem stays local-first
- deciding whether a workflow is incremental or rewritten
- extracting an editor-only engine to protect downstream boundaries

Do not create an ADR for ordinary feature work unless the feature changes an architectural decision.

## How To Create Future ADRs

1. Copy `TEMPLATE.md`
2. Assign the next sequential ADR number
3. Name the file `ADR-XXX-ShortTitle.md`
4. Write the problem in `Context` before the solution in `Decision`
5. Record rejected alternatives honestly
6. Record positive and negative consequences
7. Add the new ADR to `INDEX.md`
8. Update the ADR before changing code if the code change alters architecture boundaries

## Naming Convention

File format:

`ADR-XXX-ShortTitle.md`

Rules:

- `XXX` is a zero-padded sequence number
- title words use concise engineering language
- file names should describe the decision, not the implementation task

Examples:

- `ADR-006-RendererProtocolBoundary.md`
- `ADR-007-PhotoLibraryWriteIsolation.md`

## Status Lifecycle

Allowed statuses:

- `Proposed`
- `Accepted`
- `Superseded`
- `Deprecated`
- `Rejected`

Meaning:

- `Proposed`: under discussion, not yet project policy
- `Accepted`: current approved architectural decision
- `Superseded`: replaced by a later ADR
- `Deprecated`: still present historically, but no longer recommended for future work
- `Rejected`: considered and explicitly not adopted

When an ADR is replaced, do not delete it. Mark it `Superseded` and reference the newer ADR.

## Relationship To Other Project Documents

These documents answer different questions:

- ADR answers: `WHY`
- `HANDOFF.md` answers: `WHAT CHANGED`
- `AI_CONTEXT.md` answers: `CURRENT PROJECT STATE`
- `PROJECT_HISTORY.md` answers: `PROJECT EVOLUTION`

Practical distinction:

- use ADR when a contributor asks why the architecture is shaped this way
- use `HANDOFF.md` when a contributor asks what landed recently
- use `AI_CONTEXT.md` when a contributor needs the active product and technical framing
- use `PROJECT_HISTORY.md` when a contributor needs long-range chronology

## Working Rule

For PhotoMemo, any change that affects architecture boundaries should update the relevant ADR before the code change is implemented.

Feature work does not need a new ADR unless it changes an architectural decision.
