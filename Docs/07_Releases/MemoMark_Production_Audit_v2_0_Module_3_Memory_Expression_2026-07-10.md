# MemoMark Production Audit v2.0 Module 3

Module: Memory Engine & Expression Audit

Date: 2026-07-10

Baseline: `f74717f Add Production Audit v1.0 report`

## Scope

This module reviews:

- `MemorySubject` and adapter behavior
- Time Anchor and Life Anchor semantics
- Capture-Time Principle
- `MemoryExpressionEngine`
- `ProductionMemoryResolver`
- `CardVariableProvider`
- Expression Provider readiness
- IA-003 compatibility and AI Summary future fit

No files were modified during this module review.

## Executive Assessment

Rating: **B**

The Memory Engine boundary is directionally healthy. It does not appear to
depend on UI, Renderer, Repository, Photo Library, or network behavior. This is
the right shape for MemoMark V2.

The main release risk is semantic truth: several fallback paths still use
`Date()` when capture time, reference date, or anchor truth is missing. That is
not just a formatting issue. It can create false memory positions. For
MemoMark, false memory time is worse than missing memory time.

The module is ready for continued IA-003 work, but it should not be described
as fully production-grade until capture-time resolution is explicit.

## Evidence

- IA-003 order and frozen boundary:
  - `AGENTS.md:21`
- Capture-Time Principle:
  - `Docs/PDR/PDR-004_Configuration_Center_Architecture.md:317`
- Memory Engine should not invent data:
  - `Docs/MemoryEngine.md:74`
- `MemorySubject` model:
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift:34`
- `MemoryResult` contract:
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryResult.swift:150`
- Provider architecture ADR:
  - `Docs/ADR/ADR-007-ProviderBasedExpressionArchitecture.md:24`

## Ratings

| Dimension | Rating | Rationale |
|---|---|---|
| Semantic Correctness | B | Core model is sound, but false fallback dates remain. |
| Capture-Time Compliance | B- | Correct principle exists; some production paths still fall back to current time. |
| IA-003 Compatibility | B+ | Boundaries align with the approved IA-003 sequence. |
| Expression Provider Readiness | B | Provider idea is good, but value API is incomplete. |
| AI Summary Readiness | B- | Possible as a future provider, not as deterministic core. |
| Testability | B+ | Good contract tests exist; timezone and missing-date tests are missing. |
| Release Readiness | B | Fine for scoped TestFlight, not for "full Memory Engine production" claims. |

## P0 Findings

No P0 findings.

No evidence was found that Memory Engine directly depends on UI, Renderer, Photo
Library, or network behavior.

## P1 Findings

### P1-01: Memory expression uses current calendar instead of capture calendar

Evidence:

- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift:101`
- `Source/PhotoMemo/PhotoMemo/Models/PhotoMetadata.swift:709`
- `Source/PhotoMemo/PhotoMemo/Models/MetadataContext.swift:390`

Impact:

`MemoryExpressionEngine` uses `Calendar.current`. For photos captured in a
different timezone than the device's current timezone, age/countdown/life
position can drift relative to metadata display.

Immediate fix?

Required before IA-003D `CaptureTimeResolver` is considered closed. It can be
explicitly deferred for a narrow TestFlight if release notes avoid cross-timezone
accuracy claims.

Recommendation:

Add calendar or capture timezone to `MemoryExpressionContext` and remove naked
`Calendar.current` from memory expression calculations.

### P1-02: Legacy and Share paths can produce false memory time with `Date()`

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:173`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:75`
- `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift:21`

Impact:

When capture date is missing and `MemoryResult` does not cover the path,
processing/build time can become memory time. That violates the Capture-Time
Principle and can create incorrect user-facing anchor values.

Immediate fix?

Recommended before treating Apple Photos Share flow as production-stable. If
the current release is limited to main picker / still-image smoke, it can be
deferred with an explicit limitation.

Recommendation:

Use an explicit missing/unknown capture-time state. Do not synthesize memory
truth from export time.

### P1-03: `MemorySubjectAdapter` uses `Date()` for missing reference truth

Evidence:

- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift:23`

