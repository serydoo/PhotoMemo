# MemoMark Architecture Freeze V1

Last updated: 2026-07-01

## Purpose

This document freezes the near-term architecture rules for the current MemoMark V1 / IA-003 integration work.

The immediate goal is not “split large files for appearance.”

The immediate goal is:

```text
make boundaries strict enough that future Intent / UseCase development
can happen without View, Session, and MME drift.
```

## Current Diagnosis

MemoMark has already completed the first stage of refactor in several areas:

- large views were partially decomposed
- coordinators / repositories / intents exist
- MME preview routing exists

The current problem is no longer “whether code can be split.”

The current problem is:

```text
which layer owns which responsibility
```

The four active risks are:

1. UI layer still owns business flow in parts of V1.
2. Application-layer seams exist, but dependency direction is inconsistent.
3. `ConfigurationSession` is growing into a God Object.
4. MME is not yet the only source of truth everywhere.

## Layer Model

MemoMark should now be understood through four layers:

```text
Presentation
-> Application
-> Domain
-> Infrastructure
```

These are architecture boundaries, not necessarily top-level folder migration requirements for this slice.

## Presentation

Presentation includes:

- SwiftUI Views
- Presenters
- draft state
- bindings
- selection chrome
- preview-only UI coordination

Presentation may depend on:

- Application entry points
- pure presentation helpers
- immutable value models

Presentation must not:

- instantiate services directly
- read/write persistence directly
- decide fallback business flow
- assemble parallel save/bootstrap logic outside Application

### Presentation Iron Rule

```text
View must not new Service.
```

Examples now forbidden in View or presentation helpers:

- `SettingsService()`
- `PhotoLibraryExportService()`
- `XXXManager()`

Allowed direction:

```text
View
-> Intent / Action
-> Application entry
```

Forbidden direction:

```text
View
-> Service
-> persistence / PhotoKit / export logic
```

## Application

Application owns workflow orchestration.

It includes:

- UseCase-like entry points
- coordinators that orchestrate one user/business action
- normalization of read/write flow
- aggregation of repository calls

Application should be the only layer that decides:

- how V1 configuration is saved
- how bootstrap state is restored
- how album resolution participates in save flow
- how preview/save/export actions are sequenced

### Application Rule

Application entry points should have one clear direction.

For the current V1 line, the preferred near-term shape is:

```text
Intent
-> Coordinator / UseCase
-> Repository
```

Not:

```text
Intent
-> sometimes Coordinator
-> sometimes Repository
-> sometimes closure
-> sometimes new Service
```

### Immediate Application Entries To Preserve

- `SaveV1ConfigurationIntent`
- `LoadV1ConfigurationBootstrapIntent`
- album selection resolution as an application concern
- V1 diagnostics refresh as an application concern

### Immediate Application Entries To Add Or Consolidate

- `ApplyV1Configuration` flow
- `BootstrapV1Configuration` flow
- future `ComposePreview` flow
- future `RefreshProcessingDiagnostics` flow

## Domain

Domain owns product truth.

It includes:

- `MemoryExpressionEngine`
- subject / anchor / template semantics
- memory-expression rules
- capture-time-driven meaning

### Domain Rule

If a concept is domain truth, there must not be parallel implementations.

For the current V1 line, that means the long-term direction is:

```text
Preview
Render
Export
Share
Shortcut
Widget
-> MME
```

Stale fallbacks such as hardcoded:

- old token chains
- old preview-only sentence splices
- `"当天 11个月28天"`

must be removed over time.

## Infrastructure

Infrastructure owns external systems and persistence details.

It includes:

- `SettingsService`
- PhotoKit / album export services
- EXIF / metadata readers
- persistence and shared-defaults access

Infrastructure must not be directly reached from Presentation.

## ConfigurationSession Freeze

`ConfigurationSession` must remain a session seam, not a system seam.

It may own:

- live configuration-center state
- selection state
- controlled session mutations

It should not permanently keep accumulating:

- mock factory
- preview default registry
- template registry
- wording fallbacks
- presentation projection bundles

### Required Next Split For ConfigurationSession

Move these responsibilities out into dedicated helpers:

- preview defaults / template registry
- mock seed factory
- session projection copy
- UI-only output/write options

## Implementation Order Freeze

The approved near-term order is:

1. Remove `View -> Service` and `View -> direct persistence` paths.
2. Consolidate save/bootstrap through single Application seams.
3. Split `ConfigurationSession` by responsibility, not just by file size.
4. Remove non-MME wording drift and parallel smart-module logic.
5. Only then continue broader Intent / UseCase cleanup.

## What This Freeze Prevents

This freeze is intended to stop the repository from drifting back into:

- file-splitting without boundary cleanup
- new fallback logic inside Views
- new service instantiations inside presentation helpers
- more `ConfigurationSession` responsibility creep
- parallel memory-expression logic outside MME

## Acceptance Standard For Future Refactor Slices

A refactor slice is directionally correct if it does at least one of these:

- reduces Presentation knowledge of Infrastructure
- reduces duplicate Application entry paths
- reduces `ConfigurationSession` responsibility mixing
- reduces non-MME expression drift

A refactor slice is not sufficient if it only:

- moves code between files
- renames helpers
- shortens a file without clarifying ownership
