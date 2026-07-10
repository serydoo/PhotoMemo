# MemoMark Production Audit v2.0 Plan

Date: 2026-07-10

Baseline: `f74717f Add Production Audit v1.0 report`

## Purpose

Production Audit v1.0 established that MemoMark is ready to be evaluated as a
TestFlight validation candidate, but it mostly summarized release risks.

Production Audit v2.0 raises the review level from release risk to long-term
engineering fitness:

- Can the architecture keep evolving for the next five months?
- Can the codebase accept Video, HDR, RAW, Spatial Photo, AI Summary, and future
  sync work without collapsing existing boundaries?
- Are public service, repository, coordinator, and pipeline APIs consistent
  enough for continued maintenance?
- Which modules are testable, injectable, and diagnosable?
- Where is the architecture debt, not just the bug debt?

This review is intentionally modular. Each module gets its own report. The final
summary should be short and should reference module reports instead of
duplicating them.

## Rating System

| Dimension | Rating |
|---|---|
| Product Architecture | TBD |
| Engineering Quality | TBD |
| Release Readiness | TBD |
| Maintainability | TBD |
| Extensibility | TBD |
| Performance | TBD |
| Concurrency | TBD |
| Technical Debt | TBD |

Ratings use this scale:

- `A`: production-grade and ready to extend
- `A-`: strong, with contained debt
- `B+`: shippable, but needs planned hardening
- `B`: usable, with meaningful medium-term risk
- `C`: fragile or blocking future work

## Module Plan

### 1. Architecture & Dependency Audit

Scope:

- App entry and composition root
- dependency direction
- module boundaries
- architecture debt
- API shape across App, Service, Repository, Coordinator, Pipeline
- future extensibility pressure

Outputs:

- module boundary score
- architecture debt list
- dependency violations or near-violations
- future evolution blockers
- immediate fix recommendations

### 2. State & Repository Audit

Scope:

- SwiftUI state ownership
- Repository source-of-truth rules
- Configuration Session and Snapshot
- persistence consistency
- selected object/configuration identity

Outputs:

- state-source map
- persistence-source map
- P0/P1/P2 findings
- short-term release fixes
- long-term state model direction

### 3. Memory Engine & Expression Audit

Scope:

- MemorySubject
- Time Anchor and Life Anchor semantics
- Capture-Time Principle
- Expression Provider and variable projection
- Presentation Engine readiness

Outputs:

- semantic correctness findings
- model responsibility findings
- variable/API consistency findings
- IA-003 compatibility notes

### 4. Media Pipeline Audit

Scope:

- Metadata
- Renderer
- Live Photo
- Export
- Photo Library save-back
- MediaPipelineVNext extensibility

Outputs:

- pipeline boundary map
- still/Live Photo parity findings
- Video/HDR/RAW/Spatial Photo readiness assessment
- export fidelity and metadata preservation debt

### 5. SwiftUI Audit

Scope:

- View composition
- lifecycle refresh
- state duplication
- navigation/sheet/editing flows
- preview/render consistency
- UI performance

Outputs:

- view ownership map
- state duplication findings
- user-visible consistency risks
- decomposition plan

### 6. Release Audit

Scope:

- performance
- concurrency
- memory usage
- error handling
- observability
- dead code and release hygiene
- TestFlight readiness

Outputs:

- release score
- concurrency and memory risk list
- error observability backlog
- final TestFlight recommendation

## Review Protocol

Each module report must include:

- `Scope`
- `Evidence`
- `Ratings`
- `P0 / P1 / P2 Findings`
- `Architecture Debt`
- `Evolution Review`
- `API Design Review`
- `Dependency Review`
- `Testability Review`
- `Immediate Fixes`
- `Long-Term Optimization`
- `Release Recommendation`

P1 findings must state whether they should be fixed before the current
TestFlight candidate or can be explicitly deferred.

P2 findings must be classified as either:

- `near-term maintenance`
- `long-term architecture`
- `future capability blocker`

## Final Deliverable

After the six module reports are complete, create:

`MemoMark_Production_Audit_v2_0_Final_2026-07-10.md`

The final report should contain:

- the rating table
- top release blockers
- top architecture debts
- technical debt backlog
- recommended fix order
- final TestFlight decision