Impact:

If birthday, anchor, or reference date is missing, the adapter can freeze "now"
into the subject truth. This makes the same subject produce different memory
outputs depending on when it is adapted.

Immediate fix?

Recommended before IA-003A closure.

Recommendation:

Represent missing reference date explicitly and let UI/presentation decide how
to communicate the missing state.

## P2 Findings

### P2-01: Expression provider API has token registry but not value resolution

Evidence:

- `Source/PhotoMemo/PhotoMemo/Expression/ExpressionProvider.swift:3`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryProvider.swift:33`
- `Source/PhotoMemo/PhotoMemo/LocationExpression/Providers/LocationExpressionProvider.swift:29`

Impact:

Providers expose different signatures and only share `canonicalTokens`. Future
AI Summary, People, Weather, or richer local providers will likely hard-code
against `CardVariableProvider` unless a common value API appears.

Classification: future capability blocker.

### P2-02: `subjectStrategy` and calculator protocols are not in the main path

Evidence:

- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift:6`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionProtocols.swift:12`

Impact:

The code suggests a more configurable expression architecture, but current
runtime usage is narrower. This can confuse future agents and developers.

Classification: near-term maintenance.

### P2-03: Memory Engine currently resolves only primary anchor

Evidence:

- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift:20`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift:109`

Impact:

Multi Life Anchor and full timeline results are not yet represented. This is
acceptable for V1, but it limits the future Memory Presentation Engine.

Classification: long-term architecture.

### P2-04: Memory result identity is unstable

Evidence:

- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift:111`

Impact:

Random `UUID` generation for `MemoryAnchorResult.id` makes caching, diagnostics,
and long-term diffing harder.

Classification: near-term maintenance.

## Architecture Debt

`CardVariableProvider` is the largest compatibility debt. It merges old
`AnchorResult`, new `MemoryResult`, export descriptions, metadata summary, and
template variables. It does not block the current release, but it will make AI
Summary and additional expression providers harder to add cleanly.

## Evolution Review

IA-003A/B/C direction is correct: `BatchConfigurationSnapshot` is a transport
DTO, and semantic production state is moving toward `ConfigurationSnapshot`.

The next architecture step should be CaptureTimeResolver, not renderer
expansion. This aligns with the repository rule that Memory Engine owns Life
Position and Renderer only draws resolved output.

## API Design Review

`ProductionMemoryResolver` has a clear production path, but it still accepts
`SelectedPhoto` and `BatchConfigurationSnapshot`. Long-term, it should receive a
smaller `MemoryProductionInput` so Memory Engine does not know app transport DTO
shape.

## Dependency Review

Dependency direction is healthy. Memory Engine files are dominated by
Foundation/domain types, and no direct UI/Renderer/Photo Library dependency was
found in this review.

## Testability Review

Existing strengths:

- frozen snapshot tests
- capture-time priority tests
- provider parity tests
- `MemoryResult` contract tests

Missing tests:

- capture timezone behavior in `MemoryExpressionEngine`
- missing capture date on Share/legacy path
- deterministic result identity
- adapter behavior when reference date is unknown

## Immediate Fixes

- Add capture calendar/timezone to memory expression context.
- Remove production `captureDate ?? Date()` memory fallbacks.
- Make unknown reference date explicit in `MemorySubjectAdapter`.

## Long-Term Optimization

- Create a real provider registry: `ProviderInput -> ExpressionValue`.
- Move from rendered text to field-based MemoryBlock resolution after IA-003C.
- Keep AI Summary optional, local-first, and outside deterministic Memory Engine
  core.

## Release Recommendation

Conditional Yes for scoped TestFlight.

Memory Engine should be labeled "integration candidate", not "fully
production-grade". If Share Extension is a core TestFlight path, P1-02 should
be fixed or explicitly scoped out.
